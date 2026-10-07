"""Retain complete native admission guidance and genuine scope/route controls."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-admission-20261007')
ns = {'__name__': 'native_coordinate_admission', '__file__': str(BASE / 'book.py')}
exec(compile((BASE / 'book.py').read_bytes(), ns['__file__'], 'exec'), ns)


def main():
    html = Path('.artifacts/coordinate-admission-book/13k-isf-feature-support-matrix.html').read_text()
    proof = ns['proof'](html)
    controls = []
    for name, old, new in (
        ('borrowed-historical-command', ns['COMMAND'], 'scripts/run_with_ram_guard.sh -- python3 -B docs/audits/record-value-class-frame-publication-20261006/verify.py'),
        ('coordinate-promotion', 'does not establish coordinate meanings', 'establishes original coordinate meanings'),
        ('private-identity-promotion', 'toolchain identities remain unmeasured', 'toolchain identities are measured')):
        changed = html.replace(old, new)
        if changed == html:
            raise ValueError('nongenuine native admission control: ' + name)
        try:
            ns['proof'](changed)
        except ValueError as error:
            if str(error) != 'unique complete native coordinate admission scope and checkpoint':
                raise
            controls.append(dict(control=name, cause=str(error)))
        else:
            raise ValueError('false-green native admission scope: ' + name)
    for name in ('native-input.html', 'native-proof.json'):
        if (BASE / name).exists():
            raise ValueError('native admission capture cannot overwrite evidence')
    (BASE / 'native-input.html').write_text(html)
    (BASE / 'native-proof.json').write_text(json.dumps(dict(proof=proof, controls=controls), sort_keys=True, indent=2) + '\n')
    print('PASS complete native saved-admission/current/historical scope and genuine route/coordinate/private-promotion controls; visual QA pending.')


if __name__ == '__main__':
    main()
