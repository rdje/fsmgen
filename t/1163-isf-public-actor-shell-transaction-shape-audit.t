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
    isf_public_interface_actor_shell_transaction_shape
);

subtest 'direct ISF actor-shell transaction-shape metadata is exact' => sub {
    assert_actor_shell_transaction_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF actor-shell transaction-shape metadata is exact' => sub {
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
        assert_actor_shell_transaction_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public parser facades return advertised actor-shell transaction shape' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    assert_actor_shell_transaction_shape($adapter->parse_file($path), 'parse_file actor shell');
    assert_actor_shell_transaction_shape($adapter->parse_source($source, 'inline-apb-requester.isf'), 'parse_source actor shell');
};

subtest 'public parser rejects transactions that cannot satisfy the advertised shell shape' => sub {
    my $source = <<'ISF';
(actor bad_transaction
  (clock clk)
  (interface
    (input start))
  (transaction (main)
    (on start)))
ISF

    my $ok = eval { FSM::Adapter::ISF->new()->parse_source($source, 'bad-transaction.isf'); 1 };
    my $diagnostic = $@;

    ok(!$ok, 'nested transaction name fails before returning a malformed actor shell');
    ok(!ref($diagnostic), 'nested transaction name diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: \(transaction \.\.\.\) requires a scalar name/,
        'nested transaction name diagnostic is bounded to transaction validation',
    );
};

done_testing();

sub assert_actor_shell_transaction_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{actor_shell_transaction_shape},
        isf_public_interface_actor_shell_transaction_shape(),
        "$label actor_shell_transaction_shape is exact",
    );
}

sub assert_actor_shell_transaction_shape {
    my ($actor, $label) = @_;
    my $transactions = $actor->{transactions};

    ok(ref($transactions) eq 'ARRAY', "$label transactions is an array reference");
    ok(@$transactions > 0, "$label transactions includes at least one transaction");

    for my $transaction (@$transactions) {
        ok(ref($transaction) eq 'HASH', "$label transaction entry is a hash reference");
        ok(
            defined($transaction->{name}) && !ref($transaction->{name}) && length($transaction->{name}),
            "$label transaction '$transaction->{name}' has scalar name",
        );
        ok(ref($transaction->{clauses}) eq 'ARRAY', "$label transaction '$transaction->{name}' has clauses array");
    }
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
