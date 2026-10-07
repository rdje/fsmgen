"""Reproduce the cleared-message dependency and verify the persistent replacement."""
import contextlib
import hashlib
import io
import json
from pathlib import Path

BASE=Path('docs/audits/coordinate-public-origin-hypotheses-checks-20261007')


def need(value,cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def namespace(path):
    result={'__name__':'index_owner_counterfactual'}
    exec(compile(path.read_bytes(),str(path),'exec'),result)
    return result


def main():
    first=BASE/'first-qualify_index.py.txt'
    original=first.read_text()
    actual=json.loads((BASE/'index-repair.json').read_bytes())
    need(actual['instruments'][str(BASE/'qualify_index.py')]==pin(first.read_bytes()),
         'exact retained first executed index programme identity')
    message=(BASE/'first-commit-message.txt').read_text()
    scope=Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007/scope.txt').read_text()
    need(message.split(':',1)[0]==scope.splitlines()[0].removeprefix('Owner: '),
         'first complete transient message and persistent canonical owner agree')
    class Cleared:
        def read_text(self):
            return ''
    def counterfactual_path(value):
        return Cleared() if value=='git_message_brief.txt' else Path(value)
    old=namespace(first);old['Path']=counterfactual_path
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            old['main']()
    except ValueError as error:
        need(str(error)=='exact source-only hypothesis repair owner',
             'genuine cleared-message first-programme failure')
        cause=str(error)
    else:
        raise ValueError('first qualifier falsely accepts cleared required owner input')
    replacement="owner=(Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007/scope.txt')\n           .read_text().splitlines()[0].removeprefix('Owner: '))"
    current=BASE/'qualify_index.py'
    need(current.read_text()==original.replace("owner=Path('git_message_brief.txt').read_text().split(':',1)[0]",replacement),
         'exact persistent-owner-only repair conserves all index/source/native predicates')
    new=namespace(current);new['Path']=counterfactual_path
    output=io.StringIO()
    with contextlib.redirect_stdout(output):
        new['main']()
    need(output.getvalue()=='PASS exact whole index compaction, detailed canonical task-state retention and fresh final native source copies.\n',
         'corrected complete qualifier passes with transient message unavailable')
    product=dict(first_programme=pin(first.read_bytes()),first_message=pin(message.encode()),
                 persistent_scope=pin(scope.encode()),corrected_programme=pin(current.read_bytes()),
                 counterfactual='Only the commit-message read returns the required cleared empty value; the real message and every repository/source/native byte remain untouched.',
                 before_status=1,before_cause=cause,after_status=0)
    path=BASE/'index-owner-proof.json';raw=json.dumps(product,sort_keys=True,indent=2)+'\n'
    if path.exists():need(path.read_text()==raw,'whole retained persistent-owner repair proof')
    else:path.write_text(raw)
    print('PASS genuine cleared-message failure and exact persistent-owner repair; every source/index/native predicate conserves.')


if __name__=='__main__':
    main()
