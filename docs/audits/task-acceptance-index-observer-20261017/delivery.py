"""Retain fixed delivery checks separately from native observation admission."""
from pathlib import Path
import subprocess
import sys
from run import AUDIT, WORK, ROOT, blob, sources, git_state, save

COMMANDS = {
    'cause': ['git', 'log', '-3', '-S', 'setpgid result=', '--format=%H %s', '--', 'perl/FSM/Support/ProcessSupervisor.pm'],
    'admission': ['prove', '-v', '-Iperl', '-It/lib', str(AUDIT / 'qualify.t')],
    'book': ['mdbook', 'build', 'docs/book', '-d', str(WORK / 'book')],
    'map': ['knowledge-map/scripts/check_knowledge_map.sh'],
    'history': ['scripts/check_knowledge_card_history.pl'],
    'staged': ['scripts/check_doctrines.sh'],
}


def main():
    assert Path.cwd().resolve() == ROOT
    assert len(sys.argv) == 2 and sys.argv[1] in COMMANDS
    action = sys.argv[1]
    before, git_before = sources(), git_state()
    own_source = blob(Path(__file__).read_bytes())
    command = ['scripts/run_with_ram_guard.sh', '--', *COMMANDS[action]]
    result = subprocess.run(command, capture_output=True, timeout=300)
    after, git_after = sources(), git_state()
    record = {'command': command, 'status': result.returncode, 'producer': own_source,
              'sources_before': before, 'sources_after': after,
              'source_conserved': before == after, 'git_before': git_before, 'git_after': git_after,
              'revision_and_entries_conserved': all(git_before[k] == git_after[k] for k in ('revision', 'entries')),
              'raw_index_conserved': git_before['index'] == git_after['index'],
              'stdout': blob(result.stdout), 'stderr': blob(result.stderr)}
    save(action + '-delivery.json.gz', record)
    print(action, 'native', result.returncode, 'source conserved', record['source_conserved'],
          'entries conserved', record['revision_and_entries_conserved'],
          'raw index conserved', record['raw_index_conserved'], flush=True)
    assert result.returncode == 0 and record['source_conserved'] and record['revision_and_entries_conserved']
    if action == 'admission':
        assert record['raw_index_conserved']


if __name__ == '__main__':
    main()
