"""Reproduce a staged extra hidden from the worktree using this repository only."""
import json
import subprocess
import sys
from pathlib import Path

BASE=Path('docs/audits/book-source-index-closure-20261005')
EXTRA=Path('docs/book/src/reference-source/owned-hidden-index-control.source.txt')


def run(command):
    r=subprocess.run(command,capture_output=True,text=True)
    return {'command':command,'status':r.returncode,'stdout':r.stdout,'stderr':r.stderr}


def main():
    assert not EXTRA.exists()
    target=BASE/'final-proof.json';assert not target.exists()
    record={'scope':'One newly created owned path in the real project index, then absent from the worktree. Only that path is restored/removed; no separate Git repository or production source modification.'}
    def save():target.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
    record['baseline']=run([sys.executable,'-B','scripts/check_book_source_index.py']);save()
    assert record['baseline']['status']==0, 'admit baseline before altering the real index'
    EXTRA.write_text('Owned staged membership control; remove exactly this path.\n')
    try:
        stage=run(['git','add','--',str(EXTRA)]);record['stage']=stage;save();assert stage['status']==0
        EXTRA.unlink()
        original=run([sys.executable,'-B','scripts/book_source_references.py','--check'])
        complete=run([sys.executable,'-B','scripts/check_book_source_index.py'])
        record.update(original=original,complete=complete);save()
        assert original['status']==0 and complete['status']!=0
        assert 'complete directory-wide Git source-plane membership' in complete['stderr']
    finally:
        if EXTRA.exists(): EXTRA.unlink()
        remove=run(['git','rm','--cached','--',str(EXTRA)]);record['remove']=remove;save();assert remove['status']==0
        record['restored']=run([sys.executable,'-B','scripts/check_book_source_index.py']);save()
        assert record['restored']['status']==0
    print('PASS original admitted-path index check accepts hidden staged extra; complete indexed-directory currency rejects and restored actual index passes.')


if __name__=='__main__':main()
