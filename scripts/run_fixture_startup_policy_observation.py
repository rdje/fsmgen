"""Run one fixed, normal-user T1669 invocation with policy execution context.

This diagnostic collects no fixture ancestry or kernel sample. The original
test result, collector result and their observed cleanup remain distinct facts.
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


def run(native, evidence, root):
    test = collection = result = None
    observation_error = None
    cancelled = False
    try:
        evidence.record(
            "policy_observation_started", scope=POLICY_SCOPE,
            argv=list(launcher.TEST_ARGV),
            test_sha256=hashlib.sha256((root / launcher.TEST_ARGV[1]).read_bytes()).hexdigest(),
            caller_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            launcher_sha256=hashlib.sha256(Path(launcher.__file__).read_bytes()).hexdigest(),
            policy_sha256=hashlib.sha256(Path(launcher.policy_log.__file__).read_bytes()).hexdigest(),
            fixture_native_identity="not_observed", kernel_sample="not_collected",
            qualification="not_claimed")
        collection = launcher.policy_log.PolicyLog(root, evidence.directory, native, scope=POLICY_SCOPE)
        policy_ready = collection.prepare()
        evidence.record("policy_prepared", **policy_ready)
        test = launcher.GatedTest(native, root, evidence.directory)
        native.test = test

        def prepare():
            collection.check()
            ready_ns = time.monotonic_ns()
            evidence.record("observer_ready", ready_ns=ready_ns, test=test.identity,
                            mode="policy_only", scope=POLICY_SCOPE, policy_readiness=policy_ready)
            return ready_ns

        witness = test.release(prepare)
        evidence.record("test_release", witness=witness, test=test.identity)
        launcher.wait_for_exec(test, native, root)
        while test.poll() is None and time.monotonic() < test.deadline:
            collection.check()
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
                if launcher.retained_policy_result(evidence, scope=POLICY_SCOPE) != collected:
                    raise RuntimeError("policy status changed after collector publication")
            except (Exception, KeyboardInterrupt) as error:
                cleanup_errors.append("policy collection: " + str(error))
            else:
                try:
                    evidence.record("policy_settled", scope=POLICY_SCOPE, leader_reaped=True, failures={},
                                    result_path=str((evidence.directory / "policy-result.json").relative_to(root)))
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
    evidence.record("caller_complete", result=result, scope=POLICY_SCOPE,
                    fixture_native_identity="not_observed", kernel_sample="not_collected",
                    qualification="not_claimed")
    return result


def main():
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
        run(native, evidence, ROOT)
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
