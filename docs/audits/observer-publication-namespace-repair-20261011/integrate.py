"""Integrate the separately qualified namespace guard without changing first evidence."""
from pathlib import Path
import guard

BASE=Path('docs/audits/observer-publication-namespace-repair-20261011')


def main():
    guard.authenticate_original()
    source=(BASE/'guard.py').read_text()
    source+='\n\nimport record_value_observer_fact as finite\n'
    source+='PREPARATION = Path('+repr(str(BASE))+')\n'
    source+='PREPARATION_IDENTITY = '+repr(guard.identity((BASE/'preparation-manifest.json').read_bytes()))+'\n'
    source+='GUIDE = '+repr((BASE/'guide.txt').read_text())+'\n'
    source+='''

def authenticate():
    raw=finite.local(PREPARATION/'preparation-manifest.json',PREPARATION_IDENTITY)
    preparation=json.loads(raw)
    for name,expected in preparation.items():
        require(Path(name).name==name,'closed admitted namespace-repair member')
        finite.fingerprint(PREPARATION/name,expected)
    original=authenticate_original()
    return dict(preparation=PREPARATION_IDENTITY,complete_admitted_members=preparation,
                complete_original_namespace=original,
                scope='Complete admitted namespace repair and strict whole original publication graph; no fresh semantic reconstruction or native recapture.')


def guide(previous):
    return previous+GUIDE
'''
    helper=Path('scripts/record_value_observer_namespace_fact.py')
    guard.require(not helper.exists(),'new maintained strict namespace helper')
    helper.write_text(source)
    wrapper=Path('scripts/check_record_value_publication.py');before=wrapper.read_text();after=before
    changes={
      'import record_value_observer_fact as observer_fact\n':'import record_value_observer_fact as observer_fact\nimport record_value_observer_namespace_fact as observer_namespace_fact\n',
      'return observer_fact.guide(address_fact.guide(coordinate_fact.guide(result)))':'return observer_namespace_fact.guide(observer_fact.guide(address_fact.guide(coordinate_fact.guide(result))))',
      '    observer_before = observer_fact.authenticate()\n':'    observer_before = observer_fact.authenticate()\n    namespace_before = observer_namespace_fact.authenticate()\n',
      "    print(SUCCESS, end='')":"    require(same(namespace_before, observer_namespace_fact.authenticate()),\n            'whole original publication namespace conserved during current verification')\n    print(SUCCESS, end='')"}
    for old,new in changes.items():
        guard.require(after.count(old)==1,'unique maintained strict namespace seam')
        after=after.replace(old,new,1)
    (BASE/'integration.json').write_bytes(guard.encoded(dict(whole_before=before,whole_after=after,
         helper=source,preparation=guard.identity((BASE/'preparation-manifest.json').read_bytes()))))
    wrapper.write_text(after)
    print('PASS separately qualified strict original-namespace authentication integrated; first programme/products and historical stdout retain.')


if __name__=='__main__':main()
