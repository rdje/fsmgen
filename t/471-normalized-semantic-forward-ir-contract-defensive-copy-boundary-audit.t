#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::DefensiveCopyAudit qw(assert_contract_module_defensive_copies);

assert_contract_module_defensive_copies(
    module => 'FSM::Support::NormalizedSemanticForwardIRContract',
    sentinel => '__mutated_by_t471__',
);

done_testing();
