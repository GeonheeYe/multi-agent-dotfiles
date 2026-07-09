#!/usr/bin/env python3
"""agent-team run consistency checker."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


STAGES = {
    "initialized",
    "context_load",
    "briefs_created",
    "pm_spec",
    "expert_gateway_spec",
    "architect_design",
    "expert_gateway_design",
    "work_plan",
    "implementation_approval",
    "developer_implementation",
    "reviewer_verification",
    "expert_gateway_final",
    "user_final_confirmation",
    "final_report",
}

STATUSES = {"active", "blocked", "completed"}
MODES = {"planning", "implementation"}
EXECUTION_MODES = {"auto_split", "single_session"}
RUNTIME_MODES = {
    "no-runtime",
    "local-process",
    "local-docker-compose",
    "existing-deployed-url",
    "kubernetes-or-cluster",
    "cloud-managed",
    "ci-runtime",
    "mock-or-simulator",
    "hybrid",
}
ASSUMPTION_STATUSES = {
    "open",
    "accepted",
    "needs-validation",
    "rejected",
    "resolved",
}
OPEN_ASSUMPTION_STATUSES = {"open", "needs-validation"}
RUN_STATE_FIELDS = {
    "run_id",
    "mode",
    "execution_mode",
    "runtime_mode",
    "runtime_gate",
    "pending_reapproval",
    "pending_reapproval_reason",
    "stale_approvals",
    "status",
    "current_stage",
    "last_completed_stage",
    "next_stage",
    "gateway_retry_count",
    "review_retry_count",
    "last_decision",
    "blocked_reason",
    "open_assumptions",
    "artifacts",
    "content_hashes",
    "updated_at",
}
APPROVAL_HASH_INPUTS = (
    "01-pm-spec.md",
    "03-architect-design.md",
    "05-work-plan.md",
)
TOP_LEVEL_NUMBERED_ARTIFACTS = {
    "00-run-setup.md",
    "00-context.md",
    "00-pm-interview.md",
    "01-pm-spec.md",
    "02-expert-gateway-spec.md",
    "03-architect-design.md",
    "04-expert-gateway-design.md",
    "05-work-plan.md",
    "06-developer-implementation.md",
    "07-reviewer-verification.md",
    "08-expert-gateway-final.md",
    "09-final-report.md",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return "sha256:" + digest.hexdigest()


def split_md_row(line: str) -> list[str]:
    return [part.strip() for part in line.strip().strip("|").split("|")]


def parse_assumptions(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}

    rows: dict[str, str] = {}
    for line in read_text(path).splitlines():
        stripped = line.strip()
        if not stripped.startswith("|") or "---" in stripped:
            continue
        cells = split_md_row(stripped)
        if not cells or cells[0] in {"ID", ""}:
            continue
        if len(cells) < 8:
            rows[cells[0]] = ""
            continue
        rows[cells[0]] = cells[-1].strip("` ")
    return rows


def path_in_run(run_dir: Path, value: str) -> bool:
    try:
        path = Path(value).expanduser()
        if not path.is_absolute():
            path = run_dir / path
        path.resolve().relative_to(run_dir.resolve())
        return True
    except ValueError:
        return False


def find_hash_inputs(node: Any) -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    if isinstance(node, dict):
        inputs = node.get("inputs")
        if isinstance(inputs, dict):
            for path, expected in inputs.items():
                if isinstance(expected, str) and expected.startswith("sha256:"):
                    found.append((path, expected))
        for value in node.values():
            found.extend(find_hash_inputs(value))
    elif isinstance(node, list):
        for value in node:
            found.extend(find_hash_inputs(value))
    return found


def has_implementation_approval(run_dir: Path) -> bool:
    path = run_dir / "00-pm-interview.md"
    if not path.exists():
        return False
    text = read_text(path)
    return (
        "implementation_approval" in text
        or ("구현" in text and "승인" in text and "05-work-plan.md" in text)
    )


def has_risk_acceptance(run_dir: Path) -> bool:
    patterns = (
        "미검증 보류 승인",
        "미검증 상태로 구현 승인",
        "needs-validation 보류 승인",
        "explicit risk acceptance",
    )
    path = run_dir / "00-pm-interview.md"
    return path.exists() and any(pattern in read_text(path) for pattern in patterns)


def approval_hash_inputs(state: dict[str, Any]) -> dict[str, str]:
    approval = (state.get("content_hashes") or {}).get("implementation_approval") or {}
    inputs = approval.get("inputs") or {}
    if not isinstance(inputs, dict):
        return {}
    return {
        str(key): value
        for key, value in inputs.items()
        if isinstance(value, str) and value.startswith("sha256:")
    }


def check_read_only_claims(run_dir: Path) -> list[str]:
    warnings: list[str] = []
    role_files = [
        "02-expert-gateway-spec.md",
        "04-expert-gateway-design.md",
        "07-reviewer-verification.md",
        "08-expert-gateway-final.md",
    ]
    edit_pattern = re.compile(r"(수정했다|수정함|보정 후[^.\n]*수정|edited|modified)", re.I)
    for rel in role_files:
        path = run_dir / rel
        if not path.exists():
            continue
        for lineno, line in enumerate(read_text(path).splitlines(), start=1):
            if edit_pattern.search(line):
                warnings.append(f"{rel}:{lineno}: read-only 역할 산출물이 직접 수정 표현을 포함함")
    return warnings


def check_top_level_numbered_artifacts(run_dir: Path) -> list[str]:
    errors: list[str] = []
    for path in run_dir.glob("[0-9][0-9]-*.md"):
        if path.name not in TOP_LEVEL_NUMBERED_ARTIFACTS:
            errors.append(
                "unexpected top-level numbered artifact: "
                f"{path.name}; retry/rework outputs must live under a retry directory"
            )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    args = parser.parse_args()

    run_dir = args.run_dir.resolve()
    errors: list[str] = []
    warnings: list[str] = []

    state_path = run_dir / "run-state.json"
    if not state_path.exists():
        print(f"ERROR: run-state.json not found: {state_path}", file=sys.stderr)
        return 1

    try:
        state = json.loads(read_text(state_path))
    except json.JSONDecodeError as exc:
        print(f"ERROR: invalid run-state.json: {exc}", file=sys.stderr)
        return 1

    unknown = set(state) - RUN_STATE_FIELDS
    if unknown:
        errors.append(f"run-state.json unknown fields: {sorted(unknown)}")

    if state.get("run_id") != run_dir.name:
        errors.append(f"run_id must match run directory basename: {state.get('run_id')} != {run_dir.name}")
    if state.get("mode") not in MODES:
        errors.append(f"invalid mode: {state.get('mode')}")
    if state.get("execution_mode") not in EXECUTION_MODES:
        errors.append(f"invalid execution_mode: {state.get('execution_mode')}")
    if "runtime_mode" in state and state.get("runtime_mode") not in RUNTIME_MODES:
        errors.append(f"invalid runtime_mode: {state.get('runtime_mode')}")
    if "pending_reapproval" in state and not isinstance(state.get("pending_reapproval"), bool):
        errors.append(f"pending_reapproval must be boolean: {state.get('pending_reapproval')}")
    if "pending_reapproval_reason" in state and state.get("pending_reapproval_reason") is not None and not isinstance(state.get("pending_reapproval_reason"), str):
        errors.append("pending_reapproval_reason must be string or null")
    stale_approvals = state.get("stale_approvals") or []
    if not isinstance(stale_approvals, list) or not all(isinstance(item, str) for item in stale_approvals):
        errors.append(f"stale_approvals must be a list of strings: {stale_approvals}")
    if state.get("status") not in STATUSES:
        errors.append(f"invalid status: {state.get('status')}")

    for key in ("current_stage", "last_completed_stage", "next_stage"):
        value = state.get(key)
        if value is not None and value not in STAGES:
            errors.append(f"invalid {key}: {value}")

    for key in ("spec", "design", "final"):
        retry = (state.get("gateway_retry_count") or {}).get(key)
        if not isinstance(retry, int) or retry < 0:
            errors.append(f"invalid gateway_retry_count.{key}: {retry}")
    if not isinstance(state.get("review_retry_count"), int) or state.get("review_retry_count") < 0:
        errors.append(f"invalid review_retry_count: {state.get('review_retry_count')}")

    artifacts = state.get("artifacts") or {}
    if not isinstance(artifacts, dict):
        errors.append("artifacts must be an object")
    else:
        for key, value in artifacts.items():
            if not isinstance(value, str):
                errors.append(f"artifact {key} must be a string path")
                continue
            if not path_in_run(run_dir, value):
                errors.append(f"artifact {key} is outside run dir: {value}")
            elif not Path(value).exists():
                errors.append(f"artifact {key} path does not exist: {value}")

    assumptions = parse_assumptions(run_dir / "assumptions.md")
    if not assumptions:
        warnings.append("assumptions.md has no parsed assumptions")
    invalid_assumptions = {
        assumption_id: status
        for assumption_id, status in assumptions.items()
        if status not in ASSUMPTION_STATUSES
    }
    if invalid_assumptions:
        errors.append(f"invalid assumption statuses: {invalid_assumptions}")

    expected_open = sorted(
        assumption_id
        for assumption_id, status in assumptions.items()
        if status in OPEN_ASSUMPTION_STATUSES
    )
    actual_open = sorted(state.get("open_assumptions") or [])
    if expected_open != actual_open:
        errors.append(f"open_assumptions mismatch: expected {expected_open}, actual {actual_open}")

    for rel, expected in find_hash_inputs(state.get("content_hashes") or {}):
        path = Path(rel)
        if not path.is_absolute():
            path = run_dir / rel
        if not path.exists():
            errors.append(f"content hash input missing: {rel}")
            continue
        actual = sha256_file(path)
        if actual != expected:
            errors.append(f"content hash mismatch: {rel}")

    entering_developer = state.get("current_stage") == "developer_implementation" or state.get("next_stage") == "developer_implementation"
    if entering_developer:
        if not has_implementation_approval(run_dir):
            errors.append("developer_implementation requires implementation approval in 00-pm-interview.md")
        if state.get("pending_reapproval"):
            errors.append("developer_implementation blocked: pending_reapproval is true")
        if stale_approvals:
            errors.append(f"developer_implementation blocked: stale_approvals must be cleared or revalidated: {stale_approvals}")
        approval_inputs = approval_hash_inputs(state)
        missing_hashes = [
            rel
            for rel in APPROVAL_HASH_INPUTS
            if rel not in approval_inputs
        ]
        if missing_hashes:
            errors.append(f"developer_implementation requires implementation approval content hashes for: {missing_hashes}")
        needs_validation = [
            assumption_id
            for assumption_id, status in assumptions.items()
            if status == "needs-validation"
        ]
        if needs_validation and not has_risk_acceptance(run_dir):
            errors.append(
                "developer_implementation blocked: needs-validation assumptions remain "
                f"without explicit risk acceptance: {needs_validation}"
            )

    if state.get("pending_reapproval"):
        current_next = {state.get("current_stage"), state.get("next_stage")}
        if "implementation_approval" not in current_next:
            errors.append("pending_reapproval is true but current/next stage is not implementation_approval")

    errors.extend(check_top_level_numbered_artifacts(run_dir))
    warnings.extend(check_read_only_claims(run_dir))

    for warning in warnings:
        print(f"WARN: {warning}")
    for error in errors:
        print(f"ERROR: {error}")

    if errors:
        return 1
    print("OK: agent-team run consistency checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
