#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMStaticValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $built = build_plan();
ok($built->{ok}, 'checked VIAL/HIAL fixture reaches native UVM stimulus/service inputs');
diag(JSON::PP->new->canonical(1)->encode($built->{diagnostics})) unless $built->{ok};
my $emission = emit_backend();
ok($emission->{ok}, 'native UVM stimulus/service emission succeeds');
diag(JSON::PP->new->canonical(1)->encode($emission->{diagnostics})) unless $emission->{ok};

subtest 'transaction items and public scenarios preserve typed immutable-plan stimulus' => sub {
    my $services = artifact('uvm_stimulus_services')->{content};
    like($services,
        qr/class base_output_arbitration_ahb_write_item extends uvm_sequence_item;/,
        'one reusable typed transaction item is emitted');
    for my $field (
        [address => qr/logic \[31:0\] address;/],
        [transfer => qr/logic \[1:0\] transfer;/],
        [write => qr/bit write;/],
        [size => qr/logic \[2:0\] size;/],
        [data => qr/logic \[31:0\] data;/],
        [wait_cycles => qr/bit \[3:0\] wait_cycles;/],
    ) {
        like($services, $field->[1], "transaction field '$field->[0]' keeps its selected type");
    }
    like($services, qr/virtual function void do_copy\(uvm_object rhs\);/,
        'item copy behavior is explicit');
    like($services, qr/virtual function bit do_compare\(uvm_object rhs, uvm_comparer comparer\);/,
        'item comparison behavior is explicit');
    like($services, qr/virtual function void do_print\(uvm_printer printer\);/,
        'item printing behavior is explicit');
    unlike($services, qr/`uvm_field_/,
        'item fields use no reflection-heavy field macro');

    like($services,
        qr/class base_output_arbitration_success_sequence extends uvm_sequence#\(base_output_arbitration_ahb_write_item\);/,
        'success scenario owns one generated sequence');
    like($services,
        qr/class base_output_arbitration_unsupported_size_sequence extends uvm_sequence#\(base_output_arbitration_ahb_write_item\);/,
        'unsupported-size scenario owns one generated sequence');
    is(scalar(() = $services =~ /\bstart_item\(request\);/g), 2,
        'the two public start operations emit two sequence-item handshakes');
    is(scalar(() = $services =~ /\bfinish_item\(request\);/g), 2,
        'every emitted sequence-item handshake is closed');
    like($services, qr/request\.data = 32'hcafebabe;/,
        'success sequence retains the exact authored data value');
    like($services, qr/request\.data = 32'hffffffff;/,
        'unsupported-size sequence retains its exact pre-fault data value');
    like($services, qr/decision\.replay_selected\(4'h2\);/,
        'portable wait decision replays the immutable accepted value');
    like($services, qr/request\.wait_cycles = decision\.accepted_value;/,
        'sequence consumes the replayed decision value');
    unlike($services, qr/decision\.solve_native_preview\s*\(/,
        'generated public scenario never invokes the native solver preview');
};

subtest 'native constraint preview is bounded and isolated from portable replay' => sub {
    my $services = artifact('uvm_stimulus_services')->{content};
    like($services, qr/rand bit \[3:0\] candidate;/,
        'native decision candidate keeps the selected width and state domain');
    like($services, qr/constraint selected_domain_c \{\s+candidate inside \{\[4'h1:4'h2\]\};/s,
        'native decision domain mirrors the selected distribution bounds');
    like($services, qr/attempt_bound = 64;/,
        'native solver preview has an explicit attempt bound');
    like($services, qr/this\.srandom\(seed\);/,
        'native solver preview accepts an explicit seed');
    like($services, qr/for \(attempt_count = 1; attempt_count <= attempt_bound; attempt_count\+\+\)/,
        'native solver preview cannot retry without bound');
    like($services, qr/function void replay_selected\(bit \[3:0\] selected\);/,
        'fixed replay remains a distinct operation');
    is($emission->{backend_manifest}{capability_evidence}{public_authoring_boundary}
        {native_constraint_solving}, 'private_typed_preview_not_executed',
        'manifest labels native solving private and unexecuted');
};

subtest 'active agent, factory, and scoped configuration stay compiler-owned' => sub {
    my $fixture = artifact('uvm_fixture_package')->{content};
    my $interface = artifact('uvm_fixture_interface')->{content};
    my $top = artifact('uvm_fixture_top')->{content};
    like($fixture, qr/class base_output_arbitration_sequencer extends uvm_sequencer#/,
        'active agent has a typed sequencer');
    like($fixture, qr/class base_output_arbitration_driver_base extends uvm_driver#/,
        'active agent has a typed driver base');
    like($fixture,
        qr/base_output_arbitration_driver_base::get_type\(\), base_output_arbitration_driver::get_type\(\),\s*"uvm_test_top\.env\.agent\.driver"/,
        'one exact compiler-selected instance driver override is emitted');
    like($fixture, qr/driver\.seq_item_port\.connect\(sequencer\.seq_item_export\);/,
        'driver and sequencer connect explicitly');
    like($fixture, qr/cfg\.vif\.driver_cb\.HADDR <= request\.address;/,
        'driver maps typed address intent through the clocking block');
    like($fixture, qr/cfg\.vif\.driver_cb\.HWDATA <= request\.data;/,
        'driver maps typed data intent through the clocking block');
    like($fixture, qr/while \(cfg\.vif\.driver_cb\.HREADYOUT !== 1'b1\);/,
        'driver waits through the declared ready output');
    unlike($fixture, qr/uvm_config_db\s*#.*::(?:set|get)\([^\n]*"[^"\n]*\*/,
        'configuration uses no wildcard hierarchy path');
    like($interface, qr/output HADDR, HSEL, HSIZE, HTRANS, HWDATA, HWRITE, wait_cycles;/,
        'driver clocking block owns only selected transaction/control inputs');
    unlike($interface, qr/output [^;]*\b(?:HREADY|rst_n)\b/,
        'driver clocking block does not own reset or ready loopback');
    like($top, qr/assign vial_if\.HREADY = vial_if\.HREADYOUT;/,
        'top emits the declared ready loopback exactly once');
};

subtest 'analysis TLM and RAL preview are explicit, typed, and connected' => sub {
    my $services = artifact('uvm_stimulus_services')->{content};
    my $fixture = artifact('uvm_fixture_package')->{content};
    like($fixture, qr/uvm_analysis_port#\(base_output_arbitration_ahb_write_item\) driven_ap;/,
        'driver publishes typed immutable transaction clones');
    like($fixture, qr/uvm_analysis_port#\(base_output_arbitration_ahb_write_item\) observed_ap;/,
        'monitor publishes typed observed transactions');
    like($services,
        qr/class base_output_arbitration_transaction_observer extends uvm_subscriber#\(base_output_arbitration_ahb_write_item\);/,
        'analysis subscriber is typed');
    like($fixture, qr/uvm_tlm_analysis_fifo#\(base_output_arbitration_ahb_write_item\) driven_fifo;/,
        'analysis FIFO is typed');
    like($fixture, qr/driver\.driven_ap\.connect\(driven_fifo\.analysis_export\);/,
        'driver analysis path is connected');
    like($fixture, qr/monitor\.observed_ap\.connect\(transaction_observer\.analysis_export\);/,
        'monitor subscriber path is connected');
    like($fixture, qr/monitor\.observed_ap\.connect\(ral_predictor\.bus_in\);/,
        'monitor RAL prediction path is connected');

    like($services, qr/class base_output_arbitration_reg_data_reg extends uvm_reg;/,
        'fixture RAL register preview is source-mapped to the declared probe');
    like($services, qr/value\.configure\(this, 32, 0, "RO", 0, 32'h00000000, 1, 0, 0\);/,
        'RAL field records exact width, access, and reset preview');
    like($services, qr/class base_output_arbitration_reg_block extends uvm_reg_block;/,
        'RAL block preview is emitted');
    like($services, qr/default_map\.add_reg\(reg_data, 0, "RO"\);/,
        'RAL preview map is explicit');
    like($services, qr/class base_output_arbitration_reg_adapter extends uvm_reg_adapter;/,
        'typed RAL adapter is emitted');
    like($services, qr/class base_output_arbitration_reg_predictor extends uvm_reg_predictor#/,
        'typed RAL predictor is emitted');
    like($fixture, qr/ral_predictor\.map = ral_model\.default_map;/,
        'predictor receives the generated map');
    like($fixture, qr/ral_predictor\.adapter = ral_adapter;/,
        'predictor receives the generated adapter');
};

subtest 'source maps and capability states cover the selected services honestly' => sub {
    my %role;
    push @{$role{$_->{role}}}, $_ for @{$emission->{source_map}{entries}};
    for my $expected (qw(
        typed_sequence_item native_constrained_decision_preview
        portable_decision_replay scenario_sequence
        analysis_transaction_subscriber ral_register_preview ral_block_preview
        ral_adapter_preview ral_predictor_preview typed_transaction_sequencer
        typed_transaction_driver_base compiler_selected_transaction_driver
        active_timed_interface_agent analysis_tlm_and_ral_connections
        scoped_factory_role_substitution declared_ready_loopback
    )) {
        ok($role{$expected} && @{$role{$expected}}, "source map covers '$expected'");
    }
    is(scalar(@{$role{transaction_item_field} || []}), 6,
        'source map contains one entry per selected transaction field');
    is(scalar(@{$role{scenario_sequence} || []}), 2,
        'source map contains one entry per selected public scenario');
    is_deeply(
        [sort map { $_->{generated_symbol} } @{$role{transaction_item_field}}],
        [sort qw(address transfer write size data wait_cycles)],
        'transaction field source-map symbols are exact',
    );

    my $evidence = $emission->{backend_manifest}{capability_evidence};
    is_deeply(
        $evidence->{deferred_to_later_emission_slices},
        [qw(coverage properties models scoreboards faults results)],
        'only later semantic-family emission remains deferred');
    is($evidence->{fixture_compile}, 'not_run', 'fixture compile remains not run');
    is($evidence->{runtime}, 'not_run', 'runtime remains not run');
    is($evidence->{result}, 'not_produced', 'runtime result remains absent');
    is($evidence->{parity}, 'not_evaluated', 'parity remains unevaluated');
};

subtest 'static negative oracles reject missing or unsafe service structure' => sub {
    my @source = map { clone($_) }
        grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}};

    my @missing = grep { $_->{role} ne 'uvm_stimulus_services' } @source;
    static_failure(\@missing, 'VIAL_UVM_STATIC_REQUIRED_ROLE_ERROR',
        'missing stimulus/service package');

    my @rerandomized = map { clone($_) } @source;
    artifact_in(\@rerandomized, 'uvm_stimulus_services')->{content}
        =~ s/decision\.replay_selected\(4'h2\);/decision.solve_native_preview();/
        or die "decision-replay mutation did not apply\n";
    static_failure(\@rerandomized, 'VIAL_UVM_STATIC_SERVICE_SHAPE_ERROR',
        'portable decision rerandomization');

    my @ral = map { clone($_) } @source;
    artifact_in(\@ral, 'uvm_stimulus_services')->{content}
        =~ s/\buvm_reg_predictor\b/uvm_unselected_predictor/
        or die "RAL-predictor mutation did not apply\n";
    static_failure(\@ral, 'VIAL_UVM_STATIC_SERVICE_SHAPE_ERROR',
        'missing typed RAL predictor');

    my @factory = map { clone($_) } @source;
    artifact_in(\@factory, 'uvm_fixture_package')->{content}
        =~ s/\bset_inst_override_by_type\b/set_unselected_override/
        or die "factory-override mutation did not apply\n";
    static_failure(\@factory, 'VIAL_UVM_STATIC_SERVICE_WIRING_ERROR',
        'missing compiler-owned factory override');

    my @wildcard = map { clone($_) } @source;
    artifact_in(\@wildcard, 'uvm_fixture_package')->{content}
        =~ s/"monitor", "cfg"/"*", "cfg"/
        or die "wildcard-configuration mutation did not apply\n";
    static_failure(\@wildcard, 'VIAL_UVM_STATIC_SERVICE_WIRING_ERROR',
        'wildcard configuration scope');
};

done_testing;

sub build_plan {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub emit_backend {
    return FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-native-uvm-stimulus-services',
        backend_profile => $profile,
    });
}

sub artifact {
    my ($role) = @_;
    my @artifact = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    die "artifact role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub artifact_in {
    my ($artifacts, $role) = @_;
    my @artifact = grep { $_->{role} eq $role } @$artifacts;
    die "test fixture role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub static_failure {
    my ($artifacts, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::SVUVMStaticValidator->validate({
        backend_profile => $profile,
        artifacts => $artifacts,
    });
    ok(!$result->{ok}, "$label fails closed");
    ok((grep { $_->{code} eq $code } @{$result->{diagnostics}}),
        "$label has exact diagnostic");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
