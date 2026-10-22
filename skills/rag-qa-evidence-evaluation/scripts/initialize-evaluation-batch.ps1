[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
    [string]$BatchName,

    [Parameter(Mandatory = $true)]
    [ValidateCount(1, 20)]
    [string[]]$Platforms,

    [Parameter(Mandatory = $true)]
    [ValidateCount(1, 500)]
    [string[]]$QuestionIds,

    [Parameter(Mandatory = $true)]
    [string]$CorpusCondition,

    [string]$QuestionSetVersion = "draft",
    [string]$SessionPolicy = "isolated-new-session-per-platform-question",
    [string]$FirstResultPolicy = "preserve-first-complete-response",

    [ValidateSet('decisive', 'exhaustive')]
    [string]$ScreenshotPolicy = "decisive"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedRoot = [IO.Path]::GetFullPath($OutputRoot)
if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
    New-Item -ItemType Directory -Path $resolvedRoot -Force | Out-Null
}

$batchRoot = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $BatchName))
$allowedPrefix = $resolvedRoot.TrimEnd('\') + '\'
if (-not $batchRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Batch path escaped the output root: $batchRoot"
}
if (Test-Path -LiteralPath $batchRoot) {
    throw "Batch already exists: $batchRoot"
}

$cleanPlatforms = @($Platforms | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
$cleanQuestions = @($QuestionIds | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
if ($cleanPlatforms.Count -ne $Platforms.Count) {
    throw "Platform names must be non-empty and unique."
}
if ($cleanQuestions.Count -ne $QuestionIds.Count) {
    throw "Question IDs must be non-empty and unique."
}
foreach ($value in @($cleanPlatforms + $cleanQuestions)) {
    if ($value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw "Unsafe platform or question identifier: $value"
    }
}

New-Item -ItemType Directory -Path $batchRoot | Out-Null
foreach ($folder in @('questions', 'evidence', 'reports', 'setup')) {
    New-Item -ItemType Directory -Path (Join-Path $batchRoot $folder) | Out-Null
}

$manifest = [ordered]@{
    schema_version = 1
    batch_name = $BatchName
    status = 'draft'
    created_at = (Get-Date).ToString('o')
    objective = ''
    platforms = $cleanPlatforms
    corpus_condition = $CorpusCondition
    corpus_artifacts = @()
    question_set_version = $QuestionSetVersion
    question_ids = $cleanQuestions
    configuration_snapshot = [ordered]@{}
    session_policy = $SessionPolicy
    cache_policy = ''
    retry_policy = ''
    first_result_policy = $FirstResultPolicy
    scoring_rule = ''
    screenshot_policy = $ScreenshotPolicy
    authorized_operations = @()
    cost_boundary = ''
    exclusions = @()
    deviations = @()
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $batchRoot 'batch-manifest.json') -Encoding UTF8

$assetRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets'
Copy-Item -LiteralPath (Join-Path $assetRoot 'presentation-report-template.md') -Destination (Join-Path $batchRoot 'reports\presentation-report.md')
Copy-Item -LiteralPath (Join-Path $assetRoot 'detailed-report-template.md') -Destination (Join-Path $batchRoot 'reports\detailed-report.md')

foreach ($questionId in $cleanQuestions) {
    $questionTemplate = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $assetRoot 'question-record-template.md')
    $questionTemplate.Replace('<question-id>', $questionId) | Set-Content -LiteralPath (Join-Path $batchRoot "questions\$questionId.md") -Encoding UTF8

    foreach ($platform in $cleanPlatforms) {
        $evidenceRoot = Join-Path $batchRoot "evidence\$questionId\$platform"
        New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
        foreach ($folder in @('raw', 'screenshots')) {
            New-Item -ItemType Directory -Path (Join-Path $evidenceRoot $folder) | Out-Null
        }
        $evidence = [ordered]@{
            schema_version = 1
            question_id = $questionId
            platform = $platform
            observation_status = 'not-run'
            session_id = ''
            session_url = ''
            observed_at = ''
            elapsed_seconds = $null
            first_response_preserved = $false
            answer_raw_path = ''
            retrieval_raw_path = ''
            answer_screenshot_path = ''
            retrieval_screenshot_path = ''
            source_screenshot_path = ''
            answer_screenshot_status = 'not-required'
            retrieval_screenshot_status = 'not-required'
            source_screenshot_status = 'not-required'
            answer_screenshot_required = $false
            retrieval_screenshot_required = $false
            source_screenshot_required = $false
            visual_evidence_reason = ''
            screenshot_missing_reason = ''
            screenshot_acquisition_instruction = ''
            key_fact_result = [ordered]@{}
            verdict = ''
            citation_verdict = ''
            failure_layer = ''
            evidence_notes = ''
        }
        $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'evidence.json') -Encoding UTF8
    }
}

[PSCustomObject]@{
    batch_root = $batchRoot
    platforms = $cleanPlatforms.Count
    questions = $cleanQuestions.Count
    evidence_units = $cleanPlatforms.Count * $cleanQuestions.Count
}
