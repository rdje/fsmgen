"""Qualify whole source recipes independently before native observation."""
from common import AUTHORITY, BASE, CENSUS, load, need, read, save
import oracle


need(not (BASE/'native.json').exists(),'independent whole source proof before observation')
save('source-proof.json',oracle.source(read(AUTHORITY),read(CENSUS/'source-models.json'),load('regexes.json'),load('plan.json')))
print('PASS independent complete authored regex and source allocation proof before public capture.')
