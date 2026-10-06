"""Close verified publication admission and retain the pending retention frontier."""
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-admission-20261006')
CHECKS = Path('docs/audits/class-frame-publication-admission-checks-20261006')
ns = {'__name__': 'finish_publication_admission', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
owner = ns['OWNER']; successor = owner.rsplit('.',1)[0] + '.2'
for name in ('preparation.json','fresh-replay.json','seal-command.json','independent-result.json','default-replay.json','focused.json','publication-check.json','native-result.json'):
    result = ns['load'](CHECKS / name)
    assert type(result['status']) is int and result['status'] == 0
assert 'All tests successful' in ns['load'](CHECKS / 'focused.json')['stdout']
assert ns['same'](ns['load'](BASE / 'manifest.json'), ns['members']())
task = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
text = task.read_text()
start = text.index('- ID: `' + owner + '`'); end = text.index('\n- ID:',start+1)
block = text[start:end]
verification = 'Whole committed join/model/actual-result/transitive member and completed-owner custody authenticates at017a8f70. Complete source and raw objects reconstruct and compare whole values to the committed corpora; full class/frame/body/phase/operand join and genuine separating controls regenerate. Fresh semantic, independent actual-result and current-tooling reader executions pass with full commands/status/streams/invocation source/input pins and explicit retained original/native roles. Complete original canonical fact bodies/questions/identities/routes, physical/logical membership and global allocation conserve under unchanged collection/source budgets. Genuine member/owner/typed/scope/question/authority and real borrowed current-only success controls refuse. Actual seal0 and independent-result0 reconstruct every product, conserve every sealed member and reject typed status/counts, lost members, widened guard and real borrowed join/preparation/current-only results. Independent whole guide aggregate and native controls preserve every physical fact and collection authority. Guarded focused All tests successful Files4 Tests361 and programme parsing pass. Complete programmes/results retain in record-value-class-frame-publication-admission-20261006 and class-frame-publication-admission-checks-20261006. Final source/native refresh, measured task bytes, claim inventory/dispositions and staged doctrines/hooks gate commit. Only admission closes; semantic retention .6.3.2 and atomic current publication .6.3.3 plus all original/native/private/formatter/identity/coordinate/address/visual/HIAL/CI/push gaps retain owners. IASIM DBINP discussion is already durable, with no pivot.'
for key,value in dict(Status='done',Verification=verification,Commit='this slice; derive exact revision from work-unit Git subject').items():
    prefix = '  ' + key + ':'
    lines = block.splitlines(); assert sum(line.startswith(prefix) for line in lines) == 1
    block = '\n'.join(prefix + ' `' + value + '`' if line.startswith(prefix) else line for line in lines)
text = text[:start] + block + '\n\n' + text[end:]
acceptance = (CHECKS / 'acceptance.md.txt').read_text(); assert acceptance.splitlines()[0] not in text
task.write_text(text + '\n\n' + acceptance)
index = Path('docs/TASK_TREE.md'); text = index.read_text()
old = 'Current publication .6.3 active: admit complete join/results .6.3.1, retain every meaning .2, then atomic current/source/native publication .3;'
new = 'Current publication .6.3 active: whole join/result admission .6.3.1 done; next retain every meaning .2, then atomic current/source/native publication .3;'
assert text.count(old) == 1; index.write_text(text.replace(old,new))
memory = Path('MEMORY.md'); lines = []
for line in memory.read_text().splitlines():
    if line.startswith('- active_work_unit:'):
        line = '- active_work_unit: `' + successor + '` (pending)'
    elif line.startswith('- next_action:'):
        line = '- next_action: Activate semantic retention .6.3.2 from the clean admission commit; model every prior core/observer/tooling proposition, qualifier and question, bind complete qualified class/frame additions, and prove non-growing retention under unchanged collection authority before atomic publication.'
    elif line.startswith('- in_flight_background:'):
        line = '- in_flight_background: none; resume pending semantic retention from committed complete publication admission.'
    lines.append(line)
memory.write_text('\n'.join(lines) + '\n')
print('PASS complete publication admission closed; semantic retention remains the pending frontier.')
