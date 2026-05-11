#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use FSM::Support::ReportGeneratedOutputContract qw(build_report_generated_output_contract);
my $sentinel = '__report_generated_output_contract_full_surface_mutation__';

subtest 'report generated output contract full surface rebuilds cleanly' => sub {
    my $first = build_report_generated_output_contract();
    mutate_structure($first);
    my $second = build_report_generated_output_contract();
    my $expected = build_report_generated_output_contract();
    is_deeply($second, $expected, 'fresh generated output contract rebuilds clean full surface');
};

done_testing();

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);
    if (ref($value) eq 'ARRAY') { push @{$value}, $sentinel; mutate_structure($_) for @{$value}; return; }
    if (ref($value) eq 'HASH') { $value->{$sentinel} = $sentinel; mutate_structure($_) for values %{$value}; return; }
}
