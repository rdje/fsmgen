"""Complete fixed source roles; qualified models remain shared assumptions."""
from consumer_common import *
import intake

TEST = 't/1986-isf-record-port-value-gates.t'
CONTEXT = 'docs/audits/record-value-original-contexts-20261005'
PRIMARY = 'docs/audits/record-value-original-primary-20261005'
CAPTURE = 'docs/audits/record-value-original-candidate-20261004'
PRODUCTS = 'docs/audits/record-value-products-20261004'
MODES = ('ordinary', 'storable', 'controls')
MODEL_PATHS = (
    TEST, CAPTURE + '/observe.pl', CAPTURE + '/candidate.pl', CAPTURE + '/binding.json',
    CONTEXT + '/source_catalog.py', CONTEXT + '/source-context-catalog.json',
    CONTEXT + '/proofs.json', PRIMARY + '/cause_model.py', PRIMARY + '/proofs.json',
    'docs/audits/record-value-fields-20261004/authored-models.json',
    'docs/audits/record-value-actors-20261004/actor-models.json',
    PRODUCTS + '/products.json', PLAN['association'] + '/association.json',
    PLAN['publication'] + '/proof.json',
    *(CAPTURE + '/' + mode + '.json' for mode in MODES),
)


def module(name):
    namespace = {'__name__': 'qualified_consumer_source_input', '__file__': name}
    exec(compile(Path(name).read_bytes(), name, 'exec'), namespace)
    return namespace


def inputs():
    roles = json.loads((BASE / 'source-roles.json').read_bytes())
    members = roles['publication']['members']
    bodies = fixed(MODEL_PATHS)
    for name, body in bodies.items():
        need(name in members and pin(body) == {key: members[name][key] for key in ('bytes', 'sha256')}
             and body == Path(name).read_bytes(), 'whole declared fixed original consumer input')
    source = bodies[TEST].decode()
    binding = json.loads(bodies[CAPTURE + '/binding.json'])
    need(binding['sources'][TEST]['body'] == source, 'complete original/current authored assertion source')
    context = module(CONTEXT + '/verify.py')
    actual_source, helpers, consumers, products = context['source_models']()
    need(source == actual_source, 'whole qualified context and current test source')
    return dict(source=source, helpers=helpers, consumers=consumers,
        identities={name: pin(body) for name, body in bodies.items()},
        source_roles=pin(canonical(roles)),
        native={mode: json.loads(bodies[CAPTURE + '/' + mode + '.json'])['consumers'] for mode in MODES},
        boundary=PLAN['condition'])


def contracts():
    before = nodes(fixed([TASK])[TASK])
    active = nodes(intake.overlays()[TASK])
    parent, owner = PLAN['parent'], PLAN['owner']
    added = {parent + '.' + str(index) for index in range(1, 5)}
    need(set(active) == set(before) | added, 'exact safe consumer decomposition task domain')
    need(field(before[parent], 'Status') == 'pending' and field(active[parent], 'Status') == 'active'
         and field(active[parent], 'Children') == ', '.join(sorted(added)), 'exact original consumer activation and decomposition')
    need(all(field(before[parent], key) == field(active[parent], key) for key in ('Goal', 'Acceptance')),
         'whole unchanged original consumer Goal and Acceptance')
    for name, body in before.items():
        if name != parent:
            need(body == active[name], 'every unrelated original task block retains')
    need(all(field(active[name], 'Status') == ('active' if name == owner else 'pending')
             and field(active[name], 'Commit') == 'pending' for name in added),
         'only consumer source-contract child activates')
    return dict(parent={key: field(before[parent], key) for key in ('Goal', 'Acceptance')},
        whole_parent=active[parent].decode(), children={name: active[name].decode() for name in sorted(added)},
        condition='Original complete consumer contract retains. This source-contract leaf cannot close operands/truth, canonical publication or parent acceptance.')


def role(context):
    """Declare the source roles required by each finite assertion family."""
    label, kind = context['label'], context['kind']
    if context['helper'] is not None:
        return 'helper_eval_negation' if kind == 'ok' else 'helper_first_diagnostic_and_authored_pattern'
    if label.endswith('retains original typed JSON'):
        return 'canonical_json_before_after_readonly_source_values'
    if 'full trace contains' in label:
        return 'whole_synthetic_carp_operand_with_opaque_native_coordinates'
    if label in ('oracle selects the actual message', 'the same false cause cannot satisfy the diagnostic oracle'):
        return 'authored_synthetic_first_line'
    if label == 'prepared scope does not share parser types':
        return 'authored_whole_actor_and_detached_source_copy'
    if 'expected equal packed width' in label or label in ('independent nested packed width', 'independent flattened packed width'):
        return 'authored_resolved_type_width'
    if 'payload compatibility contract' in label:
        return 'own_payload_api_result_and_authored_resolved_types'
    if kind == 'is_deeply':
        return 'own_reference_api_whole_typed_graph_and_literal_layout'
    return 'own_value_api_result_or_exact_selected_scalar'


def candidate_header(data):
    return dict(schema_version=1, owner=PLAN['owner'], revision=PLAN['revision'],
        inputs=data['identities'], source_roles=data['source_roles'], contracts=contracts(),
        boundary=data['boundary'],
        native={mode: pin(canonical(rows)) for mode, rows in data['native'].items()},
        typed_policy='Preserve original scalar JSON kinds and whole graph/reference structure. Assertions may compare scalar string values; this source-contract slice derives no outcome from native passed flags.',
        opaque_policy='The artificial Carp operand is a complete retained native input, not evidence of a genuine provider cause. Native coordinates, hidden identities and provider/settings/flags remain under their original limits.')
