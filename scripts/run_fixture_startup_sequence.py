"""Observe a finite T1669 sequence using one separately authenticated helper.

This is prospective diagnosis, never retry-based qualification. Each iteration
uses the unchanged fixed caller; a failed invocation or any capture ends the
sequence. Only this controller owns helper shutdown between iterations.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import sys
import time

import run_fixture_startup_observation as launcher


ROOT = launcher.ROOT
MAX_INVOCATIONS = 20
SEQUENCE_SECONDS = 300


def invocation_reserve():
    # The test's own deadline runs concurrently with preparation/observation.
    # Reserve both readiness waits, exec observation, observer settlement and
    # final owned-child reaping. Helper shutdown is reserved separately below.
    observation = (2 * launcher.READY_SECONDS + launcher.EXEC_SECONDS
                   + launcher.observer.OBSERVATION_SECONDS
                   + launcher.observer.SETTLE_SECONDS)
    return max(launcher.TEST_SECONDS, observation) + 2 * launcher.REAP_SECONDS


def settled_iteration(evidence, result, submitted):
    """Require the retained cleanup evidence before another test can start."""
    raw = launcher.observer.read_local_file(
        evidence.directory / "observations.jsonl", evidence.root,
        launcher.observer.MAX_LOG_BYTES)
    rows = [json.loads(row) for row in raw.splitlines()]
    settled = [row for row in rows if row.get("event") == "settled"]
    if (len(settled) != 1 or settled[0].get("observed_fixtures_gone") is not True
            or type(settled[0].get("observed_fixture_count")) is not int
            or settled[0]["observed_fixture_count"] <= 0
            or settled[0].get("helper_stopped") is not False
            or settled[0].get("helper_shutdown_owner") != "caller"
            or settled[0].get("capture_received") is not submitted
            or result.get("leader_reaped") is not True
            or result.get("released") is not True or result.get("timeout") is not False
            or result.get("native_wait_status") != 0 or result.get("returncode") != 0
            or (evidence.directory / "failure.json").exists()):
        raise RuntimeError("iteration lacks successful original status or observed cleanup")


def run_sequence(session, native, journal, root):
    try:
        deadline = time.monotonic() + SEQUENCE_SECONDS
        completed = 0
        reason = "invocation_limit"
        journal.record("sequence_started", helper=session.helper,
                       sequence_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                       session=str(session.directory.relative_to(root)),
                       max_invocations=MAX_INVOCATIONS, budget_seconds=SEQUENCE_SECONDS,
                       invocation_reserve_seconds=invocation_reserve(),
                       helper_cleanup_seconds=launcher.observer.SETTLE_SECONDS,
                       qualification="not_claimed")
        for number in range(1, MAX_INVOCATIONS + 1):
            launcher.require_ready(session, native)
            remaining = deadline - time.monotonic()
            if remaining < invocation_reserve() + launcher.observer.SETTLE_SECONDS:
                reason = "insufficient_time_for_complete_invocation"
                break
            evidence = launcher.observer.Evidence(root)
            try:
                journal.record("iteration_started", number=number,
                               evidence=str(evidence.directory.relative_to(root)))
                result = launcher.run(session, native, evidence, root, stop_session=False)
                settled_iteration(evidence, result, session.submitted)
                completed += 1
                journal.record("iteration_completed", number=number, result=result,
                               capture_requested=session.submitted)
            finally:
                evidence.stream.close()
            if time.monotonic() > deadline - launcher.observer.SETTLE_SECONDS:
                raise TimeoutError("sequence exceeded its reserved diagnostic budget")
            if session.submitted:
                reason = "capture_received"
                break
            launcher.require_ready(session, native)
        outcome = {"reason": reason, "completed_invocations": completed,
                   "capture_received": session.submitted, "qualification": "not_claimed",
                   "unobserved_descendants": "unknown"}
        journal.record("sequence_outcome", **outcome)
    except (Exception, KeyboardInterrupt) as error:
        journal.problem("observation", error)
        raise
    finally:
        try:
            launcher.stop_helper(session)
            journal.record("sequence_settled", helper_stopped=True,
                           authentication_invalidated=True)
        except (Exception, KeyboardInterrupt) as error:
            journal.problem("cleanup", error)
            raise
    if time.monotonic() > deadline:
        error = TimeoutError("sequence cleanup exceeded its diagnostic budget")
        journal.problem("final", error)
        raise error
    return outcome


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", required=True)
    args = parser.parse_args()
    if sys.platform != "darwin" or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError("run the diagnostic sequence as the normal user on Darwin")
    if os.environ.get("FSMGEN_RAM_GUARD_ACTIVE") != "1":
        raise ValueError("run this sequence through scripts/run_with_ram_guard.sh")
    native = launcher.OwnedProcesses()
    session = launcher.observer.CaptureSession(args.session, native, ROOT)
    journal = None
    sequence_owns_session = False

    def interrupted(_signum, _frame):
        raise KeyboardInterrupt

    previous = signal.signal(signal.SIGTERM, interrupted)
    try:
        os.umask(0o077)
        journal = launcher.observer.Evidence(ROOT)
        print(str(journal.directory.relative_to(ROOT)), flush=True)
        sequence_owns_session = True
        outcome = run_sequence(session, native, journal, ROOT)
        return 0 if outcome["capture_received"] else 2
    except (Exception, KeyboardInterrupt) as error:
        if journal is not None:
            journal.problem("final", error)
        print(str(error), file=sys.stderr)
        return 130 if isinstance(error, KeyboardInterrupt) else 1
    finally:
        signal.signal(signal.SIGTERM, previous)
        if journal is not None:
            journal.stream.close()
        if not sequence_owns_session:
            launcher.stop_helper(session)


if __name__ == "__main__":
    raise SystemExit(main())
