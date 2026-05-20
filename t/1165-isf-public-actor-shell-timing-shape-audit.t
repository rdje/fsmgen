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
    isf_public_interface_actor_shell_timing_shape
);

subtest 'direct ISF actor-shell timing metadata is exact' => sub {
    assert_timing_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF actor-shell timing metadata is exact' => sub {
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
        assert_timing_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public parser facades return advertised actor timing shape' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    assert_apb_timing_shape($adapter->parse_file($path), 'parse_file actor shell');
    assert_apb_timing_shape($adapter->parse_source($source, 'inline-apb-requester.isf'), 'parse_source actor shell');

    my $minimal = $adapter->parse_source(<<'ISF', 'minimal-timing.isf');
(actor minimal_timing
  (interface
    (input start)))
ISF

    is($minimal->{clock}, 'clk', 'minimal actor defaults omitted clock to clk');
    is_deeply(
        $minimal->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'minimal actor defaults omitted reset to async active-low rst_n',
    );
    is($minimal->{watchdog}, '65535', 'minimal actor defaults omitted watchdog to 65535');
};

subtest 'public parser rejects timing declarations that cannot satisfy the advertised shape' => sub {
    my $adapter = FSM::Adapter::ISF->new();

    for my $case (
        [
            'nested clock name',
            <<'ISF',
(actor bad_clock
  (clock (clk))
  (interface
    (input start)))
ISF
            qr/\AError: \(clock \.\.\.\) requires a scalar name/,
        ],
        [
            'nested reset name',
            <<'ISF',
(actor bad_reset
  (clock clk)
  (reset ((rst_n) async active_low))
  (interface
    (input start)))
ISF
            qr/\AError: \(reset \.\.\.\) requires a scalar name/,
        ],
        [
            'non-integer watchdog',
            <<'ISF',
(actor bad_watchdog
  (clock clk)
  (watchdog slow)
  (interface
    (input start)))
ISF
            qr/\AError: \(watchdog \.\.\.\) requires a positive integer/,
        ],
    ) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { $adapter->parse_source($source, "$label.isf"); 1 };
        my $diagnostic = $@;

        ok(!$ok, "$label fails before returning malformed timing metadata");
        ok(!ref($diagnostic), "$label diagnostic is scalar");
        like($diagnostic, $pattern, "$label diagnostic is bounded to timing validation");
    }
};

done_testing();

sub assert_timing_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{actor_shell_timing_shape},
        isf_public_interface_actor_shell_timing_shape(),
        "$label actor_shell_timing_shape is exact",
    );
}

sub assert_apb_timing_shape {
    my ($actor, $label) = @_;

    is($actor->{clock}, 'clk', "$label clock preserves the scalar actor clock");
    ok(ref($actor->{reset}) eq 'HASH', "$label reset is a hash reference");
    is($actor->{reset}{name}, 'rst_n', "$label reset name is scalar");
    is($actor->{reset}{kind}, 'async', "$label reset kind is scalar");
    is($actor->{reset}{polarity}, 'active_low', "$label reset polarity is scalar");
    like($actor->{watchdog}, qr/\A[1-9][0-9]*\z/, "$label watchdog is a positive integer");
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
