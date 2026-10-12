"""Development-only whole independent parent-candidate interface."""
from parent_common import *
import model
import reader

candidate = model.propose(model.inputs())
qualified = reader.check(candidate)
save_product('development-candidate.json.gz', candidate)
save('development-qualification.json', qualified)
print('PASS development-only complete source-bound original-consumer parent candidate and independent meaning/admission/current/failure qualification.')
