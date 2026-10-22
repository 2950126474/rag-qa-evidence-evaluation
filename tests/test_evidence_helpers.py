"""Synthetic record checks only; no platform calls or actual answer evaluation."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
RAG = ROOT / 'skills/rag-qa-evidence-evaluation/scripts'
PWSH = os.environ.get('SKILL_TEST_PWSH', 'pwsh')

class RagTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        result = subprocess.run([PWSH, '-NoProfile', '-File', str(RAG / 'initialize-evaluation-batch.ps1'),
                                 '-OutputRoot', str(self.root), '-BatchName', 'synthetic',
                                 '-Platforms', 'demo', '-QuestionIds', 'Q1', '-CorpusCondition', 'synthetic'], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.batch = self.root / 'synthetic'
        self.manifest_path = self.batch / 'batch-manifest.json'
        self.evidence_path = self.batch / 'evidence/Q1/demo/evidence.json'
        self.manifest = json.loads(self.manifest_path.read_text(encoding='utf-8-sig'))
        self.evidence = json.loads(self.evidence_path.read_text(encoding='utf-8-sig'))

    def validate(self):
        self.manifest_path.write_text(json.dumps(self.manifest), encoding='utf-8')
        self.evidence_path.write_text(json.dumps(self.evidence), encoding='utf-8')
        result = subprocess.run([PWSH, '-NoProfile', '-File', str(RAG / 'validate-evidence-batch.ps1'),
                                 '-BatchRoot', str(self.batch), '-Json'], capture_output=True, text=True, encoding='utf-8')
        return result.returncode, json.loads(result.stdout)

    def completed_fixture(self):
        self.manifest.update(status='evidence-complete', objective='synthetic check', scoring_rule='exact match')
        (self.batch / 'questions/Q1.md').write_text('Why this is tested: synthetic\nGold answer: 1\nSource anchor: fixture\n## Atomic key facts\n1\n## Judgment rule\nExact match\n', encoding='utf-8')
        (self.batch / 'evidence/Q1/demo/raw/answer.txt').write_text('1', encoding='utf-8')
        self.evidence.update(observation_status='executed', session_id='synthetic-session',
                             observed_at='2026-10-22T00:00:00Z', answer_raw_path='evidence/Q1/demo/raw/answer.txt',
                             verdict='pass', citation_verdict='correct', first_response_preserved=True)

    def test_draft_can_be_structurally_valid_without_being_complete(self):
        code, result = self.validate()
        self.assertEqual(code, 0)
        self.assertTrue(result['valid'])
        self.assertFalse(result['evidence_complete'])

    def test_existing_batch_is_preserved(self):
        before = self.manifest_path.read_bytes()
        result = subprocess.run([PWSH, '-NoProfile', '-File', str(RAG / 'initialize-evaluation-batch.ps1'),
                                 '-OutputRoot', str(self.root), '-BatchName', 'synthetic',
                                 '-Platforms', 'demo', '-QuestionIds', 'Q1', '-CorpusCondition', 'synthetic'],
                                capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(before, self.manifest_path.read_bytes())

    def test_dot_identifiers_cannot_escape_evidence_layout(self):
        for field in ['-BatchName', '-Platforms', '-QuestionIds']:
            args = {'-BatchName': 'rejected', '-Platforms': 'demo', '-QuestionIds': 'Q1'}
            args[field] = '..'
            command = [PWSH, '-NoProfile', '-File', str(RAG / 'initialize-evaluation-batch.ps1'),
                       '-OutputRoot', str(self.root), '-CorpusCondition', 'synthetic']
            for key, value in args.items():
                command.extend([key, value])
            result = subprocess.run(command, capture_output=True)
            self.assertNotEqual(result.returncode, 0, field)
            self.assertFalse((self.root / 'rejected').exists())

    def test_unrun_rejected_for_executed_and_final_states(self):
        for status in ['executed', 'evidence-complete', 'reported']:
            self.manifest['status'] = status
            code, result = self.validate()
            self.assertNotEqual(code, 0)
            self.assertFalse(result['evidence_complete'])

    def test_complete_batch_passes(self):
        self.completed_fixture()
        code, result = self.validate()
        self.assertEqual(code, 0, result)
        self.assertTrue(result['evidence_complete'])

    def test_final_missing_rules_and_placeholders_rejected(self):
        self.completed_fixture()
        self.manifest['scoring_rule'] = ''
        self.assertNotEqual(self.validate()[0], 0)
        self.manifest['scoring_rule'] = 'exact'
        (self.batch / 'questions/Q1.md').write_text('Why this is tested:\nGold answer: <expected answer>\nSource anchor:\n## Atomic key facts\n## Judgment rule', encoding='utf-8')
        self.assertNotEqual(self.validate()[0], 0)

    def test_pending_gold_and_missing_raw_rejected(self):
        self.completed_fixture()
        self.evidence['verdict'] = 'gold-answer-pending'
        self.assertNotEqual(self.validate()[0], 0)
        self.evidence['verdict'] = 'pass'
        (self.batch / 'evidence/Q1/demo/raw/answer.txt').unlink()
        self.assertNotEqual(self.validate()[0], 0)

    def test_required_unavailable_screenshot_rejected_in_final(self):
        self.completed_fixture()
        self.evidence.update(answer_screenshot_required=True, screenshot_missing_reason='synthetic blocked UI',
                             screenshot_acquisition_instruction='open synthetic session')
        for status in ['not-required', 'missing', 'capture-blocked', 'not-exposed']:
            self.evidence['answer_screenshot_status'] = status
            self.assertNotEqual(self.validate()[0], 0, status)
        (self.batch / 'screen.png').write_bytes(b'synthetic placeholder; existence check only')
        self.evidence.update(answer_screenshot_status='captured', answer_screenshot_path='screen.png')
        self.assertEqual(self.validate()[0], 0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
