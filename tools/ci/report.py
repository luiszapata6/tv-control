#!/usr/bin/env python3
"""Builds a Markdown report from the step logs of every CI job.

Each job uploads an artifact `logs-<job>` with `<step>.log` and `<step>.status`
files (see step.sh). The report is committed to the `ci-results` branch so the
results can be read with plain git, without the GitHub Actions UI.

    python tools/ci/report.py <artifacts dir> <output dir>
"""

from __future__ import annotations

import os
import pathlib
import sys

TAIL = 150
KEEP = 4000


def main() -> int:
    src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    sha = os.environ.get("GITHUB_SHA", "local")[:12]
    run_url = f"{os.environ.get('GITHUB_SERVER_URL', '')}/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{os.environ.get('GITHUB_RUN_ID', '')}"
    rows, failures = [], []
    run_dir = out / "runs" / sha
    run_dir.mkdir(parents=True, exist_ok=True)
    for job_dir in sorted(p for p in src.iterdir() if p.is_dir()):
        job = job_dir.name.removeprefix("logs-")
        for status in sorted(job_dir.glob("*.status")):
            step = status.stem
            code, secs = (status.read_text().split() + ["?", "?"])[:2]
            log = status.with_suffix(".log")
            text = log.read_text(errors="replace") if log.exists() else ""
            lines = text.splitlines()
            (run_dir / f"{job}__{step}.log").write_text("\n".join(lines[-KEEP:]) + "\n")
            ok = code == "0"
            rows.append(f"| {job} | {step} | {'PASS' if ok else 'FAIL'} | {secs}s |")
            if not ok:
                failures.append((job, step, lines[-TAIL:]))
    jobs_missing = os.environ.get("JOB_RESULTS", "")
    verdict = "PASS" if not failures and "failure" not in jobs_missing else "FAIL"
    md = [
        f"# CI {verdict} — {sha}",
        "",
        f"Run: {run_url}",
        f"Commit: {os.environ.get('COMMIT_MESSAGE', '').splitlines()[0] if os.environ.get('COMMIT_MESSAGE') else ''}",
        f"Job results: {jobs_missing}",
        "",
        "| job | step | result | time |",
        "| --- | --- | --- | --- |",
        *rows,
        "",
    ]
    for job, step, tail in failures:
        md += [f"## {job} / {step} (last {TAIL} lines)", "", "```", *tail, "```", ""]
    report = "\n".join(md)
    (run_dir / "summary.md").write_text(report)
    (out / "latest.md").write_text(report)
    with (out / "index.md").open("a") as fh:
        fh.write(f"- {verdict} {sha} {run_url}\n")
    print(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
