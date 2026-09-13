"""One-time recovery of this slice's proven newly created, misrooted render."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat

import inspect_book

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
LOG = ROOT / '.artifacts/logs' / BASE.name
SOURCE = (ROOT / '../../../.artifacts/tmp/native-proxy-populated-controller-book-20260913').resolve()
TARGET = ROOT / '.artifacts/tmp/native-proxy-populated-controller-book-20260913'


def main():
    assert (LOG / 'book.exit').read_bytes() == b'0\n'
    assert not TARGET.exists() and not TARGET.is_symlink()
    start = (LOG / 'book.stdout').stat().st_birthtime
    end = (LOG / 'book.exit').stat().st_mtime
    paths = [SOURCE, *SOURCE.rglob('*')]
    initial = {}
    for path in paths:
        info = path.lstat()
        assert info.st_dev == ROOT.stat().st_dev and info.st_uid == os.getuid()
        assert stat.S_ISREG(info.st_mode) or stat.S_ISDIR(info.st_mode)
        assert start <= info.st_birthtime <= end
        initial[path] = (info.st_dev, info.st_ino, info.st_mode, info.st_size, info.st_birthtime)
    files = [p for p in paths if p.is_file()]
    directories = [p for p in paths if p.is_dir()]
    assert len(files) == 99 and len(directories) == 4
    manifest = []
    for path in sorted(files):
        body = path.read_bytes()
        manifest.append(dict(path=str(path.relative_to(SOURCE)), size_bytes=len(body), sha256=hashlib.sha256(body).hexdigest()))
    for path in sorted(directories, key=lambda p: len(p.parts)):
        (TARGET / path.relative_to(SOURCE)).mkdir(mode=0o700)
    for row in manifest:
        shutil.copyfile(SOURCE / row['path'], TARGET / row['path'])
    for row in manifest:
        body = (TARGET / row['path']).read_bytes()
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
        assert (TARGET / row['path']).stat().st_dev == ROOT.stat().st_dev
    assert sorted(str(p.relative_to(TARGET)) for p in TARGET.rglob('*') if p.is_file()) == [r['path'] for r in manifest]
    for name, passages in [('16dk-inactive-proxy-lifetimes.html', inspect_book.PASSAGES),
                            ('16dc-vial-portable-verilator-runtime-measurement.html', inspect_book.RUNTIME_PASSAGES)]:
        parser = inspect_book.Text(); parser.feed((TARGET / 'book' / name).read_text())
        text = ' '.join(''.join(parser.fragments).replace('\u2019', "'").split())
        assert all(passage in text for passage in passages)
    assert set([SOURCE, *SOURCE.rglob('*')]) == set(paths)
    for path, expected in initial.items():
        info = path.lstat()
        assert (info.st_dev, info.st_ino, info.st_mode, info.st_size, info.st_birthtime) == expected
    for row in manifest:
        path = SOURCE / row['path']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == row['sha256']
        path.unlink()
    for path in sorted(directories, key=lambda p: len(p.parts), reverse=True):
        path.rmdir()
    assert not SOURCE.exists() and not SOURCE.is_symlink()
    result = dict(owner=json.loads((BASE / 'scope.json').read_bytes())['owner'],
                  cause='The CLI --dest-dir is relative to the invocation working directory, not docs/book. A mistaken ../../../ prefix selected a path outside the repository on the same SSD.',
                  original_destination_from_repository='../../../.artifacts/tmp/native-proxy-populated-controller-book-20260913/book',
                  correct_command='mdbook build docs/book --dest-dir .artifacts/tmp/native-proxy-populated-controller-book-20260913/book',
                  source_same_volume=True, all_source_objects_owned_and_born_during_render=True,
                  capture_start=start, capture_end=end, manifest=manifest,
                  copied_files=len(files), copied_bytes=sum(r['size_bytes'] for r in manifest),
                  source_directories=len(directories), exact_copied_bytes_verified=True,
                  relocated_rendered_passages_verified=True, exact_original_output_absent=True,
                  other_volume_artifact_directories_untouched=True,
                  target=str(TARGET.relative_to(ROOT)), target_cleanup_owner='inspect_book.py')
    with (BASE / 'book-recovery.json').open('x') as stream:
        json.dump(result, stream, sort_keys=True, indent=2); stream.write('\n')
    print(json.dumps({k:v for k,v in result.items() if k != 'manifest'}, sort_keys=True))


if __name__ == '__main__':
    main()
