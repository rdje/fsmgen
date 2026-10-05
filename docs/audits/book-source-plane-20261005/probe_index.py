"""Calibrate Git-result conservation using actual staged entries and corruptions."""
import importlib.util
import json
import subprocess
from pathlib import Path

BASE=Path('docs/audits/book-source-plane-20261005')


def main():
    spec=importlib.util.spec_from_file_location('indexed_book_source_plane','scripts/book_source_references.py')
    plane=importlib.util.module_from_spec(spec);spec.loader.exec_module(plane)
    rows=plane.expected_rows();plane.check_index(rows)
    paths=[plane.MANIFEST]+[str(asset.relative_to(plane.ROOT)) for _,asset,_ in plane.endpoints(rows)]
    command=['git','-C',str(plane.ROOT),'ls-files','--stage','-z','--',*paths]
    original=subprocess.check_output(command);entries=[e for e in original.split(b'\0') if e]
    real_output=subprocess.check_output;refusals=[]
    asset_entry=next(e for e in entries if b'\tdocs/book/src/reference-source/' in e and not e.endswith(b'/routes.jsonl'))
    for name in ('missing-index-member','wrong-index-mode','wrong-index-endpoint','conflicted-index','wrong-index-producer'):
        altered=list(entries)
        if name=='missing-index-member':altered.remove(asset_entry)
        elif name=='wrong-index-mode':altered[altered.index(asset_entry)]=asset_entry.replace(b'120000 ',b'100644 ',1)
        elif name=='wrong-index-endpoint':
            meta,path=asset_entry.split(b'\t',1);mode,oid,stage=meta.split();altered[altered.index(asset_entry)]=b' '.join((mode,b'0'*len(oid),stage))+b'\t'+path
        elif name=='conflicted-index':altered[altered.index(asset_entry)]=asset_entry.replace(b' 0\t',b' 1\t',1)
        candidate=b'\0'.join(altered)+b'\0'
        def controlled_output(args,*a,**kw):
            if args==command:return candidate
            value=real_output(args,*a,**kw)
            if name=='wrong-index-producer' and args[-1]=='scripts/book_source_references.py' and '--stage' in args:
                meta,path=value.strip().split('\t',1);mode,oid,stage=meta.split()
                return ' '.join((mode,'0'*len(oid),stage))+'\t'+path+'\n'
            return value
        try:
            subprocess.check_output=controlled_output
            try:plane.check_index(rows)
            except ValueError as error:refusals.append({'control':name,'refusal':str(error)})
            else:raise AssertionError('false-green staged projection: '+name)
        finally:subprocess.check_output=real_output
    record={'actual_index_entries':original.decode(),'actual_path_population':paths,'controls':refusals,
            'scope':'Actual staged Git producer and generated-object data are the baseline. Isolated command-response corruptions preserve production files and both real Git indexes; real hash-object/source reads remain active.'}
    target=BASE/'index-proofs.json';assert not target.exists();target.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
    print('PASS actual Git projection conserves complete staged source/producer/assets; real lost-member/mode/endpoint/conflict/producer controls reject.')


if __name__=='__main__':main()
