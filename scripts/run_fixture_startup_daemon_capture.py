"""One fixed T1669 daemon-context capture with calibrated portable publication.

Use an existing admitted helper and explicit local calibration runs. The shared
launcher retains original argv, target-family policy, deadlines and cleanup.
This entrypoint never starts authentication or accepts a predicate override.
"""

import json
import os
import signal
import sys

import fixture_policy_publication as publication
import run_fixture_startup_observation as launcher


ROOT = launcher.ROOT
SCOPE = "daemon_context"
PUBLIC_FAILURE = "fixture daemon capture failed; retained evidence remains authoritative"
PUBLIC_SEQUENCE_FAILURE = "fixture daemon sequence failed; retained evidence remains authoritative"


class CaptureFailure(RuntimeError):
    """Public failure text is fixed; private causes stay in evidence/chaining."""

    def __init__(self, *, interrupted=False, published=None):
        super().__init__(PUBLIC_FAILURE)
        self.interrupted = interrupted
        self.published = published


def _problem(evidence, stage, error):
    # A full/broken evidence destination must not expose a private logging
    # exception or prevent the remaining physical owner from being settled.
    if evidence is not None:
        try:
            evidence.problem(stage, error)
        except (Exception, KeyboardInterrupt):
            pass


def run(session, native, evidence, root, calibrations, *, stop_session=True, target_family="all",
        _calibration_admission=None, _before_launch=None):
    """Keep launch ownership in the qualified caller; wrap admission/publication."""
    handed_off = False
    try:
        launcher.observer.require_target_family(target_family)
        admitted = publication.associations.calibration_snapshot(calibrations, root)
        if (_calibration_admission is not None and publication.associations.canonical(admitted)
                != publication.associations.canonical(_calibration_admission)):
            raise ValueError("calibration changed after sequence admission")
        evidence.record("daemon_calibration_preflight", scope=SCOPE,
                        sha256=publication.associations.digest(publication.associations.canonical(admitted)))
        # The finite controller checks readiness and the full existing reserve
        # after calibration work, immediately before handing off launch ownership.
        if _before_launch is not None:
            _before_launch()
        result = published = failure = None
        interrupted = False
        handed_off = True
        try:
            result = launcher.run(session, native, evidence, root, stop_session=stop_session,
                                  target_family=target_family, policy_scope=SCOPE)
        except (Exception, KeyboardInterrupt) as error:
            failure = error
            interrupted = isinstance(error, KeyboardInterrupt)
            _problem(evidence, "observation", error)
        try:
            target = str(evidence.directory.relative_to(root))
            published = publication.publish(target, calibrations, admitted, root)
        except (Exception, KeyboardInterrupt) as error:
            _problem(evidence, "final", error)
            interrupted = interrupted or isinstance(error, KeyboardInterrupt)
            if failure is None:
                failure = error
        if failure is not None:
            raise CaptureFailure(interrupted=interrupted, published=published) from failure
        return {"original": result, "publication": published}
    except CaptureFailure:
        raise
    except (Exception, KeyboardInterrupt) as error:
        _problem(evidence, "observation", error)
        raise CaptureFailure(interrupted=isinstance(error, KeyboardInterrupt)) from error
    finally:
        # Once handed off, launcher.run owns this exact existing cleanup path.
        # A sequence deliberately keeps ownership across individual invocations.
        if stop_session and not handed_off:
            pending = sys.exc_info()[1]
            try:
                launcher.stop_helper(session)
            except (Exception, KeyboardInterrupt) as error:
                _problem(evidence, "cleanup", error)
                interrupted = isinstance(error, KeyboardInterrupt) or (
                    isinstance(pending, CaptureFailure) and pending.interrupted)
                raise CaptureFailure(interrupted=interrupted) from pending or error


def _checked_publication(published, *, successful_iteration=False):
    publication.associations.fields(published, ("receipt", "sha256"))
    raw = publication.associations.canonical(published["receipt"])
    checked = publication.consume(raw, published["sha256"], ROOT)
    if successful_iteration:
        report = checked["diagnostic"]
        if (report["original"] != dict(returncode=0, timeout=False, released=True, leader_reaped=True)
                or report["collector"]["returncode"] not in (0, -signal.SIGINT)
                or report["collector"]["reported_failure"] is not False
                or report["collector"]["leader_reaped"] is not True
                or report["collector"]["forced_kill"] is not False):
            raise ValueError("sequence receipt retains an unsuccessful original or collector")
    return {"receipt": checked["receipt"], "sha256": published["sha256"]}


def _emit_publication(published):
    print(json.dumps(_checked_publication(published), sort_keys=True))


def _emit_sequence(outcome, limit):
    """Admit closed public outcome/receipt fields before emitting any of them."""
    associations = publication.associations
    associations.fields(outcome, ("reason", "completed_invocations", "capture_received", "qualification",
                                   "unobserved_descendants", "publications"))
    associations.integer(outcome["completed_invocations"], limit)
    count = outcome["completed_invocations"]
    if (type(outcome["capture_received"]) is not bool
            or outcome["qualification"] != "not_claimed" or outcome["unobserved_descendants"] != "unknown"
            or outcome["reason"] not in ("invocation_limit", "insufficient_time_for_complete_invocation", "capture_received")
            or (outcome["reason"] == "capture_received") is not outcome["capture_received"]
            or (outcome["capture_received"] and count == 0)
            or (outcome["reason"] == "invocation_limit" and count != limit)
            or (outcome["reason"] == "insufficient_time_for_complete_invocation" and count == limit)):
        raise ValueError("sequence outcome lacks a closed truthful disposition")
    associations.bounded_list(outcome["publications"], limit, 0)
    if len(outcome["publications"]) != count:
        raise ValueError("sequence publication count disagrees with its completed iterations")
    checked = [_checked_publication(published, successful_iteration=True) for published in outcome["publications"]]
    if (len({p["receipt"]["run"] for p in checked}) != count
            or len({p["receipt"]["admission_sha256"] for p in checked}) > 1):
        raise ValueError("sequence publications repeat an iteration or change calibration")
    for published in checked:
        print(json.dumps(published, sort_keys=True))
    print(json.dumps({key: value for key, value in outcome.items() if key != "publications"}, sort_keys=True))


def main(argv=None, *, _sequence=False):
    session = evidence = previous_signal = previous_umask = None
    handed_off = False
    status = 1
    failed = True
    public_failure = PUBLIC_SEQUENCE_FAILURE if _sequence else PUBLIC_FAILURE
    try:
        if _sequence:
            import run_fixture_startup_sequence as sequence
        parser = publication.associations.PrivateArgumentParser(
            prog="fixture-daemon-sequence" if _sequence else "fixture-daemon-capture",
            description=sequence.__doc__ if _sequence else __doc__, allow_abbrev=False)
        parser.add_argument("--session", required=True)
        parser.add_argument("--calibration", action="append", required=True)
        parser.add_argument("--target-family", choices=launcher.observer.TARGET_FAMILIES, default="all")
        args = parser.parse_args(argv)
        if sys.platform != "darwin" or os.getuid() == 0 or os.geteuid() == 0:
            raise ValueError("normal-user Darwin capture is required")
        if os.environ.get("FSMGEN_RAM_GUARD_ACTIVE") != "1":
            raise ValueError("the RAM guard is required")

        def interrupted(_signum, _frame):
            raise KeyboardInterrupt

        previous_signal = signal.signal(signal.SIGTERM, interrupted)
        previous_umask = os.umask(0o077)
        native = launcher.OwnedProcesses()
        session = launcher.observer.CaptureSession(args.session, native, ROOT)
        evidence = launcher.observer.Evidence(ROOT)
        print(str(evidence.directory.relative_to(ROOT)), flush=True)
        handed_off = True
        if _sequence:
            result = sequence.run_sequence(session, native, evidence, ROOT,
                                           target_family=args.target_family, calibrations=args.calibration)
            _emit_sequence(result, sequence.MAX_INVOCATIONS)
            status = 0 if result["capture_received"] else 2
        else:
            result = run(session, native, evidence, ROOT, args.calibration, target_family=args.target_family)
            _emit_publication(result["publication"])
            status = 0
        failed = False
    except CaptureFailure as error:
        status = 130 if error.interrupted else 1
        if error.published is not None:
            try:
                _emit_publication(error.published)
            except (Exception, KeyboardInterrupt) as publication_error:
                if isinstance(publication_error, KeyboardInterrupt):
                    status = 130
                _problem(evidence, "final", publication_error)
    except (Exception, KeyboardInterrupt) as error:
        status = 130 if isinstance(error, KeyboardInterrupt) else 1
        _problem(evidence, "final", error)
    finally:
        if session is not None and not handed_off:
            try:
                launcher.stop_helper(session)
            except (Exception, KeyboardInterrupt) as error:
                failed = True
                status = 130 if status == 130 or isinstance(error, KeyboardInterrupt) else 1
                _problem(evidence, "cleanup", error)
        if evidence is not None:
            try:
                evidence.stream.close()
            except (Exception, KeyboardInterrupt) as error:
                failed = True
                status = 130 if status == 130 or isinstance(error, KeyboardInterrupt) else 1
        if previous_umask is not None:
            os.umask(previous_umask)
        if previous_signal is not None:
            signal.signal(signal.SIGTERM, previous_signal)
    if failed:
        print(public_failure, file=sys.stderr)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
