"""Complete external gate receipts; expected diagnostics remain visible."""
import json
import fcntl
import subprocess
import sys
from pathlib import Path
from common import BASE, canonical, need, pin


if __name__ == '__main__':
    need(len(sys.argv)>=3, 'named check and explicit command')
    name,command=sys.argv[1],sys.argv[2:]
    path=BASE/'checks.json'
    lock_path=Path('.artifacts/raw-stack-prerequisites-20261011/checks.lock')
    lock_path.parent.mkdir(parents=True,exist_ok=True)
    with lock_path.open('a+b') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        saved=json.loads(path.read_bytes()) if path.exists() else {}
        need(name not in saved, 'retain first complete check result')
    programmes={str(p):dict(body=(body:=p.read_bytes()).decode(),identity=pin(body))
                for p in sorted(BASE.glob('*.py'))}
    inputs={path:entry['identity'] for path,entry in programmes.items()}
    inputs.update({arg:pin(Path(arg).read_bytes()) for arg in command if Path(arg).is_file()})
    indirect = [Path(name) for name in (
        'scripts/check_record_value_publication.py',
        'scripts/record_value_observer_fact.py',
        'scripts/record_value_observer_namespace_fact.py',
        't/python/test_record_value_current_publication.py',
        'docs/knowledge/record-value-original-observer-helper-paths.md',
        'docs/book/src/13k-isf-feature-support-matrix.md')]
    inputs.update({str(path):pin(path.read_bytes()) for path in indirect})
    result=subprocess.run(command,capture_output=True,text=True)
    after={path:pin(Path(path).read_bytes()) for path in inputs}
    # Commands may run independently; only this short read/merge/write is
    # serialized. Reload after the child so an older invocation cannot erase
    # a receipt completed while it was running.
    with lock_path.open('a+b') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        saved=json.loads(path.read_bytes()) if path.exists() else {}
        need(name not in saved, 'retain first complete check result')
        saved[name]=dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr,
                         inputs=inputs,inputs_after=after,epoch_conserved=after==inputs,
                         programmes=programmes)
        path.write_bytes(canonical(saved))
    print(name,result.returncode,result.stdout[-1400:],result.stderr[-1800:],flush=True)
    need(after==inputs,'complete direct and declared indirect source epoch conserved')
    need(type(result.returncode) is int and result.returncode==0,'external check success: '+name)
