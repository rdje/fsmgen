"""Retain every genuine whole regex hostile candidate and intended rejection."""
from common import load, save
from verify import falsify


save('controls.json',falsify(load('regexes.json'),load('plan.json'),load('native.json')))
print('PASS genuine complete regex source/value/flags/encoding/member/role/profile/native controls.')
