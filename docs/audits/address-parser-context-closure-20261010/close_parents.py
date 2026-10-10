"""Require complete current source evidence before closing exact source parents."""
import collections
import hashlib
import json
import re
from pathlib import Path

BASE = Path('docs/audits/address-parser-context-closure-20261010')
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def pin(raw):
    return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}


def main():
    proof=json.loads((BASE/'proof.json').read_bytes())
    inputs=json.loads((BASE/'inputs.json').read_bytes())
    checks=json.loads((BASE/'checks.json').read_bytes())
    outcome=checks['final-independent']
    if (type(outcome['status']) is not int or outcome['status']!=0
            or outcome['stdout']!='PASS complete original parser/context and helper source closure; full source integration and original native identity remain open.\n'):
        raise ValueError('complete final original source qualification required')
    for name,value in proof['programmes'].items():
        if pin((BASE/name).read_bytes())!=value:
            raise ValueError('whole final source programme custody')
    first=json.loads((BASE/'first-join-proof.json.txt').read_bytes())
    for name in ('source.py','runtime.py','qualify.py'):
        if pin((BASE/name).read_bytes())!=first['programmes'][name]:
            raise ValueError('first admission dependency still exact')
    measured=proof['measured']
    modes=inputs['boundary_inputs']['construction_model']['modes']
    expected={
        'parser_reference_slots':sum(sum('reference_kind' in a for f in c['frames'] for a in f['arguments'])
                                     for mode in modes for c in mode['cases']),
        'new_context_slots':sum(len(c['pending']) for mode in modes for c in mode['cases']),
        'original_api_bridges':sum(len(p['all_apis']) for p in inputs['protocols']),
        'original_private_bridges':sum(len(p['copies']) for p in inputs['protocols']),
        'retained_context_caller_holders':sum((len(p['retained_api_callers'])+len(p['retained_private_callers']))*len(m['cases'])
                                              for p,m in zip(inputs['protocols'],modes,strict=True))}
    if any(type(measured[k]) is not int or measured[k]!=v for k,v in expected.items()):
        raise ValueError('all original source membership independently recounted')
    for protocol in inputs['protocols']:
        if dict(collections.Counter(r['kind'] for r in protocol['all_apis']))!=measured['api_kinds']:
            raise ValueError('every original mode API population, not a selected subset')
    required={'lost-actual-recursive-clone-returned-delegate','lost-successful-returned-API-event',
              'later-refusal-previous-context-caller-lost','borrowed-existing-sample-context-for-original-slot'}
    if not required<=set(c['name'] for c in proof['controls']):
        raise ValueError('genuine source/phase/holder gap controls required')
    text=TASK.read_text();unit=(BASE/'scope.txt').read_text().strip()
    records={match[1]:match[0] for match in re.findall(r'(- ID: `([^`]+)`\n.*?)(?=\n- ID:|\Z)',text,re.S)}
    closed=[]
    units=[unit]+[unit.rsplit('.',n)[0] for n in range(1,5)]
    rationale={
        units[0]:'Every original context API/private joint and parser reference operand qualifies with complete retained caller/source lifecycle membership.',
        units[1]:'Both representation/probe and original context/source children qualify; complete graph aliases, numeric boundaries, every source slot and original protocol joins conserve.',
        units[2]:'Complete actor/type/interface/clause construction and context/private-root source populations both qualify at each original refusal; receiver and returned-delegate contracts conserve.',
        units[3]:'Entry/normalization and actor/context children cover every original parser reference exactly once, all source ancestors, saved delegates and original caller holders without native payload inference.',
        units[4]:'Complete helper/callback/subtest and parser children qualify together; full remaining source integration remains the next sibling.'}
    for identifier in units:
        node=records[identifier]
        children=re.search(r'^  Children: `([^`]+)`$',node,re.M)
        child_ids=children[1].split(', ') if children else []
        if any('  Status: `done`' not in records[c] for c in child_ids):
            raise ValueError('full child populations must qualify before parent closure: '+identifier)
        if '  Status: `active`' not in node:
            raise ValueError('exact active source owner required')
        goal=re.search(r'^  Goal: `([^`]+)`$',node,re.M)[1]
        acceptance=re.search(r'^  Acceptance: `([^`]+)`$',node,re.M)[1]
        closed.append({'unit':identifier,'goal':goal,'acceptance':acceptance,'children':child_ids,
            'evidence':rationale[identifier], 'whole_proof':pin((BASE/'proof.json').read_bytes()),
            'scope':'Source-only closure; full source/raw integration, native flags/payload/identity, cold replay and canonical publication remain open.'})
        node=node.replace('  Status: `active`','  Status: `done`',1)
        verification='  Verification: `'+rationale[identifier]+' Final-independent actual0 and whole parent acceptance/evidence in docs/audits/address-parser-context-closure-20261010/parent-acceptance.json; first admitted returned-clone omission, full first programmes/products/proof and actual0 retain. Final delegate names derive from verified API kinds, all successful returned events qualify and genuine omission controls reject. Corrected boundary/helper and every original typed protocol conserve. No original native identity, payload/flags, global census or full source integration is claimed.`'
        node=re.sub(r'^  Verification:.*$',lambda _:verification,node,count=1,flags=re.M)
        node=node.replace('  Commit: `pending`','  Commit: `this slice`',1)
        text=text.replace(records[identifier],node,1);records[identifier]=node
    source_parent=units[-1].rsplit('.',1)[0];successor=source_parent+'.5'
    if '  Status: `active`' not in records[source_parent] or '  Status: `pending`' not in records[successor]:
        raise ValueError('full source integration remains the actual next owned sibling')
    result={'owner':unit,'requirements':closed,'independent_original_recount':expected,
            'final_programmes':proof['programmes'],'controls':len(proof['controls']),
            'next_source_parent':source_parent,'next_pending_leaf':successor,
            'scope':'Exact original full parent acceptance retained verbatim and checked against complete source evidence; source integration and every native/publication successor remain open.'}
    target=BASE/'parent-acceptance.json'
    if target.exists(): raise ValueError('retain first whole parent closure audit')
    target.write_text(json.dumps(result,sort_keys=True,indent=2)+'\n');TASK.write_text(text)
    memory=Path('MEMORY.md');m=memory.read_text().replace('`'+unit+'` (active)','`'+source_parent+'` (active)')
    m=re.sub(r'^- next_action:.*$', '- next_action: After the clean context/source closure commit, activate the pending complete source-role integration child. Conserve every operation/private/Value/Metadata/nested/helper/parser model and prove full simultaneous source membership before any raw-address or canonical publication successor.',m,flags=re.M)
    memory.write_text(m)
    print('PASS complete original source recount and verbatim parent acceptance audit; exact source containers close, full integration remains next.')


if __name__=='__main__':
    main()
