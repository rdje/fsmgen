"""Reproduce the frozen first-final source membership refusal."""
from join_common import *

if __name__ == '__main__':
    name = str(BASE / 'final.py')
    first = json.loads((BASE / 'formal-programmes-final.json').read_bytes())['programmes'][name]
    body = first['body'].encode()
    need(pin(body) == first['identity'], 'whole frozen first-final qualifier source')
    namespace = {'__name__': 'immutable_first_final_source', '__file__': name}
    exec(compile(body, name, 'exec'), namespace)
    namespace['first_failure']()
    raise ValueError('first-final source membership unexpectedly accepted')
