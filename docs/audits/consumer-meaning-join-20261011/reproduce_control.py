"""Reproduce the immutable first Storable control-construction failure."""
import copy
import runpy
from join_common import *

if __name__ == '__main__':
    first = json.loads((BASE / 'formal-programmes.json').read_bytes())['programmes']
    name = str(BASE / 'controls.py')
    need(Path(name).read_bytes() == first[name]['body'].encode(), 'whole immutable first control source')
    value = load_product('candidate.json.gz')
    width = value['modes'][1]['consumers'][16]['native']['expected'][1]['storage'][1][0][1]['signals'][1][0][1]['type_spec'][1]['members'][1]['data'][1]['width']
    need(type(width) is str and width == '7', 'independent original Storable test-copy kind diagnosis')
    source = runpy.run_path(name, run_name='immutable_first_control_source')
    source['storable_kind'](copy.deepcopy(value))
    raise ValueError('first control construction unexpectedly accepted')
