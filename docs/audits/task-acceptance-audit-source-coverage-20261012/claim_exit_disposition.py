"""Own the new native-exit book claim without relaxing complete claim review."""
from pathlib import Path
import json

BASE = Path(__file__).parent
REGISTRY = Path('doctrine/claim_verification/dispositions.jsonl')
INVENTORY = Path('doctrine/claim_verification/inventory.jsonl')
CANDIDATE = 'published-a8de5f1e3a283483d3bcf130'

def main():
    before = REGISTRY.read_text()
    rows = list(map(json.loads, before.splitlines()))
    candidates = [r for r in map(json.loads, INVENTORY.read_text().splitlines())
                  if r.get('candidate_id') == CANDIDATE]
    assert len(candidates) == 1
    assert candidates[0]['excerpt'].startswith('exit 1. `fresh_owner`')
    assert all(r.get('candidate_id') != CANDIDATE for r in rows)
    disposition = dict(
        schema_version=1, record_type='disposition', candidate_id=CANDIDATE,
        disposition='derived_gate', owner_path='docs/tasks/CLAIM-VERIFICATION-ADOPTION.md',
        owner_task='CLAIM-VERIFICATION-ADOPTION.5.6',
        rederive=dict(
            producer_paths=['scripts/check_task_acceptance.sh',
                            't/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm',
                            str(BASE / 'focused-index-actual.json')],
            evidence='The sealed existing_source case stages a Perl source without an owner '
                     'in this repository alternate index. The real checker returns exit 1 '
                     'with its missing-owner diagnostic; the envelope retains that native '
                     'result separately from checker_returned fixture completion.'),
        falsify=dict(
            oracle_paths=['t/2068-task-acceptance-index-runtime.t'],
            competing_hypothesis='The fixture always fails, or fixture completion promotes '
                                 'the checker failure to success.',
            evidence='T2068 independently requires existing_source exit 1 and !ok, fresh '
                     'checked evidence exit 0, unchecked/stale evidence exit 1 and the '
                     'documentation-only exemption when no registry delta is staged. '
                     'The hostile caller environment still reaches the specific native '
                     'ownership refusal, with unchanged main index and settled cleanup.'),
        durability=dict(
            producer_paths=['t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm',
                            str(BASE / 'focused-index-actual.json'),
                            'docs/tasks/TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.md'],
            watcher_paths=['t/2068-task-acceptance-index-runtime.t', 'scripts/check_doctrines.sh'],
            evidence='Retain complete captured adapter/test/checker/registry sources and '
                     'native Git/checker commands, statuses and streams. The standing '
                     'verification_architecture group owns this disposition; implementation '
                     'belongs to TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.1. The first '
                     'staged gate native1 for missing review remains failed, separately '
                     'from the pre-existing shared-owner native1 and open audit scope.'))
    after = '\n'.join(json.dumps(row, sort_keys=True, separators=(',', ':'))
                      for row in [rows[0], *sorted([*rows[1:], disposition],
                                                   key=lambda r: r['candidate_id'])]) + '\n'
    evidence = dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.1',
                    first_native='staged-actual.json', first_status=1, expected_status=0,
                    before=before, after=after, candidate=candidates[0],
                    condition='Post-invocation repair review, not a measured first '
                              'complete doctrine-input before-image. Native first streams '
                              'retain; unchanged complete-group review remains required.')
    with (BASE / 'claim-exit-repair.json').open('x') as stream:
        json.dump(evidence, stream, sort_keys=True, separators=(',', ':'))
        stream.write('\n')
    REGISTRY.write_text(after)
    print('Added bounded native-exit disposition; first staged failure retained.')

if __name__ == '__main__':
    main()
