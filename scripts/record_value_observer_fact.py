"""Authenticate admitted finite observer facts; no fresh original recapture."""
import hashlib
import json
import subprocess
from pathlib import Path

import book_source_references as plane

BASE = Path('docs/audits/observer-current-publication-20261011')
REPAIR = Path('docs/audits/observer-original-header-join-20261011')
REVISION = 'a9fa6d6955797577c6be8fd54c1c6a507e48a526'
CARD = 'docs/knowledge/record-value-original-observer-helper-paths.md'
QUESTION = 'what qualifies complete original observer argument headers?'
ADMISSION = {'bytes': 8400, 'sha256': 'cb47a2ef21890191fa8e2d5f49ea6cb8fda4b30fa3856b4e25c691c19eca1315'}
GUIDE = '''Complete finite observer acceptance now joins every source expression and whole
encoded header with its observer, callback, refusal, subtest or do-load role.
The completed source, class/frame, public grammar, scalar, regex, hidden-value
and original-header children reexecute before this publication. Each original
frame and full argument header retains its exact membership and order.

Full literal, quote, escape, truncation and count-marker compatibility uses the
qualified current grammar. Authored regex constructor alternatives remain
explicit. Whole reference tokens, receiver parameters and private framework/eval
intervals conserve their original bytes without supplying native identity.
Original provider, formatter settings, flags, encoding and native identities
remain unmeasured. Source-selected meaning and encoded compatibility retain
separate evidence roles.

For example, a different proper prefix of an authored public subtest name can
pass a dated predecessor that checks only a prefix. It fails the complete token
contract here. Removing a required ellipsis, changing a quote or count marker,
borrowing a frame, changing a role, omitting an argument or reordering a frame
also fails its distinct full contract. Complete original and altered products,
actual outcomes and the independent lexical/source/allocation reader remain
available in the dated original-header qualification.

The canonical observer fact now admits this complete finite result through a
non-growing review. Every earlier meaning, question and probe retains its role;
the previous full-format uncertainty is refined only by the explicitly
conditional grammar. The first growing drafts and their actual refusals remain
retained. Genuine lost-meaning, lost-question, lost-probe, wrong-owner, wrong-root,
narrowed-scope and native-promotion proposals reject before any admission seal.
The review is an engineering judgment, not an automated language-equivalence
oracle.

The maintained current reader authenticates the complete admitted preparation,
whole original-header namespace and actual prerequisite receipts. It still
checks all current canonical sources, global direct and cached question
ownership, exact physical capacity, canonical source copies and rendered
guidance. Authentication does not freshly reconstruct original executions.
Its historical success stream remains compatible. Unrelated qualified canonical
progress remains permitted under the unchanged collection authority.

Replay the complete dated publication independently of later current progress:

```bash
scripts/run_with_ram_guard.sh -- python3 -B docs/audits/observer-current-publication-20261011/verify.py
```

The earlier observer and address paragraphs retain their checkpoint roles.
Only the unchanged finite observer parent and its completed children close here.
Complete raw-stack joining is next. First-cause, consumer, alias, cold, permanent,
host-native, private and visual acceptance retain their own unchanged owners;
HIAL and full CI/push gates remain open.

'''


def require(condition, cause):
    if not condition:
        raise ValueError(cause)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def fingerprint(relative, expected):
    """Bounded same-volume streaming authentication of complete admitted bytes."""
    require(type(expected) is dict and set(expected) == {'bytes', 'sha256'}
            and type(expected['bytes']) is int and expected['bytes'] >= 0
            and type(expected['sha256']) is str
            and len(expected['sha256']) == 64, 'closed admitted observer identity')
    path = plane.ROOT / plane.relative(str(relative))
    plane.local_parents(path)
    require(not path.is_symlink() and path.is_file(), 'ordinary admitted observer input')
    before = path.stat()
    require(before.st_dev == plane.ROOT.stat().st_dev
            and before.st_size == expected['bytes'], 'same-volume bounded observer input')
    digest = hashlib.sha256()
    total = 0
    with path.open('rb') as stream:
        while True:
            chunk = stream.read(min(1024 * 1024, expected['bytes'] - total + 1))
            if not chunk:
                break
            total += len(chunk)
            require(total <= expected['bytes'], 'bounded whole observer input')
            digest.update(chunk)
    after = path.stat()
    require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns)
            == (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
            and dict(bytes=total, sha256=digest.hexdigest()) == expected,
            'whole admitted observer bytes conserved')
    return expected


def local(relative, expected):
    fingerprint(relative, expected)
    return plane.local_read(plane.ROOT / plane.relative(str(relative)), expected['bytes'])


def admission():
    return json.loads(local(BASE / 'admission-manifest.json', ADMISSION))


def cards(previous):
    admitted = admission()
    before = local(BASE / 'before-card.md.txt', admitted['before-card.md.txt'])
    after = local(BASE / 'published-card.md.txt', admitted['published-card.md.txt'])
    require(CARD in previous and previous[CARD].encode() == before,
            'whole predecessor observer meanings and routes')
    result = dict(previous)
    result[CARD] = after.decode()
    return result


def guide(previous):
    return previous + GUIDE


def authenticate():
    # Fixed code authority qualifies the complete admission before any proposed
    # locator, schema, root, status or success stream is consumed.
    admitted = admission()
    require(type(admitted) is dict and bool(admitted), 'complete admitted observer preparation')
    for name, expected in admitted.items():
        require(Path(name).name == name, 'closed observer preparation member path')
        fingerprint(BASE / name, expected)
    fixed = subprocess.run(['git', '--no-replace-objects', 'show',
                            REVISION + ':' + str(REPAIR / 'manifest.json')],
                           capture_output=True, cwd=plane.ROOT)
    require(type(fixed.returncode) is int and fixed.returncode == 0
            and fixed.stderr == b'', 'complete fixed observer repair authority')
    require(local(REPAIR / 'manifest.json', identity(fixed.stdout)) == fixed.stdout,
            'whole original observer repair manifest')
    repair = json.loads(fixed.stdout)
    actual_names = {str(path.relative_to(plane.ROOT / REPAIR))
                    for path in (plane.ROOT / REPAIR).rglob('*') if path.is_file()}
    require(actual_names == set(repair) | {'manifest.json', 'checks.json'},
            'complete original observer repair namespace')
    for name, expected in repair.items():
        fingerprint(REPAIR / plane.relative(name), expected)
    checks = subprocess.run(['git', '--no-replace-objects', 'show',
                             REVISION + ':' + str(REPAIR / 'checks.json')],
                            capture_output=True, cwd=plane.ROOT)
    require(type(checks.returncode) is int and checks.returncode == 0
            and checks.stderr == b'', 'fixed complete original observer gate receipts')
    fingerprint(REPAIR / 'checks.json', identity(checks.stdout))
    prepared = json.loads(local(BASE / 'prerequisites.json', admitted['prerequisites.json']))
    for path, row in prepared['fixed'].items():
        fingerprint(path, row['identity'])
    return dict(admission=ADMISSION, preparation=admitted,
                original_repair_manifest=identity(fixed.stdout),
                original_repair_members=repair, original_gate_receipts=identity(checks.stdout),
                fixed_prerequisite_inputs=prepared['fixed'],
                scope='Complete admitted finite observer preparation and original namespace authentication; no fresh semantic reconstruction, original recapture or native identity.')
