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
    isf_public_interface_actor_shell_drive_shape
);

subtest 'direct ISF actor-shell drive metadata is exact' => sub {
    assert_drive_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF actor-shell drive metadata is exact' => sub {
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
        assert_drive_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public parser facades return advertised actor drive shape' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    assert_drive_shape($adapter->parse_file($path), 'parse_file actor shell');
    assert_drive_shape($adapter->parse_source($source, 'inline-apb-requester.isf'), 'parse_source actor shell');
};

subtest 'public parser rejects drives that cannot satisfy the advertised shell shape' => sub {
    my $adapter = FSM::Adapter::ISF->new();

    for my $case (
        [
            'nested drive name',
            <<'ISF',
(actor bad_drive_name
  (clock clk)
  (interface
    (output done))
  (drive ((done_phase))
    (done 1)))
ISF
            qr/\AError: \(drive \.\.\.\) requires a scalar name/,
        ],
        [
            'nested drive parameter',
            <<'ISF',
(actor bad_drive_param
  (clock clk)
  (interface
    (output done))
  (drive (done_phase (value))
    (done value)))
ISF
            qr/\AError: drive 'done_phase' parameter names must be scalar/,
        ],
    ) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { $adapter->parse_source($source, "$label.isf"); 1 };
        my $diagnostic = $@;

        ok(!$ok, "$label fails before returning malformed drive metadata");
        ok(!ref($diagnostic), "$label diagnostic is scalar");
        like($diagnostic, $pattern, "$label diagnostic is bounded to drive validation");
    }
};

done_testing();

sub assert_drive_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{actor_shell_drive_shape},
        isf_public_interface_actor_shell_drive_shape(),
        "$label actor_shell_drive_shape is exact",
    );
}

sub assert_drive_shape {
    my ($actor, $label) = @_;
    my $drives = $actor->{drives};

    ok(ref($drives) eq 'HASH', "$label drives is a hash reference");
    ok(exists($drives->{psel}), "$label includes parameterized psel drive");
    ok(exists($drives->{setup_phase}), "$label includes simple setup_phase drive");

    for my $name (sort keys %$drives) {
        my $drive = $drives->{$name};
        ok(length($name), "$label drive key '$name' is non-empty");
        ok(ref($drive) eq 'HASH', "$label drive '$name' entry is a hash reference");
        ok(ref($drive->{params}) eq 'ARRAY', "$label drive '$name' params is an array reference");
        ok(ref($drive->{body}) eq 'ARRAY', "$label drive '$name' body is an array reference");
        for my $param (@{$drive->{params}}) {
            ok(defined($param) && !ref($param) && length($param), "$label drive '$name' param '$param' is scalar");
        }
    }

    is_deeply($drives->{psel}{params}, ['val'], "$label parameterized psel drive keeps scalar param list");
    is_deeply($drives->{setup_phase}{params}, [], "$label simple setup_phase drive has empty params list");
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
