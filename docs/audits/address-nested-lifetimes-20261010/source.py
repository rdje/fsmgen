"""Complete nested source-pair intake with fresh qualified prerequisites."""
import contextlib
import hashlib
import io
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/address-nested-lifetimes-20261010')
META = Path('docs/audits/address-metadata-core-20261010')
OP = Path('docs/audits/address-source-boundaries-20261010')
PRIVATE = Path('docs/audits/address-private-topology-20261010')
INHERITED = Path('docs/audits/record-value-original-inherited-frames-20261005')
FORWARDING = Path('docs/audits/record-value-original-forwarding-20261005')
REVISION = '24bb56b75f9dbd811d846571965da36fe08bec10'
META_SUCCESS = 'PASS complete Metadata core source bindings, independent encoded-graph traversal and separating controls; numeric and nested Value joins remain open.\n'


def identity(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def module(path):
    namespace = {'__name__': 'nested_lifetime_prerequisite'}
    exec(compile(path.read_bytes(), str(path), 'exec'), namespace)
    return namespace


def load(path):
    return json.loads(path.read_bytes())


def rebuild():
    original_bytes, original_text, reads = Path.read_bytes, Path.read_text, {}
    def retain(path):
        relative = path.resolve().relative_to(Path.cwd())
        if not relative.is_relative_to(BASE):
            reads[str(relative)] = identity(original_bytes(path))
    def read_bytes(path):
        result = original_bytes(path)
        retain(path)
        return result
    def read_text(path, *args, **kwargs):
        result = original_text(path, *args, **kwargs)
        retain(path)
        return result
    try:
        Path.read_bytes, Path.read_text = read_bytes, read_text
        transcript = io.StringIO()
        with contextlib.redirect_stdout(transcript):
            module(META / 'verify.py')['main']()
        if transcript.getvalue() != META_SUCCESS:
            raise ValueError('fresh complete Metadata reader and actual-source prerequisite controls')
        meta_inputs, meta_hypotheses, meta_proof = (load(META / name) for name in
                                                   ('inputs.json', 'hypotheses.json', 'proof.json'))
        for name, pin in meta_proof['programmes'].items():
            if identity((META / name).read_bytes()) != pin:
                raise ValueError('whole completed Metadata qualification programme')
        outcome = load(META / 'checks.json')['complete-independent']
        if type(outcome['status']) is not int or outcome['status'] != 0 or outcome['stdout'] != META_SUCCESS:
            raise ValueError('actual completed Metadata qualification outcome')
        operations, operation_hypotheses = load(OP / 'inputs.json'), load(OP / 'hypotheses.json')
        private = {(row['domain'][0], row['domain'][1]): row for row in load(PRIVATE / 'inputs.json')}
        source = meta_inputs['nested_sources']
        observer, value = source['observer'], source['value']
        contracts = {
            'caller_record': 'push @api, {kind => $kind, caller => $caller, helper => $active_helper,',
            'saved_capture': "my $capture = FSM::Support::ISFInterfacePortMetadata->can('capture_interface_port_metadata');",
            'unchanged_checked_alias': 'my $checked = $spec;',
            'copied_root': '$root = dclone($root);',
            'capture_construct': "capture_interface_port_metadata({inputs => [{name => 'value', type => 'resolved_value',\n            width => $checked->{width}, type_spec => $checked}], outputs => []});",
            'caught_before_new_guard': 'my $error = $@;',
        }
        for key, statement in contracts.items():
            body = observer if key in ('caller_record', 'saved_capture') else value
            if statement not in body:
                raise ValueError('whole nested source alias/retained-holder contract: ' + key)
        forwarding = module(FORWARDING / 'verify.py')
        capture = forwarding['primary']['result_reader']['CAPTURE'] if 'primary' in forwarding else forwarding['nested']['primary']['result_reader']['CAPTURE']
        records = {mode: load(capture / (mode + '.json')) for mode in ('ordinary', 'storable', 'controls')}
        forwarded = forwarding['expected_models'](source, records)
        if forwarded != load(FORWARDING / 'proofs.json')['models']:
            raise ValueError('complete unchanged source catch/forward/new-throw models')
        inherited = module(INHERITED / 'verify.py')['expected_models'](source)
        if inherited != load(INHERITED / 'proofs.json')['models']:
            raise ValueError('complete unchanged inherited Value/operation source paths')
        inherited_by_key = {(mode['mode'], pair['scope_api']): pair
                            for mode in inherited for pair in mode['pairs']}
        forward_by_key = {(mode['mode'], pair['scope_api']): pair
                          for mode in forwarded for pair in mode['pairs']}
        op_by_key = {(row['mode'], row['domain'], row['index']): row for row in operations}
        hyp_by_key = {(row['mode'], row['domain'], row['index']): row
                      for row in operation_hypotheses['cases']}
        meta_by_key = {(row['mode'], row['capture_api']): row for row in meta_hypotheses['cases']}
        cases = []
        for row in meta_inputs['cases']:
            mode, pair = row['mode'], row['pair']
            parent, child = pair['scope_api'], pair['capture_api']
            root = private[mode, pair['private_copy']]
            if root['kind'] != 'value-private' or root['api'] != parent or root['result'] != pair['private_result_model']:
                raise ValueError('whole qualified active Value private root and pair allocation')
            cases.append({'mode': mode, 'metadata_input': row, 'metadata_hypothesis': meta_by_key[mode, child],
                          'value_private': root, 'inherited': inherited_by_key[mode, parent],
                          'forwarding': forward_by_key[mode, parent],
                          'scope_operation_source': op_by_key[mode, 'api', parent],
                          'capture_operation_source': op_by_key[mode, 'api', child],
                          'scope_operation_hypothesis': hyp_by_key[mode, 'api', parent],
                          'capture_operation_hypothesis': hyp_by_key[mode, 'api', child]})
        keys = {(row['mode'], row['metadata_input']['pair']['scope_api']) for row in cases}
        if keys != set(inherited_by_key) or keys != set(forward_by_key):
            raise ValueError('complete nested source-pair and inherited/forwarding membership')
        inputs = {'cases': cases, 'contracts': contracts,
                  'scope': 'Complete finite original nested source pairs, all three source-record/throw views, and exact core/operation/private/forwarding prerequisites. No numeric address operands are interpreted.'}
    finally:
        Path.read_bytes, Path.read_text = original_bytes, original_text
    if any(path.endswith('/raw-product.json') for path in reads):
        raise ValueError('new numeric-address intake prohibited in nested source model')
    for path, pin in reads.items():
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        if identity(raw) != pin or original_bytes(Path(path)) != raw:
            raise ValueError('whole fixed Git nested source input: ' + path)
    return inputs, {'revision': REVISION, 'inputs': dict(sorted(reads.items())),
                    'fresh_Metadata_reader_stdout': transcript.getvalue(),
                    'scope': 'Whole fixed Git nested source and complete fresh Metadata/core/operation/private/source-control qualification; native/provider/formatter identities remain unmeasured.'}


def main():
    inputs, custody = rebuild()
    thaw = module(Path('docs/audits/record-value-original-value-frames-20261005/verify.py'))['primary']['graph']['thaw']
    hypotheses = module(BASE / 'model.py')['derive'](inputs, thaw)
    for name, result in [('inputs.json', inputs), ('binding.json', custody), ('hypotheses.json', hypotheses)]:
        target = BASE / name
        if target.exists():
            raise ValueError('retain first complete nested source product: ' + name)
        target.write_text(json.dumps(result, sort_keys=True, indent=2) + '\n')
    print('PASS complete nested source alias and phase-lifetime hypotheses; numeric and native identities remain open.')


if __name__ == '__main__':
    main()
