"""Independent complete scalar hypotheses before the public native capture."""
from common import BASE, CENSUS, load, need, read, save
import oracle


if __name__ == '__main__':
    need(not (BASE / 'native.json').exists(), 'independent source hypotheses precede observation')
    save('source-proof.json', oracle.verify_source(read(CENSUS / 'source-models.json'),
         load('scalars.json'), load('plan.json')))
    print('PASS independent whole scalar source members, values, constructors and selected headers before native observation.')
