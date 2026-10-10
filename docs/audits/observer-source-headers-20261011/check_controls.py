"""Execute and retain each complete genuine source-header candidate losslessly."""
from common import load, save
import verify


if __name__=='__main__':
    save('controls.json',verify.controls(load('headers.json'),load('current-headers.json'),load('contracts.json'),write=True))
    print('PASS every complete genuine source/header/role/format/schema/value/profile/native-promotion/parent-acceptance hostile candidate rejects at its intended contract.')
