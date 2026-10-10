"""Close only source nodes after full literal contracts and independent recounts."""
import json
import re
from pathlib import Path

BASE = Path('docs/audits/address-source-integration-20261010')
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')


def module(name):
    path = BASE / name
    ns = {'__name__': 'complete_source_parent_acceptance'}
    exec(compile(path.read_bytes(),str(path),'exec'),ns)
    return ns


def main():
    target = BASE/'parent-acceptance.json'
    if target.exists():
        raise ValueError('retain exact first complete parent acceptance')
    source = module('source.py')
    spec = json.loads((BASE/'inputs.json').read_bytes())
    data = source['data'](spec)
    product = json.loads((BASE/'hypotheses.json').read_bytes())
    proof = json.loads((BASE/'proof.json').read_bytes())
    measured = module('oracle.py')['qualify'](product,data,spec)
    if measured != proof['measured']:
        raise ValueError('complete current independent source evidence')
    checks = json.loads((BASE/'checks.json').read_bytes())
    outcome = checks['complete-final-independent']
    if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != 'PASS complete source role/graph/lifetime integration; original raw/native and governed publication remain open.\n':
        raise ValueError('actual complete final source qualification')
    if checks['focused']['status'] != 0 or 'All tests successful.' not in checks['focused']['stdout']:
        raise ValueError('actual focused source/public regression qualification')
    required_controls = {'unknown-native-view-field','unknown-native-binding-field',
        'equal-payload-source-target-graph-merged','borrowed-actual-other-private-copy-domain',
        'borrowed-actual-other-private-result-holder','actual-private-input-result-merged',
        'earlier-observer-callers-omitted','lost-parser-reference-in-own-source-grammar',
        'lost-nested-Metadata-reference','symbolic-checkpoint-carrier-promoted-to-held',
        'failed-capture-reactivated-at-outer-throw','lost-returned-helper-result-holder'}
    if not required_controls <= {r['name'] for r in proof['controls']}:
        raise ValueError('complete source acceptance separating-control axes')
    # Recount from canonical predecessor frames and operation domains, independently
    # of the producer's census and without a new original raw-address intake.
    op = {(r['mode'],r['domain'],r['index']):r for r in data['operation']['hypotheses']['cases']}
    core = {(r['mode'],r['index']):r for r in data['value']['hypotheses']['cases']}
    nested = {(r['mode'],v['record_api'],v['phase']):v for r in data['nested']['hypotheses']['cases'] for v in r['views']}
    parser = {(m['mode'],r['domain'][2]):r for m in data['parser']['hypotheses']['modes'] for r in m['cases']}
    expected_domains = {tuple(boundary['domain'][:4]) for r in op.values() for boundary in r['operations']}
    actual_domains = [tuple(v['domain']) for m in product['modes'] for v in m['views']]
    if len(actual_domains) != len(expected_domains) or set(actual_domains) != expected_domains:
        raise ValueError('every original operation record/phase exactly once')
    refs = 0
    for mode in data['helper']['hypotheses']['modes']:
        for case in mode['cases']:
            for view in case['views']:
                _, domain, index, phase = view['domain']
                if domain == 'parses':
                    frames = parser[mode['mode'],index]['frames']
                elif (mode['mode'],index) in core:
                    frames = core[mode['mode'],index]['frames'][:-1] + op[mode['mode'],domain,index]['operations'][0]['frames']
                else:
                    frames = nested[mode['mode'],index,phase]['frames']
                frames = frames + view['frames']
                refs += sum(a.get('kind') in ('reference','regex_source') or ('kind' not in a and 'reference_kind' in a)
                            for f in frames for a in f['arguments'])
    if refs != measured['reference_operands']:
        raise ValueError('complete own source role census independent parent recount')
    leaf = (BASE/'scope.txt').read_text().strip()
    integration, source_parent = leaf.rsplit('.',1)[0], leaf.rsplit('.',2)[0]
    before = TASK.read_text()
    def nodes(text):
        matches = list(re.finditer(r'^- ID: `([^`]+)`\n',text,re.M))
        return {m[1]:text[m.start():matches[i+1].start() if i+1<len(matches) else len(text)]
                for i,m in enumerate(matches)}
    original, current, contracts = nodes(before), before, []
    for unit in (leaf,integration,source_parent):
        all_nodes = nodes(current)
        block = all_nodes[unit]
        fields = {key:re.search(r'^  '+key+r': `([^`]+)`',block,re.M)[1] for key in ('Status','Goal','Acceptance')}
        if fields['Status'] != 'active':
            raise ValueError('only active verified source parent closes')
        children = re.search(r'^  Children: `([^`]+)`',block,re.M)
        if children and any('  Status: `done`' not in all_nodes[child.strip()] for child in children[1].split(',')):
            raise ValueError('every full source child must be done before parent closure')
        contracts.append({'unit':unit,'goal':fields['Goal'],'acceptance':fields['Acceptance'],
                          'complete_before':source['pin'](original[unit].encode()),
                          'evidence':{'proof':source['pin']((BASE/'proof.json').read_bytes()),
                              'whole_model_registry':spec['models'],'source_domains':len(expected_domains),
                              'independently_recounted_reference_operands':refs,
                              'full_source_scope':product['scope']}})
        block = block.replace('  Status: `active`','  Status: `done`',1)
        block = re.sub(r'^  Verification: `[^`]*`',
            '  Verification: `Complete source integration qualifies in docs/audits/address-source-integration-20261010/proof.json and parent-acceptance.json. Full literal acceptance and every child conserve; independent canonical frame/domain recount and final actual0 qualify every source role, graph alias, private/caller holder, returned-call state and opaque CODE boundary. All54 genuine controls reject, including actual native-field admission repair, borrowed equal-payload/private copies, parser/nested grammar omissions and carrier promotions. Full current book/proposed fact and focused/doctrine/hook gates qualify same-slice commitment. Only source nodes close; raw/native identity and governed publication remain successors.`',block,count=1,flags=re.M)
        block = re.sub(r'^  Commit: `[^`]*`','  Commit: `this slice`',block,count=1,flags=re.M)
        current = current.replace(all_nodes[unit],block,1)
    raw_parent = source_parent.rsplit('.',1)[0]
    if '  Status: `active`' not in nodes(current)[raw_parent] or '  Status: `pending`' not in nodes(current)[raw_parent+'.3']:
        raise ValueError('raw address parent and successor stay open')
    TASK.write_text(current)
    target.write_text(json.dumps({'contracts':contracts,'measured':measured,
        'recount':{'source_domains':len(expected_domains),'reference_operands':refs},
        'before_task':source['pin'](before.encode()),'after_task':source['pin'](current.encode()),
        'raw_parent':raw_parent,'next_raw_child':raw_parent+'.3',
        'scope':'Close exactly the source integration leaf, its integration parent and remaining-source-role parent; preserve every raw/native/publication successor.'},sort_keys=True,indent=2)+'\n')
    print('PASS literal complete source parent acceptance and independent full role/domain recount; raw/native/publication stay open.')


if __name__ == '__main__':
    main()
