"""Retain complete same-repository index-probe source and native gate epochs."""
from pathlib import Path
import argparse,hashlib,json,subprocess
BASE=Path('docs/audits/task-acceptance-audit-source-coverage-20261012')
SOURCES=['t/lib/FSM/Test/TaskAcceptanceIndexRuntime.pm','t/2068-task-acceptance-index-runtime.t','t/1669-task-acceptance-fixture-runtime.t','t/lib/FSM/Test/ProcessSupervisor.pm','perl/FSM/Support/ProcessSupervisor.pm','perl/FSM/ProjectDataLocality.pm','scripts/check_task_acceptance.sh','scripts/run_with_ram_guard.sh','doctrine/task_acceptance/change_paths.tsv','doctrine/task_acceptance/evidence_signatures.tsv']
def epoch(command):
 names=set(SOURCES)|{str(p) for p in BASE.glob('*.py')}
 names.update(s for s in command if len(s)<240 and '\n' not in s and Path(s).is_file())
 return {name:dict(body=Path(name).read_text(),bytes=Path(name).stat().st_size,sha256=hashlib.sha256(Path(name).read_bytes()).hexdigest()) for name in sorted(names)}
def save(name,row):
 with (BASE/name).open('x') as out:json.dump(row,out,sort_keys=True,separators=(',',':'));out.write('\n')
if __name__=='__main__':
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('label');parser.add_argument('command',nargs=argparse.REMAINDER);args=parser.parse_args()
 assert args.command and args.label and all(c in 'abcdefghijklmnopqrstuvwxyz0123456789-' for c in args.label)
 folder=Path('.artifacts')/BASE.name/'checks'/args.label;folder.mkdir(parents=True,exist_ok=False)
 command=['scripts/run_with_ram_guard.sh','--',*args.command];before=epoch(args.command)
 started=dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.1',command=command,expected_status=0,programmes=before,stdout_path=str(folder/'stdout.txt'),stderr_path=str(folder/'stderr.txt'))
 save(args.label+'-started.json',started)
 with (folder/'stdout.txt').open('xb') as out,(folder/'stderr.txt').open('xb') as err:r=subprocess.run(command,stdout=out,stderr=err)
 after=epoch(args.command);actual=dict(**started,status=r.returncode,stdout=(folder/'stdout.txt').read_text(),stderr=(folder/'stderr.txt').read_text(),programmes_after=after)
 save(args.label+'-actual.json',actual);print(args.label,'native',r.returncode,flush=True)
 if r.returncode or before!=after:raise SystemExit(1)
