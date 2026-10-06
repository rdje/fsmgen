"""Advance only after actual current, independent and focused results pass."""
import json
from pathlib import Path

CHECKS = Path('docs/audits/tooling-current-reader-checks-20261006')
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
OWNER = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.5.4.2.3'
PARENT = OWNER.removesuffix('.5.4.2.3')


def main():
    for name in ('seal-command.json', 'independent-result.json', 'focused.json', 'observer-current.json', 'roles-command.json', 'locality.json'):
        receipt = json.loads((CHECKS / name).read_bytes())
        assert type(receipt['status']) is int and receipt['status'] == 0, name
    focused = json.loads((CHECKS / 'focused.json').read_bytes())
    assert 'All tests successful.' in focused['stdout'] and 'Files=4, Tests=361' in focused['stdout']
    s = TASK.read_text()
    summaries = {
        OWNER: 'Whole fixed-Git publication/actual-result roots and current source programmes authenticate; fresh default-guarded prior independent replay0 retains complete products. Only tooling date/current route changes, with exact body, ordered questions and core/observer cards preserved; whole physical/source-global queries conserve at minus2 encoded bytes and zero LF under unchanged six-dimensional authority. Actual direct/cache complete core/observer/tooling ownership, source selection/endpoints/bytes/ignore/index/budgets and scoped checkpoint/current/native guidance qualify. Nine companion and thirteen retained observer controls reject; native guide/three controls qualify. Actual old current1, tooling snapshot0 and unrelated current0 restore exact source bytes and independently measured book authority. Final guarded current/build/seal0 and independent whole-result0 regenerate all products, preserve all nine sealed members and reject nine typed/member/default-guard/real borrowed observer/snapshot results. First guessed native source-token intervention was a genuine-assertion no-op failure; original programme/result retain and the independent checker reproduces it before qualifying the exact heading mutation. Original locality0 and still-advertised observer current0 pass. Focused All tests successful Files4 Tests361 passes. Complete proofs/programmes/results live under record-value-tooling-current-reader-20261006 and tooling-current-reader-checks-20261006. Final refreshed source copies, measured task bytes, claim inventory and staged doctrines/normal hooks gate commit. Public .5.4.2/.5.4/.5 close; class/frame .6 is next. Original/private/formatter/coordinate/address/native/visual/HIAL/CI/push and collection rollover debt retain owners. Subordinate DBINP timing record recommends executable intent with explicit virtual-time transaction/cycle capabilities without selecting contracts, activating IASIM or pivoting.',
        PARENT + '.5.4.2': 'Semantic retention .1, exact observer publication .2 and complete tooling/core/observer current-route repair .3 are independently qualified and committed per leaf. Whole retained facts/questions, source/current/snapshot/native/result roles and unchanged collection authority conserve. No original recapture, wider semantic identity or healthy-collection claim. Public publication is complete; class/frame .6 and original historical/private/native/visual/HIAL/CI/push gaps remain owned.',
        PARENT + '.5.4': 'Draft construction .1, semantic retention, observer publication and tooling companion repair .2 are complete with authenticated source/native/current queries, genuine controls and independently consumed actual results. Original source facts/questions and seals retain under unchanged collection authority. Public-boundary publication closes; original historical/private/formatter/class/frame/coordinate/address/native and broader qualification limits remain explicit.',
        PARENT + '.5': 'Installed public documentation/profile .1, independent public native controls .2, finite original public boundary join .3 and qualified fact/current reader publication .4 are complete. The dated current public contract supports only the finite authored-name-prefix/CODE-kind/delegate/body/entry/do-load compatibility at retained phases. Original toolchain/provider identity, private eval purposes, formatter/settings, hidden arguments, receiver/callback contents/identity and remaining class/frame/coordinate/address/native meanings are not inferred. Class/frame join .6 is the next eligible leaf.',
    }
    for unit, summary in summaries.items():
        a = s.index('- ID: `' + unit + '`'); b = s.index('\n- ID:', a + 1)
        node = s[a:b]; assert '\n  Status: `active`\n' in node
        node = node.replace('Status: `active`', 'Status: `done`', 1)
        v = node.index('  Verification:'); c = node.index('\n  Commit:', v)
        node = node[:v] + '  Verification: `' + summary + '`' + node[c:]
        node = node.replace('  Commit: `pending`', '  Commit: `this tooling repair closure; resolve by work-unit Git subject`', 1)
        s = s[:a] + node + s[b:]
    s += '''

## Acceptance Checklist — complete tooling current-route repair

- [x] **ROOT CAUSE (WHY + WHERE)** — Actual `git log -1 --format=%H --fixed-strings -S 'whole current source/role/question/reader epoch'` identifies e11d97f0c79c22c240243350a27e000a13bc6243 in root-cause.json. The superseded publication reader's check_live exact core/helper/tooling epoch rejects the admitted observer extension; roles.json retains its actual public --current1 with that exact cause. The first companion control searched absent source tokens and made no intervention; first-preflight.json and first-verify.py.txt retain the failure, and independent-result.json reproduces it before the corrected Canonical Source Views heading intervention qualifies.
- [x] **ADDRESSED (verified)** — Final guarded seal-command.json0 and independent-result.json0 authenticate complete prior publication/actual-result members, conserve every sealed member and regenerate complete source/query/authority/control/native/role products. Exact tooling body/questions and core/observer cards retain; only date/route change. Complete physical metrics, independently source-derived global query conservation, actual direct/cache complete ownership and all source-plane/current/native contracts pass under unchanged collection authority. Nine companion, thirteen observer, three native and nine actual-result typed/member/default-guard/real borrowed-success controls reject. Actual old-current refusal, snapshot0, unrelated current0/restoration, locality0 and observer-current0 are distinct. Saved transitive native prerequisites remain saved, not recaptured; original identity/visual/HIAL/CI/push gaps remain owned.
- [x] **NO REGRESSION** — Guarded focused.json reports `All tests successful` with `Files=4, Tests=361` for live book paths, feature matrix, task integrity and Knowledge Map shards. The scoped current and source-plane checks conserve original routes/bytes/ignore/index budgets; the actual unrelated book intervention passes and exact chapter/registry restoration qualifies. Native build/source refresh, claim inventory and mandatory staged doctrines/normal hooks complete the commit. Original programmes/seals and production/test code remain unchanged.
'''
    TASK.write_text(s)
    index = Path('docs/TASK_TREE.md'); lines = index.read_text().splitlines()
    i = next(i for i, line in enumerate(lines) if line.startswith('| `SEMANTIC-INTROSPECTION-MCP-FRONTIER` |'))
    lines[i] = '| `SEMANTIC-INTROSPECTION-MCP-FRONTIER` | `active` | `R13 / semantic API and MCP` | Push deferred .69.2; HIAL/full CI/push .69.3 open. Parser .4 and public framework/publication .5 complete, including retained facts and repaired tooling current routes under unchanged collection authority. Next class/frame .6; coordinates/addresses and consumer/alias/cold joins retain owners. Daily census .76 done; visual QA remains open. | [task](docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md) |'
    index.write_text('\n'.join(lines) + '\n')
    memory = Path('MEMORY.md'); text = memory.read_text()
    text = text.replace(OWNER + '` (active)', PARENT + '.6` (pending)')
    start = text.index('- next_action:'); end = text.index('\n- in_flight_uncommitted:', start)
    text = text[:start] + '- next_action: Activate class/frame join .6; reexecute complete finite source/API/observer/parser/framework meanings and raw prerequisites, preserving coordinate/address and final-parent successors.' + text[end:]
    text = text.replace('none; tooling companion source/current/result qualification is in progress.', 'none after required final commit gates; class/frame join .6 has not started.')
    memory.write_text(text)
    print('PASS actual-result-gated public parent closure and next class/frame pointer; final commit gates remain.')


if __name__ == '__main__':
    main()
