"""Retain complete genuine value/profile/opaque/acceptance hostile products."""
from common import load,save
from verify import falsify

save('controls.json',falsify(load('source-products.json'),load('opaque-evidence.json'),load('task-contracts.json')))
print('PASS complete genuine source/value/role/encoding/profile/opaque/member/acceptance controls with intended independent rejections.')
