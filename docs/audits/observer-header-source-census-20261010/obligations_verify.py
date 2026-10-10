"""Independently retain unchanged parent authority and complete successor ownership."""
import subprocess
from common import BASE, REVISION, load, need, pin, same, save


def block(text, identifier):
    marker = '- ID: `' + identifier + '`'
    need(text.count(marker) == 1, 'unique full task authority')
    start = text.index(marker)
    end = text.find('\n- ID:',start+1)
    return text[start:end if end >= 0 else None]


def field(text, name):
    matches = [line for line in text.splitlines() if line.startswith('  ' + name + ':')]
    need(len(matches) == 1, 'whole unique task field: ' + name)
    return matches[0]


def main():
    owner = (BASE / 'scope.txt').read_text().strip()
    parent = owner.rsplit('.',1)[0]
    contracts, plan, census = load('task-contracts.json'),load('obligation-plan.json'),load('census.json')
    r = subprocess.run(['git','--no-replace-objects','show',REVISION + ':' + contracts['task']],capture_output=True,text=True)
    need(type(r.returncode) is int and r.returncode == 0 and not r.stderr and contracts['revision'] == REVISION,
         'actual whole fixed parent/task authority')
    need(contracts['original_source_header_parent'] == block(r.stdout,parent)
         and contracts['completed_public_display'] == block(r.stdout,parent.rsplit('.',1)[0]+'.1')
         and '\n  Status: `done`\n' in contracts['completed_public_display'], 'unchanged complete fixed prerequisite and parent')
    for name,suffix in [('active_source_census','.1'),('successor_source_values','.2'),('successor_full_headers','.3')]:
        need(contracts[name].startswith('- ID: `' + parent + suffix + '`\n'), 'complete exact owned child')
    need(plan['owner'] == parent + '.2' and plan['following_full_headers'] == parent + '.3'
         and plan['original_parent_acceptance'] == field(contracts['original_source_header_parent'],'Acceptance'),
         'unchanged full parent acceptance and exact successor owners')
    need(set(plan['obligations']) == set(census['obligations']), 'complete exact source-header obligation domain')
    for name, item in plan['obligations'].items():
        need(set(item) == {'action','complete_locations'} and type(item['action']) is str and item['action']
             and same(item['complete_locations'],census['obligations'][name]), 'whole ordered successor source obligation')
    proof = dict(inputs={n:pin((BASE / n).read_bytes()) for n in ('task-contracts.json','obligation-plan.json','census.json')},
        owners=dict(census=owner,source_values=plan['owner'],full_headers=plan['following_full_headers']),
        original_acceptance=plan['original_parent_acceptance'],
        scope='Complete obligations remain owned under unchanged parent acceptance; no exact scalar/header/original native closure is inferred.')
    if (BASE / 'obligations-proof.json').exists():
        need(same(load('obligations-proof.json'),proof), 'whole immutable obligation ownership proof')
    else:
        save('obligations-proof.json',proof)
    print('PASS complete source-header obligations and exact successor ownership under unchanged original parent acceptance.')


if __name__ == '__main__':
    main()
