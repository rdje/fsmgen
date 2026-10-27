use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;

my $json = JSON::PP->new->canonical;
sub parse {
    my ($source) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi(\$source));
}
sub source {
    my ($parameters, $name) = @_;
    $name //= 'direct_generic_profile';
    return "(?fsm:$name (+system (clock clk) (sreset reset)) (+params $parameters) "
        . '(+size (data_port 1)) (idle (= (data_port 0))))';
}
sub generate { return FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($_[0]) }
sub captures {
    my ($module) = @_;
    return $json->encode([$module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings]);
}
my %capture;

subtest 'actual source relationships become natural generics with static controls' => sub {
    open my $in, '<', 't/data/ial0-direct-vhdl-natural-defaults.fsm' or die $!;
    my $text = do { local $/; <$in> }; close $in or die $!;
    my $module = parse($text);
    my $before = captures($module);
    my $hdl = generate($module);
    my ($block) = $hdl =~ /  generic \(\n(.*?)\n  \);/s;
    is($block . "\n", <<'VHDL', 'entire independently expected declaration block preserves identity, kinds and dependency order');
    NEG : integer := -1;
    SAME : integer := 16;
    WIDTH : natural := 16;
    COPY : natural := WIDTH;
    TOTAL : natural := (COPY + 2);
    RESIDUE : natural := (TOTAL mod WIDTH);
    PAD : std_logic_vector(7 downto 0) := "10100101"
VHDL
    is(captures($module), $before, 'whole source captures and JSON kinds survive actual generation');
    like($hdl, qr/\bdata_port\s+<=\s+'0';/, 'the direct executable body survives generic preparation');
    my $backend = FSM::HDL::FlattenedDT::Backend::VHDL->new(flattened_dt => {});
    my $sv = FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($module);
    my $standalone = $backend->convert_systemverilog_to_vhdl($sv);
    like($standalone, qr/WIDTH : integer := 16;/, 'public raw conversion retains its existing integer profile');
    like($standalone, qr/COPY : integer := WIDTH;/, 'raw conversion invents no canonical source environment');
    $capture{source} = {source => $text, hdl => $hdl, standalone => $standalone};
};

subtest 'physical module copies retain lexical source scope and actual target mapping' => sub {
    my $module = parse(source('(COPY WIDTH) (WIDTH 16) (_PAD 8\'hA5)', '_source_module'));
    my $copy = FSM::CoreAST::FSMModule->new(name => 'physical_copy',
        parameters => $module->parameters,
        _parameter_default_sources => $module->parameter_default_sources,
        _parameter_default_bindings => $module->parameter_default_bindings);
    my $before = captures($copy);
    my $hdl = generate($copy);
    like($hdl, qr/entity physical_copy is/, 'physical output identity stays independent of captured source owner');
    like($hdl, qr/WIDTH : natural := 16;\s+COPY : natural := WIDTH;/s, 'copied defaults keep source relationships');
    like($hdl, qr/PAD : std_logic_vector\(7 downto 0\) := "10100101"/, 'unrelated static name uses actual generated mapping');
    is(captures($copy), $before, 'physical copy getters stay unchanged');
    my $original = generate($module);
    like($original, qr/entity source_module is/, 'the actual source module identity is normalized before generic admission');
    $capture{physical_copy} = $hdl;
};

subtest 'unsupported source relationships refuse before an artifact returns' => sub {
    for my $case (
        ['sized related root', "(WIDTH 8'h10) (COPY WIDTH)", qr/decimal|natural/],
        ['bitwise relationship', '(WIDTH 16) (COPY (and WIDTH 3))', qr/parameter expression|decimal|scalar/],
        ['negative intermediate', '(WIDTH 0) (COPY (- WIDTH 1))', qr/negative|portable/],
        ['reserved generic', '(WIDTH 16) (OUT WIDTH)', qr/identifier|reserved/],
        ['case-folded target collision', '(WIDTH 16) (COPY WIDTH) (width 16)', qr/collid/],
    ) {
        my ($label, $parameters, $reason) = @$case;
        my $module = parse(source($parameters));
        my $before = captures($module);
        my $hdl = eval { generate($module) };
        my $error = $@;
        ok(!defined($hdl), "$label returns no artifact");
        like($error, qr/\[direct scaffold\].*Unsupported generated SystemVerilog shape/s, "$label keeps the direct backend diagnostic boundary");
        like($error, $reason, "$label explains its bounded profile");
        is(captures($module), $before, "$label preserves captured inputs");
        $capture{refusals}{$label} = $error;
    }
};

if (my $path = $ENV{FSMGEN_DIRECT_VHDL_INTEGRATION_CAPTURE}) {
    open my $out, '>', $path or die $!;
    print {$out} $json->encode(\%capture), "\n" or die $!;
    close $out or die $!;
}
done_testing();
