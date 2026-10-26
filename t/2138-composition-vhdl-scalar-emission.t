use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Composition::RTLChildRealizer;
use FSM::Composition::GeneratedChildRealizer;
use FSM::Composition::Plan;
use FSM::Composition::RealizedInstance;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(signal_ref_binding);
use FSM::Pipeline::HDLGenerator;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::SourcePathResolver;
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-vhdl-scalar-emission.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
my $resolver = FSM::SourcePathResolver->new;
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec=>$spec,
    fsm_file=>$path, source_path_resolver=>$resolver);
my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet=>1, target_language=>'vhdl');
my $loader = FSM::Composition::RTLInterfaceLoader->new(path_resolver=>$resolver);
my @children;
for my $instance (@{$spec->top->instances}) {
    my %args = (instance=>$instance, composition_spec=>$spec, fsm_file=>$path, target_language=>'vhdl');
    if ($instance->kind eq 'rtl') {
        push @children, FSM::Composition::RTLChildRealizer->realize_rtl_child_instance(%args, rtl_interface_loader=>$loader);
    } else {
        my $method = $instance->kind eq 'fsmc' ? 'realize_fsmc_child_instance' : 'realize_dtc_child_instance';
        push @children, FSM::Composition::GeneratedChildRealizer->$method(%args, pipeline=>$pipeline,
            header=>'?top:vhdl_scalar_top', source_path_resolver=>$resolver);
    }
}
# Realization owns parameter/declaration evidence; connect its actual ports to
# declared top ports before asking the prepared structural emitter for HDL.
@children = map {
    my $child = $_;
    FSM::Composition::RealizedInstance->new(
        kind=>$child->kind, instance_name=>$child->instance_name, module_name=>$child->module_name,
        source_name=>$child->source_name, interface_ports=>$child->interface_ports,
        parameter_overrides=>$child->parameter_overrides, module_info=>$child->module_info,
        hdl_code=>$child->hdl_code, port_bindings=>[map {
            signal_ref_binding($_->name, $_->name eq 'ready' ? $child->kind.'_ready' : $_->name)
        } @{$child->interface_ports}],
    );
} @children;
my $plan = FSM::Composition::Plan->new(top_name=>$spec->top->name, raw_spec=>$spec,
    ports=>$spec->top->ports_blocks->[0]->ports, instances=>\@children);
my $ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
$ir->{target_language} = 'vhdl';
sub emit { FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($_[0]) }
sub refuses {
    my ($label,$change,$pattern) = @_;
    my $input = copy($ir); $change->($input); my $before = $json->encode($input);
    my $ok = eval {emit($input);1}; my $error = $@;
    ok(!$ok,"$label refuses"); like($error,$pattern,"$label names the boundary");
    is($json->encode($input),$before,"$label preserves caller data");
}
my $expected = <<'HDL';
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vhdl_scalar_top is
  generic (
    WIDTH : natural := 16;
    COPY : natural := WIDTH;
    EQUAL : natural := 16;
    TOTAL : natural := (COPY + 2)
  );
  port (
    clk : in std_logic;
    rstn : in std_logic;
    rtl_ready : out std_logic;
    fsmc_ready : out std_logic;
    dtc_ready : out std_logic
  );
end entity vhdl_scalar_top;

architecture rtl of vhdl_scalar_top is
begin
  rtl_child : entity work.scalar_rtl
    generic map (
      COUNT => TOTAL,
      OTHER => EQUAL,
      STATIC => 2
    )
    port map (
      clk => clk,
      ready => rtl_ready
    );
  fsm_child : entity work.scalar_fsm
    generic map (
      COUNT => TOTAL,
      OTHER => EQUAL,
      STATIC => 2
    )
    port map (
      clk => clk,
      rstn => rstn,
      ready => fsmc_ready
    );
  dt_child : entity work.scalar_dt
    generic map (
      COUNT => TOTAL,
      OTHER => EQUAL,
      STATIC => 2
    )
    port map (
      ready => dtc_ready
    );
end architecture rtl;
HDL
chomp $expected;
subtest 'actual parsed children and captured IR emit exact natural defaults and integer actuals' => sub {
    for my $child (@children[1,2]) {
        like($child->hdl_code, qr/COUNT\s*:\s*integer\s*:=\s*8/, 'actual generated child declares an integer generic');
    }
    my $text = eval {emit($ir)};
    is($@,'','prepared VHDL scalar profile emits');
    is($text,$expected,'complete literal expected HDL preserves default order and selected child references');
    is(emit(FSM::IR::StructuralRTLIR->new(%$ir)),$expected,'object and hash entrypoints agree');
    my $input = copy($ir);
    $input->{parameter_environment}{parameters}{WIDTH}{value_text} = '999';
    $input->{parameter_environment}{parameters}{WIDTH}{value_payload}{payload} = '999';
    $_->{value_text} = 'WRONG_CACHE' for map {grep {exists $_->{binding_expression}} @{$_->{parameter_overrides}}} @{$input->{instances}};
    is(emit($input),$expected,'default and actual validation caches cannot supply emitted values');
};
subtest 'declaration types, scopes, identifiers and pending widths refuse explicitly' => sub {
    refuses('missing default evidence',sub {delete $_[0]{instances}[0]{parameter_overrides}[0]{declaration_default_value_text}},qr/declaration.*evidence|integer.*declaration/);
    refuses('wrong declaration payload',sub {$_[0]{instances}[0]{parameter_overrides}[0]{declaration_default_value_payload}{payload}="8'h08"},qr/declaration.*evidence|integer.*declaration/);
    refuses('sized child default',sub {my $p=$_[0]{instances}[0]{parameter_overrides}[0];$p->{declaration_default_value_text}="8'h08";$p->{declaration_default_value_payload}{payload}="8'h08"},qr/integer.*declaration|decimal.*declaration/);
    refuses('aggregate child declaration',sub {$_[0]{instances}[0]{parameter_overrides}[0]{declaration_default_value_kind}='list'},qr/scalar|integer.*declaration/);
    refuses('unknown child default type',sub {delete $_[0]{instances}[0]{parameter_overrides}[0]{declaration_default_value_type_spec}},qr/declaration.*evidence|integer.*declaration/);
    refuses('foreign binding scope',sub {$_[0]{instances}[0]{parameter_overrides}[0]{binding_expression}{scope}{owner}='other'},qr/scope/);
    refuses('VHDL generic keyword',sub {$_[0]{instances}[0]{parameter_overrides}[0]{name}='SIGNAL'},qr/reserved/);
    refuses('bad child module identifier',sub {$_[0]{instances}[0]{module_name}='bad__module'},qr/identifier/);
    refuses('case-folded child generic collision',sub {$_[0]{instances}[0]{parameter_overrides}[1]{name}='count'},qr/duplicate.*generic|generic.*collid/i);
    refuses('top port collision',sub {$_[0]{ports}[0]{name}='width'},qr/WIDTH.*port/);
    refuses('missing environment',sub {delete $_[0]{parameter_environment}},qr/symbolic parameter binding.*blocked/s);
    refuses('incomplete port width',sub {$_[0]{ports}[0]{width_contract}={}},qr/width.*complete width contract/s);
};
subtest 'static formatting and profile discovery keep exact boundaries' => sub {
    my $static = copy($ir); delete $static->{parameter_environment};
    delete $_->{binding_expression} for map {@{$_->{parameter_overrides}}} @{$static->{instances}};
    $static->{instances}[0]{parameter_overrides}[1]{name} = 'count';
    my $ok = eval {emit($static);1};
    ok(!$ok, 'static child generic collisions also refuse');
    like($@,qr/duplicate.*generic|generic.*collid/i,'static collision names the same target namespace boundary');
    $static->{instances}[0]{parameter_overrides}[1]{name} = 'SIGNAL';
    $ok = eval {emit($static);1};
    ok(!$ok, 'static child generic keywords also refuse');
    like($@,qr/reserved in VHDL/,'static keyword refusal names the target rule');
    for my $target (qw(vhdl VHDL)) {
        is(emit({module_name=>'static_top',target_language=>$target,ports=>[],nets=>[],instances=>[]}),
            "library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n\nentity static_top is\nend entity static_top;\n\narchitecture rtl of static_top is\nbegin\nend architecture rtl;",'ordinary complete static byte shape stays exact');
    }
    my $contract = build_composition_parameter_contract();
    is_deeply($contract->{prepared_vhdl_scalar_emission},{top_defaults=>JSON::PP::true,
        natural_to_integer_child_actuals=>JSON::PP::true,symbolic_port_widths=>JSON::PP::true,
        source_admission=>JSON::PP::false},'discovery describes only the prepared VHDL subset');
    ok(!$contract->{public_source_planning_supported} && !$contract->{hdl_emission_supported},'complete source/HDL support remains unqualified');
};
done_testing;
