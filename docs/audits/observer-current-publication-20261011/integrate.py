"""Publish only the independently reviewed fixed topic and maintained reader."""
import subprocess
from pathlib import Path
from common import BASE, load, need, pin, save
import model


def main():
    need((BASE/'independent-prerequisite-proof.json').exists(),'complete fresh semantic qualification precedes publication')
    before=(BASE/'before-card.md.txt').read_bytes();after=(BASE/'published-card.md.txt').read_bytes()
    model.qualify(load('proposal.json'),before,after,load('review.json'))
    members={p.name:pin(p.read_bytes()) for p in sorted(BASE.iterdir()) if p.is_file()}
    need('admission-manifest.json' not in members,'first complete observer admission')
    save('admission-manifest.json',members)
    template=(BASE/'observer_fact.py.txt').read_text()
    need(template.count("'__ADMISSION__'")==1 and template.count("'__GUIDE__'")==1,'unique observer admission and guide slots')
    generated=template.replace("'__ADMISSION__'",repr(pin((BASE/'admission-manifest.json').read_bytes())),1).replace("'__GUIDE__'","'''"+(BASE/'guide.txt').read_text()+"'''",1)
    helper=Path('scripts/record_value_observer_fact.py');need(not helper.exists(),'new maintained observer fact helper')
    helper.write_text(generated)
    wrapper=Path('scripts/check_record_value_publication.py');original=wrapper.read_text();changed=original
    replacements={
        'import record_value_address_fact as address_fact\n':'import record_value_address_fact as address_fact\nimport record_value_observer_fact as observer_fact\n',
        'return address_fact.cards(coordinate_fact.cards(result))':'return observer_fact.cards(address_fact.cards(coordinate_fact.cards(result)))',
        'return address_fact.guide(coordinate_fact.guide(result))':'return observer_fact.guide(address_fact.guide(coordinate_fact.guide(result)))',
        '    address_before = address_fact.authenticate()\n':'    address_before = address_fact.authenticate()\n    observer_before = observer_fact.authenticate()\n',
        '    print(SUCCESS, end=\'\')':'    require(same(observer_before, observer_fact.authenticate()),\n            \'whole admitted observer qualification conserved during current verification\')\n    print(SUCCESS, end=\'\')'}
    for old,new in replacements.items():
        need(changed.count(old)==1,'unique maintained publication integration seam')
        changed=changed.replace(old,new,1)
    save('wrapper-integration.json',dict(before=pin(original.encode()),after=pin(changed.encode()),whole_before=original,whole_after=changed))
    wrapper.write_text(changed)
    card=Path(model.CARD);need(card.read_bytes()==before,'whole live topic before sole atomic admission');card.write_bytes(after)
    print('PASS complete independently qualified non-growing observer topic and maintained reader integration; native/current checks remain pending.')


if __name__=='__main__':main()
