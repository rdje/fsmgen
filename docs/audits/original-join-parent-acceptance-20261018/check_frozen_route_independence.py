"""Exercise frozen recovery beside changed and absent current files."""
import argparse
import base64
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
AUDIT = Path('docs/audits/original-join-parent-acceptance-20261018')
READER = AUDIT / 'frozen_operand_route.py'
SAVED = AUDIT / 'frozen-operand-route-qualified.json.gz'
OUTPUT = AUDIT / 'frozen-route-independence.json.gz'
CARD = Path('docs/knowledge/claim-verification-record-enforcement.md')
HELPER = AUDIT / 'verify_claim_readers.sh'


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def check():
    programme = (ROOT / READER).read_bytes()
    saved = (ROOT / SAVED).read_bytes()
    parent = ROOT / '.artifacts/tmp/tests'
    assert not parent.is_symlink() and parent.stat().st_dev == ROOT.stat().st_dev
    fixture = Path(tempfile.mkdtemp(prefix='frozen-route-', dir=parent))
    assert fixture.stat().st_dev == ROOT.stat().st_dev
    records = []
    try:
        (fixture / AUDIT).mkdir(parents=True)
        (fixture / READER).write_bytes(programme)
        (fixture / SAVED).write_bytes(saved)
        (fixture / CARD).parent.mkdir(parents=True)
        for label, card, helper in (
            ('changed-current', b'changed current card\n', b'changed current helper\n'),
            ('different-current', b'---\ninvalid: card\n', b'exit 97\n'),
            ('missing-current', None, None)):
            for path, body in ((CARD, card), (HELPER, helper)):
                if body is None:
                    (fixture / path).unlink()
                else:
                    (fixture / path).write_bytes(body)
            command = ['python3', '-B', str(READER)]
            result = subprocess.run(command, cwd=fixture, stdin=subprocess.DEVNULL,
                                    capture_output=True, timeout=60)
            # Only root normalization affects the retained failure wire. The
            # child source, frozen inputs and full streams otherwise retain.
            record = dict(label=label, command=command, status=result.returncode,
                stdout=result.stdout.decode().replace(str(ROOT), '.'),
                stderr=result.stderr.decode().replace(str(ROOT), '.'),
                card=None if card is None else blob(card),
                helper=None if helper is None else blob(helper))
            records.append(record)
            assert result.returncode == 0, record
            assert result.stdout == b'Frozen original route reconstructs completely; live filesystem reads are denied.\n'
            assert not result.stderr
            assert (fixture / SAVED).read_bytes() == saved
        return dict(schema='fsmgen.frozen_route_independence.v1',
            programme=blob(Path(__file__).read_bytes()), reader=blob(programme),
            saved=blob(saved), actual=records,
            scope='Actual new frozen reader defaults beside altered and absent current card/helper files in an isolated same-volume workspace. Complete saved result stays unchanged. Git objects remain in the primary repository; no secondary repository or original reader is created or executed.')
    finally:
        # This directory was exclusively created here; only regular files
        # created above may be removed, never a shared cache or repository.
        allowed = {READER, SAVED, CARD, HELPER}
        for member in fixture.rglob('*'):
            assert not member.is_symlink() and member.stat().st_dev == ROOT.stat().st_dev
            if member.is_file():
                assert member.relative_to(fixture) in allowed
        shutil.rmtree(fixture)
        assert not fixture.exists()


def main():
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    args = parser.parse_args()
    value = check()
    output = ROOT / OUTPUT
    assert not output.is_symlink()
    if args.write:
        with output.open('xb') as stream:
            stream.write(gzip.compress((json.dumps(value, sort_keys=True) + '\n').encode(), mtime=0))
    else:
        actual = json.loads(gzip.decompress(output.read_bytes()))
        assert json.dumps(actual, sort_keys=True) == json.dumps(value, sort_keys=True)
    print('Changed and absent current files leave actual frozen default recovery unchanged.')


if __name__ == '__main__':
    main()
