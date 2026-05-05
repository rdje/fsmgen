#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Test::DefensiveCopyAudit qw(assert_exported_builder_defensive_copies);

assert_exported_builder_defensive_copies(
    module => 'FSM::Support::SupportAccountingSection',
    builder => 'build_support_accounting_section',
    sentinel => '__mutated_by_t486__',
);

done_testing();
