"""Qualify both complete joins with an independent direct-source oracle."""
from common import BASE,CENSUS,PREDICATE,SCALAR,REGEX,PUBLIC,RAW,load,read,save
import oracle

source=read(CENSUS/'source-models.json')
save('source-proof.json',oracle.verify_source(source,read(PREDICATE/'predicate-values-qualified.json'),
    read(SCALAR/'scalars.json'),read(REGEX/'regexes.json'),read(REGEX/'plan.json'),load('source-products.json')))
save('opaque-proof.json',oracle.verify_opaque(source,read(PUBLIC),read(RAW),load('opaque-evidence.json')))
print('PASS independent complete source/value/obligation/profile reconstruction and whole original opaque evidence allocation.')
