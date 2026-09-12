"""Select close addresses from authenticated healthy event/handle evidence."""
from collections import Counter


def select(row):
    operation = row['operation']
    calls = operation['boundary_calls']
    handles = {h['label']: h for h in operation['handles']}
    stack, opened, closed = [], {}, []
    for index, event in enumerate(operation['events']):
        pieces = event.split(':')
        if pieces[0] == 'call':
            ident = int(pieces[1])
            if pieces[2] == 'before':
                assert calls[ident]['parent'] == (stack[-1] if stack else None)
                stack.append(ident)
            else:
                assert pieces[2] == 'after' and stack.pop() == ident
        elif pieces[0] == 'opened':
            label = ':'.join(pieces[1:]); handle = handles[label]
            assert label not in opened
            if handle['kind'] == 'lock':
                assert not stack
                symbol, occurrence, ident = 'NativeProxyImageCoordination::_transaction', 0, None
            else:
                ident = stack[-1]; call = calls[ident]
                symbol, occurrence = call['name'], call['occurrence']
            opened[label] = dict(kind=handle['kind'], symbol=symbol, occurrence=occurrence,
                address=handle['kind'] + '|' + symbol + '#' + str(occurrence),
                baseline_handle=label, baseline_open_call_id=ident,
                baseline_path=handle['path'], baseline_open_event=index)
        elif pieces[0] == 'close' and pieces[-1] == 'before':
            label = ':'.join(pieces[1:-1]); handle = handles[label]
            assert label in opened and label not in [x['baseline_handle'] for x in closed]
            assert operation['events'][index + 1] == 'close:' + label + ':after'
            assert handle['actual_close_ok'] == handle['closed_after_call'] == handle['closed_at_return'] == 1
            assert handle['reported_return'] == 1 and handle['reported_errno'] == 0
            closing_scope = calls[stack[-1]]['name'] if stack else (
                'NativeProxyImageCoordination::_transaction' if handle['kind'] == 'lock'
                else 'NativeProxyObservationRelease::_close_owned')
            closed.append(dict(opened[label], baseline_close_event=index,
                baseline_close_scope=closing_scope, baseline_close_caller=handle['close_caller']))
    assert not stack and set(opened) == set(handles)
    assert len(closed) == len(handles) == len({r['address'] for r in closed})
    return sorted(closed, key=lambda r: r['address'])


def cases(selectors):
    result = [dict(index=0, name='healthy', reports=[], primary=None)]
    for selector in selectors:
        result.append(dict(index=len(result), name='single:' + selector['address'],
            reports=[dict(address=selector['address'], kind=selector['kind'],
                          symbol=selector['symbol'], occurrence=selector['occurrence'], errno='EIO')],
            primary=None))
    return result


def resolve(calls, context, reports):
    """Bind closed portable reports to this prospective input flow."""
    occurrences, directories = Counter(), 0
    available = {}
    for call in calls:
        symbol = call['name']; occurrence = occurrences[symbol]; occurrences[symbol] += 1
        if symbol == 'NativeProxyImageCustody::_source':
            kind, label = 'source', call['opens']
            parent = calls[call['parent']]['name']
            scope = 'NativeProxyObservationRelease::_close_owned' if parent in (
                'NativeProxyObservationRelease::_prepare', 'NativeProxyObservationRelease::_retain_live_sources') else parent
        elif symbol in ('NativeProxyImageCoordination::_names', 'NativeProxyImageCustody::_members'):
            kind, label, scope = 'directory', 'directory:' + str(directories), symbol
            directories += 1
        else:
            continue
        address = kind + '|' + symbol + '#' + str(occurrence)
        available[address] = dict(address=address, kind=kind, symbol=symbol, occurrence=occurrence,
            label=label, path=call['path'], open_call_id=call['id'], close_scope=scope,
            close_caller=scope.rsplit('::', 1)[0])
    symbol = 'NativeProxyImageCoordination::_transaction'; address = 'lock|' + symbol + '#0'
    available[address] = dict(address=address, kind='lock', symbol=symbol, occurrence=0,
        label='lock:0', path=context['acquired']['lock']['path'], open_call_id=None,
        close_scope=symbol, close_caller='NativeProxyImageCoordination')
    result, seen = [], set()
    for report in reports:
        assert set(report) == {'address', 'kind', 'symbol', 'occurrence', 'errno'}
        assert report['errno'] == 'EIO' and type(report['occurrence']) is int and report['occurrence'] >= 0
        address = report['address']; assert address not in seen; seen.add(address)
        bound = available[address]
        assert all(report[k] == bound[k] for k in ('kind', 'symbol', 'occurrence'))
        result.append(bound)
    return result
