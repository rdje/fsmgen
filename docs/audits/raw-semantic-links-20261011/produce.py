"""Propose explicit semantic edges from the complete inherited candidate only."""
from common import *


def propose(candidate):
    rows = []
    allocation = []
    for mode in candidate['modes']:
        allocation.append(dict(mode=mode['mode'], domains={name: dict(
            population=domain['population'], empty=domain['empty_string_members'],
            nonempty=[row['record'][2] for row in domain['records']])
            for name, domain in mode['domains'].items()}))
        for domain in mode['domains'].values():
            for record in domain['records']:
                raw = record['original']
                frames = [s for s in raw['segments'] if s['kind'] == 'frame']
                phases = []
                for phase in record['phases']:
                    source = phase['source_class_frame']
                    headers = []
                    for header in phase['source_headers']:
                        a, h = header['allocation'], header['source_header']
                        identifiers = h['source_argument_ids']
                        headers.append(dict(source_path=a['source_path'], frame_index=a['frame_position'],
                            function=h['expression']['function'], whole_frame=pin(canonical(header['original_frame'])),
                            whole_header=pin(canonical(header)), argument_ids=identifiers,
                            arguments=[phase['source_arguments'][key] for key in identifiers]))
                    numbers = phase['numbers']
                    phases.append(dict(domain=phase['domain'],
                        classification={key: source[key] for key in ('phase', 'family', 'guard_source', 'inferred_class', 'native_class')},
                        headers=headers, public_headers=phase['public_headers'], loads=phase['loads'],
                        callers=phase['coordinate']['callers_inner_to_outer'],
                        coordinate_boundary={key: value for key, value in phase['coordinate'].items() if key != 'callers_inner_to_outer'},
                        address=dict(numbers=numbers, whole_source=pin(canonical(phase['source_address'])),
                            whole_holders=pin(canonical(phase['holders'])), whole_parsed=pin(canonical(phase['parsed_address']))),
                        opaque=phase['qualified_class_frame']['complete_own_positions']['opaque_framework']))
                rows.append(dict(record=record['record'],
                    stack=dict(body=raw['body_identity'], segments=[pin(canonical(s)) for s in raw['segments']],
                               frames=[pin(canonical(f)) for f in frames]),
                    first_cause=record['source_case']['exception'], context=raw['context'],
                    observer=record['observer_coordinate'], phases=phases,
                    opaque=dict(allocation=record['opaque_allocation'], lexemes=raw['opaque_lexemes'],
                                qualified_frames=record['qualified_case']['opaque_frames']),
                    forwarding=record['forwarding']))
    return dict(scope=SCOPE, allocation=allocation, original_unknowns=candidate['original_unknowns'],
                inherited_scopes=candidate['inherited_scopes'], records=rows)


if __name__ == '__main__':
    candidate = inherited()
    candidate['semantic_links'] = propose(candidate)
    save_product('candidate.json.gz', candidate)
    print('PASS complete proposed links saved with every inherited candidate component; independent qualification still required.')
