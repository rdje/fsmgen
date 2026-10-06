"""Close verified admission only and point at the pending semantic join."""
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-admission-20261006')
CHECKS = Path('docs/audits/class-frame-admission-checks-20261006')
ns = {'__name__': 'finish_admission', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
owner = ns['OWNER']; parent = owner.rsplit('.', 1)[0]; successor = parent + '.2'
for name in ('fresh-replay.json', 'seal-command.json', 'independent-result.json', 'focused.json', 'publication-check.json', 'member-path-result.json'):
    result = ns['load'](CHECKS / name)
    assert type(result['status']) is int and result['status'] == 0
assert 'All tests successful' in ns['load'](CHECKS / 'focused.json')['stdout']
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


verification = 'Whole fixed-Git direct/transitive regular member, explicit completed-owner and immutable raw intake authenticate. Eight actual guarded declared readers pass with exact command/status/streams and invocation-time whole input/source identities; fresh public interfaces/native mutants and retained original/native/checkpoint roles stay distinct. Raw inventory, genuine admission/source/result/native controls and independent actual seal regenerate completely. Nine typed/member/default-guard/real borrowed-result refusals qualify. First sandbox denial2 and flat-census refusal1 retain; original programme reproduces nested-root cause. Real nested same-basename byte insertion proves old-address false-green and repaired full-path refusal with flat manifest bytes preserved. Whole fresh invocation programme retains; all execution definitions equal final source except unused unsealed manifest addressing. Independent book aggregate/four controls preserve every physical fact and collection authority. Guarded focused All tests successful Files4 Tests361 passes. Complete programmes/proofs/actuals are in record-value-class-frame-admission-20261006 and class-frame-admission-checks-20261006. Final source/native refresh, measured task bytes, claim inventory and staged doctrines/normal hooks gate commit. No independent class/frame join, live currency or original recapture claim; .6.2/.6.3 and all original/private/provider/hook/formatter/coordinate/address/native/HIAL/visual/CI/push gaps retain owners.'
text = update_node(text, owner, dict(Status='done', Verification=verification, Commit='this slice; derive exact revision from work-unit Git subject'))
text = update_node(text, parent, dict(Verification='Admission .1 complete: whole committed custody, distinct fresh/retained roles, actual result durability and repaired full-relative member semantics. Independent join .2 and final publication .3 remain pending. Every original raw byte, old seal and historical/private/coordinate/address gap retains; admission alone closes no class/frame semantics.'))
acceptance = (CHECKS / 'acceptance.md.txt').read_text()
assert acceptance.splitlines()[0] not in text
task.write_text(text + '\n\n' + acceptance)
index = Path('docs/TASK_TREE.md'); text = index.read_text()
old = 'Parser .4 and public framework/publication .5 complete, including retained facts and repaired tooling current routes under unchanged collection authority. Next class/frame .6; coordinates/addresses and consumer/alias/cold joins retain owners.'
new = 'Parser .4/public .5 complete. Class/frame admission .6.1 done: complete custody and scoped actual replays; full-relative seal repair qualified. Next independent join .6.2, then publication .6.3; coordinates/addresses and consumer/alias/cold joins retain owners.'
assert text.count(old) == 1; index.write_text(text.replace(old, new))
memory = Path('MEMORY.md'); lines = []
for line in memory.read_text().splitlines():
    if line.startswith('- active_work_unit:'):
        line = '- active_work_unit: `' + successor + '` (pending)'
    elif line.startswith('- next_action:'):
        line = '- next_action: Activate independent class/frame join .6.2 from clean admission commit; derive complete source contract before consuming original observations, then qualify every own body/phase and separating controls.'
    elif line.startswith('- in_flight_background:'):
        line = '- in_flight_background: none; resume independent class/frame join from committed admission.'
    line = line.replace('.5.4 must preserve all unique facts/questions through governed compaction.', '.6.3 must preserve all unique facts/questions through governed compaction.')
    lines.append(line)
memory.write_text('\n'.join(lines) + '\n')
print('PASS verified admission closed; independent class/frame join remains the pending frontier.')
