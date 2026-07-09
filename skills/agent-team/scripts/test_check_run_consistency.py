import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("check-run-consistency.py")


def sha256_file(path: Path) -> str:
    import hashlib

    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return "sha256:" + digest.hexdigest()


def write_run(run_dir: Path, state_overrides=None, interview_text=None):
    (run_dir / "assumptions.md").write_text(
        "| ID | 단계 | 담당 | 가정 | 근거 | 틀렸을 때 리스크 | 검증 방법 | 상태 |\n"
        "| --- | --- | --- | --- | --- | --- | --- | --- |\n",
        encoding="utf-8",
    )
    for name in ("01-pm-spec.md", "03-architect-design.md", "05-work-plan.md"):
        (run_dir / name).write_text(f"# {name}\n", encoding="utf-8")
    (run_dir / "00-pm-interview.md").write_text(
        interview_text
        or "implementation_approval: 05-work-plan.md 기준 구현 승인. 과거 기록: 재승인 필요였으나 지금은 재승인 완료.\n",
        encoding="utf-8",
    )

    state = {
        "run_id": run_dir.name,
        "mode": "implementation",
        "execution_mode": "auto_split",
        "runtime_mode": "local-process",
        "runtime_gate": "root-pre-pm",
        "pending_reapproval": False,
        "pending_reapproval_reason": None,
        "stale_approvals": [],
        "status": "active",
        "current_stage": "developer_implementation",
        "last_completed_stage": "implementation_approval",
        "next_stage": "developer_implementation",
        "gateway_retry_count": {"spec": 0, "design": 0, "final": 0},
        "review_retry_count": 0,
        "last_decision": None,
        "blocked_reason": None,
        "open_assumptions": [],
        "artifacts": {},
        "content_hashes": {
            "implementation_approval": {
                "approved_at": "2026-06-11T00:00:00Z",
                "inputs": {
                    "01-pm-spec.md": sha256_file(run_dir / "01-pm-spec.md"),
                    "03-architect-design.md": sha256_file(run_dir / "03-architect-design.md"),
                    "05-work-plan.md": sha256_file(run_dir / "05-work-plan.md"),
                },
            }
        },
        "updated_at": "2026-06-11T00:00:00Z",
    }
    if state_overrides:
        state.update(state_overrides)

    (run_dir / "run-state.json").write_text(json.dumps(state, ensure_ascii=False), encoding="utf-8")


class CheckRunConsistencyTests(unittest.TestCase):
    def run_checker(self, run_dir: Path):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(run_dir)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )

    def test_historical_reapproval_text_does_not_block_when_state_is_clear(self):
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp) / "2026-06-11-agent-team"
            run_dir.mkdir()
            write_run(run_dir)

            result = self.run_checker(run_dir)

            self.assertEqual(result.returncode, 0, result.stdout)

    def test_pending_reapproval_blocks_developer_entry(self):
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp) / "2026-06-11-agent-team"
            run_dir.mkdir()
            write_run(
                run_dir,
                {
                    "pending_reapproval": True,
                    "pending_reapproval_reason": "work plan changed after approval",
                },
            )

            result = self.run_checker(run_dir)

            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("pending_reapproval", result.stdout)

    def test_developer_entry_requires_approval_hash_baseline(self):
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp) / "2026-06-11-agent-team"
            run_dir.mkdir()
            write_run(run_dir, {"content_hashes": {}})

            result = self.run_checker(run_dir)

            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("implementation approval content hashes", result.stdout)

    def test_stale_approvals_block_developer_entry(self):
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp) / "2026-06-11-agent-team"
            run_dir.mkdir()
            write_run(run_dir, {"stale_approvals": ["expert_gateway_spec"]})

            result = self.run_checker(run_dir)

            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("stale_approvals", result.stdout)

    def test_reviewer_rework_outputs_do_not_extend_top_level_stage_numbering(self):
        with tempfile.TemporaryDirectory() as tmp:
            run_dir = Path(tmp) / "2026-06-11-agent-team"
            run_dir.mkdir()
            write_run(
                run_dir,
                {
                    "current_stage": "reviewer_verification",
                    "last_completed_stage": "developer_implementation",
                    "next_stage": "reviewer_verification",
                },
            )
            (run_dir / "08-architect-a7-remote-metric-design.md").write_text(
                "# retry artifact in wrong location\n",
                encoding="utf-8",
            )

            result = self.run_checker(run_dir)

            self.assertNotEqual(result.returncode, 0, result.stdout)
            self.assertIn("unexpected top-level numbered artifact", result.stdout)


if __name__ == "__main__":
    unittest.main()
