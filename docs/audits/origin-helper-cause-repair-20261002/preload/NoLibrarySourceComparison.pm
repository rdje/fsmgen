package NoLibrarySourceComparison;
use strict;
use warnings;
use parent 'FSM::Test::LibraryDocumentOriginAuthority';

# Retain real canonical construction and getters; bypass only opaque reload
# authentication, exposing actual accepted source/actor/proof forgeries.
sub validate {return 1}
1;
