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

my $limit = build_vial_execution_contract()->{limits}{execution_types};
my $first_shape = scalar_shape(1);
my $ctx = type_context($limit - 1);

my $first_id = FSM::VIAL::ExecutionBuilder->_test_register_type(
    $ctx, $first_shape, 'type/first',
);
like($first_id, qr{\Aexecution-type/[0-9a-f]{64}\z},
    'a novel type at the exact boundary is admitted');
is(scalar(@{$ctx->{type_entries}}), $limit,
    'the exact-boundary type fills the execution table');

my $duplicate_id = FSM::VIAL::ExecutionBuilder->_test_register_type(
    $ctx, scalar_shape(1), 'type/duplicate',
);
is($duplicate_id, $first_id,
    'an existing canonical shape remains reusable at the type limit');
is(scalar(@{$ctx->{type_entries}}), $limit,
    'duplicate reuse does not consume another type-table slot');
is_deeply($ctx->{type_entries}[-1]{semantic_ids},
    ['type/first', 'type/duplicate'],
    'duplicate reuse still accumulates its semantic identities');

my $second_shape = scalar_shape(2);
my $original_clone = \&FSM::VIAL::ExecutionBuilder::_clone;
my $shape_clone_calls = 0;
my ($accepted, $error);
{
    no warnings 'redefine';
    local *FSM::VIAL::ExecutionBuilder::_clone = sub {
        ++$shape_clone_calls
            if ref($_[0]) && refaddr($_[0]) == refaddr($second_shape);
        return $original_clone->(@_);
    };
    $accepted = eval {
        FSM::VIAL::ExecutionBuilder->_test_register_type(
            $ctx, $second_shape, 'type/one-over',
        );
        1;
    };
    $error = $@;
}

ok(!$accepted, 'a novel one-over type is rejected');
isa_ok($error, 'FSM::VIAL::ExecutionBuilder::Failure');
is_deeply(
    [@{$error}{qw(code phase message semantic_path)}],
    [
        'VIAL_EXECUTION_LIMIT_ERROR',
        'limit',
        "execution_types exceeds the limit $limit",
        '/type_table',
    ],
    'one-over rejection retains the exact execution-type diagnostic',
);
is(scalar(@{$ctx->{type_entries}}), $limit,
    'one-over rejection leaves the type table at the admitted boundary');
is(scalar(keys %{$ctx->{type_by_shape}}), 1,
    'one-over rejection leaves no cached type entry');
is($shape_clone_calls, 0,
    'one-over admission rejects before cloning the novel type payload');

done_testing();

sub type_context {
    my ($count) = @_;
    my @entries;
    $#entries = $count - 1 if $count;
    return {
        type_by_shape => {},
        type_entries => \@entries,
    };
}

sub scalar_shape {
    my ($width) = @_;
    return {
        kind => 'scalar',
        state_domain => 'two_state',
        signed => 0,
        width => $width,
    };
}

package FSM::VIAL::ExecutionBuilder;

sub _test_register_type {
    my ($class, @args) = @_;
    return _register_type(@args);
}
