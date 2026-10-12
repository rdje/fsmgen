"""Propose complete unchanged parent and every qualified independent meaning."""
from acceptance_common import *
import parent_model

if __name__ == '__main__':
    save_product('candidate.json.gz', parent_model.propose(parent_model.inputs()))
    print('PASS proposed complete unchanged independent meaning-parent acceptance; independent admission required.')
