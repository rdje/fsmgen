"""Copy and qualify every fresh finite-probe fixture member for committed recovery."""
import ast
import hashlib
import json
from pathlib import Path

CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
# Retention needs only custody utilities and the finite reader, not the full
# transitive semantic namespace already executed by the role checks.
utility = Path('docs/audits/record-value-class-frame-admission-20261006/verify.py')
names = {'require','same','identity','load','module'}
functions = [n for n in ast.parse(utility.read_bytes()).body if isinstance(n,ast.FunctionDef) and n.name in names]
assert {n.name for n in functions} == names
exec(compile(ast.Module(body=functions,type_ignores=[]),str(utility),'exec'),globals())
ns = dict(require=require,same=same,identity=identity,load=load,module=module)
DESTINATION = CHECKS / 'fresh-finite-probe'
PROOF = CHECKS / 'fresh-probe-retention.json'
PREFIX = 'PASS fresh exact-source seven-mode native replay and independent complete graph/cause/TAP controls: '


def derive(record):
    rows = load(CHECKS / 'roles.json')['records']; actual = next(r for r in rows if r['name'] == 'core-obligation-3')
    require(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'].startswith(PREFIX)
        and actual['stdout'].endswith('\n'),'actual complete fresh finite replay success before retention')
    path = Path(actual['stdout'][len(PREFIX):].strip())
    require(not path.is_absolute() and '..' not in path.parts and path.is_relative_to(Path('.artifacts/record-value-copy-reader-20261004')),'contained same-volume original finite fixture recipe')
    require(record['receipt'] == str(path) and record['fixture'] == str(path.parent) and record['destination'] == str(DESTINATION), 'whole original/copy fixture and actual receipt roles')
    require(record['role'] == 'Complete fresh finite probe fixture retained byte-for-byte; original native/raw captures unchanged and not recaptured.', 'explicit finite native retention scope')
    require(record['actual'] == identity(json.dumps(actual,sort_keys=True).encode()),'whole original finite replay actual process association')
    members = {str(p.relative_to(DESTINATION)):identity(p.read_bytes()) for p in DESTINATION.rglob('*') if p.is_file()}
    require(members and all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in record['members'].values())
        and same(record['members'],members),'whole complete discrete finite fixture member conservation')
    require(all(not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in DESTINATION.rglob('*')),'same-volume regular retained finite fixture')
    reader = ns['module'](Path('docs/audits/record-value-copy-reader-20261004/verify.py')); reader['authenticate']()
    observed = load(DESTINATION / path.name)
    require(observed['qualification'] == 'PASS' and observed['fixture'] == str(path.parent),'exact retained actual finite native qualification and source root')
    fresh = reader['check_population'](DESTINATION / reader['CAPTURE'],str(path.parent))
    require(same(fresh,observed['records']),'all actual native fixture outputs equal full retained replay records')
    reader['check_replay'](observed,reader['check_population'](reader['CAPTURE'],'.'))
    for name in ('probe.pl','candidate.pl'):
        require((DESTINATION / reader['CAPTURE'] / name).read_bytes() == (reader['CAPTURE'] / name).read_bytes(),'exact whole retained finite native programme: ' + name)
    return members


def main():
    require(not PROOF.exists() and not DESTINATION.exists(),'fresh finite retention cannot overwrite')
    actual = next(r for r in load(CHECKS / 'roles.json')['records'] if r['name'] == 'core-obligation-3')
    require(type(actual['status']) is int and actual['status'] == 0 and actual['stdout'].startswith(PREFIX),'genuine fresh finite actual success')
    receipt = Path(actual['stdout'][len(PREFIX):].strip()); fixture = receipt.parent
    require(not fixture.is_absolute() and '..' not in fixture.parts and fixture.is_relative_to(Path('.artifacts/record-value-copy-reader-20261004')),'repository-local finite fixture before copying')
    require(fixture.resolve().is_relative_to(Path.cwd().resolve()) and not fixture.is_symlink()
        and fixture.stat().st_dev == Path.cwd().stat().st_dev,'same-volume contained original finite fixture root')
    originals = {}
    for path in fixture.rglob('*'):
        require(not path.is_symlink() and path.stat().st_dev == Path.cwd().stat().st_dev,'local non-symlink original finite fixture')
        if path.is_file(): originals[str(path.relative_to(fixture))] = path.read_bytes()
    require(originals and receipt.name in originals,'complete original finite native member population')
    for relative,raw in originals.items():
        path = DESTINATION / relative; path.parent.mkdir(parents=True,exist_ok=True); path.write_bytes(raw)
    require({str(p.relative_to(DESTINATION)):p.read_bytes() for p in DESTINATION.rglob('*') if p.is_file()} == originals,'copy verify complete finite fixture bytes before use')
    proof = dict(receipt=str(receipt),fixture=str(fixture),destination=str(DESTINATION),members={p:identity(raw) for p,raw in originals.items()},
        actual=identity(json.dumps(actual,sort_keys=True).encode()),role='Complete fresh finite probe fixture retained byte-for-byte; original native/raw captures unchanged and not recaptured.')
    derive(proof); PROOF.write_text(json.dumps(proof,sort_keys=True,indent=2)+'\n')
    print('PASS complete actual fresh finite fixture copy, byte/member verification and independent native replay qualification; no ignored scratch dependency.')


if __name__ == '__main__': main()
