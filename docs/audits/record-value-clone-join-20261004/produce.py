"""Retain whole original native/source-tree/joint/referent join records."""
import json
from pathlib import Path
from source_roots import digest, exact, native_graph

BASE = Path('docs/audits/record-value-clone-join-20261004')
old = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
native = json.loads(Path('docs/audits/record-value-structured-clones-20261004/ordinary.json').read_text())
source = json.loads(Path('docs/audits/record-value-clone-tree-20261004/tree-products.json').read_text())['rows']
referents = {row['index']: row for row in json.loads(Path('docs/audits/record-value-clones-20261004/referents.json').read_text())['ordinary']}
rows = []
for model in source:
    index = model['index']
    assert exact(old['api'][index], native_graph.base(native['api'][index]))
    assert exact(model['record'], old['api'][index])
    assert exact(model['joint'], native['api'][index]['joint_input_result'])
    rows.append({'index': index, 'source_index': index, 'native_index': index,
        'legacy_index': index, 'root_index': model['root_index'],
        'source_path': model['source_path'], 'parent_index': model['parent_index'],
        'whole_source_root': model['whole_source_root'],
        'whole_tree_record': digest(model), 'whole_native_record': digest(native['api'][index]),
        'whole_legacy_record': digest(old['api'][index]), 'source_product': model['record'],
        'joint': model['joint'], 'referents': referents[index]})
(BASE / 'join-products.json').write_text(json.dumps({'rows': rows}, sort_keys=True, indent=2) + '\n')
conservation = native_graph.conserved(old, native, True)
assert exact(conservation, json.loads(Path('docs/audits/record-value-clones-20261004/legacy-conservation.json').read_text()))
(BASE / 'native-conservation.json').write_text(json.dumps(conservation, sort_keys=True, indent=2) + '\n')
print('PASS full original native/source-tree/joint/referent join and exact complete native conservation retained without replacing source semantic authority.')
