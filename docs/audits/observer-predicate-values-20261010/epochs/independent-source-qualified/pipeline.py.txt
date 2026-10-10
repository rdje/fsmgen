"""Save each complete program epoch and actual result, including first failures."""
import subprocess
import sys
from common import BASE, canonical, need, pin


def main():
    name,*command=sys.argv[1:]
    need(name.replace('-','').isalnum() and command,'named actual command')
    destination=BASE/('actual-'+name+'.json'); epoch=BASE/'epochs'/name
    need(not destination.exists() and not epoch.exists(),'retain first complete actual epoch')
    epoch.mkdir(parents=True)
    sources={}
    for path in sorted(list(BASE.glob('*.py'))+list(BASE.glob('*.pl'))+[BASE/'public-contracts.json']):
        raw=path.read_bytes(); (epoch/(path.name+'.txt')).write_bytes(raw); sources[str(path)]=pin(raw)
    result=subprocess.run(command,capture_output=True,text=True)
    destination.write_bytes(canonical(dict(command=command,programs=sources,status=result.returncode,stdout=result.stdout,stderr=result.stderr)))
    print(name,result.returncode,result.stdout[-1800:],result.stderr[-1800:])
    raise SystemExit(result.returncode)


if __name__ == '__main__': main()
