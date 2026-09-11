"""Pure selected-call effect interpreter; it performs no fixture I/O."""
from collections import Counter, defaultdict
import copy

RELEASE = 'NativeProxyObservationRelease'
SOURCE = 'NativeProxyImageCustody::_source'


def address(symbol, occurrence, phase): return symbol + '#' + str(occurrence) + ':' + phase


def vector(calls, sealed):
    children = defaultdict(list); ordinals = Counter(); occurrences = {}
    for call in calls:
        children[call['parent']].append(call['id'])
        occurrences[call['id']] = ordinals[call['name']]; ordinals[call['name']] += 1
    state = dict(unlink_attempted=0, unlink_completed=0, reference_absence_verified=0, last_reference_check=None)
    result = []

    def event(call, phase):
        if phase == 'after' and (call['name'] in sealed or call['name'] == SOURCE): return
        result.append(dict(address=address(call['name'], occurrences[call['id']], phase), effects=copy.deepcopy(state)))

    def visit(ident):
        call = calls[ident]; event(call, 'before')
        if call['name'] == RELEASE + '::_assert_absent':
            state['last_reference_check'] = dict(phase=call['phase'], state='unknown')
        for child in children[ident]: visit(child)
        if call['name'] == RELEASE + '::_unlink_exact':
            state.update(unlink_attempted=1, unlink_completed=1)
        if call['name'] == RELEASE + '::_assert_absent':
            state.update(reference_absence_verified=1, last_reference_check=dict(phase=call['phase'], state='absent'))
        event(call, 'after')

    for root in children[None]: visit(root)
    return sorted(result, key=lambda row: row['address'])


def order_skeleton(context, before, order):
    """Permute loop input roles only; these are not codec-valid filesystem cases.

    Synthetic sorted names preserve each record's original image association.
    Only the selected-hold path needed by the call-flow algorithm is rebased.
    No synthetic path is opened, hashed into a valid reference, or admitted.
    """
    context = copy.deepcopy(context); before = copy.deepcopy(before)
    references = sorted((path, node) for path, node in before['store'].items() if path.startswith('references/'))
    assert sorted(order) == list(range(len(references)))
    store = context['store']['path']
    hold = context['acquired']['observation_reference']['source']['identity']
    original = hold['path']
    for path, _ in references: del before['store'][path]
    for position, index in enumerate(order):
        path, node = references[index]; renamed = 'references/' + format(position, '064x') + '.json'
        before['store'][renamed] = node
        if store + '/' + path == original: hold['path'] = store + '/' + renamed
    assert hold['path'] != original
    return context, before
