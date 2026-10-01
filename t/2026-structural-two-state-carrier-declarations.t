use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;

my $json = JSON::PP->new->canonical;
my $mixed = {
    kind=>'record', width=>10, member_order=>[qw(tag payload)],
    members=>{
        tag=>{kind=>'bits',width=>2,signed=>0},
        payload=>{kind=>'record',width=>8,member_order=>[qw(data flags)],members=>{
            data=>{kind=>'bits',width=>5,signed=>1,state_model=>'four_state'},
            flags=>{kind=>'list',width=>3,items=>[
                {kind=>'bit',width=>1,signed=>0,state_model=>'two_state'},
                {kind=>'bits',width=>2,signed=>0,state_model=>'two_state'},
            ]},
        }},
    },
};
my $four_state = $json->decode($json->encode($mixed));
$_->{state_model} = 'four_state' for @{$four_state->{members}{payload}{members}{flags}{items}};
my $list = {kind=>'list',width=>6,items=>[
    {kind=>'bits',width=>2,signed=>0,state_model=>'four_state'},
    {kind=>'record',width=>4,member_order=>[qw(flag data)],members=>{
        flag=>{kind=>'bit',width=>1,signed=>0,state_model=>'two_state'},
        data=>{kind=>'bits',width=>3,signed=>1},
    }},
]};
my $two_state = {kind=>'record',width=>3,member_order=>[qw(flag data)],members=>{
    flag=>{kind=>'bit',width=>1,signed=>0,state_model=>'two_state'},
    data=>{kind=>'bits',width=>2,signed=>1,state_model=>'two_state'},
}};

subtest 'typed carriers preserve exact nested data models with legal declaration classes' => sub {
    for my $target (qw(systemverilog verilog)) {
        my $ir = {
            module_name=>'typed_carriers',target_language=>$target,ports=>[],instances=>[],
            nets=>[
                {name=>'mixed_bus',width=>10,declared_type_name=>'mixed',declared_type_spec=>$mixed},
                {name=>'four_bus',width=>10,declared_type_name=>'four',declared_type_spec=>$four_state},
                {name=>'list_bus',width=>6,declaration_keyword=>'wire',declared_type_name=>'list',declared_type_spec=>$list},
                {name=>'two_bus',width=>3,declaration_keyword=>'wire',declared_type_name=>'two',declared_type_spec=>$two_state},
                {name=>'mixed_variable',width=>10,declaration_keyword=>'logic',declared_type_name=>'mixed',declared_type_spec=>$mixed},
                {name=>'two_scalar',width=>5,signed=>1,state_model=>'two_state',declaration_keyword=>'wire'},
                {name=>'four_scalar',width=>5,signed=>1,state_model=>'four_state',declaration_keyword=>'wire'},
                {name=>'legacy_scalar',width=>5,declaration_keyword=>'wire'},
            ],
        };
        my $before = $json->encode($ir);
        my $hdl = FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($ir);
        is($json->encode($ir),$before,"$target preserves complete input IR JSON kinds and declarations");
        for my $line (
            'fsmgen_m14_typed_carriers__mixed__fsmgen_t mixed_bus;',
            'wire fsmgen_m14_typed_carriers__four__fsmgen_t four_bus;',
            'fsmgen_m14_typed_carriers__list__fsmgen_t list_bus;',
            'fsmgen_m14_typed_carriers__two__fsmgen_t two_bus;',
            'fsmgen_m14_typed_carriers__mixed__fsmgen_t mixed_variable;',
            'bit signed [4:0] two_scalar;',
            'wire logic signed [4:0] four_scalar;',
            'wire [4:0] legacy_scalar;',
        ) {
            like($hdl,qr/^    \Q$line\E$/m,"$target literal legal carrier: $line");
        }
        unlike($hdl,qr/^    wire .*\b(?:mixed_bus|list_bus|two_bus|two_scalar);$/m,
            "$target never places a two-state carrier on a wire");
        like($hdl,qr/logic signed \[4:0\] data;.*bit item_0;.*bit \[1:0\] item_1;/s,
            "$target preserves mixed signed/four-state data and nested two-state list leaves");
        like($hdl,qr/logic \[1:0\] item_0;.*bit flag;.*logic signed \[2:0\] data;/s,
            "$target preserves the independently authored list-of-record declaration");
        like($hdl,qr/bit flag;\n    bit signed \[1:0\] data;/,
            "$target preserves every two-state record leaf without widening");
    }
};

subtest 'actual previously failing source changes only its illegal carrier declaration' => sub {
    my $work = tempdir(CLEANUP=>1);
    my $output = "$work/domains.sv";
    my $result = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--quiet',
        '--language','systemverilog','--output',$output,
        't/data/isf_record_input_generated_domains_runtime.isf'],'');
    is($result->{exit_code},0,'unchanged failing authored source still emits through the public strict interface')
        or diag($result->{stdout},$result->{stderr});
    return if $result->{exit_code};
    my $actual = read_file($output);
    my $expected = read_file('docs/audits/record-input-generated-observation-20261001/re-emitted-domains-systemverilog.sv.source');
    is($expected =~ s/^    wire (fsmgen_m34_packed_input_generated_domains_top__frame__fsmgen_t comp_link_io__writer_isf_write_held_data;)$/    $1/m,
        1,'immutable diagnosed product has exactly the illegal generated whole-copy carrier');
    s/^\/\/ Date:.*\n//mg for $actual,$expected;
    is($actual,$expected,'complete public product preserves all types, layout, roles, wiring and logic except the repaired declaration and date');
};

done_testing;

sub read_file {
    open my $fh,'<:raw',$_[0] or die $!;
    local $/; my $value=<$fh>; close $fh or die $!; return $value;
}
