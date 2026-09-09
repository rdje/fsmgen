"""Run the fixed calibrated daemon-context sequence with one admitted helper."""

import run_fixture_startup_daemon_capture as caller


def main(argv=None):
    return caller.main(argv, _sequence=True)


if __name__ == "__main__":
    raise SystemExit(main())
