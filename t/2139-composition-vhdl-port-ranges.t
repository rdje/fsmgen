use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::SourcePathResolver;
use FSM::Support::CompositionParameterContract qw(build_composition_parameter_contract);

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $path = 't/data/composition-vhdl-port-ranges.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $plan = FSM::Composition::Plan->new(top_name => $spec->top->name, raw_spec => $spec,
    ports => $spec->top->ports_blocks->[0]->ports);
my $ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan)->as_hashref;
$ir->{target_language} = 'vhdl';
sub emit { FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($_[0]) }
sub port { my ($input, $name) = @_; return (grep {$_->{name} eq $name} @{$input->{ports}})[0] }
sub refuses {
    my ($label, $change, $pattern) = @_;
    my $input = copy($ir); $change->($input); my $before = $json->encode($input);
    my $ok = eval {emit($input);1}; my ($error) = split /\n/, $@;
    ok(!$ok, "$label refuses"); like($error, $pattern, "$label identifies the boundary");
    is($json->encode($input), $before, "$label preserves caller data");
}
sub expression {
    my ($input, $tree, $references) = @_;
    my $contract = port($input, 'data')->{width_contract};
    $contract->{expression} = $tree; $contract->{references} = $references // [];
}
my $expected = <<'HDL';
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vhdl_range_top is
  generic (
    W : natural := 1;
    COPY : natural := W;
    SAME : natural := 1
  );
  port (
    clk : in std_logic;
    fixed : in std_logic_vector(2 downto 0);
    data : in std_logic_vector((COPY - 1) downto 0);
    result : out std_logic_vector((((W * 6) / 2) - 1) downto 0);
    folded : in std_logic_vector((4 - 1) downto 0);
    remainder : in std_logic_vector((((COPY mod 3) + 1) - 1) downto 0)
  );
end entity vhdl_range_top;

architecture rtl of vhdl_range_top is
begin
end architecture rtl;
HDL
chomp $expected;
subtest 'actual parsed Plan and IR preserve VHDL vector range identities and static formatting' => sub {
    my $before = $json->encode($ir);
    my $text = eval {emit($ir)};
    is($@, '', 'prepared captured VHDL ranges emit');
    is($text, $expected, 'complete independently expected module retains aliases, arithmetic and one-bit vectors');
    return unless defined $text;
    is(emit(FSM::IR::StructuralRTLIR->new(%$ir)), $expected, 'object entrypoint preserves complete output');
    my $input = copy($ir);
    port($input, $_)->{width} = 999 for qw(data result folded remainder);
    is(emit($input), $expected, 'numeric port width caches cannot replace source ranges');
    port($input, 'data')->{signed} = 1;
    port($input, 'data')->{state_model} = 'two_state';
    like(emit($input), qr/data : in signed\(\(COPY - 1\) downto 0\)/,
        'signed range retains the existing VHDL state representation');
    port($input, 'data')->{width_contract}{expression} = ['param', [['SAME']]];
    port($input, 'data')->{width_contract}{references}[0]{token} = 'SAME';
    like(emit($input), qr/data : in signed\(\(SAME - 1\) downto 0\)/,
        'equal-default selected identity and singleton selector wrappers survive');
    is($json->encode($ir), $before, 'source and nested captured IR remain unchanged');
};
subtest 'hostile contracts refuse without numeric fallback' => sub {
    refuses('foreign scope', sub {port($_[0], 'data')->{width_contract}{scope}{owner} = 'other'}, qr/width.*scope/i);
    refuses('missing lookup', sub {port($_[0], 'data')->{width_contract}{references} = []}, qr/width.*lookup/i);
    refuses('wrong identity', sub {port($_[0], 'data')->{width_contract}{references}[0]{token} = 'W'}, qr/width.*lookup/i);
    refuses('wrong lookup kind', sub {port($_[0], 'data')->{width_contract}{references}[0]{kind} = 'static_symbol'}, qr/width.*lookup/i);
    refuses('extra lookup', sub {push @{port($_[0], 'data')->{width_contract}{references}}, {kind=>'parameter',token=>'W'}}, qr/width.*lookup/i);
    refuses('unknown parameter', sub {expression($_[0], ['param','MISSING'], [{kind=>'parameter',token=>'MISSING'}])}, qr/width.*parameter/i);
    refuses('missing contract', sub {port($_[0], 'data')->{width_contract} = {}}, qr/width.*contract/i);
    refuses('raw expression', sub {expression($_[0], 'W + 1')}, qr/width.*lookup/i);
    refuses('aggregate static', sub {port($_[0], 'result')->{width_contract}{references}[1]{value_payload} = {kind=>'list',items=>[]}}, qr/aggregate payload/);
    refuses('declared type conflict', sub {port($_[0], 'data')->{declared_type_name} = 'custom'}, qr/width.*declared type/i);
    refuses('zero width', sub {expression($_[0], ['-',1,1])}, qr/positive integer width/);
    refuses('negative width', sub {expression($_[0], ['-',1,2])}, qr/negative/);
    refuses('zero divisor', sub {expression($_[0], ['/',1,0])}, qr/divides by zero/);
    refuses('zero modulo', sub {expression($_[0], ['%',1,0])}, qr/modulo by zero/);
    refuses('out-of-range folded', sub {expression($_[0], '2147483648')}, qr/portable integer range/);
    refuses('intermediate overflow', sub {expression($_[0], ['*','2147483647',2,0])}, qr/portable integer range/);
    refuses('bitwise operator', sub {expression($_[0], ['&',1,1])}, qr/unsupported width.*operator/);
    refuses('unknown operator', sub {expression($_[0], ['<<',1,1])}, qr/unsupported width.*operator/);
    refuses('malformed expression', sub {expression($_[0], {})}, qr/malformed width expression/);
    refuses('missing environment', sub {delete $_[0]{parameter_environment}}, qr/port width contract emission is blocked/);
    my $cyclic = copy($ir); my $tree = []; push @$tree, $tree; expression($cyclic, $tree);
    my $ok = eval {emit($cyclic);1};
    ok(!$ok, 'cyclic expression refuses'); like($@,qr/cyclic.*width expression/,'cycle has a contextual diagnostic');
};
subtest 'discovery retains source and full verification boundaries' => sub {
    my $contract = build_composition_parameter_contract();
    ok($contract->{prepared_vhdl_scalar_emission}{symbolic_port_widths}, 'prepared VHDL ranges advertised');
    ok(!$contract->{public_source_planning_supported} && !$contract->{hdl_emission_supported}
        && !$contract->{prepared_vhdl_scalar_emission}{source_admission}, 'source and complete HDL support stay false');
};
done_testing;
