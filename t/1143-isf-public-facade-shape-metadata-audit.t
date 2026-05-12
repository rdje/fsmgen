#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

my $expected_shape_fields = {
    constructor_receiver_shape => 'exact class invocant: FSM::Adapter::ISF or FSM::Scheduler::ISF',
    constructor_argument_shape => 'even-length option/value list after class invocant; currently only debug is public',
    parser_method_receiver_shape => 'object returned by FSM::Adapter::ISF->new(...)',
    scheduler_method_receiver_shape => 'object returned by FSM::Scheduler::ISF->new(...)',
    parse_file_argument_shape => 'exactly one scalar filesystem path to a .isf source after object invocant',
    parse_file_path_requirement => 'defined scalar path with .isf suffix naming a readable regular file before private parsing',
    parse_source_argument_shape => 'exactly two scalar arguments after object invocant: source text and source label',
    lower_argument_shape => 'scheduler-consumable actor value returned by FSM::Adapter::ISF',
    report_argument_shape => 'scheduler-consumable actor value returned by FSM::Adapter::ISF',
};

my $expected_actor_shell_keys = [
    qw(
        actor_name
        transactions
        interface
    ),
];

subtest 'direct ISF facade shape metadata is exact' => sub {
    assert_facade_shape_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF facade shape metadata is exact' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_facade_shape_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_facade_shape_metadata {
    my ($contract, $label) = @_;

    for my $field (sort keys %$expected_shape_fields) {
        is($contract->{$field}, $expected_shape_fields->{$field}, "$label $field is exact");
    }

    is_deeply(
        $contract->{actor_shell_required_keys},
        $expected_actor_shell_keys,
        "$label actor shell required keys are exact",
    );
    assert_unique_scalar_list(
        $contract->{actor_shell_required_keys},
        "$label actor shell required keys",
    );

    my @surface_keys = (sort keys %$expected_shape_fields, 'actor_shell_required_keys');
    assert_public_top_level_contains(
        $contract->{public_top_level_presence_keys},
        \@surface_keys,
        $label,
    );
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
    }
}

sub assert_public_top_level_contains {
    my ($published_keys, $required_keys, $label) = @_;
    my %published = map { $_ => 1 } @{$published_keys || []};

    for my $key (@$required_keys) {
        ok($published{$key}, "$label public top-level discovery includes $key");
    }
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
