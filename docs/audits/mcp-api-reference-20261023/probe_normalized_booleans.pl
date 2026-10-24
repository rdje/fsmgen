#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);

# Direct public-builder synthetic metadata, never a source/compiler query.
my $json = JSON::PP->new->canonical;
my @cases;
for my $case (
    ['json_values', {
        module_info => {
            system_contract => {clock => 'clk', reset => 'rst_n', reset_active_level => 'low',
                reset_keyword => 'sresetn', reset_kind => 'synchronous',
                declare_ports => JSON::PP::false, implicit => JSON::PP::true},
            signal_analysis => {inputs => [{direction => 'input', name => 'data', signed => JSON::PP::false, width => 1}],
                outputs => [], multi_bit => [], single_bit => []},
        },
        result => {intent_hir => {probe_values => [JSON::PP::false, JSON::PP::true, 0, 1, '0', '1', '', undef,
            {false_value => JSON::PP::false, true_value => JSON::PP::true, nested => [JSON::PP::false, undef]}]}},
    }],
    ['plain_values', {result => {intent_hir => {probe_values => [0, 1, '0', '1', '', undef, [], {}, {nested => [7, 'seven']}]} }}],
) {
    my ($id, $input) = @$case;
    my $before = $json->encode($input);
    my $output = build_normalized_semantic_success_report(%$input);
    push @cases, {id => $id, input => $json->decode($before), caller_before => $before,
        caller_after => $json->encode($input), output => $output};
}

my $private = bless {hidden => 'private'}, 'FSMTest::PrivateMetadata';
my $scalar = 9;
my $input = {intent_hir => {private_object => $private, scalar_reference => \$scalar,
    false_value => JSON::PP::false, values => [JSON::PP::false, $private, 0, undef]}};
my $output = build_normalized_semantic_success_report(result => $input);
push @cases, {id => 'private_refs', input_recipe => {
    private_class => 'FSMTest::PrivateMetadata', scalar_reference_value => 9,
    false_value => JSON::PP::false, values => ['json_false', 'private_object', 'number_zero', 'null'],
}, output => $output, caller_private_unchanged =>
    refaddr($input->{intent_hir}{private_object}) == refaddr($private) ? JSON::PP::true : JSON::PP::false,
    caller_scalar_value => $scalar,
    caller_false_kind => JSON::PP::is_bool($input->{intent_hir}{false_value}) ? 'boolean' : 'wrong',
};
print $json->encode({scope => 'synthetic_public_builder_metadata_no_source_query',
    runtime => {perl => "$^V", json_pp => "$JSON::PP::VERSION"}, cases => \@cases}), "\n";
