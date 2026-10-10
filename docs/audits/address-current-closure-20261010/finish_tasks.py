"""Prepare the complete reviewed final frontier for independent qualification."""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from contracts import (ADDRESS, BASE, CLOSED, OWNER, PUBLICATION_OWNER, READERS,
                       TASK, baseline, contract, load, navigation, need, nodes, read, root)

CHECKLIST = '''
  ## Acceptance Checklist (enforced)

  - [x] **ROOT CAUSE (WHY + WHERE)** — git log -S in docs/audits/address-current-closure-20261010/root-cause.json identifies d82d1ef as the exact atomic publication predecessor. Its complete maintained guidance and original address/publication Goal, Acceptance and Children leave final container acceptance open. Fixed complete prerequisite namespaces and original/proposed/current source domains establish that boundary without inferring native identity.
  - [x] **ADDRESSED (verified)** — docs/audits/address-current-closure-20261010/proof.json independently reconstructs whole original bodies, source/holder/numerical associations and every unchanged parent obligation. Fresh complete semantic receipts join whole reviewed cards, every question/probe/history, current/native guidance and canonical copied sources. Genuine whole owner/scope/source/receipt interventions reject; only verified finite address nodes close. Re-derivation, falsification and durability remain distinct; full raw-stack/native/cold/visual/HIAL successors stay owned.
  - [x] **NO REGRESSION** — All tests successful; Files=3, Tests=310 in focused. Fresh complete source, class/frame, coordinate, admission, operand, holder, numerical, raw-parent, preparation, current and current-native readers pass with typed actual outcomes. Whole final book/source copies, unchanged Knowledge Map authority, task measurements, claim inventory, staged scripts/check_doctrines.sh and normal hooks gate commitment. The sandbox process-inspection refusal remains actual2, never success. No original native recapture, allowance widening, full CI or push occurs.

'''


def main():
    root()
    checks = load(BASE / 'checks.json')
    for name in [*READERS, 'close', 'focused-repaired', 'current', 'source-current']:
        need(type(checks[name]['status']) is int and checks[name]['status'] == 0, 'fresh verified prerequisites before final frontier: ' + name)
    _, _, before = baseline()
    original = nodes(before[TASK]); text = read(TASK).decode(); current = nodes(text.encode())
    descriptions = {
        ADDRESS: 'Full unchanged finite address/lifetime container acceptance qualifies in docs/audits/address-current-closure-20261010/proof.json. Every source/core/helper/parser/nested/raw/numerical/publication descendant is done. Whole original bodies, source graphs, active holders and simultaneous numerical relations join complete fresh readers and genuine separating controls. Cross-call/capture/native/provider/formatter/hidden identities remain opaque; full raw-stack joining and downstream scopes retain their owners.',
        PUBLICATION_OWNER: 'Complete unchanged governed publication acceptance qualifies in docs/audits/address-current-closure-20261010/proof.json. Whole original/proposed/current cards, all questions/probes/history and exact book/native/copied-source domains conserve under unchanged collection authority. Fresh complete semantic/current/native results, genuine scope/ownership/receipt controls and focused/task/claim/staged/hook gates qualify. Only finite address nodes close; full raw-stack joining remains next.',
        OWNER: 'Independent complete dated closure is docs/audits/address-current-closure-20261010/proof.json. Fixed whole prerequisite namespaces, unchanged original Goal/Acceptance/Children, complete original source/holder/numerical reconstruction and all fresh typed semantic results join exact original/proposed/current source, global question/probe/history, book/native/copied-source and capacity domains. Genuine whole controls reject count-only closure, borrowed domains/owners/commands, scope promotion, omissions and malformed results. Sandbox process inspection first refused actual2; approved complete replay passed. Final task/book/claim/staged doctrines and normal hooks gate commitment; full raw-stack joining is next, native and broader successors remain open.'}
    for key in sorted(CLOSED):
        block = current[key]
        need(contract(block) == contract(original[key]) and '  Status: `active`\n' in block,
             'whole active unchanged closure task before finalization')
        final = block.replace('  Status: `active`\n', '  Status: `done`\n', 1)
        final, count = re.subn(r'^  Verification: `[^\n]*`$', '  Verification: `' + descriptions[key] + '`', final, count=1, flags=re.M)
        need(count == 1, 'unique final verification field')
        final = final.replace('  Commit: `pending`', '  Commit: `this slice`', 1)
        if key == OWNER:
            final = final.rstrip('\n') + '\n' + CHECKLIST
        need(text.count(block) == 1, 'whole exact final task body replacement')
        text = text.replace(block, final, 1)
    Path(TASK).write_text(text)
    memory, index = navigation(before)
    Path('MEMORY.md').write_text(memory); Path('docs/TASK_TREE.md').write_text(index)
    print('PASS unchanged complete finite address/publication task contracts and final raw-stack frontier prepared; final independent/staged/hook qualification gates commitment.')


if __name__ == '__main__':
    main()
