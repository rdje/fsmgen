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
    isf_public_interface_actor_shell_rule_shape
);

subtest 'direct ISF actor-shell rule metadata is exact' => sub {
    assert_rule_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF actor-shell rule metadata is exact' => sub {
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
        assert_rule_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public parser facades return advertised actor rule shape' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'full_featured.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    assert_rule_shape($adapter->parse_file($path), 'parse_file actor shell');
    assert_rule_shape($adapter->parse_source($source, 'inline-full-featured.isf'), 'parse_source actor shell');

    my $apb_path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $apb_actor = $adapter->parse_file($apb_path);
    ok(ref($apb_actor->{rules}) eq 'ARRAY', 'rule-free APB actor still exposes a rules array');
    is(scalar(@{$apb_actor->{rules}}), 0, 'rule-free APB actor exposes an empty rules array');
};

subtest 'public parser rejects rules that cannot satisfy the advertised shell shape' => sub {
    my $source = <<'ISF';
(actor bad_rule
  (clock clk)
  (interface
    (input start)
    (output done))
  (rule (always_ready)
    (done 1)))
ISF

    my $ok = eval { FSM::Adapter::ISF->new()->parse_source($source, 'bad-rule.isf'); 1 };
    my $diagnostic = $@;

    ok(!$ok, 'nested rule name fails before returning malformed rule metadata');
    ok(!ref($diagnostic), 'nested rule name diagnostic is scalar');
    like(
        $diagnostic,
        qr/\AError: \(rule \.\.\.\) requires a scalar name/,
        'nested rule name diagnostic is bounded to rule validation',
    );
};

done_testing();

sub assert_rule_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{actor_shell_rule_shape},
        isf_public_interface_actor_shell_rule_shape(),
        "$label actor_shell_rule_shape is exact",
    );
}

sub assert_rule_shape {
    my ($actor, $label) = @_;
    my $rules = $actor->{rules};

    ok(ref($rules) eq 'ARRAY', "$label rules is an array reference");
    ok(@$rules > 0, "$label includes rule entries");

    for my $rule (@$rules) {
        ok(ref($rule) eq 'HASH', "$label rule entry is a hash reference");
        ok(defined($rule->{name}) && !ref($rule->{name}) && length($rule->{name}), "$label rule '$rule->{name}' has scalar name");
        ok(!exists($rule->{when}) || !ref($rule->{when}) || ref($rule->{when}) eq 'ARRAY', "$label rule '$rule->{name}' has optional when clause");
        ok(ref($rule->{actions}) eq 'ARRAY', "$label rule '$rule->{name}' has actions array");
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
