#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_actor_shell_actor_name_shape
);

subtest 'direct ISF actor-shell actor-name metadata is exact' => sub {
    assert_actor_name_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF actor-shell actor-name metadata is exact' => sub {
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
        assert_actor_name_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public parser facades return advertised actor-name shape' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    assert_actor_name_shape($adapter->parse_file($path), 'parse_file actor shell');
    assert_actor_name_shape($adapter->parse_source($source, 'inline-apb-requester.isf'), 'parse_source actor shell');
};

subtest 'public parser rejects actor roots that cannot satisfy the advertised actor-name shape' => sub {
    my $source = <<'ISF';
(actor (bad_actor)
  (clock clk)
  (interface
    (input start)))
ISF

    my $ok = eval { FSM::Adapter::ISF->new()->parse_source($source, 'bad-actor-name.isf'); 1 };
    my $diagnostic = $@;

    ok(!$ok, 'nested actor name fails before returning a malformed actor shell');
    ok(!ref($diagnostic), 'nested actor name diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: \(actor \.\.\.\) requires a scalar name/,
        'nested actor name diagnostic is bounded to actor validation',
    );
};

done_testing();

sub assert_actor_name_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{actor_shell_actor_name_shape},
        isf_public_interface_actor_shell_actor_name_shape(),
        "$label actor_shell_actor_name_shape is exact",
    );
}

sub assert_actor_name_shape {
    my ($actor, $label) = @_;

    ok(defined($actor->{actor_name}), "$label actor_name is defined");
    ok(!ref($actor->{actor_name}), "$label actor_name is scalar");
    ok(length($actor->{actor_name}), "$label actor_name is non-empty");
    is($actor->{actor_name}, 'apb_requester', "$label actor_name preserves the actor root identifier");
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
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
