"""Closed read-only factory image for the declared historical semantic-reader role."""
import contextlib
import gzip
import json
from pathlib import Path

import execute
import prepare

AUDIT = execute.AUDIT
FACTORY = 'scripts/check_record_value_publication.py'
ROLES = {'prerequisites', 'association'}
_active = False


def inventory():
    name = str(AUDIT / 'historical-factory-role-inventory.json.gz')
    body = execute.read(name)
    committed = execute.command(['git', '--no-replace-objects', 'show',
                                 '5a6b98c51e4bb79c562b0bc00646d2b16957965f:' + name])
    assert body == committed, 'exact committed historical-source proposal'
    return json.loads(gzip.decompress(body))


def check_image(image):
    expected = inventory()
    assert image == expected, 'whole source-role/import/contract inventory'
    modules = image['historical_imports']['modules']
    assert FACTORY in modules and image['differing_imports'] == [FACTORY]
    for name, row in modules.items():
        body = prepare.unblob(row)
        if name != FACTORY:
            assert execute.read(name) == body, 'unchanged historical import: ' + name
    old = prepare.unblob(modules[FACTORY])
    assert all(prepare.unblob(role['factory']) == old for role in image['historical_roles'].values())
    return old


@contextlib.contextmanager
def source_view(role, image=None):
    """Change one declared input read, without changing any programme or disk byte.

    The legacy programme already compiles the factory from its fixed Git revision.
    Its identity guard must see the same historical input in this explicitly
    historical role. The live/current publication route must never enter this view.
    """
    global _active
    assert Path.cwd().resolve() == execute.ROOT, 'historical source paths are repository-relative'
    assert role in ROLES and not _active, 'one explicit historical semantic role'
    image = inventory() if image is None else image
    old = check_image(image)
    target = execute.ROOT / FACTORY
    original = Path.read_bytes
    live_before = original(target)
    assert prepare.identity(live_before) == {key: image['current_factory'][key] for key in ('bytes', 'sha256')}
    reads = []

    def read(path):
        # Lexical absolute paths avoid following any additional symlink or repository.
        absolute = path if path.is_absolute() else Path.cwd() / path
        if absolute == target:
            reads.append(dict(path=FACTORY, role=role, source=prepare.identity(old)))
            return old
        return original(path)

    _active = True
    Path.read_bytes = read
    try:
        yield dict(role=role, reads=reads, historical_factory=prepare.identity(old),
                   live_factory=prepare.identity(live_before),
                   scope='Historical source view only; no live factory currency or semantic qualification is implied.')
    finally:
        Path.read_bytes = original
        _active = False
        assert original(target) == live_before, 'live factory must remain untouched'
        check_image(image)
