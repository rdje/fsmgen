"""Complete context source bindings, retained protocol callers and compact relations."""
import copy
import json
import re
from pathlib import Path

SCOPE = ('Complete own parser context source graphs and source-role closure, with original private protocol '
         'and retained context caller bridges. Fresh probes do not measure original native identity, payload or '
         'flags. Provider implementation, framework/global object census, complete source/raw integration, '
         'cold replay and canonical publication remain open.')


class SourceNode:
    def __init__(self, kind, path):
        self.kind, self.path, self.children = kind, path, {}


def decode(encoded):
    nodes = {}
    def walk(value, path):
        if type(value) is not list:
            return value
        kind, body = value
        if kind == 'reference':
            return nodes[body]
        node = SourceNode(kind.upper(), path)
        nodes[path] = node
        for key, child in (body.items() if kind == 'hash' else enumerate(body)):
            escaped = str(key).replace('~', '~0').replace('/', '~1')
            node.children[str(key)] = walk(child, path + '/' + escaped)
        return node
    root = walk(encoded, '')
    return root, nodes


def reachable(roots):
    seen = set()
    def visit(node):
        if not isinstance(node, SourceNode) or node in seen:
            return
        seen.add(node)
        for value in node.children.values():
            visit(value)
    for root in roots:
        visit(root)
    return seen


def derive(inputs):
    boundary = inputs['boundary_inputs']
    public = copy.deepcopy(inputs['boundary_model']['public'])
    root, nodes = decode(public['final']['graph'])
    source_nodes = {path: node for path, node in nodes.items() if path and not (
        re.fullmatch(r'/(?:3|4|5|6|7|8|9)', path) or re.fullmatch(r'/(?:7|8|9)/\d+(?:/arguments)?', path))}
    live = reachable([nodes[path] for path in ('/0', '/1', '/2', '/3/0', '/3/1', '/6/0')])
    modes = []
    for old_mode, protocol in zip(boundary['construction_model']['modes'], inputs['protocols'], strict=True):
        bindings = copy.deepcopy(old_mode['bindings'])
        old_paths = old_mode['cases'][0]['final_graph_bindings']
        graph_keys = {path: old_paths.get(path, 'parse:2:context-node:' + path) for path in source_nodes}
        for path, key in graph_keys.items():
            if key not in bindings:
                bindings[key] = {'reference_kind': source_nodes[path].kind, 'origin': {
                    'kind': 'own_context_checkpoint_node', 'mode': old_mode['mode'], 'parse_index': 2, 'node': path,
                    'scope': 'Fresh complete source graph; original native payload/flags/identity unmeasured.'}}
        callers = []
        for group, rows, holder in (('api', protocol['retained_api_callers'], '@api'),
                                   ('private', protocol['retained_private_callers'], '@copies')):
            for row in rows:
                key = f'parse:2:{group}-caller:{row["index"]}'
                callers.append(key)
                bindings[key] = {'reference_kind': 'ARRAY', 'origin': {'kind': 'retained_context_protocol_caller',
                    'mode': old_mode['mode'], 'parse_index': 2, 'group': group, 'index': row['index'],
                    'caller': row['caller'], 'expression': '[caller]', 'holder': holder}}
        api_bridge = [{'kind': original['kind'], 'original_api': original['index'], 'source_event': i}
            for i, original in enumerate(protocol['all_apis'])]
        copied = root.children['7'].children
        copy_indices = [int(i) for i, row in copied.items() if row.children['module'] in ('Values', 'Metadata')]
        copy_bridge = [{'module': copied[str(i)].children['module'], 'original_copy': old['index'], 'probe_copy': i}
            for old, i in zip(protocol['copies'], copy_indices, strict=True)]
        cases = []
        for old in old_mode['cases']:
            index = old['domain'][2]
            occurrences = copy.deepcopy(old['inherited_occurrences'] + old['occurrences'])
            occurrences += [{key: item[key] for key in ('frame', 'argument', 'role')}
                | {'binding': graph_keys['/3/1']} for item in old['pending']]
            held = sorted(set(old['held']) | set(callers)
                          | ({graph_keys[node.path] for node in live} if index == 2 else set()))
            cases.append({'domain': copy.deepcopy(old['domain']), 'frames': copy.deepcopy(old['frames']),
                'occurrences': occurrences, 'pending': [], 'held': held,
                'construction_bridge': {key: key for key in old['held']},
                'final_graph_bindings': graph_keys if index == 2 else {},
                'original_api_bridge': api_bridge if index == 2 else [],
                'api_witnesses': copy.deepcopy(protocol['all_apis']) if index == 2 else [],
                'original_private_bridge': copy_bridge if index == 2 else [],
                'retained_context_callers': sorted(callers),
                'source_distinctions': {'relation': 'all_unordered_pairs_of_distinct_members',
                    'members': held, 'count': len(held) * (len(held) - 1) // 2},
                'active_roots': ['/0', '/1', '/2', '/3/0', '/3/1', '/6/0'] if index == 2 else [],
                'returned_context_delegates': ['record_context_scope', 'record_actor_scope', 'record_transaction_scope',
                    'record_transaction_samples', 'record_value_scope', 'record_value_reference',
                    'capture_interface_port_metadata', 'snapshot_interface_port_metadata', 'resolve_packed_range',
                    'clone_structured_value', 'resolve'],
                'returned_api_events': {'relation': 'all_successful_context_API_events_before_parser_refusal',
                    'original_apis': [r['index'] for r in protocol['all_apis']]},
                'returned_context_delegate_scope': 'Recorded original APIs and own context constructors/resolver; prior actor/helper/private-call phase contracts conserve. This is not a global call census.',
                'inactive_intermediates': {'contexts': [2], 'scopes': [1, 2, 3, 4, 5, 6], 'samples': [0]}
                    if index == 2 else {'contexts': [0, 1, 2], 'scopes': list(range(8)), 'samples': [0], 'references': [0]},
                'lifetime_scope': 'The sample lexical block has ended before _clauses. Probe-retained intermediate outputs and carriers are not original holders; no object death or global/native object census is asserted.'})
        modes.append({'mode': old_mode['mode'], 'bindings': bindings, 'cases': cases})
    return {'scope': SCOPE, 'preserved_boundary': copy.deepcopy(inputs['boundary_model']),
        'preserved_helper': copy.deepcopy(inputs['helper_model']),
        'public': public, 'modes': modes,
        'closure': {'helper': 'Complete helper/callback/subtest source population conserved and independently qualified.',
            'parser': 'Every original parser core/operation-boundary reference source slot qualified exactly once; no pending context slot.',
            'containers': 'Actor/context, parser and helper/parser source containers qualify; full source integration remains the next owned sibling.',
            'open': 'Original native/provider/formatter/Regexp/CODE/framework/global identity, full source/raw integration, cold replay and canonical publication remain open.'}}
