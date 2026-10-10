"""Close only proved coordinate nodes and prepare the exact successor resume pointer."""
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-current-closure-20261010')
REVISION = '7efdbf512bfd865220fb13f83fbbded9b42cdcf0'
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def need(condition, cause):
    if not condition:
        raise ValueError(cause)


def field(block, name, value):
    result, count = re.subn(r'^  ' + name + r': `[^\n]*`$', lambda match: '  ' + name + ': `' + value + '`', block, count=1, flags=re.M)
    need(count == 1, 'unique final coordinate task field: ' + name)
    return result


def main():
    checks = json.loads((BASE / 'checks.json').read_bytes())
    for name in ('original-semantic', 'close', 'focused', 'book-build', 'native', 'current-native'):
        need(type(checks[name]['status']) is int and checks[name]['status'] == 0, 'whole prerequisite actual success: ' + name)
    owner = (BASE / 'scope.txt').read_text().strip()
    publication = owner.rsplit('.', 1)[0]
    execution = publication.rsplit('.', 1)[0]
    coordinate = execution.rsplit('.', 1)[0]
    address = coordinate.rsplit('.', 1)[0] + '.4'
    raw = TASK.read_text()
    notes = {
        coordinate: 'Complete history rollover and raw-coordinate execution children qualify. Whole pre-intake own/public/expression hypotheses, original matching and hostile controls, exact raw/error/argument conservation and current publication join without coordinate normalization. Fresh complete original semantic replay and separate final source/query/book/native/capacity snapshot qualify the finished own-coordinate scope. Pinned finite public contracts retain their dated role; original private/framework/provider/formatter/toolchain/identity, addresses, alias, visual/HIAL/full-CI/push retain separate owners. See final publication child and its complete actual proof.',
        execution: 'All complete predecessor custody, independent source recipes, original intake/matching/hostile and current publication children qualify. Every original own coordinate and source association, forwarding phase, opaque operand and raw allocation conserves; genuine line/file/source controls preserve predecessor meanings before refusal. Fresh unchanged original semantic execution and independently reconstructed final current publication require actual success before commit. Original private/framework/provider/formatter/toolchain/identity/address/alias and native/visual/HIAL/full-CI/push owners remain open.',
        execution + '.2': 'Every own catalog, pinned public caller/eval/Carp/subtest contract and composed source-only hypothesis child is done. Fixed hypotheses precede original-coordinate intake; complete used and unused expression alternatives and legitimate invocation-root recipes retain. Fresh full matching/hostile replay consumes the complete source closure and original custody. Original formatter/private/provider/toolchain identities remain unmeasured; no opaque inherited operand establishes a referent. Final publication child records whole actual proof.',
        publication: 'Qualified non-growing retention, atomic four-card current publication and final whole delivery children qualify. Every earlier question/probe/locality obligation and exact original source remains retrievable; source-derived complete current allocation and native guidance preserve unchanged collection ceilings. Fresh original semantic replay and whole dated final publication proof qualify only completed coordinate nodes. All original private/framework/address/identity/alias/visual/HIAL/full-CI/push scopes retain separate owners.',
        owner: 'Fresh unchanged full original-coordinate semantic reader succeeds with the exact complete admitted result, predecessor class/frame/visible-argument preservation, all original custody and source/matching inputs, genuine coordinate interventions and whole-result controls. First failures and RAM-stopped prefixes remain non-success evidence. The final current guide and complete source/query/history/book/native/capacity publication are independently reconstructed from the committed atomic epoch and exact retained final inputs. Default dated replay uses fixed Git sources and saved native/query inputs, preserving later unrelated current progress as a separate role. Initial allocation preflight omitted a second answers block: exact first source/actual failure and complete row difference retain, corrected full source allocation equals both actual query streams, and genuine later-block omission refuses. Every prior card/question/probe remains exact; only final guide endings, owned task closure and navigation change. Final pointer rebuild preserves complete rendered guidance and refreshes every copied source including Memory. Re-derivation: independent complete Git/source/query/history/census/native/task reconstruction and fresh full semantic execution. Falsification: complete genuine coordinate/predecessor/result controls plus typed status, borrowed current success, source/card/query/authority/late-answer/scope/native-address controls. Durability: unchanged sealed corpus, complete dated programmes, original/final sources, full actual results and task/Git. Guarded focused All tests successful; Files=3, Tests=310 and complete final current/native readers pass. Successful independent snapshot, fresh claims/staged doctrines and normal hooks are required before commit. Only proved coordinate nodes close; original private/framework/provider/formatter/toolchain/identity/address/alias/visual/HIAL/full-CI/push remain open. Raw-address/lifetime qualification is next.'}
    for ident, verification in notes.items():
        start = raw.index('- ID: `' + ident + '`')
        end = raw.find('\n- ID:', start + 1)
        if end < 0:
            end = len(raw)
        block = raw[start:end]
        block = field(field(field(block, 'Status', 'done'), 'Verification', verification), 'Commit', 'this slice; completed child history retains')
        if ident == owner:
            need('Acceptance Checklist (enforced)' not in block, 'fresh final publication acceptance only')
            block += '''  ## Acceptance Checklist (enforced)

  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S in root-cause.json pins atomic publication at 7efdbf512bfd865220fb13f83fbbded9b42cdcf0, while the final container remains open. Complete committed task/source/publication records identify every remaining closure obligation. First preflight actual failure and exact first oracle reproduce omission of the second answers block; the existing parser accumulates all blocks and complete actual query rows expose the assumption.
  - [x] **ADDRESSED (verified)** — Fresh original-semantic actual0 reconstructs the whole sealed qualification and every original source/custody/predecessor/control result. Final current-native actual0 and complete source/query/native capture qualify current publication. Separate dated snapshot reconstruction must pass every original/final source, question/probe/history, full book/native/capacity and task contract plus genuine typed/borrowed/omission/authority/scope controls before commitment. Only finished coordinate nodes close; address and all private/native owners remain open.
  - [x] **NO REGRESSION** — All tests successful; Files=3, Tests=310 in focused. Final pointer build and every copied-source check, complete current reader, independent whole dated snapshot, fresh claims, staged scripts/check_doctrines.sh and normal hooks gate commit. Historical programmes/seals, all four current cards and every collection ceiling conserve; no broader runtime/identity/address/visual/HIAL/full-CI/push closure is inferred.

'''
        raw = raw[:start] + block + raw[end:]
    TASK.write_text(raw)
    old = subprocess.check_output(['git', '--no-replace-objects', 'show', REVISION + ':MEMORY.md']).decode()
    need(old.count(owner + '` (pending)') == 1, 'unique committed final publication pointer')
    pointer = old.replace(owner + '` (pending)', address + '` (pending)', 1)
    begin, end = pointer.index('- next_action:'), pointer.index('- in_flight_uncommitted:')
    pointer = pointer[:begin] + '- next_action: Start the raw-address/lifetime leaf. Derive each opaque address role from complete qualified source graphs and simultaneous-live calls; reject borrowed/aliased addresses and wrong reference kinds. Preserve original private/provider/formatter/toolchain/identity and downstream scopes; commit each verified slice.\n' + pointer[end:]
    Path('MEMORY.md').write_text(pointer)
    print('PASS only completed coordinate task contracts close and exact next address/lifetime pointer is ready; final native rebuild and independent/staged gates required.')


if __name__ == '__main__':
    main()
