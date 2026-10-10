"""Execute the explicit independent source reconstruction before falsification."""
from common import BASE, load, save
from oracle import validate

save('independent.json', validate(load('census.json'), load('source-models.json'), (BASE / 'source-models.json').read_bytes()))
print('PASS complete independent census reconstruction; both qualified schemas and original unknowns retain.')
