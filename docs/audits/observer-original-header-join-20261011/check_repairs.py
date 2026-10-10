"""Retain complete actual local-defect replay results."""
from common import save
from local_repairs import replay

if __name__=='__main__':
    save('local-repair-proof-qualified.json',replay())
    print('PASS every complete first import/reference/count failure replays and the independent corrected contracts qualify.')
