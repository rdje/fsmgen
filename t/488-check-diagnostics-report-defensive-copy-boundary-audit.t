#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::CheckDiagnostics qw(
    build_check_failure_report
    build_check_success_report
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t488__';
my $source = File::Spec->rel2abs(
    File::Spec->catfile($FindBin::Bin, 'corpus', 'direct_intent_integer_literals.fsm'),
);

subtest 'check success report builder returns fresh nested structures' => sub {
    my %args = (
        input => $source,
        source_file => $source,
        strict_mode => 1,
        target_language => 'systemverilog',
        module_info => {
            module_name => 'direct_intent_integer_literals',
            state_count => 2,
            signal_count => 3,
            composition_child_count => 0,
        },
    );

    my $first = build_check_success_report(%args);
    mutate_structure($first, $sentinel);

    my $second = build_check_success_report(%args);
    ok(!contains_sentinel($second, $sentinel), 'fresh success report is not affected by prior caller mutation');
    is($second->{producer}{report_source}, 'FSM::Support::CheckDiagnostics', 'fresh success report keeps producer owner');
    is_deeply($second->{diagnostics}, [], 'fresh success report keeps diagnostics empty');
    ok(ref($second->{support_accounting}) eq 'HASH', 'fresh success report keeps support accounting object');
    ok(!$second->{generated_output}{emitted}, 'fresh success report keeps emitted flag false');
};

subtest 'check failure report builder returns fresh nested structures' => sub {
    my %args = (
        input => $source,
        source_file => $source,
        strict_mode => 1,
        target_language => 'systemverilog',
        message => "Source file: '$source'\nSynthetic check failure for defensive-copy audit",
    );

    my $first = build_check_failure_report(%args);
    mutate_structure($first, $sentinel);

    my $second = build_check_failure_report(%args);
    ok(!contains_sentinel($second, $sentinel), 'fresh failure report is not affected by prior caller mutation');
    is($second->{producer}{report_source}, 'FSM::Support::CheckDiagnostics', 'fresh failure report keeps producer owner');
    is(scalar(@{$second->{diagnostics}}), 1, 'fresh failure report keeps one diagnostic');
    ok(ref($second->{diagnostics}[0]{support_accounting}) eq 'HASH', 'fresh failure diagnostic keeps support accounting object');
    ok(!$second->{generated_output}{emitted}, 'fresh failure report keeps emitted flag false');
};

done_testing();
