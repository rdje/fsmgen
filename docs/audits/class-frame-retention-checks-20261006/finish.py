"""Close complete verified retention and preserve the pending atomic frontier."""
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-retention-20261006')
CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
ns = {'__name__':'finish_complete_retention','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
owner = ns['OWNER']; successor = owner.rsplit('.',1)[0] + '.3'
for name in ('semantic-preparation.json','fresh-replay.json','seal-command.json','independent-result.json','live-unchanged-result.json','focused.json','publication-check.json','native-result.json'):
    actual = ns['load'](CHECKS / name)
    assert type(actual['status']) is int and actual['status'] == 0
assert 'All tests successful' in ns['load'](CHECKS / 'focused.json')['stdout']
assert ns['same'](ns['load'](BASE / 'manifest.json'),ns['members']())
task = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'); text = task.read_text()
start = text.index('- ID: `' + owner + '`'); end = text.index('\n- ID:',start+1); block = text[start:end]
verification = 'Complete original core/observer/tooling sentence/clause propositions, qualifiers, exact code literals, metadata, ordered questions and replay obligations retain in the reviewed proposal. Target-only source revisions conserve every original source unit and producer operation; prose equivalence is explicit engineer judgment, not unrestricted mechanical proof. First actual budget1 adds bytes/LF and second1 retains LF growth; both whole original producers/proposals/maps/actuals reconstruct independently. Complete final proposal reduces whole bytes/LF under unchanged full capacity authority and global question allocation. All physical/logical members and complete admitted source-class/frame/body/phase/operand products conserve; genuine proposition/qualifier/question/source/member/owner/kind/scope/authority and inherited separating class/body controls qualify. Fresh complete admission passes before source mutation, with original native captures/results retained. First native1 independently reproduces sole smart double-hyphen rendering mismatch; complete first guide/render/publication/results retain before exact inline-code repair. Corrected independent book aggregate/native guide controls qualify. Actual seal0 and independent-result0 regenerate all products, conserve every sealed byte and reject typed/member/guard/real borrowed admission/constructor/budget successes. Live-unchanged default replay confirms all old physical/logical source facts and collection authority; no current card or reader-route mutation occurs. Guarded focused All tests successful Files4 Tests361 and complete programme parsing qualify. Complete programmes/proofs/actuals retain in record-value-class-frame-retention-20261006 and class-frame-retention-checks-20261006. Final source/native refresh, measured task bytes, claim inventory and staged doctrines/hooks gate commit. Only retention closes; atomic publication .6.3.3 and every original/native/private/formatter/identity/coordinate/address/visual/HIAL/CI/push successor retain owners. IASIM DBINP timing clarification is already durable; no pivot or activation.'
for key,value in dict(Status='done',Verification=verification,Commit='this slice; derive exact revision from work-unit Git subject').items():
    prefix = '  ' + key + ':'; lines = block.splitlines(); assert sum(line.startswith(prefix) for line in lines) == 1
    block = '\n'.join(prefix + ' `' + value + '`' if line.startswith(prefix) else line for line in lines)
text = text[:start] + block + '\n\n' + text[end:]
acceptance = (CHECKS / 'acceptance.md.txt').read_text(); assert acceptance.splitlines()[0] not in text
task.write_text(text + '\n\n' + acceptance)
index = Path('docs/TASK_TREE.md'); text = index.read_text()
old = 'Current publication .6.3 active: whole join/result admission .6.3.1 done; next retain every meaning .2, then atomic current/source/native publication .3;'
new = 'Current publication .6.3 active: whole join/result admission .6.3.1 and complete semantic retention .2 done; next atomic current/source/native publication .3;'
assert text.count(old) == 1; index.write_text(text.replace(old,new))
memory = Path('MEMORY.md'); lines = []
for line in memory.read_text().splitlines():
    if line.startswith('- active_work_unit:'):
        line = '- active_work_unit: `' + successor + '` (pending)'
    elif line.startswith('- next_action:'):
        line = '- next_action: Activate atomic current publication .6.3.3 from the clean retention commit; authenticate complete admission/retention roots, publish every retained/additional qualified fact and all affected reader routes together under unchanged collection authority, then qualify current/native/snapshot roles.'
    elif line.startswith('- in_flight_background:'):
        line = '- in_flight_background: none; resume pending atomic current publication from committed complete semantic retention.'
    lines.append(line)
memory.write_text('\n'.join(lines) + '\n')
print('PASS complete verified semantic retention closed; atomic current publication remains the pending frontier.')
