"""Prepare only inert values; never allocate or inspect synthetic fixture paths."""
from __future__ import annotations

import copy

from support import BASE, MODEL, OLD_MODEL, authenticate, digest, document, write
import oracle


def build(selection, seeds):
    contexts, archives, vectors = {}, {}, []
    for profile, seed in sorted(seeds.items()):
        objects = oracle.catalog(seed)
        contexts[profile] = oracle.context(seed, objects)
        directory = seed['observers']['a']['directory']['path']
        archives[profile] = dict(receipts={name: copy.deepcopy(value['archive'])
            for name, value in seed['observers'].items()}, nodes={path: copy.deepcopy(node)
            for path, node in objects.items() if path == directory or path.startswith(directory + '/')})
    for case in selection['cases']:
        seed = seeds[case['profile']]
        objects = oracle.catalog(seed)
        state = OLD_MODEL.initial(seed)
        for length in range(len(case['order']) + 1):
            if length:
                result = OLD_MODEL.transition(seed, state, case['order'][length - 1])
                assert result['returned'], case['name']
            nodes = oracle.physical_projection(seed, state, objects)
            vectors.append(dict(case=case['name'], profile=case['profile'],
                completed=case['order'][:length], archives=sorted(state['archives']),
                expected_sha256=digest(oracle.stable(nodes)), node_count=len(nodes)))
    sources = seeds['same_image']['observers']['a']['acquired']['target_sources']
    return dict(schema='fsmgen.inactive_lifetime_files_data.v1', identity_origin='synthetic_only',
        actual_fixture_operations=0, contexts=contexts, archives=archives, vectors=vectors,
        payloads={key + '_hex': sources[index]['bytes_hex'] for key, index in
            selection['payload_source']['target_sources'].items()},
        different_image_suffix_hex=selection['payload_source']['different_image_suffix_hex'])


def main():
    plan = document(BASE / 'plan.json')
    authenticate(plan, document(BASE / 'prepare-pins.json'))
    value = build(document(BASE / 'selection.json'), document(MODEL / 'prepared.json')['seeds'])
    write(BASE / 'prepared.json', value)
    print('inert lifetime data: contexts=%d prefixes=%d actual_fixture_operations=0' %
          (len(value['contexts']), len(value['vectors'])))


if __name__ == '__main__':
    main()
