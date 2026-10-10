"""Select complete source roles and full public header expressions before comparison."""
from common import BASE, CLASS, HEADERS, SCOPE, canonical, inputs, need, pin, read, save


def selected():
    source = read(CLASS / 'source-models.json')
    headers = read(HEADERS / 'headers.json')
    prior = read(CLASS / 'proofs.json')['full_prior_public_join']
    own = {(m['mode'], c['domain'], c['index']):c
           for m in prior['own_join']['contexts'] for c in m['cases']}
    public = {(m['mode'], c['domain'], c['index']):c
              for m in prior['modes'] for c in m['cases']}
    by_path = {tuple(v['source']['path']):key for key,v in headers['operands'].items()}
    allocations = []
    for header in headers['headers']:
        path = header['path']
        mode = source['modes'][path[1]]
        case = mode['cases'][path[3]]
        key = mode['mode'], case['domain'], case['index']
        positions = own[key]['phases'][path[5]]
        branch = path[6:]
        if branch[0] == 'own' and branch[1] in ('core', 'helper', 'body', 'entry'):
            position = positions[branch[1] + '_positions'][branch[2]]
        elif branch[:2] == ['own', 'operations']:
            need(branch[3] == 'frames', 'whole source operation header path')
            position = positions['operations'][branch[2]][branch[4]]
        elif branch[0] == 'public' and branch[1] in ('body', 'entry'):
            position = positions[branch[1] + '_positions'][branch[2]]
        else:
            need(branch[:2] == ['public', 'own_eval_boundaries'], 'closed whole source header role')
            position = positions['operations'][branch[2]][branch[3]]
        allocations.append(dict(header_id=header['id'], source_path=path, record=list(key),
                                phase=path[5], frame_position=position))
    virtual, loads = [], []
    for mi, mode in enumerate(source['modes']):
        for ci, case in enumerate(mode['cases']):
            key = mode['mode'], case['domain'], case['index']
            for pi, phase in enumerate(case['phases']):
                path = ['modes', mi, 'cases', ci, 'phases', pi]
                interface = phase['public']
                need(interface['public_path'] == ['Test::Builder::subtest', 'Test::More::subtest'],
                     'source-qualified complete public path')
                name = by_path[tuple(path + ['public', 'public_name'])]
                callback = by_path[tuple(path + ['public', 'callback'])]
                virtual.append(dict(id=pin(canonical(path + ['public', 'public_path', 0]))['sha256'],
                    source_path=path + ['public', 'public_path', 0], record=list(key), phase=pi,
                    frame_position=public[key]['phases'][pi]['public_positions'][0],
                    function=interface['public_path'][0], complete_argument_ids=[name, callback],
                    receiver_role=interface['receiver'], profile=headers['current_profile'],
                    meaning='Full source/public name and callback-kind expression with a whole opaque receiver parameter; no original private/native receiver meaning.'))
                for branch in ('own', 'public'):
                    loads.append(dict(source_path=path+[branch, 'load'], record=list(key), phase=pi,
                        frame_position=own[key]['phases'][pi]['load_position'],
                        diagnostic_marker=phase[branch]['load'], source_operator='do',
                        diagnostic_marker_is_source_operator=False))
    return dict(scope=SCOPE, source_headers=allocations, public_headers=virtual, loads=loads,
                source_expression=pin((HEADERS/'headers.json').read_bytes()),
                original_unknowns=headers['original_unmeasured'],
                raw_comparison='not performed by this source/role selection',
                inputs={str(p):pin(p.read_bytes()) for p in inputs()})


if __name__ == '__main__':
    need(not (BASE/'joined.json').exists(), 'source role selection before original encoded comparison')
    save('selected.json', selected())
    print('PASS complete source header/public/load hypotheses and alias roles selected before original encoded comparison.')
