"""Run one unchanged default reader with its declared historical factory input."""
import argparse
from pathlib import Path
import runpy
import sys
import traceback

import corrected_intake
import execute
import historical_factory
import prepare


def receipt_path(role):
    assert role in historical_factory.ROLES
    return execute.AUDIT / ('corrected-' + role + '-source-view.json.gz')


def replay(role, runner=runpy.run_path):
    assert role in historical_factory.ROLES
    inventory = corrected_intake.inventory()
    command = inventory['cohorts'][role]['original_command']
    assert command[:2] == ['python3', '-B'] and len(command) == 3
    entry = command[2]
    prior_path, prior_argv = sys.path[:], sys.argv[:]
    original_read = Path.read_bytes
    live = (execute.ROOT / historical_factory.FACTORY).read_bytes()
    proof, error = None, None
    try:
        with historical_factory.source_view(role, inventory['historical_source_image']) as proof:
            sys.path.insert(0, str(execute.ROOT / Path(entry).parent))
            sys.argv[:] = [entry]
            runner(entry, run_name='__main__')
    except BaseException:
        error = traceback.format_exc()
        raise
    finally:
        sys.path[:] = prior_path
        sys.argv[:] = prior_argv
        receipt = dict(schema='fsmgen.original_historical_source_view.v1', role=role,
                       command=command, proof=proof, error=error,
                       restored=Path.read_bytes is original_read,
                       live_factory_before=prepare.identity(live),
                       live_factory_after=prepare.identity((execute.ROOT / historical_factory.FACTORY).read_bytes()))
        execute.save(receipt_path(role), receipt)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('role', choices=sorted(historical_factory.ROLES))
    role = parser.parse_args().role
    # Only the committed recorder may create this exclusive run's start marker.
    import execute_corrected
    revision = execute_corrected.qualification()
    started = execute.safe(execute.AUDIT / ('corrected-' + role + '-started.json.gz'))
    record = execute.json.loads(execute.gzip.decompress(execute.read(started.relative_to(execute.ROOT))))
    assert record['qualification'] == revision and record['label'] == role
    assert record['command'] == ['scripts/run_with_ram_guard.sh', '--', *corrected_intake.inventory()['cohorts'][role]['command']]
    assert not execute.safe(receipt_path(role)).exists(), 'historical source-view slot is already spent'
    replay(role)
