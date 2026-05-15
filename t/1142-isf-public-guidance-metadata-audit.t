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

my $expected_guidance = [
    'Treat this as the first bounded public ISF downstream-consumer contract, advertised through embedding.isf_public_interface.',
    'Treat the contract as live: exact metadata audits describe the current advertised surface, not a promise that ISF or the schedule-report schema is frozen.',
    'The public in-process seam is the parser/scheduler facade pair, not the raw parser AST or LoweringIR internals.',
    'The lower(...) result currently advertises the files map as scheduled module, specialized library-child module, and generated composition-top .fsm artifacts; the whole result hash is not yet a broad API.',
    'The library catalog path list and shipped_library_definitions entries are live discovery metadata for reusable ISF definitions; add or change entries only with source, limitations, and tests updated together.',
    'The schedule report currently advertises only the named top-level and summary key families; wider schema promises must be documented and regression-backed before downstream tools rely on them.',
    'The live human contract documents must evolve in the same slices that change supported ISF syntax, facade behavior, lower result shape, or schedule-report shape.',
    'Feature-driven public ISF changes must move the matching public contract and manifest audit tests in the same slice as the implementation.',
];

subtest 'direct ISF guidance metadata is exact and unique' => sub {
    assert_guidance(
        build_isf_public_interface_contract()->{guidance},
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF guidance metadata is exact and unique' => sub {
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
        assert_guidance(
            $view->{payload}{embedding}{isf_public_interface}{guidance},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_guidance {
    my ($guidance, $label) = @_;

    is_deeply($guidance, $expected_guidance, "$label guidance list is exact");
    assert_unique_scalar_list($guidance, "$label guidance list");
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        ok($value !~ /\n/, "$label entry '$value' is a single line");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
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
