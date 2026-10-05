"""Exercise LF/CR/UTF8 source boundaries with complete known-bad bytes retained."""
import importlib.util
import json
import shutil
from pathlib import Path

BASE=Path('docs/audits/book-source-plane-20261005')


def main():
    spec=importlib.util.spec_from_file_location('lf_bounded_book_source','scripts/book_source_references.py')
    plane=importlib.util.module_from_spec(spec);spec.loader.exec_module(plane)
    root=BASE/'raw-line-controls';assert not root.exists();root.mkdir();plane.ROOT=root.resolve()
    original=json.loads((BASE/'initial-raw-line-probe.json').read_text());cases={
        'original-CR-split-false-green':(original['source'].encode(),1),
        'exact-EOF-boundary':(b'X'*plane.SOURCE_LINE_BYTES,0),
        'exact-LF-boundary':(b'X'*plane.SOURCE_LINE_BYTES+b'\n',0),
        'exact-CRLF-boundary':(b'X'*plane.SOURCE_LINE_BYTES+b'\r\n',0),
        'bare-EOF-CR-overflow':(b'X'*plane.SOURCE_LINE_BYTES+b'\r',1),
        'invalid-UTF8':(b'valid prefix\xff',1),
    }
    results={}
    for name,(raw,expected) in cases.items():
        (root/'source.txt').write_bytes(raw)
        try: result=plane.source_bytes('source.txt')
        except ValueError as error: status,refusal=1,str(error)
        else: assert result==raw;status,refusal=0,None
        assert status==expected,name
        results[name]={'payload_hex':raw.hex(),'status':status,'refusal':refusal}
    record={'cases':results,'scope':'Actual raw source reader; only CR immediately before LF is excluded from content width. A bare EOF CR counts. Invalid UTF8 rejects before publication. No production source/asset mutation.'}
    target=BASE/'raw-line-proofs.json';assert not target.exists();target.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
    assert root.parent==BASE and root.name=='raw-line-controls';shutil.rmtree(root);assert not root.exists()
    print('PASS original raw-LF false green now rejects; exact EOF/LF/CRLF boundaries pass, bare EOF CR overflow and invalid UTF8 reject.')


if __name__=='__main__':main()
