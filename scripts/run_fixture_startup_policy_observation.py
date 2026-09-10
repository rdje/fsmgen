"""Run one fixed, normal-user T1669 invocation with fixture and policy context.

Exact observed fixture ancestry and source bytes accompany live policy logs.
No kernel sample is collected. Original, collector and observed-fixture cleanup
remain distinct facts; unobserved descendants are unknown.
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


ROOT = Path(__file__).resolve().parent.parent
POLICY_SCOPE = "execution_context"


def require_policy_scope(scope):
    if scope not in ("execution_context", "daemon_context"):
        raise ValueError("unknown policy-only collection scope")


def run(native, evidence, root, *, policy_scope=POLICY_SCOPE):
    require_policy_scope(policy_scope)
    test = collection = census = result = fixture_result = None
    observation_error = None
    cancelled = False
    try:
        evidence.record(
            "policy_observation_started", scope=policy_scope,
            argv=list(launcher.TEST_ARGV),
            test_sha256=hashlib.sha256((root / launcher.TEST_ARGV[1]).read_bytes()).hexdigest(),
            caller_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            launcher_sha256=hashlib.sha256(Path(launcher.__file__).read_bytes()).hexdigest(),
            policy_sha256=hashlib.sha256(Path(launcher.policy_log.__file__).read_bytes()).hexdigest(),
            observer_sha256=hashlib.sha256(Path(launcher.observer.__file__).read_bytes()).hexdigest(),
            fixture_native_identity="pending", kernel_sample="not_collected",
            qualification="not_claimed")
        collection = launcher.policy_log.PolicyLog(root, evidence.directory, native, scope=policy_scope)
        policy_ready = collection.prepare()
        if not isinstance(policy_ready, dict) or policy_ready.get("scope") != policy_scope:
            raise RuntimeError("policy readiness has unexpected collection scope")
        evidence.record("policy_prepared", **policy_ready)
        test = launcher.GatedTest(native, root, evidence.directory)
        native.test = test

        def prepare():
            collection.check()
            ready_ns = time.monotonic_ns()
            evidence.record("observer_ready", ready_ns=ready_ns, test=test.identity,
                            mode="policy_only", scope=policy_scope, policy_readiness=policy_ready)
            return ready_ns

        witness = test.release(prepare)
        evidence.record("test_release", witness=witness, test=test.identity)
        launcher.wait_for_exec(test, native, root)

        def check_observation():
            collection.check()
            if time.monotonic() >= test.deadline:
                raise TimeoutError("fixture census reached the original test deadline")

        census = launcher.observer.FixtureCensus(test.identity, native, evidence, root,
                                                 checkpoint=check_observation)
        evidence.record("fixtures_attached", test=test.identity, mode="passive",
                        unobserved_descendants="unknown")
        while test.poll() is None and time.monotonic() < test.deadline:
            check_observation()
            census.scan()
            time.sleep(launcher.observer.POLL_SECONDS)
    except (Exception, KeyboardInterrupt) as error:
        observation_error = error
        cancelled = isinstance(error, KeyboardInterrupt)
        evidence.problem("observation", error)
    finally:
        cleanup_errors = []
        try:
            if test is not None:
                # A collector failure does not cancel an already released
                # original test. Its existing deadline still bounds completion.
                result = test.finish(cancel=cancelled or not test.released)
                pending = evidence.directory / "test-result.next"
                pending.write_text(json.dumps(result, indent=2) + "\n")
                pending.replace(evidence.directory / "test-result.json")
        except (Exception, KeyboardInterrupt) as error:
            cleanup_errors.append("test cleanup: " + str(error))
        if collection is not None:
            try:
                collected = collection.finish()
                if launcher.retained_policy_result(evidence, scope=policy_scope) != collected:
                    raise RuntimeError("policy status changed after collector publication")
            except (Exception, KeyboardInterrupt) as error:
                cleanup_errors.append("policy collection: " + str(error))
            else:
                try:
                    evidence.record("policy_settled", scope=policy_scope, leader_reaped=True, failures={},
                                    result_path=str((evidence.directory / "policy-result.json").relative_to(root)))
                except (Exception, KeyboardInterrupt) as error:
                    if observation_error is None:
                        observation_error = error
        if census is not None:
            try:
                fixture_result = census.settle()
                pending = evidence.directory / "fixture-result.next"
                pending.write_text(json.dumps(fixture_result, indent=2) + "\n")
                pending.replace(evidence.directory / "fixture-result.json")
                if (set(fixture_result) != {"observed_fixtures_gone", "observed_fixture_count", "unobserved_descendants"}
                        or fixture_result["observed_fixtures_gone"] is not True
                        or type(fixture_result["observed_fixture_count"]) is not int
                        or fixture_result["observed_fixture_count"] != len(census.seen)
                        or fixture_result["unobserved_descendants"] != "unknown"
                        or any(launcher.observer.still_live(native, info) for info in census.seen.values())):
                    raise RuntimeError("passive fixture settlement disagrees with observed identities")
            except (Exception, KeyboardInterrupt) as error:
                cleanup_errors.append("observed fixtures: " + str(error))
            else:
                try:
                    evidence.record("fixtures_settled", mode="passive", **fixture_result)
                except (Exception, KeyboardInterrupt) as error:
                    if observation_error is None:
                        observation_error = error
        if cleanup_errors:
            failure = RuntimeError("; ".join(cleanup_errors))
            evidence.problem("cleanup", failure)
            raise failure
    if observation_error is not None:
        evidence.problem("observation", observation_error)
        raise observation_error
    if result is None or result["timeout"] or result["returncode"] != 0:
        raise RuntimeError("original test failed; retained TAP/wait status remains authoritative")
    if census is None or fixture_result is None:
        raise RuntimeError("original lacks observed fixture settlement")
    census.require_coverage()
    evidence.record("caller_complete", result=result, scope=policy_scope,
                    fixture_native_identity="observed_subset", fixtures=fixture_result,
                    kernel_sample="not_collected",
                    qualification="not_claimed")
    return result


def main(*, policy_scope=POLICY_SCOPE):
    require_policy_scope(policy_scope)
    argparse.ArgumentParser(description=__doc__).parse_args()
    if sys.platform != "darwin" or os.getuid() == 0 or os.geteuid() == 0:
        raise ValueError("run the diagnostic caller as the normal user on Darwin")
    if os.environ.get("FSMGEN_RAM_GUARD_ACTIVE") != "1":
        raise ValueError("run this caller through scripts/run_with_ram_guard.sh")
    native = launcher.OwnedProcesses()
    evidence = None

    def interrupted(_signum, _frame):
        raise KeyboardInterrupt

    previous = signal.signal(signal.SIGTERM, interrupted)
    previous_umask = os.umask(0o077)
    try:
        evidence = launcher.observer.Evidence(ROOT)
        print(str(evidence.directory.relative_to(ROOT)), flush=True)
        run(native, evidence, ROOT, policy_scope=policy_scope)
        return 0
    except (Exception, KeyboardInterrupt) as error:
        if evidence is not None:
            evidence.problem("final", error)
        print(str(error), file=sys.stderr)
        return 130 if isinstance(error, KeyboardInterrupt) else 1
    finally:
        signal.signal(signal.SIGTERM, previous)
        os.umask(previous_umask)
        if evidence is not None:
            evidence.stream.close()


if __name__ == "__main__":
    raise SystemExit(main())
