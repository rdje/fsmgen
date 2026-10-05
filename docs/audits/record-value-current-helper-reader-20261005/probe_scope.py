"""Run the real scoped qualifier against a concrete unrelated publication."""
import contextlib
import hashlib
import io
import json
import runpy
import sys
from pathlib import Path

BASE = Path('docs/audits/record-value-current-helper-reader-20261005')
REGISTRY = 'doctrine/live_document_size/surfaces.jsonl'
CHAPTER = 'docs/book/src/90-reference-map.md'
HELPER = 'docs/book/src/13k-isf-feature-support-matrix.md'


def main():
    original = {p: Path(p).read_text() for p in (REGISTRY, CHAPTER, HELPER)}
    additions = {
        CHAPTER: '\nCanonical source references remain distinct from normative book chapters.\n',
        HELPER: '\nThe reference map describes the book navigation independently of helper qualification.\n',
    }
    paths = sorted(Path('docs/book/src').glob('*.md'))
    before = {'files': len(paths), 'lines_total': sum(p.read_bytes().count(b'\n') for p in paths),
              'bytes_total': sum(p.stat().st_size for p in paths)}
    rows = list(map(json.loads, original[REGISTRY].splitlines()))
    change = next(r for r in rows if r.get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    change.update({'authority_id': 'CURRENT-HELPER-UNRELATED-CONTROL', 'baseline': before,
                   'delta': {'files': 0, 'lines_total': sum(v.count('\n') for v in additions.values()),
                             'bytes_total': sum(len(v.encode()) for v in additions.values())},
                   'owner': 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.73.2.3.1',
                   'rationale': 'Isolated meaningful reference guidance outside the protected helper reader section.'})
    candidates = {p: original[p] + v for p, v in additions.items()}
    candidates[REGISTRY] = ''.join(json.dumps(r, sort_keys=True, separators=(',', ':'))+'\n' for r in rows)
    protected = [p for p in Path('docs/audits/record-value-helper-topic-publication-20261005').rglob('*') if p.is_file()]
    protected += [Path(p) for p in original]
    pins = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
    old_read, old_argv = Path.read_text, sys.argv
    stdout, stderr = io.StringIO(), io.StringIO()
    def controlled_read(path, *args, **kwargs):
        return candidates.get(str(path), None) if str(path) in candidates else old_read(path, *args, **kwargs)
    try:
        Path.read_text = controlled_read
        sys.argv = [str(BASE / 'verify.py'), '--current']
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            runpy.run_path(str(BASE / 'verify.py'), run_name='__main__')
    finally:
        Path.read_text, sys.argv = old_read, old_argv
    assert all(hashlib.sha256(Path(p).read_bytes()).hexdigest() == pin for p, pin in pins.items())
    record = {'before': original, 'candidates': candidates, 'additions': additions,
              'aggregate_before': before, 'aggregate_delta': change['delta'], 'protected_sha256': pins,
              'status': 0, 'stdout': stdout.getvalue(), 'stderr': stderr.getvalue(),
              'scope': 'Real current qualifier with virtual unrelated chapter, helper-chapter tail and measured whole-book authority changes. No production or sealed evidence changed.'}
    target = BASE / 'unrelated-publication-probe.json'; assert not target.exists()
    target.write_text(json.dumps(record, sort_keys=True, indent=2)+'\n')
    print('PASS actual scoped current qualifier admits the concrete unrelated publication; all production and original snapshot inputs remain exact.')


if __name__ == '__main__':
    main()
