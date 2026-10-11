"""Contrast legitimate current producer advancement with its exact dated source role."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys

from capture import BASE, pin, save

sys.path.insert(0, 'scripts')
import book_source_references as plane
import record_value_observer_namespace_fact as namespace
import record_value_raw_fact as fact

VIEW = Path('.artifacts/raw-canonical-preparation-20261011/source-view-v3')
COMMAND = ['python3', '-B', 'docs/audits/raw-semantic-parent-closure-20261011/verify.py']


def need(value, message):
    if not value:
        raise ValueError(message)


def census(source):
    plane.local_parents(plane.ROOT / VIEW / 'endpoint')
    declared = {name: {k: row[k] for k in ('bytes', 'sha256')} for name, row in source['members'].items()}
    namespace.check_tree(VIEW, declared)
    need(all(bool((VIEW / name).stat().st_mode & 0o111) == (row['mode'] == '100755')
             for name, row in source['members'].items()), 'complete fixed checkpoint executable modes')
    return pin(fact.encoded(source))


def run(label, environment):
    result = subprocess.run(COMMAND, cwd=VIEW, env=environment, capture_output=True, text=True)
    actual = dict(command=COMMAND, cwd=str(VIEW), status=result.returncode,
                  stdout=result.stdout, stderr=result.stderr)
    save(label + '-result.json', actual)
    return actual


def main():
    fact.preparation()
    source = json.loads((fact.PREPARATION / 'source-v3.json').read_bytes())
    before = census(source)
    name = 'scripts/check_record_value_publication.py'
    old = (VIEW / name).read_bytes()
    current = Path(name).read_bytes()
    need(old != current and pin(old) == {k: source['members'][name][k] for k in ('bytes', 'sha256')},
         'genuine current producer advancement from the exact accepted source epoch')
    labels = ('fixed-original', 'fixed-current-instrument', 'fixed-restored')
    need(all(not (BASE / (label + '-result.json')).exists() for label in labels), 'all fixed-source result routes preflight')
    environment = os.environ.copy()
    environment.update(GIT_DIR=str(Path('.git').resolve()), GIT_WORK_TREE=str(VIEW.resolve()))
    original = run(labels[0], environment)
    need(type(original['status']) is int and original['status'] == 0
         and original['stdout'] == fact.PARENT_SUCCESS and original['stderr'] == '', 'actual complete dated positive before control')
    # The fixture is an ignored copy in this repository, never an original or another Git repository.
    def interrupted(signum, frame):
        raise SystemExit(128 + signum)
    prior_signal = signal.signal(signal.SIGTERM, interrupted)
    try:
        (VIEW / name).write_bytes(current)
        changed = run(labels[1], environment)
    finally:
        (VIEW / name).write_bytes(old)
        signal.signal(signal.SIGTERM, prior_signal)
    restored = census(source)
    need(type(changed['status']) is int and changed['status'] == 1 and changed['stdout'] == ''
         and 'whole current source equals fixed Git bytes' in changed['stderr'],
         'actual current producer cannot be borrowed into historical fixed-source proof')
    final = run(labels[2], environment)
    need(final == original and census(source) == before == restored, 'whole restored original source and native result conserve')
    save('fixed-source-control.json', dict(before=before, restored=restored, source_revision=source['revision'],
        factory=name, original_factory=pin(old), current_factory=pin(current),
        original_body=old.decode(), current_body=current.decode(), labels=list(labels),
        condition='Only the explicit copied producer byte epoch changes. Original reader, full fixed source population and original semantic/native/private limits retain. Current advancement is qualified separately.'))
    print('PASS unchanged complete dated reader, genuine current-instrument refusal and exact restored source/native result.')


if __name__ == '__main__':
    main()
