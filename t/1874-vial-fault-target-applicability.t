#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use JSON::PP ();
use Test::More;
use lib "$FindBin::Bin/../perl";
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Tool qw(execute_vial_tool_request);

my $package = 'ahb_subordinate_base_output_arbitration';
my $fixture_id = "$package\::fixture::base_output_arbitration";
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $hial = read_file($hial_id);
my %base = map { $_ => read_file('vial/ahb_subordinate_base_output_arbitration'
    . ($_ == 2 ? '_v2' : '') . '.vial') } (1, 2);
sub envelope {
    my ($id, $text, $kind) = @_;
    return {source_id => $id, source_kind_hint => $kind, text => $text,
        encoding => 'utf-8', origin => 'repository', display_name => $id,
        canonical_id => undef, relative_path => $id, metadata => {}};
}
sub public_plan {
    my ($version, $text, $dut_id, $dut_text, $kind) = @_;
    my $sink = [];
    my $result = execute_vial_tool_request({
        schema => "fsmgen.vial_tool_request.v$version", schema_version => $version,
        action => 'plan', vial_source => envelope('fault_applicability.vial', $text, 'vial'),
        hial_source => envelope($dut_id // $hial_id, $dut_text // $hial, $kind // 'ppif'),
        options => {source_style => 'auto', output_style => undef, fixture_id => undef,
            scenario_ids => [], execution_profile => "core_directed_single_clock_execution_v$version",
            backend_profile => undef, replay_manifest => undef, native_extension_catalogs => [],
            artifact_policy => {mode => 'virtual', artifact_root => undef}, quiet => JSON::PP::false},
    }, {source_catalog => {}, artifact_sink => $sink});
    return ($result, $sink);
}
sub semantic {
    return FSM::VIAL::Parser->parse_source({text => $_[0], source_name => 'fault_applicability.vial'});
}
sub native_plan {
    my ($version, $text) = @_;
    return FSM::VIAL::PlanBuilder->build({semantic_ir => semantic($text),
        hial_source => {source_id => $hial_id, format => 'ppif', text => $hial},
        fixture_id => undef, scenario_ids => [],
        execution_profile => "core_directed_single_clock_execution_v$version",
        replay_manifest => undef, native_extension_catalog => []});
}
sub alternate {
    my ($version, $selected) = @_;
    my $text = $base{$version};
    $text =~ s/\(transaction write "transaction\/ahb_write" ahb_write\)/(transaction write "transaction\/ahb_write" ahb_write)\n            (transaction alternate "transaction\/alternate_write" ahb_write)/ or die 'missing binding';
    $text =~ s/\(target \(transaction write size\)\)/(target (transaction $selected size))/ or die 'missing fault';
    return $text;
}

subtest 'canonical target resolves uniquely through genuine execution bindings' => sub {
    for my $version (1, 2) {
        my ($public) = public_plan($version, $base{$version});
        ok($public->{success}, "v$version canonical public planning succeeds") or diag explain $public->{diagnostics};
        my $built = native_plan($version, $base{$version});
        ok($built->{ok}, 'native execution construction succeeds') or diag explain $built->{diagnostics};
        my $execution = $built->{execution_ir}->as_hashref;
        my $fault = $execution->{faults}[0];
        my @bindings = grep { $_->{transaction_semantic_id} eq $fault->{transaction_id} }
            @{$execution->{bindings}{transactions}};
        is(scalar @bindings, 1, 'fault declaration resolves to one genuine binding');
        is($bindings[0]{semantic_id}, "$fixture_id\::transaction_binding::write", 'authored alias is exact');
        is($bindings[0]{transaction_id}, 'transaction/ahb_write', 'binding reaches the real HIAL transaction');
        is($fault->{field_name}, 'size', 'execution retains selected field');
        is($fault->{substitute}{value}{value_hex}, '7', 'execution retains authored substitution');
        ok(!exists($fault->{transaction_binding_id}), 'unambiguous record retains legacy shape');
        if ($version == 1) {
            my $emitted = FSM::VIAL::Backend::SVPortableVerilator->emit({
                execution_ir => $built->{execution_ir}, bridge_manifest => $built->{bridge_manifest},
                backend_inputs => $built->{backend_inputs},
                artifact_root => '.artifacts/test/vial-fault-target-applicability',
                backend_profile => 'sv_portable_verilator'});
            ok($emitted->{ok}, 'canonical portable SV emits without compiling or executing');
            my ($tb) = grep { $_->{relpath} =~ m{/src/base_output_arbitration_tb\.sv\z} }
                @{$emitted->{artifacts}};
            like($tb->{content}, qr/HSIZE = 3'h7;/, 'selected field substitution reaches emitted drive');
            like($tb->{content}, qr/HSIZE = 3'h2;/, 'unfaulted authored drive remains present');
            ok(!scalar(grep { $_->{relpath} =~ /(?:runtime-trace|compile-transcript|run-transcript)/ }
                @{$emitted->{artifacts}}), 'emission produces no runtime evidence');
        }
    }
};

subtest 'distinct source aliases cannot invent an AHB bridge transaction' => sub {
    for my $version (1, 2) {
        for my $selected (qw(write alternate)) {
            my $text = alternate($version, $selected);
            my $ir = semantic($text);
            my $fixture = $ir->as_hashref->{packages}[0]{fixtures}[0];
            is($fixture->{faults}[0]{transaction_binding_id},
                "$fixture_id\::transaction_binding::$selected", 'source target is valid and precise');
            # Exercise only the first-party normalization seam. This does not
            # manufacture a bridge or imply that the complete plan is admitted.
            my $normalized = FSM::VIAL::ExecutionBuilder::_build_faults({
                fixture => $fixture, type_entries => [], type_by_shape => {}});
            is($normalized->[0]{transaction_binding_id}, $fixture->{faults}[0]{transaction_binding_id},
                'fault normalization preserves explicit scope');
            is($normalized->[0]{transaction_id}, "$package\::transaction::ahb_write",
                'normalization separately retains declaration identity');
            is($normalized->[0]{substitute}{value}{value_hex}, '7', 'normalization retains actual typed value');
            my ($result, $sink) = public_plan($version, $text);
            ok(!$result->{success}, 'public planning rejects unmatched bridge binding');
            is($result->{diagnostics}[0]{code}, 'VIAL_BIND_REFERENCE_ERROR', 'failure is binding-specific');
            like($result->{diagnostics}[0]{message}, qr/transaction bridge reference 'transaction\/alternate_write' is unresolved/,
                'diagnostic names the missing bridge contract');
            ok(!defined($result->{plan}), 'no partial plan');
            is_deeply($result->{artifacts}, [], 'no partial public artifacts');
            is_deeply($sink, [], 'caller artifact sink remains empty');
        }
        my $duplicate = alternate($version, 'alternate');
        $duplicate =~ s{transaction/alternate_write}{transaction/ahb_write};
        my $parsed = eval { semantic($duplicate); 1 };
        ok(!$parsed, 'reusing the same bridge ref cannot bypass the scope boundary');
        like("$@", qr/duplicate transaction bridge reference/, 'source diagnostic identifies duplicate bridge reference');
    }
};

subtest 'plain IAL1 declaration-order transactions do not grant execution support' => sub {
    my $text = <<'VIAL';
(vial (version 1) (package plain
  (imports) (types)
  (transactions (transaction command (fields (data (logic 8))) (events on complete)))
  (models) (scoreboards)
  (fixtures (fixture plain
    (dut dut (unit "unit/verification_observation_metadata")
      (domains (domain bus "domain/default"))
      (endpoints (endpoint valid "endpoint/valid" (logic 1) public_port))
      (transactions (transaction tx "transaction/main" command)))
    (instances) (coverage)
    (faults (fault changed (target (transaction tx data))
      (action (substitute #b11111111)) (duration (cycles bus 1))))
    (randomness (seed 1))
    (scenarios (scenario smoke (timeout (cycles bus 8)) (steps (reset bus 1))))))))
VIAL
    ok(semantic($text), 'plain transaction fault source is semantically valid');
    my ($result, $sink) = public_plan(1, $text, 'isf/verification_observation_metadata.isf',
        read_file('isf/verification_observation_metadata.isf'), 'isf');
    ok(!$result->{success}, 'plain IAL1 transaction is not admitted for execution');
    is($result->{diagnostics}[0]{code}, 'VIAL_BIND_EVENT_ERROR', 'correlation requirement fails precisely');
    like($result->{diagnostics}[0]{message}, qr/transaction 'transaction\/main' requires single_active correlation/,
        'declaration-order bridge metadata is not silently promoted');
    is_deeply($sink, [], 'failed correlation publishes nothing');
};

done_testing();
sub read_file {
    open my $fh, '<:raw', "$FindBin::Bin/../$_[0]" or die $!;
    local $/; my $text = <$fh>; close $fh or die $!; return $text;
}
