#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(refaddr);
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);

# Synthetic metadata through the advertised public builder. These controls run
# no parser/compiler/source query and advertise no new source-language fields.
my $json = JSON::PP->new->canonical;

subtest 'JSON booleans survive in declared system and signal fields' => sub {
    my $metadata = {
        system_contract => {
            clock => 'clk', reset => 'rst_n', reset_active_level => 'low',
            reset_keyword => 'sresetn', reset_kind => 'synchronous',
            declare_ports => JSON::PP::false, implicit => JSON::PP::true,
        },
        signal_analysis => {
            inputs => [{name => 'data', direction => 'input', width => 1,
                        signed => JSON::PP::false}],
            outputs => [], single_bit => [], multi_bit => [],
        },
    };
    my $before = $json->encode($metadata);
    my $report = build_normalized_semantic_success_report(module_info => $metadata);
    is($json->encode($report->{semantic}{system_contract}),
       $json->encode($metadata->{system_contract}), 'all effective-system fields and JSON kinds retain');
    is($json->encode($report->{semantic}{signal_analysis}),
       $json->encode($metadata->{signal_analysis}), 'signal entry fields and JSON kinds retain');
    ok(JSON::PP::is_bool($report->{semantic}{system_contract}{declare_ports}), 'false remains a JSON boolean');
    ok(JSON::PP::is_bool($report->{semantic}{system_contract}{implicit}), 'true remains a JSON boolean');
    ok(JSON::PP::is_bool($report->{semantic}{signal_analysis}{inputs}[0]{signed}), 'signed false remains a JSON boolean');
    ok(exists $report->{semantic}{explicit_system_contract}
       && !defined $report->{semantic}{explicit_system_contract}, 'unpreserved explicit-system key retains null');
    ok(!exists $report->{semantic}{composition}
       && !exists $report->{semantic}{symbol_contract}
       && !exists $report->{semantic}{protocol_intent_bundle}, 'unavailable optional children remain absent');
    is($json->encode($metadata), $before, 'builder leaves caller metadata unchanged');
};

subtest 'nested arrays retain positions and distinguish boolean numeric string and null values' => sub {
    my $values = [JSON::PP::false, JSON::PP::true, 0, 1, '0', '1', '', undef,
                  {false_value => JSON::PP::false, true_value => JSON::PP::true,
                   nested => [JSON::PP::false, undef]}];
    my $result = {intent_hir => {probe_values => $values}};
    my $before = $json->encode($result);
    my $report = build_normalized_semantic_success_report(result => $result);
    my $copy = $report->{semantic}{forward_ir}{intent_hir}{probe_values};
    is($json->encode($copy), $json->encode($values), 'complete ordered JSON values and kinds retain');
    is($json->encode($result), $before, 'caller values and kinds retain');
    $copy->[8]{nested}[0] = JSON::PP::true;
    is($json->encode($result), $before, 'editing the returned nested copy cannot change caller metadata');
};

subtest 'recognized JSON booleans do not admit private objects or unsupported references' => sub {
    my $private = bless {private_payload => 'hidden'}, 'FSMTest::PrivateMetadata';
    my $scalar = 9;
    my $input = {
        private_object => $private, scalar_reference => \$scalar,
        false_value => JSON::PP::false,
        values => [JSON::PP::false, $private, 0, undef],
    };
    my $report = build_normalized_semantic_success_report(result => {intent_hir => $input});
    my $output = $report->{semantic}{forward_ir}{intent_hir};
    ok(!exists $output->{private_object}, 'private object remains filtered');
    ok(!exists $output->{scalar_reference}, 'unsupported scalar reference remains filtered');
    is($json->encode($output),
       $json->encode({false_value => JSON::PP::false, values => [JSON::PP::false, 0, undef]}),
       'only unsupported references are removed; safe false values retain their positions');
    is(refaddr($input->{private_object}), refaddr($private), 'caller private object remains untouched');
    is($scalar, 9, 'caller scalar reference remains untouched');
};

done_testing();
