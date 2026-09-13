"""Finite admission domain; importing this module performs no fixture operation."""

from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PARENT = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.4'
OWNER = PARENT + '.1'
EXECUTION_OWNER = PARENT + '.2'
EXECUTION_NAME = 'native-proxy-language-coordination-20260913'
OUTPUT = '.artifacts/logs/' + EXECUTION_NAME
STORE_PARENT = '.artifacts/tmp/native-proxy-image-custody/cases'
WAIT_NS = 2_000_000_000
BOUNDS = dict(cases=12, workers=20, probes=4, children=24, concurrent_children=2,
              case_seconds=20, total_seconds=300, term_seconds=2, kill_seconds=2,
              worker_output_bytes=32768, event_bytes=4096, events_per_worker=32,
              journal_bytes=2097152, fixture_nodes=6, fixture_file_bytes=0)


def cases():
    selected = []
    for outcome in ('handoff', 'deadline', 'cancel', 'replace'):
        for holder, waiter in (('perl', 'python'), ('python', 'perl')):
            name = holder + '_holds_' + waiter + '_' + outcome
            selected.append(dict(name=name, kind='pair', holder=holder, waiter=waiter,
                                 outcome=outcome, store=STORE_PARENT + '/fsmgen-Language20260913_' + name))
    for language in ('perl', 'python'):
        for sealed in (True, False):
            name = language + '_exec_' + ('sealed' if sealed else 'omitted_seal')
            selected.append(dict(name=name, kind='inheritance', language=language,
                                 sealed=sealed, store=STORE_PARENT + '/fsmgen-Language20260913_' + name))
    for case in selected:
        case['retired_lock'] = case['store'] + '_retired.lock' if case.get('outcome') == 'replace' else None
    return selected


SCOPE = (
    'Inactive preinitialized empty stores and the current Perl inspect_store transaction. '
    'The Python peer implements only the checked empty-store coordination protocol. '
    'These workers do not publish images, compile, launch a native proxy, query a collector '
    'or use the live canonical store. Cooperative serialization does not establish protection '
    'against arbitrary noncooperating writers. Controlled lock replacement is a rejecting '
    'fault, never a normal repair. Exec probes run before lock acquisition; no worker spawns '
    'while it holds coordination. Worker-local clocks and controller clocks remain separate.'
)
