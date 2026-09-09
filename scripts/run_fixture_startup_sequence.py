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
import run_fixture_startup_daemon_capture as daemon


ROOT = launcher.ROOT
MAX_INVOCATIONS = 20
SEQUENCE_SECONDS = 300
RUST_SEQUENCE_SECONDS = 900


class InvocationReserveExpired(TimeoutError):
    """Preflight used the remaining launch allowance; no child was admitted."""


def invocation_reserve():
    # The test's own deadline runs concurrently with preparation/observation.
    # Reserve both readiness waits, exec observation, observer settlement and
    # final owned-child reaping. Helper shutdown is reserved separately below.
    observation = (2 * launcher.READY_SECONDS + launcher.EXEC_SECONDS
                   + launcher.observer.OBSERVATION_SECONDS
                   + launcher.observer.SETTLE_SECONDS)
    return (max(launcher.TEST_SECONDS, observation) + 2 * launcher.REAP_SECONDS
            + launcher.policy_log.START_SECONDS + 2 * launcher.policy_log.REAP_SECONDS)


def settled_iteration(evidence, result, submitted, target_family, *, policy_scope="fixture_path"):
    """Require the retained cleanup evidence before another test can start."""
    raw = launcher.observer.read_local_file(
        evidence.directory / "observations.jsonl", evidence.root,
        launcher.observer.MAX_LOG_BYTES)
    rows = [json.loads(row) for row in raw.splitlines()]
    settled = [row for row in rows if row.get("event") == "settled"]
    if (len(settled) != 1 or settled[0].get("observed_fixtures_gone") is not True
            or type(settled[0].get("observed_fixture_count")) is not int
            or settled[0]["observed_fixture_count"] <= 0
            or type(settled[0].get("selected_fixture_count")) is not int
            or not 0 < settled[0]["selected_fixture_count"] <= settled[0]["observed_fixture_count"]
            or settled[0].get("target_family") != target_family
            or settled[0].get("helper_stopped") is not False
            or settled[0].get("helper_shutdown_owner") != "caller"
            or settled[0].get("capture_received") is not submitted
            or result.get("leader_reaped") is not True
            or result.get("released") is not True or result.get("timeout") is not False
            or result.get("native_wait_status") != 0 or result.get("returncode") != 0
            or (evidence.directory / "failure.json").exists()):
        raise RuntimeError("iteration lacks successful original status or observed cleanup")
    policy = [row for row in rows if row.get("event") == "policy_settled"]
    if (len(policy) != 1 or policy[0].get("leader_reaped") is not True
            or policy[0].get("failures") != {}
            or policy[0].get("result_path") != str(
                (evidence.directory / "policy-result.json").relative_to(evidence.root))):
        raise RuntimeError("iteration lacks settled policy retention")
    launcher.retained_policy_result(evidence, scope=policy_scope)


def retained_daemon_publication(evidence, published, admitted, result):
    """Read the pinned archive index and bind its context to this iteration."""
    archive = daemon.archive
    associations = archive.associations
    associations.fields(published, ("index", "sha256"))
    raw = archive.analysis.read_local(evidence.directory / archive.INDEX_FILE,
                                       evidence.root, archive.MAX_INDEX_BYTES)
    checked = archive.consume(raw, published["sha256"], evidence.root)
    index = checked["index"]
    context = index["context"]
    if (index != published["index"]
            or context["run"] != str(evidence.directory.relative_to(evidence.root))
            or associations.canonical(context["calibrations"]) != associations.canonical(admitted)
            or context["original"] != {key: result[key] for key in
                                        ("returncode", "timeout", "released", "leader_reaped")}):
        raise ValueError("archive disagrees with its admitted sequence iteration")
    daemon._require_successful_context(context)
    return {"index": index, "sha256": published["sha256"]}


def run_sequence(session, native, journal, root, *, target_family="all", calibrations=None):
    try:
        launcher.observer.require_target_family(target_family)
        # Keep complete invocation/cleanup reserves while allowing the Rust
        # selector more opportunities to observe an intermittent longer wait.
        budget_seconds = RUST_SEQUENCE_SECONDS if target_family == "rust" else SEQUENCE_SECONDS
        deadline = time.monotonic() + budget_seconds
        admitted = None
        publications = []
        policy_scope = "fixture_path"
        if calibrations is not None:
            admitted = daemon.archive.associations.calibration_snapshot(calibrations, root)
            policy_scope = daemon.SCOPE

        def before_daemon_launch():
            launcher.require_ready(session, native)
            if deadline - time.monotonic() < invocation_reserve() + launcher.observer.SETTLE_SECONDS:
                raise InvocationReserveExpired("insufficient time after calibration preflight")

        completed = 0
        reason = "invocation_limit"
        journal.record("sequence_started", helper=session.helper,
                       target_family=target_family,
                       sequence_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                       session=str(session.directory.relative_to(root)),
                       max_invocations=MAX_INVOCATIONS, budget_seconds=budget_seconds,
                       invocation_reserve_seconds=invocation_reserve(),
                       helper_cleanup_seconds=launcher.observer.SETTLE_SECONDS,
                       policy_start_seconds=launcher.policy_log.START_SECONDS,
                       policy_cleanup_seconds=2 * launcher.policy_log.REAP_SECONDS,
                       qualification="not_claimed")
        if admitted is not None:
            journal.record("sequence_calibration_admitted", scope=policy_scope,
                           sha256=daemon.archive.associations.digest(
                               daemon.archive.associations.canonical(admitted)))
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
                if admitted is None:
                    result = launcher.run(session, native, evidence, root,
                                          stop_session=False, target_family=target_family)
                else:
                    try:
                        capture = daemon.run(session, native, evidence, root, calibrations,
                                             stop_session=False, target_family=target_family,
                                             _calibration_admission=admitted,
                                             _before_launch=before_daemon_launch)
                    except daemon.CaptureFailure as error:
                        if isinstance(error.__cause__, InvocationReserveExpired):
                            reason = "insufficient_time_for_complete_invocation"
                            journal.record("iteration_deferred", number=number, reason=reason)
                            break
                        raise
                    result = capture["original"]
                settled_iteration(evidence, result, session.submitted, target_family,
                                  policy_scope=policy_scope)
                if admitted is not None:
                    pinned = retained_daemon_publication(evidence, capture["publication"], admitted, result)
                    publications.append(pinned)
                    journal.record("iteration_publication", number=number,
                                   schema=daemon.archive.SCHEMA,
                                   index_path=str((evidence.directory / daemon.archive.INDEX_FILE).relative_to(root)),
                                   sha256=pinned["sha256"])
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
        if admitted is not None:
            # Journal events retain small schema/path/digest anchors only. Each
            # full index lives in its own bounded file and public output record.
            outcome["publications"] = publications
    except (Exception, KeyboardInterrupt) as error:
        journal.problem("observation", error)
        raise
    finally:
        pending = sys.exc_info()[1]
        try:
            launcher.stop_helper(session)
            journal.record("sequence_settled", helper_stopped=True,
                           authentication_invalidated=True)
        except (Exception, KeyboardInterrupt) as error:
            daemon._problem(journal, "cleanup", error)
            if isinstance(pending, daemon.CaptureFailure):
                raise daemon.CaptureFailure(
                    interrupted=pending.interrupted or isinstance(error, KeyboardInterrupt),
                    published=pending.published) from pending
            raise
    if time.monotonic() > deadline:
        error = TimeoutError("sequence cleanup exceeded its diagnostic budget")
        journal.problem("final", error)
        raise error
    return outcome


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", required=True)
    parser.add_argument("--target-family", choices=launcher.observer.TARGET_FAMILIES, default="all")
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
        outcome = run_sequence(session, native, journal, ROOT, target_family=args.target_family)
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
