"""Publish the owned HDL policy explanation without widening book capacity."""
from pathlib import Path
from collections import Counter
import base64
import gzip
import hashlib
import json
import re
import textwrap

PATH = Path('docs/book/src/16dc-vial-portable-verilator-runtime-measurement.md')
RECEIPT = Path('docs/audits/ghdl-test-policy-20261012/book-review.json.gz')
OLD = '''This checkpoint qualifies the index adapter. Audit-source declaration repair
remains open in `TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.2`. The first shared
policy-owner watcher failed on pre-existing direct GHDL test supervision;
`.1.1.2` owns that repair before parent acceptance or full-CI qualification.
The first failure and its incomplete source-census boundary remain recorded;
the passing index cases do not qualify the whole ownership watcher or HDL.
'''
REPLACEMENT = '''The index adapter qualifies bounded checker/evidence cases. Audit-source
coverage remains open in `TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.2`.
The first shared policy-owner watcher failed on pre-existing direct HDL test
supervision; `.1.1.2` owns the sealed repair below. That first failure and its
incomplete source-census boundary remain recorded. Index cases alone do not
qualify the whole ownership watcher or HDL. Parent acceptance and full CI
retain separate owners.
'''
ADDITION = r'''### HDL behavior test policy

`FSM::Test::HDLBehaviorRuntime` owns the existing GHDL behavior tests and
storage-name Verilator lint. It reuses the shared supervisor, preserving each
caller's schema, stage, analysis/runtime options, top, stop time and assertions.
Each native stage retains its fixed 60-second wall and one-MiB aggregate capture.
These are safety budgets, not runtime-performance measurements.

| Profile | Existing contract |
| --- | --- |
| `reset_behavior` | Reset kind and polarity |
| `reset_only` | Reset-only outputs and hold |
| `internal_role` | Internal reset/write/hold ownership |
| `storage_ownership` | Actor storage reset/write/read/hold |
| `child_storage_reads` | Live parent storage reads |
| `dynamic_count` | Wait-count timing and sampling |
| `unsigned_comparison` | Integer truth-table comparison |
| `extract_runtime` | Extraction capture, hold and reset |
| `storage_identifier` | GHDL analysis and fixed Verilator lint |

Inside a generated fixture, call `run_ghdl_analysis($profile, $directory,
\@sources)` before `run_ghdl_behavior($profile, $directory)`. The latter uses
the sealed top and stop time; `storage_identifier` has no runtime stage.
`run_storage_identifier_lint($directory, $source, $objects)` admits only its
fixed lint command. Arbitrary command, flag, bound and top substitutions fail
before process creation.

Directories must be below `.artifacts/tmp`; sources and object paths remain
inside their fixture. Symlink ancestry, traversal and nested Git metadata are
refused. Marker controls create no Git repository. The first read-only
namespace probe exposed overly broad artifact admission; its native failure
remains recorded alongside the corrected public-API controls.

Each GHDL profile caches its canonical provider. Existing
`FSMGEN_RESET_GHDL` selection remains available except for `storage_identifier`,
which retains PATH-only selection. Verilator lint also caches its canonical
tool. Later PATH/startup-variable changes cannot redirect admitted commands;
child scratch stays fixture-local and the caller environment stays unchanged.
Missing providers retain explicit skips in the original tests.

Run the native policy controls and an original comparison bench with:

```bash
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib \
  t/2069-hdl-behavior-runtime.t
scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib \
  t/1910-vhdl-unsigned-comparison-literals.t
```

T2069 uses generated fake providers to observe admitted commands and challenge
native nonzero exit, signal, overflow and a TERM-resistant leader/descendant
at the sealed deadline. It preserves each closed result and performs no retry.
Those controls qualify policy and cleanup; actual HDL semantics require the
original benches with their real providers. A skipped bench supplies no native
HDL qualification. The shared ownership watcher permits the adapter and keeps
direct test supervision restricted to its hostile-process oracle.

'''


def pieces(text):
    """Separate fenced regions before considering any paragraph reflow."""
    result, block, fenced, marker = [], [], False, None
    for line in text.splitlines(keepends=True):
        match = re.match(r'^ {0,3}(`{3,}|~{3,})', line)
        if not fenced and match:
            result.append((False, ''.join(block)))
            block, fenced, marker = [line], True, match.group(1)
        elif fenced:
            block.append(line)
            if re.fullmatch(r' {0,3}' + re.escape(marker[0]) +
                            '{' + str(len(marker)) + r',}\s*', line.rstrip('\n')):
                result.append((True, ''.join(block)))
                block, fenced, marker = [], False, None
        else:
            block.append(line)
    assert not fenced, 'unclosed fence is not admissible for reflow'
    result.append((False, ''.join(block)))
    return result


def identity(body):
    return dict(bytes=len(body), lines=body.count(b'\n'),
                line_bytes=max(map(len, body.splitlines()), default=0),
                sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def main():
    before = PATH.read_bytes()
    original = before.decode()
    assert original.count(OLD) == 1
    anchor = 'RAM-guard metric fixtures now use '
    assert original.count(anchor) == 1
    semantic = original.replace(OLD, REPLACEMENT).replace(anchor, ADDITION + anchor)
    need = max(0, semantic.count('\n') - 4728)
    saved, compacted, records = 0, [], []
    for fenced, block in pieces(semantic):
        if fenced or saved >= need:
            compacted.append(block)
            continue
        paragraphs = re.split(r'(\n\n+)', block)
        for index in range(0, len(paragraphs), 2):
            paragraph = paragraphs[index]
            lines = paragraph.splitlines()
            if saved >= need or len(lines) < 3 or re.search(r'\d', paragraph):
                continue
            if any(re.match(r'^(?:\s|[#|>*+\-]|<!--)', line) or
                   line.endswith('  ') for line in lines):
                continue
            # Existing inline-code contents and Markdown links must stay exact.
            candidate = textwrap.fill(' '.join(lines), width=175,
                                      break_long_words=False, break_on_hyphens=False)
            if paragraph.endswith('\n'):
                candidate += '\n'
            if re.findall(r'`[^`]*`', paragraph) != re.findall(r'`[^`]*`', candidate):
                continue
            if re.findall(r'\[[^\]]*\]\([^)]*\)', paragraph) != re.findall(
                    r'\[[^\]]*\]\([^)]*\)', candidate):
                continue
            gain = paragraph.count('\n') - candidate.count('\n')
            if gain <= 0:
                continue
            assert paragraph.split() == candidate.split()
            records.append(dict(before=paragraph, after=candidate, saved_lines=gain))
            paragraphs[index] = candidate
            saved += gain
        compacted.append(''.join(paragraphs))
    final = ''.join(compacted)
    # Reflow changes whitespace only; semantic edits are explicitly declared above.
    assert semantic.split() == final.split()
    assert [p for f, p in pieces(semantic) if f] == [p for f, p in pieces(final) if f]
    assert Counter(line for line in semantic.splitlines() if re.search(r'\d', line)) == Counter(
        line for line in final.splitlines() if re.search(r'\d', line))
    after = final.encode()
    assert len(after) <= 292485 and after.count(b'\n') <= 4728
    receipt = dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.2',
                   path=PATH.as_posix(), before=identity(before), after=identity(after),
                   replaced={'before': OLD, 'after': REPLACEMENT}, addition=ADDITION,
                   reflow=records, checks=dict(words_conserved=True,
                   all_fences_byte_identical_to_semantic_candidate=True,
                   all_numeric_lines_identical_to_semantic_candidate=True),
                   unchanged_allowance={'bytes': 292485, 'lines': 4728},
                   programme=Path(__file__).relative_to(Path.cwd()).as_posix(),
                   programme_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest())
    with RECEIPT.open('xb') as stream:
        stream.write(gzip.compress(json.dumps(receipt, sort_keys=True).encode(), mtime=0))
    PATH.write_bytes(after)
    print('Book published:', len(after), 'bytes;', after.count(b'\n'),
          'lines;', len(records), 'prose reflows;', saved, 'lines recovered')


if __name__ == '__main__':
    main()
