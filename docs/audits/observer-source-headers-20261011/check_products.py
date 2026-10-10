"""Actually execute the independent full source-header and public grammar reconstruction."""
from common import load, save
import contracts
import oracle


if __name__=='__main__':
    save('contracts.json',contracts.derive())
    save('independent-proof.json',oracle.validate(load('headers.json'),load('current-headers.json')))
    save('public-grammar-proof.json',oracle.public_contract())
    print('PASS complete independent source/header/schema/value/group/load reconstruction, lossless full modes, known conditional texts and whole public grammar/native constructor bindings.')
