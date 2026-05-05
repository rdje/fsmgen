#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::NormalizedSemanticReport qw(
    build_normalized_semantic_failure_report
    build_normalized_semantic_success_report
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t489__';
my $source = File::Spec->rel2abs(
    File::Spec->catfile($FindBin::Bin, 'corpus', 'direct_intent_integer_literals.fsm'),
);

subtest 'normalized semantic success report builder returns fresh nested structures' => sub {
    my %args = (
        input => $source,
        source_file => $source,
        strict_mode => 1,
        target_language => 'systemverilog',
        module_info => {
            module_name => 'direct_intent_integer_literals',
            source_root_kind => 'fsm',
            state_count => 2,
            regular_state_names => [qw(IDLE RUN)],
            signal_names => [qw(clk rst_n done)],
            signal_analysis => {
                signals => [
                    { name => 'done', width => 1, direction => 'output' },
                ],
            },
            system_contract => {
                clock => 'clk',
                reset => 'rst_n',
            },
            symbol_contract => {
                signals => {
                    done => { width => 1, kind => 'output' },
                },
            },
        },
        result => {
            intent_hir => {
                module_name => 'direct_intent_integer_literals',
                signal_names => [qw(clk rst_n done)],
            },
            lowered_rtl_ir => {
                target_language => 'systemverilog',
                composition_shared_datapath_candidates => [
                    { name => 'none', reason => 'direct source' },
                ],
            },
            structural_rtl_ir => {
                module_name => 'direct_intent_integer_literals',
                ports => [
                    { name => 'clk', direction => 'input' },
                ],
            },
            composition_report => {
                lane => 'direct',
                ports => [
                    { name => 'done', origin => 'fsm_output' },
                ],
                port_origin_counts => {
                    fsm_output => 1,
                },
                ordered_port_origins => ['fsm_output'],
            },
        },
    );

    my $first = build_normalized_semantic_success_report(%args);
    mutate_structure($first, $sentinel);

    my $second = build_normalized_semantic_success_report(%args);
    ok(!contains_sentinel($second, $sentinel), 'fresh success report is not affected by prior caller mutation');
    is($second->{producer}{report_source}, 'FSM::Support::NormalizedSemanticReport', 'fresh success report keeps producer owner');
    is_deeply($second->{diagnostics}, [], 'fresh success report keeps diagnostics empty');
    ok(ref($second->{semantic}{module}) eq 'HASH', 'fresh success report keeps semantic module object');
    ok(ref($second->{semantic}{forward_ir}{structural_rtl_ir}) eq 'HASH', 'fresh success report keeps structural RTL IR object');
    ok(!$second->{generated_output}{emitted}, 'fresh success report keeps emitted flag false');
};

subtest 'normalized semantic failure report builder returns fresh nested structures' => sub {
    my %args = (
        input => $source,
        source_file => $source,
        strict_mode => 1,
        target_language => 'systemverilog',
        message => "Source file: '$source'\nSynthetic normalized semantic failure for defensive-copy audit",
    );

    my $first = build_normalized_semantic_failure_report(%args);
    mutate_structure($first, $sentinel);

    my $second = build_normalized_semantic_failure_report(%args);
    ok(!contains_sentinel($second, $sentinel), 'fresh failure report is not affected by prior caller mutation');
    is($second->{producer}{report_source}, 'FSM::Support::NormalizedSemanticReport', 'fresh failure report keeps producer owner');
    is(scalar(@{$second->{diagnostics}}), 1, 'fresh failure report keeps one diagnostic');
    ok(ref($second->{support_accounting}) eq 'HASH', 'fresh failure report keeps support accounting object');
    ok(!$second->{generated_output}{emitted}, 'fresh failure report keeps emitted flag false');
};

done_testing();
