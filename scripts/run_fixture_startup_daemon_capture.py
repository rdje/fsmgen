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


def _emit_publication(published):
    publication.associations.fields(published, ("receipt", "sha256"))
    raw = publication.associations.canonical(published["receipt"])
    checked = publication.consume(raw, published["sha256"], ROOT)
    print(json.dumps({"receipt": checked["receipt"], "sha256": published["sha256"]}, sort_keys=True))


def main(argv=None):
    session = evidence = previous_signal = previous_umask = None
    handed_off = False
    status = 1
    try:
        parser = publication.associations.PrivateArgumentParser(
            prog="fixture-daemon-capture", description=__doc__, allow_abbrev=False)
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
        result = run(session, native, evidence, ROOT, args.calibration, target_family=args.target_family)
        _emit_publication(result["publication"])
        status = 0
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
                status = 130 if status == 130 or isinstance(error, KeyboardInterrupt) else 1
                _problem(evidence, "cleanup", error)
        if evidence is not None:
            try:
                evidence.stream.close()
            except (Exception, KeyboardInterrupt) as error:
                status = 130 if status == 130 or isinstance(error, KeyboardInterrupt) else 1
        if previous_umask is not None:
            os.umask(previous_umask)
        if previous_signal is not None:
            signal.signal(signal.SIGTERM, previous_signal)
    if status:
        print(PUBLIC_FAILURE, file=sys.stderr)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
