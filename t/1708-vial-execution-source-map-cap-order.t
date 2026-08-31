#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Scalar::Util qw(refaddr);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALExecutionContract qw(build_vial_execution_contract);
use FSM::VIAL::ExecutionBuilder;

my $limit = build_vial_execution_contract()->{limits}{source_map_records};
my $ctx = source_map_context($limit - 1);
my $first_location = source_location(10);

FSM::VIAL::ExecutionBuilder->_test_add_source_map(
    $ctx, '/plan/exact', '/semantic/exact', ['/bridge/exact'], $first_location,
);
is(scalar(@{$ctx->{source_map}}), $limit,
    'a source-map record at the exact boundary is admitted');
is_deeply($ctx->{source_map}[-1], {
        plan_path => '/plan/exact',
        semantic_path => '/semantic/exact',
        bridge_fact_paths => ['/bridge/exact'],
        source_locations => [$first_location],
    }, 'the exact-boundary source-map payload is unchanged');

my $second_location = source_location(20);
my $original_clone = \&FSM::VIAL::ExecutionBuilder::_clone;
my $location_clone_calls = 0;
my ($accepted, $error);
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_clone = sub {
        ++$location_clone_calls
            if ref($_[0]) && refaddr($_[0]) == refaddr($second_location);
        return $original_clone->(@_);
    };
    $accepted = eval {
        FSM::VIAL::ExecutionBuilder->_test_add_source_map(
            $ctx, '/plan/one-over', '/semantic/one-over',
            ['/bridge/one-over'], $second_location,
        );
        1;
    };
    $error = $@;
}

ok(!$accepted, 'a one-over source-map record is rejected');
isa_ok($error, 'FSM::VIAL::ExecutionBuilder::Failure');
is_deeply(
    ref($error) ? [@{$error}{qw(code phase message semantic_path)}] : [],
    [
        'VIAL_EXECUTION_LIMIT_ERROR',
        'limit',
        "source_map_records exceeds the limit $limit",
        '/source_map',
    ],
    'one-over rejection retains the exact execution source-map diagnostic',
);
is(scalar(@{$ctx->{source_map}}), $limit,
    'one-over rejection leaves the source-map table at its admitted boundary');
is($ctx->{source_map}[-1]{plan_path}, '/plan/exact',
    'one-over rejection leaves no appended source-map record');
is($location_clone_calls, 0,
    'one-over admission rejects before cloning the source location');

done_testing();

sub source_map_context {
    my ($count) = @_;
    my @records;
    $#records = $count - 1 if $count;
    return {source_map => \@records};
}

sub source_location {
    my ($start) = @_;
    return {
        source_name => 'generated/source-map-cap-order.vial',
        start_byte => $start,
        end_byte_exclusive => $start + 1,
        start_line => 1,
        start_column => $start + 1,
        end_line => 1,
        end_column => $start + 2,
    };
}

package FSM::VIAL::ExecutionBuilder;

sub _test_add_source_map {
    my ($class, @args) = @_;
    return _add_source_map(@args);
}
