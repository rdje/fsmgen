#!/usr/bin/env python3
"""Recheck mdBook destination resolution without writing outside the repository."""
from pathlib import Path
import json
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
scratch = root / '.artifacts' / 'tmp'
scratch.mkdir(parents=True, exist_ok=True)
assert scratch.resolve().is_relative_to(root)
assert scratch.stat().st_dev == root.stat().st_dev
marker = 'FSMGEN_BOOK_DESTINATION_PROBE'
with tempfile.TemporaryDirectory(prefix='mdbook-destination-', dir=scratch) as temporary:
    work = Path(temporary)
    book = work / 'book-source'
    (book / 'src').mkdir(parents=True)
    (book / 'book.toml').write_text('[book]\ntitle = "Destination probe"\n')
    (book / 'src/SUMMARY.md').write_text('# Summary\n\n- [Probe](chapter.md)\n')
    (book / 'src/chapter.md').write_text('# Probe\n\n' + marker + '\n')
    receipts = []
    for mode in ('relative', 'absolute'):
        destination = work / (mode + '-output')
        assert not destination.exists()
        argument = destination.name if mode == 'relative' else str(destination)
        result = subprocess.run(
            ['mdbook', 'build', str(book), '--dest-dir', argument],
            cwd=work, text=True, capture_output=True, timeout=45,
        )
        assert result.returncode == 0, result.stderr
        assert marker in (destination / 'chapter.html').read_text()
        assert not (book / destination.name).exists()
        assert destination.resolve().is_relative_to(root)
        assert destination.stat().st_dev == root.stat().st_dev
        receipts.append({'mode': mode, 'exit_code': result.returncode,
                         'resolved_against_invocation_cwd': True,
                         'fresh_render_contains_marker': True,
                         'repository_local_same_volume': True})
    version = subprocess.run(['mdbook', '--version'], text=True,
                             capture_output=True, check=True, timeout=15).stdout.strip()
print(json.dumps({'mdbook_version': version, 'probes': receipts,
                  'temporary_workspace_removed': not work.exists()}, sort_keys=True))
