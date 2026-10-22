[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BatchRoot,

    [switch]$RequireScreenshots,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = [IO.Path]::GetFullPath($BatchRoot)
$errors = [Collections.Generic.List[string]]::new()
$warnings = [Collections.Generic.List[string]]::new()

function Add-MissingTextError {
    param([object]$Object, [string]$Property, [string]$Context)
    $propertyValue = $Object.PSObject.Properties[$Property]
    if ($null -eq $propertyValue -or [string]::IsNullOrWhiteSpace([string]$propertyValue.Value)) {
        $errors.Add("$Context missing $Property")
    }
}

function Test-LinkedFile {
    param([string]$RelativePath, [string]$Context, [string]$Field, [bool]$Required)
    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        if ($Required) { $errors.Add("$Context missing $Field") }
        return $false
    }
    $candidate = if ([IO.Path]::IsPathRooted($RelativePath)) { $RelativePath } else { Join-Path $root $RelativePath }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $errors.Add("$Context links missing file in $Field`: $RelativePath")
        return $false
    }
    return $true
}

if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Batch root not found: $root"
}

$manifestPath = Join-Path $root 'batch-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Batch manifest not found: $manifestPath"
}
$manifest = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json
$finalClaim = [string]$manifest.status -in @('evidence-complete', 'reported')
$executionClaim = $finalClaim -or [string]$manifest.status -eq 'executed'
if ([string]$manifest.status -notin @('draft', 'ready-for-review', 'fixed-for-this-batch', 'executed', 'evidence-complete', 'reported')) {
    $errors.Add('invalid batch status')
}

foreach ($field in @('batch_name', 'status', 'corpus_condition', 'question_set_version', 'session_policy', 'first_result_policy')) {
    Add-MissingTextError -Object $manifest -Property $field -Context 'batch manifest'
}
if (@($manifest.platforms).Count -lt 1) { $errors.Add('batch manifest has no platforms') }
if (@($manifest.question_ids).Count -lt 1) { $errors.Add('batch manifest has no question IDs') }
foreach ($field in @('objective', 'scoring_rule')) {
    if ([string]::IsNullOrWhiteSpace([string]$manifest.$field)) {
        if ($finalClaim) { $errors.Add("final batch $field is blank") }
        else { $warnings.Add("batch $field is blank") }
    }
}
$manifestScreenshotPolicyProperty = $manifest.PSObject.Properties['screenshot_policy']
$screenshotPolicy = if ($RequireScreenshots) {
    'exhaustive'
}
elseif ($null -eq $manifestScreenshotPolicyProperty -or [string]::IsNullOrWhiteSpace([string]$manifestScreenshotPolicyProperty.Value)) {
    $warnings.Add('batch manifest missing screenshot_policy; using decisive for backward compatibility')
    'decisive'
}
else {
    [string]$manifestScreenshotPolicyProperty.Value
}
if ($screenshotPolicy -notin @('decisive', 'exhaustive')) {
    $errors.Add("batch manifest has invalid screenshot_policy: $screenshotPolicy")
}

$checked = 0
foreach ($questionId in @($manifest.question_ids)) {
    $questionPath = Join-Path $root "questions\$questionId.md"
    if (-not (Test-Path -LiteralPath $questionPath -PathType Leaf)) {
        $errors.Add("missing question record: $questionId")
    }
    else {
        $questionText = Get-Content -Raw -LiteralPath $questionPath -Encoding UTF8
        foreach ($marker in @('Why this is tested:', 'Gold answer:', 'Source anchor:', '## Atomic key facts', '## Judgment rule')) {
            if ($questionText -notlike "*$marker*") { $errors.Add("question $questionId missing marker: $marker") }
        }
        if ($questionText -match '<[^>]+>') {
            if ($finalClaim) { $errors.Add("question $questionId still contains template placeholders") }
            else { $warnings.Add("question $questionId still contains template placeholders") }
        }
    }

    foreach ($platform in @($manifest.platforms)) {
        $checked++
        $context = "$questionId/$platform"
        $evidencePath = Join-Path $root "evidence\$questionId\$platform\evidence.json"
        if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
            $errors.Add("missing evidence manifest: $context")
            continue
        }
        $evidence = Get-Content -Raw -LiteralPath $evidencePath -Encoding UTF8 | ConvertFrom-Json
        if ([string]$evidence.observation_status -eq 'not-run') {
            if ($executionClaim) { $errors.Add("claimed executed/final batch contains unrun observation: $context") }
            else { $warnings.Add("observation not run: $context") }
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string]$evidence.observation_status)) {
            $errors.Add("$context observation status is blank")
        }
        foreach ($field in @('session_id', 'observed_at', 'answer_raw_path', 'verdict', 'citation_verdict')) {
            Add-MissingTextError -Object $evidence -Property $field -Context $context
        }
        if ([string]$evidence.verdict -notin @('pass', 'partial', 'fail', 'core-pass-extra-risk', 'gold-answer-pending')) {
            $errors.Add("$context has invalid verdict")
        }
        if ($finalClaim -and [string]$evidence.verdict -eq 'gold-answer-pending') {
            $errors.Add("$context cannot be final while gold answer is pending")
        }
        if ([string]$evidence.citation_verdict -notin @('correct', 'partial', 'wrong', 'missing', 'not-exposed')) {
            $errors.Add("$context has invalid citation verdict")
        }
        if (-not [bool]$evidence.first_response_preserved) { $errors.Add("$context first response is not marked preserved") }
        [void](Test-LinkedFile -RelativePath ([string]$evidence.answer_raw_path) -Context $context -Field 'answer_raw_path' -Required $true)

        $screenshotPairs = @(
            @{ Path = 'answer_screenshot_path'; Status = 'answer_screenshot_status'; Required = 'answer_screenshot_required' },
            @{ Path = 'retrieval_screenshot_path'; Status = 'retrieval_screenshot_status'; Required = 'retrieval_screenshot_required' },
            @{ Path = 'source_screenshot_path'; Status = 'source_screenshot_status'; Required = 'source_screenshot_required' }
        )
        foreach ($pair in $screenshotPairs) {
            $pathProperty = $evidence.PSObject.Properties[$pair.Path]
            $statusProperty = $evidence.PSObject.Properties[$pair.Status]
            $requiredProperty = $evidence.PSObject.Properties[$pair.Required]
            $value = if ($null -eq $pathProperty) { '' } else { [string]$pathProperty.Value }
            $visualRequired = $screenshotPolicy -eq 'exhaustive' -or
                ($null -ne $requiredProperty -and [bool]$requiredProperty.Value)
            $status = if ($null -eq $statusProperty -or [string]::IsNullOrWhiteSpace([string]$statusProperty.Value)) {
                if ([string]::IsNullOrWhiteSpace($value)) { 'missing' } else { 'captured' }
            }
            else {
                [string]$statusProperty.Value
            }
            if ($status -notin @('captured', 'not-required', 'not-exposed', 'capture-blocked', 'missing')) {
                $errors.Add("$context has invalid $($pair.Status): $status")
                continue
            }
            if ($status -eq 'captured') {
                [void](Test-LinkedFile -RelativePath $value -Context $context -Field $pair.Path -Required $true)
                continue
            }
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $errors.Add("$context has $($pair.Path) but $($pair.Status) is $status")
            }
            if ($visualRequired -and $status -eq 'not-required') {
                $errors.Add("$context marks required visual evidence as not-required in $($pair.Status)")
            }
            if ($visualRequired -and $status -in @('missing', 'capture-blocked', 'not-exposed')) {
                if ([string]::IsNullOrWhiteSpace([string]$evidence.screenshot_missing_reason)) {
                    $errors.Add("$context has required $($pair.Path) without screenshot_missing_reason")
                }
                if ([string]::IsNullOrWhiteSpace([string]$evidence.screenshot_acquisition_instruction)) {
                    $errors.Add("$context has required $($pair.Path) without screenshot_acquisition_instruction")
                }
                if ($finalClaim) {
                    $errors.Add("$context cannot be evidence-complete while required $($pair.Path) is $status")
                }
            }
            if (-not $visualRequired -and $status -eq 'missing') {
                $errors.Add("$context must mark intentionally omitted $($pair.Path) as not-required")
            }
        }
    }
}

$result = [PSCustomObject]@{
    batch_root = $root
    evidence_units_checked = $checked
    screenshot_policy = $screenshotPolicy
    require_screenshots_override = [bool]$RequireScreenshots
    valid = ($errors.Count -eq 0)
    validation_scope = $(if ($finalClaim) { 'final-evidence-check' } else { 'structure-and-records-check' })
    evidence_complete = ($finalClaim -and $errors.Count -eq 0)
    errors = @($errors)
    warnings = @($warnings)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
}
else {
    $result
}

if ($errors.Count -gt 0) { exit 1 }
