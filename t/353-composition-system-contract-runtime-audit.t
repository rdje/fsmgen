#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::NormalizedSemanticReport qw(
    build_normalized_semantic_success_report
);
use FSM::Support::NormalizedSemanticSystemContract qw(
    normalized_semantic_system_contract_presence_keys
);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $composition_path = repo_file('fsm/apb_tb.fsm');
my $expected_system_contract = {
    clock => 'clk',
    reset => 'rst_n',
    reset_keyword => 'areset',
    reset_kind => 'async',
    reset_active_level => 0,
    declare_ports => 1,
    implicit => 1,
};

subtest 'composition intent_hir infers one effective shared system contract from agreeing children' => sub {
    my $result = generate_result($composition_path);

    assert_keys_present(
        $result->{intent_hir}{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'composition intent_hir system_contract keeps bounded keys',
    );
    assert_keys_present(
        $result->{module_info}{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'composition module_info system_contract keeps bounded keys',
    );

    assert_expected_system_contract(
        $result->{intent_hir}{system_contract},
        'composition intent_hir system_contract recovers the shared child contract',
    );
    assert_expected_system_contract(
        $result->{module_info}{system_contract},
        'composition module_info system_contract mirrors the inferred child contract',
    );
    ok(
        exists $result->{intent_hir}{explicit_system_contract}
            && !defined $result->{intent_hir}{explicit_system_contract},
        'composition intent_hir keeps explicit_system_contract absent when the top did not author one',
    );
};

subtest 'composition normalized semantic success report keeps the bounded inferred system_contract shape' => sub {
    my $result = generate_result($composition_path);
    my $report = build_normalized_semantic_success_report(
        input => 'protocol.apb_tb',
        source_file => $composition_path,
        target_language => 'systemverilog',
        strict_mode => 1,
        result => $result,
        module_info => $result->{module_info},
    );

    assert_keys_present(
        $report->{semantic}{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'composition semantic report system_contract keeps bounded keys',
    );
    assert_expected_system_contract(
        $report->{semantic}{system_contract},
        'composition semantic report system_contract preserves the inferred child contract',
    );
    ok(
        exists $report->{semantic}{explicit_system_contract}
            && !defined $report->{semantic}{explicit_system_contract},
        'composition semantic report keeps explicit_system_contract null when the top did not author one',
    );
};

subtest 'composition CLI semantic JSON export preserves the inferred system_contract shape' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $composition_path],
    );

    ok($success, 'semantic JSON export succeeds for the APB composition fixture');
    is(join('', @{$stderr_buf || []}), '', 'semantic JSON export keeps stderr clean');

    my $decoded = decode_json(join('', @{$stdout_buf || []}));
    assert_keys_present(
        $decoded->{semantic}{system_contract},
        normalized_semantic_system_contract_presence_keys(),
        'composition semantic JSON system_contract keeps bounded keys',
    );
    assert_expected_system_contract(
        $decoded->{semantic}{system_contract},
        'composition semantic JSON system_contract preserves the inferred child contract',
    );
    ok(
        exists $decoded->{semantic}{explicit_system_contract}
            && !defined $decoded->{semantic}{explicit_system_contract},
        'composition semantic JSON keeps explicit_system_contract null when the top did not author one',
    );
};

done_testing();

sub generate_result {
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relpath);
}

sub assert_keys_present {
    my ($payload, $keys, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    for my $key (@{$keys || []}) {
        ok(exists $payload->{$key}, "$label: keeps key $key");
    }
}

sub assert_expected_system_contract {
    my ($payload, $label) = @_;
    ok(ref($payload) eq 'HASH', "$label: payload is a hash");
    return unless ref($payload) eq 'HASH';

    is($payload->{clock}, $expected_system_contract->{clock}, "$label: keeps expected clock");
    is($payload->{reset}, $expected_system_contract->{reset}, "$label: keeps expected reset");
    is($payload->{reset_keyword}, $expected_system_contract->{reset_keyword}, "$label: keeps expected reset keyword");
    is($payload->{reset_kind}, $expected_system_contract->{reset_kind}, "$label: keeps expected reset kind");
    is(boolish($payload->{reset_active_level}), $expected_system_contract->{reset_active_level}, "$label: keeps expected reset active level");
    is(boolish($payload->{declare_ports}), $expected_system_contract->{declare_ports}, "$label: keeps expected declare_ports");
    is(boolish($payload->{implicit}), $expected_system_contract->{implicit}, "$label: keeps expected implicit flag");
}

sub boolish {
    my ($value) = @_;
    return 0 unless defined $value;
    return $value ? 1 : 0 if JSON::PP::is_bool($value);
    return $value ? 1 : 0;
}
