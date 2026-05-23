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
    isf_public_interface_actor_shell_interface_shape
);

subtest 'direct ISF actor-shell interface-shape metadata is exact' => sub {
    assert_actor_shell_interface_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF actor-shell interface-shape metadata is exact' => sub {
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
        assert_actor_shell_interface_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public parser facades return advertised actor-shell interface shape' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    assert_actor_shell_interface_shape($adapter->parse_file($path), 'parse_file actor shell');
    assert_actor_shell_interface_shape($adapter->parse_source($source, 'inline-apb-requester.isf'), 'parse_source actor shell');
};

subtest 'public parser rejects interface ports that cannot satisfy the advertised shell shape' => sub {
    my $adapter = FSM::Adapter::ISF->new();

    for my $case (
        [
            'unsupported direction',
            <<'ISF',
(actor bad_direction
  (clock clk)
  (interface
    (inout data)))
ISF
            qr/\AError: interface port direction must be input or output/,
        ],
        [
            'nested port name',
            <<'ISF',
(actor bad_name
  (clock clk)
  (interface
    (input (data))))
ISF
            qr/\AError: interface port requires a scalar name/,
        ],
        [
            'non-positive port width',
            <<'ISF',
(actor bad_width
  (clock clk)
  (interface
    (output data (width 0))))
ISF
            qr/\AError: interface port 'data' width must be a positive integer or actor scalar parameter/,
        ],
        [
            'unknown symbolic port width',
            <<'ISF',
(actor symbolic_width
  (clock clk)
  (interface
    (output data (width WIDTH))))
ISF
            qr/\AError: actor 'symbolic_width' interface port 'data' width token 'WIDTH' is not a declared actor scalar parameter/,
        ],
    ) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { $adapter->parse_source($source, "$label.isf"); 1 };
        my $diagnostic = $@;

        ok(!$ok, "$label fails before returning a malformed actor shell");
        ok(!ref($diagnostic), "$label diagnostic is scalar");
        like($diagnostic, $pattern, "$label diagnostic is bounded to interface validation");
    }
};

done_testing();

sub assert_actor_shell_interface_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{actor_shell_interface_shape},
        isf_public_interface_actor_shell_interface_shape(),
        "$label actor_shell_interface_shape is exact",
    );
}

sub assert_actor_shell_interface_shape {
    my ($actor, $label) = @_;
    my $interface = $actor->{interface};

    ok(ref($interface) eq 'HASH', "$label interface is a hash reference");
    ok(ref($interface->{inputs}) eq 'ARRAY', "$label interface inputs is an array reference");
    ok(ref($interface->{outputs}) eq 'ARRAY', "$label interface outputs is an array reference");

    assert_port_entries($interface->{inputs}, "$label input");
    assert_port_entries($interface->{outputs}, "$label output");

    is(port_width($interface->{inputs}, 'start'), 1, "$label default-width input normalizes to 1");
    is(port_width($interface->{inputs}, 'req_addr'), 32, "$label explicit-width input keeps its width");
    is(port_width($interface->{outputs}, 'PSEL'), 1, "$label default-width output normalizes to 1");
    is(port_width($interface->{outputs}, 'PADDR'), 32, "$label explicit-width output keeps its width");
}

sub assert_port_entries {
    my ($ports, $label) = @_;

    for my $port (@{$ports || []}) {
        ok(ref($port) eq 'HASH', "$label port entry is a hash reference");
        ok(defined($port->{name}) && !ref($port->{name}) && length($port->{name}), "$label port '$port->{name}' has scalar name");
        like($port->{width}, qr/\A[1-9][0-9]*\z/, "$label port '$port->{name}' has positive integer width");
    }
}

sub port_width {
    my ($ports, $name) = @_;
    my ($port) = grep { $_->{name} eq $name } @{$ports || []};
    ok($port, "found port '$name'");
    return $port ? $port->{width} : undef;
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
