"""Reproduce both first draft failures and independently constrain the repairs."""
import contextlib
import hashlib
import io
import json
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-capture-checks-20261007')


def need(value, cause):
    if not value:
        raise ValueError(cause)


def namespace(path):
    result = {'__name__': 'draft_failure_reproduction'}
    exec(compile(path.read_bytes(), str(path), 'exec'), result)
    return result


def pin(path):
    body = path.read_bytes()
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest())


def main():
    pairs = [('first-verify_book.py.txt', 'first-native-guide.json', 'verify_book.py',
              'whole source guide exact scoped replacement and prior conservation'),
             ('first-verify_saved.py.txt', 'saved-result.json', 'verify_saved.py',
              'genuine independent saved result control')]
    source = (BASE / 'book-source.md.txt').read_text()
    rendered = (BASE / 'book-input.html').read_text()
    build = json.loads((BASE / 'book.json').read_bytes())
    rows = []
    for retained, receipt, current, cause in pairs:
        first_path = BASE / retained
        actual = json.loads((BASE / receipt).read_bytes())
        need(type(actual['status']) is int and actual['status'] == 1
             and actual['stdout'] == '' and ('ValueError: ' + cause + '\n') in actual['stderr']
             and actual['instruments'][str(BASE / current)] == pin(first_path),
             'complete original failed command streams and exact first programme custody')
        old = namespace(first_path)
        try:
            if current == 'verify_book.py':
                old['check'](source, rendered, build)
            else:
                with contextlib.redirect_stdout(io.StringIO()):
                    old['main']()
        except ValueError as error:
            need(str(error) == cause, 'exact first native/result failure reproduced')
        else:
            raise ValueError('first actual failure did not reproduce')
        new = namespace(BASE / current)
        if current == 'verify_book.py':
            need(old['OLD_BLOCK'] != new['OLD_BLOCK'] and old['BLOCK'] == new['BLOCK'],
                 'only fixed predecessor meaning changes')
            new['check'](source, rendered, build)
        else:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                new['main']()
            product = json.loads(output.getvalue())
            need([r['control'] for r in product['controls']][:2]
                 == ['Boolean-saved-status','float-saved-status'], 'genuine typed candidates now reach intended native status refusals')
            old_bytes = first_path.read_text()
            expected = old_bytes.replace("need(changed != wire, 'genuine independent saved result control')",
                "need(json.dumps(changed, sort_keys=True) != json.dumps(wire, sort_keys=True),\n             'genuine independent saved result control')")
            need((BASE / current).read_text() == expected, 'exact type-preserving genuineness repair with whole predicates conserved')
        rows.append(dict(first_programme=pin(first_path), first_actual=actual,
                         repaired_programme=pin(BASE / current), reproduced_cause=cause,
                         before_status=1, after_status=0))
    path = BASE / 'repair-proof.json'
    encoded = json.dumps(rows, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == encoded, 'whole retained draft repair proof')
    else:
        path.write_text(encoded)
    print('PASS both complete first draft failures reproduce; exact repaired source/native and typed-result predicates qualify.')


if __name__ == '__main__':
    main()
