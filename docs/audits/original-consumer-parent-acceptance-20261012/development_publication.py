"""Preflight whole publication, preserved contracts and every physical capacity axis."""
from parent_common import *
import interfaces
import intake
import publish

names = (TASK, BOOK, REGISTRY, 'MEMORY.md', 'docs/TASK_TREE.md')
before = {name: Path(name).read_bytes() for name in names}
need(all(before[name] == body for name, body in intake.overlays().items()), 'whole current unchanged activation before pure publication')
after, measured = publish.transformation(before)
original, final = nodes(before[TASK]), nodes(after[TASK])
need(original.keys() == final.keys(), 'whole preflight canonical task membership')
for name, block in original.items():
    if name in (PLAN['owner'], PLAN['parent']):
        need(all(field(block, key) == field(final[name], key) for key in ('Goal', 'Acceptance', 'Children'))
             and field(final[name], 'Status') == 'done', 'whole original canonical contracts retain')
    else:
        need(block == final[name], 'every unrelated whole task preflight beforeimage retains')
need(all(field(final[PLAN['parent'] + '.' + str(i)], 'Status') == 'done' for i in range(1, 5))
     and field(final[PLAN['next_join']], 'Status') == field(final[PLAN['full_alias']], 'Status') == 'pending', 'only complete original consumer acceptance closes')
rows = list(map(json.loads, after[REGISTRY].splitlines()))
physical = metrics({'MEMORY.md': after['MEMORY.md']})
for row in rows:
    if row.get('surface_id') == 'active_resume':
        for key, value in physical.items():
            if key != 'files':
                need(value * 100 < row['health_targets'][key] * row['milestones']['warning_pct'], 'preflight all resume health axes below warning threshold')
    elif row.get('surface_id') in ('task_evidence', 'shipped_behavior'):
        actual = measured['task_metrics' if row['surface_id'] == 'task_evidence' else 'book_after']
        need(all(row['enforcement_ceilings'][key] is None or value <= row['enforcement_ceilings'][key] for key, value in actual.items()), 'preflight every unchanged task/book ceiling')
for block in re.findall(rb'```(?:bash|sh)\n(.*?)```', before[BOOK], re.S):
    need(after[BOOK].count(block) == before[BOOK].count(block), 'all runnable original book commands conserve')
protected = b'Perl reader checks captured UTF-8 bytes and lossless physical reconstruction;'
need(before[BOOK].count(protected) == after[BOOK].count(protected) == 1, 'exact canonical encoding disposition')
public = interfaces.public()
prior = public['historical']()
canonical_source = public['sources']()
record = public['current_input'](prior, canonical_source)
record['chapter'] = after[BOOK].decode()
public['check'](record, canonical_source, prior, public['authority'](prior))
interfaces.contracts()
snapshots = {}
for i, name in enumerate(names):
    snapshots[name] = {}
    for role, body in (('before', before[name]), ('after', after[name])):
        path = BASE / ('development-publication-' + role + '-' + str(i) + '.gz')
        need(not path.exists(), 'fresh whole development publication snapshot')
        path.write_bytes(gzip.compress(body, mtime=0))
        snapshots[name][role] = dict(snapshot=str(path), identity=pin(body))
save('development-publication.json', dict(owner=PLAN['owner'], snapshots=snapshots, measured=measured,
     resume_metrics=physical, current=pin(canonical(record)), scope='Pure development proposal only; no live metadata/source changes or formal acceptance.'))
need(all(Path(name).read_bytes() == body for name, body in before.items()), 'pure development leaves every live beforeimage unchanged')
print('PASS development-only whole unchanged canonical publication and all task/book/resume physical axes.')
