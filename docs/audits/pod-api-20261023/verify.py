#!/usr/bin/env python3
"""Re-derive the saved census against its immutable Git boundary."""
import hashlib
import json
from pathlib import Path
import subprocess

saved = json.loads(Path('docs/audits/pod-api-20261023/inventory.json').read_text())
revision = saved['capture_revision']
assert len(revision) == 40 and all(c in '0123456789abcdef' for c in revision)
paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, 'perl/FSM']).decode().splitlines()
expected = sorted(p for p in paths if p.endswith('.pm'))
rows = saved['sources']
assert expected == [r['path'] for r in rows]
for row in rows:
    raw = subprocess.check_output(['git', 'show', f"{revision}:{row['path']}"])
    assert row['bytes'] == len(raw) and row['sha256'] == hashlib.sha256(raw).hexdigest()
    # Independent syntax/presence oracle against the immutable source bytes.
    probe = subprocess.check_output(['perl', '-MPod::Simple::Checker', '-e',
        'local $/; my $s=<STDIN>; my $c=Pod::Simple::Checker->new; my $o=""; '
        '$c->output_string(\\$o); $c->parse_string_document($s); '
        'print(($c->content_seen?1:0).":".(($c->any_errata_seen || $o =~ /\\S/)?1:0));'], input=raw)
    assert probe.decode() == f"{int(row['pod'])}:{int(row['errors'])}"
# Falsification: malformed POD must produce errata; plain Perl must lack content.
for raw, result in [(b'=head1 NAME\n\nBroken E<missing>\n', b'1:1'), (b'package Empty;\n1;\n', b'0:0')]:
    probe = subprocess.check_output(['perl', '-MPod::Simple::Checker', '-e',
        'local $/; my $c=Pod::Simple::Checker->new; my $o=""; $c->output_string(\\$o); '
        '$c->parse_string_document(<STDIN>); print(($c->content_seen?1:0).":".(($c->any_errata_seen || $o =~ /\\S/)?1:0));'], input=raw)
    assert probe == result
print(f"Saved source join: {len(rows)} modules; {sum(r['pod'] for r in rows)} with POD; "
      f"{sum(not r['pod'] for r in rows)} without; {sum(r['errors'] for r in rows)} with syntax errors. "
      "All source identities and malformed/plain controls passed.")
