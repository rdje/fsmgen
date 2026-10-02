package FSM::Test::NoDocumentComparison;
use parent 'FSM::Test::LibraryDocumentOriginAuthority';
# Actual counterfactual: canonical source/actor/export/clone producers still run,
# but a fresh consumer does not compare against independently supplied bytes.
sub validate {1}
1;
