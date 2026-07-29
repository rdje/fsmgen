package FSM::Test::ProjectDataLocality;

use strict;
use warnings;

use FSM::ProjectDataLocality qw(configure_project_temp_environment);

configure_project_temp_environment(purpose => 'tests');

1;
