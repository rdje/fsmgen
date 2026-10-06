"""Close the complete verified finite join and point to pending publication."""
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-join-20261006')
CHECKS = Path('docs/audits/class-frame-join-checks-20261006')
ns = {'__name__': 'finish_class_frame_join', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
owner = ns['OWNER']; parent = owner.rsplit('.', 1)[0]; successor = parent + '.3'
for name in ('source-derivation.json', 'qualified-preparation.json', 'seal-command.json', 'independent-result.json', 'default-replay.json', 'focused-qualified.json', 'publication-check.json', 'native-result.json'):
    result = ns['load'](CHECKS / name)
    assert type(result['status']) is int and result['status'] == 0
assert 'All tests successful' in ns['load'](CHECKS / 'focused-qualified.json')['stdout']
assert ns['same'](ns['load'](BASE / 'manifest.json'), ns['members']())
task = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
text = task.read_text()


def update_node(text, node, fields):
    start = text.index('- ID: `' + node + '`'); end = text.index('\n- ID:', start + 1)
    block = text[start:end]
    for name, value in fields.items():
        prefix = '  ' + name + ':'
        lines = block.splitlines()
        assert sum(line.startswith(prefix) for line in lines) == 1
        block = '\n'.join(prefix + ' `' + value + '`' if line.startswith(prefix) else line for line in lines)
    return text[:start] + block + '\n\n' + text[end:]


verification = 'Whole committed input member/task/completed-owner/source custody and fresh complete admission replay qualify with explicit saved prerequisite/native roles. Actual qualified source associations retained before new original intake; prior whole serialized inner operands remain opaque evidence and the uncaptured initial terminal has no fabricated receipt. Every original raw allocation/body/context conserves; all source-inferred class/family/phase/function/visible argument/operation/helper/body/public/entry/load meanings and complete inner-to-outer operand relations join. Genuine bridge-only class/family/phase/order/argument/population/native-promotion controls preserve predecessor products and pass their full predicates before the new bridge refuses; real opaque inner-body mutation also passes prior own/public meanings but breaks forwarding. First actual preparation1 exposes shared object aliasing; detached associations repair it without serialized contract changes, and independent consumption reproduces the original cause. First native checker/actual legacy1 retain smart-apostrophe mismatch; exact rendered glyph repair qualifies. Initial focused2 names absent guessed test; exact tracked paths rerun unchanged intended suite. Actual seal0 and independent-result0 regenerate all products, conserve every sealed member and reject nine typed/member/default-guard/real borrowed-result controls. Complete programmes/results in record-value-class-frame-join-20261006 and class-frame-join-checks-20261006. Exact guide/book/fact authority and native controls preserve every current fact/question/route and collection limit. Focused All tests successful Files4 Tests361, syntax, final source/native refresh, task bytes, claim inventory and staged doctrines/hooks gate commit. Final current fact publication .6.3 and all original native/private/provider/hook/formatter/coordinate/address/visual/HIAL/CI/push gaps retain owners.'
text = update_node(text, owner, dict(Status='done', Verification=verification, Commit='this slice; derive exact revision from work-unit Git subject'))
text = update_node(text, parent, dict(Verification='Complete prerequisite admission .1 and independent finite class/frame/source/body/phase/argument/operand join .2 verified. Current publication .3 remains pending; parent closure waits its complete proof. Every original raw byte, old seal and historical native/private/formatter/coordinate/address gap retains.'))
acceptance = (CHECKS / 'acceptance.md.txt').read_text()
assert acceptance.splitlines()[0] not in text
task.write_text(text + '\n\n' + acceptance)
index = Path('docs/TASK_TREE.md'); text = index.read_text()
old = 'Class/frame admission .6.1 done: complete custody and scoped actual replays; full-relative seal repair qualified. Next independent join .6.2, then publication .6.3;'
new = 'Class/frame admission .6.1 and independent finite class/frame/body/operand join .6.2 done. Next current publication .6.3;'
assert text.count(old) == 1; index.write_text(text.replace(old, new))
memory = Path('MEMORY.md'); lines = []
for line in memory.read_text().splitlines():
    if line.startswith('- active_work_unit:'):
        line = '- active_work_unit: `' + successor + '` (pending)'
    elif line.startswith('- next_action:'):
        line = '- next_action: Activate class/frame publication .6.3 from the clean independent join commit; authenticate complete new model/result closure, then publish every qualified fact under unchanged Knowledge Map authority with current/native/result controls.'
    elif line.startswith('- in_flight_background:'):
        line = '- in_flight_background: none; resume pending current class/frame publication from committed independent join.'
    lines.append(line)
memory.write_text('\n'.join(lines) + '\n')
print('PASS complete finite class/frame join closed; current fact publication remains the pending frontier.')
