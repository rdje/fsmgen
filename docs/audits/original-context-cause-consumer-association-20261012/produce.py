"""Save one complete positive association candidate without touching old producers."""
from association_common import *
import association_inputs
import model


if __name__ == '__main__':
    save_product('candidate.json.gz', model.propose(association_inputs.inputs()))
    print('PASS complete original context/cause/coordinate/consumer association proposal; independent qualification remains separate.')
