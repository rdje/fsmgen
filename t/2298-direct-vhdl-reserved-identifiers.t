use strict;
use warnings;
use File::Spec;
use FindBin;
use Test::More;
use JSON::PP;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::HDL::FlattenedDT::Backend::VHDL;
use FSM::Pipeline::HDLGenerator;

my $backend = 'FSM::HDL::FlattenedDT::Backend::VHDL';
my $json = JSON::PP->new->canonical;
my $root = File::Spec->catdir($FindBin::Bin, '..');

sub read_source {
    my ($relative) = @_;
    open my $in, '<', File::Spec->catfile($root, split m{/}, $relative) or die $!;
    my $text = do { local $/; <$in> };
    close $in or die $!;
    return $text;
}

sub parse {
    my ($text) = @_;
    return FSM::Adapter::FSMGenFull->new(debug => 0)
        ->parse_fsm(scalar Lispish::multi(\$text));
}

sub captures {
    my ($module) = @_;
    return $json->encode([
        $module->parameters, $module->parameter_default_sources,
        $module->parameter_default_bindings,
        { map {
            my $signal = $module->signals->{$_};
            $_ => [$signal->declared_width_source, $signal->declared_width_binding,
                $signal->declared_width_requirements]
        } keys %{$module->signals} },
    ]);
}

subtest 'public sources emit legal reserved-state and data declarations' => sub {
    for my $case (
        ['fsm/apb_requester.fsm', 'constant', 'ACCESS'],
        ['t/corpus/direct_rhs_concat_pack.fsm', 'signal', 'OUT'],
    ) {
        my ($path, $kind, $original) = @$case;
        my $result = eval {
            FSM::Pipeline::HDLGenerator->new(
                target_language => 'vhdl', quiet => 1, debug_level => 0,
            )->generate_hdl_from_file(File::Spec->catfile($root, split m{/}, $path));
        };
        ok($result, "$path generates through the public pipeline") or diag $@;
        next unless $result;
        my $hdl = $result->{hdl_code};
        like($hdl, qr/\b\Q$kind\E\s+\Q${original}_identifier\E\s*:/,
            "$path uses a legal deterministic physical declaration");
        unlike($hdl, qr/\b\Q$original\E\b/,
            "$path retains no reserved declaration or reference token");
    }
};

subtest 'only declared names change while grammar, comments and strings conserve' => sub {
    my $sv = <<'SV';
module naming_case (
    input wire IN_DATA,
    output reg OUT,
    output reg OUT_identifier,
    output reg out,
    output reg END
);
// module access (input wire end); OUT END
/* wire access; parameter OUT = 0; */
always_comb begin
    OUT = IN_DATA;
    OUT_identifier = IN_DATA;
    out = IN_DATA;
    END = IN_DATA;
end
initial $display("wire end; access OUT END");
endmodule
SV
    my $plan = FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv);
    is_deeply($plan->{identifier_map}, {
        OUT => 'OUT_identifier_2', out => 'out_identifier_3', END => 'END_identifier',
    }, 'case-folded allocation avoids real names and ignores fake declarations');
    like($plan->{text}, qr/\balways_comb begin\b/, 'SV opening grammar survives');
    is(scalar(() = $plan->{text} =~ /\bend\b/g), scalar(() = $sv =~ /\bend\b/g),
        'every SV end token, including quoted/commented text, survives');
    like($plan->{text}, qr{\Q// module access (input wire end); OUT END\E},
        'line comment bytes survive');
    like($plan->{text}, qr{\Q/* wire access; parameter OUT = 0; */\E},
        'block comment bytes survive');
    ok(index($plan->{text}, '$display("wire end; access OUT END")') >= 0,
        'string bytes survive');
    like($plan->{text}, qr/\bOUT_identifier_2 = IN_DATA;/, 'upper-case data reference maps');
    like($plan->{text}, qr/\bout_identifier_3 = IN_DATA;/, 'lower-case data reference maps separately');
    like($plan->{text}, qr/\bEND_identifier = IN_DATA;/, 'SV-legal upper-case keyword neighbor maps');
};

subtest 'module, type, constant and storage declaration roles are discovered' => sub {
    my $sv = <<'SV';
module access (
    input wire RANGE,
    output TYPE DATA_PORT
);
typedef struct packed {
    logic [1:0] payload;
} TYPE;
localparam CONSTANT = 2'b01;
reg [1:0] SIGNAL;
always_comb begin
    SIGNAL = CONSTANT;
    DATA_PORT = SIGNAL;
end
endmodule
SV
    my $plan = FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv);
    is_deeply($plan->{identifier_map}, {
        access => 'access_identifier', RANGE => 'RANGE_identifier',
        TYPE => 'TYPE_identifier', CONSTANT => 'CONSTANT_identifier',
        SIGNAL => 'SIGNAL_identifier',
    }, 'all supported declaration roles receive legal target names');
    like($plan->{text}, qr/output TYPE_identifier DATA_PORT/,
        'type use follows its declaration');
    like($plan->{text}, qr/SIGNAL_identifier = CONSTANT_identifier/,
        'storage and constant uses follow their declarations');
};

subtest 'mapped symbolic ports retain original lexical width captures' => sub {
    my $source = read_source('t/data/ial0-direct-symbolic-comb.fsm');
    $source =~ s/\bDATA\b/OUT/g;
    my $module = parse($source);
    my $before = captures($module);
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = eval { $dt->generate_vhdl($module) };
    ok(defined($hdl), 'source-aware symbolic output is normalized') or diag $@;
    if (defined $hdl) {
        like($hdl, qr/OUT_identifier : out std_logic_vector\(\(COPY - 1\) downto 0\)/,
            'physical output name keeps its exact symbolic vector rank');
        like($hdl, qr/OUT_identifier'length/, 'assignment sizing uses the mapped physical target');
    }
    is(captures($module), $before, 'complete original parameter/width captures and JSON kinds conserve');
    my $sv = $dt->generate_systemverilog($module);
    my $raw = eval { $backend->new(flattened_dt => {})->convert_systemverilog_to_vhdl($sv) };
    ok(!defined($raw), 'raw conversion gains no symbolic source authority');
    like($@, qr/unsupported generated port declaration/, 'raw refusal remains the declaration boundary');
};

subtest 'reserved generic source identities remain refused' => sub {
    my $module = parse('(?fsm:bad_generic (+system (clock clk) (sreset reset)) '
        . '(+params (WIDTH 8) (OUT WIDTH)) (+size (DATA_PORT 1)) '
        . '(idle (= (DATA_PORT 0))))');
    my $before = captures($module);
    my $hdl = eval { FSM::HDL::FlattenedDT->new(debug => 0)->generate_vhdl($module) };
    ok(!defined($hdl), 'a reserved related generic returns no artifact');
    like($@, qr/\[direct scaffold\].*(?:identifier|reserved)/s,
        'generic refusal stays inside the explicit direct target boundary');
    is(captures($module), $before, 'generic refusal preserves the source binding environment');
};

subtest 'declared SV keywords cannot be disguised as target aliases' => sub {
    my $sv = <<'SV';
module bad_source (
    input wire IN_DATA,
    output reg end
);
always_comb begin
    end = IN_DATA;
end
endmodule
SV
    my $result = eval { FSM::HDL::FlattenedDT::Backend::VHDL::_plan_generated_vhdl_identifiers($sv) };
    ok(!defined($result), 'an actual declaration using an SV keyword is refused');
    like($@, qr/\[direct scaffold\].*declared.*end.*SystemVerilog/s,
        'the refusal identifies invalid source grammar instead of rewriting it');
};

done_testing();
