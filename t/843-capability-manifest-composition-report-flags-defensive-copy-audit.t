#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::CompositionReportContract qw(build_composition_report_contract);
my $sentinel = '__manifest_composition_report_mutation__';

subtest 'manifest-embedded composition report JSON-safety flags rebuilds cleanly after caller mutation' => sub {
    my $first = build_capability_manifest();
    my $mutated = $first->{embedding}{composition_report};
    $mutated->{'raw_report_json_safe'} = $mutated->{'raw_report_json_safe'} ? 0 : 1;
    $mutated->{'sanitized_report_json_safe'} = $mutated->{'sanitized_report_json_safe'} ? 0 : 1;
    $mutated->{'sanitizes_private_perl_objects'} = $mutated->{'sanitizes_private_perl_objects'} ? 0 : 1;
    $mutated->{'stable_nested_content'} = $mutated->{'stable_nested_content'} ? 0 : 1;

    my $second = build_capability_manifest();
    my $contract = $second->{embedding}{composition_report};
    my $expected = build_composition_report_contract();
    is($contract->{'raw_report_json_safe'} ? 1 : 0, $expected->{'raw_report_json_safe'} ? 1 : 0, 'fresh manifest composition report rebuilds clean raw_report_json_safe');
    is($contract->{'sanitized_report_json_safe'} ? 1 : 0, $expected->{'sanitized_report_json_safe'} ? 1 : 0, 'fresh manifest composition report rebuilds clean sanitized_report_json_safe');
    is($contract->{'sanitizes_private_perl_objects'} ? 1 : 0, $expected->{'sanitizes_private_perl_objects'} ? 1 : 0, 'fresh manifest composition report rebuilds clean sanitizes_private_perl_objects');
    is($contract->{'stable_nested_content'} ? 1 : 0, $expected->{'stable_nested_content'} ? 1 : 0, 'fresh manifest composition report rebuilds clean stable_nested_content');
};
done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
