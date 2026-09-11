"""Finite effect/cleanup transition model; supplied events are not OS evidence."""
from __future__ import annotations


def evaluate(case):
    """Interpret one declared interruption trace without touching the filesystem.

    An absence observation is historical, not inferred from a return status.
    A close report is distinct from the actual descriptor state recorded by a
    later concrete tracer. The model assumes every scheduled actual close runs.
    """
    effect = dict(unlink_attempted=0, unlink_completed=0, reference_absence_verified=0, last_reference_check=None)
    named = case['initial_name']
    error = ''
    events = []
    for event in case['events']:
        events.append(event)
        kind = event['kind']
        if kind == 'unlink_attempt': effect['unlink_attempted'] = 1
        elif kind == 'unlink_complete':
            assert effect['unlink_attempted'] == 1 and named == 'original'
            effect['unlink_completed'] = 1; named = 'absent'
        elif kind == 'replacement_appears':
            assert effect['unlink_completed'] == 1 and named == 'absent'
            named = 'replacement'
        elif kind == 'absence_begin':
            assert effect['unlink_completed'] == 1
            effect['last_reference_check'] = dict(phase=event['phase'], state='unknown')
        elif kind == 'absence_result':
            check = effect['last_reference_check']; assert check['state'] == 'unknown'
            assert event['state'] == ('absent' if named == 'absent' else 'present')
            check['state'] = event['state']
            if event['state'] == 'absent': effect['reference_absence_verified'] = 1
        elif kind == 'error':
            assert not error; error = event['error']; break
        else: raise AssertionError('unknown effect event')
    closes = []
    for owner in case['owned_closures']:
        report_error = 'close:' + owner if owner in case['close_errors'] else ''
        closes.append(dict(owner=owner, actual_close=True, reported_error=report_error))
        if not error and report_error: error = report_error
    success = not error
    assert not success or effect['last_reference_check'] == dict(phase='finish', state='absent')
    return dict(success=success, error=error, effects=effect, current_name=named, closes=closes,
                successful_receipt=success, runtime_authorized=False, events_consumed=len(events))
