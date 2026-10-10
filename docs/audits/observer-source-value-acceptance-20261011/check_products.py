"""Execute the independent parent join and genuine complete hostile controls."""
from common import load, save, same, need
import contracts
import verify


if __name__=='__main__':
    task_contracts=contracts.derive()
    need(same(task_contracts,load('contracts.json')),'whole unchanged initial task contracts')
    product=load('product-qualified.json')
    save('independent-proof-qualified.json',verify.validate(product,task_contracts))
    save('controls-qualified.json',verify.falsify(product,task_contracts))
    print('PASS complete independent original source-value acceptance and genuine whole hostile candidates.')
