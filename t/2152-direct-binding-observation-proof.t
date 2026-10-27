use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;
use FSM::ParameterDefaultEnvironmentSupport;

my $helper='FSM::ParameterDefaultEnvironmentSupport';
ok($helper->can('prove_binding_observations'),'complete direct binding observation proof exists') or do {done_testing();exit};
my $json=JSON::PP->new->canonical;
sub copy {return $json->decode($json->encode($_[0]))}
my $raw=Lispish::multi('t/data/ial0-parameter-default-sources.fsm');
my $module=FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm($raw);
my ($parameters,$sources,$bindings)=($module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings);
my $before=$json->encode([$raw,$parameters,$sources,$bindings]);
my %capture;
sub prove_bindings {return $helper->prove_binding_observations(parameters=>$_[0] // $parameters,
    sources=>$_[1] // $sources,bindings=>$_[2] // $bindings)}
sub reference {return {parameter=>$_[0],token=>$_[0].($_[1] // ''),suffix=>$_[1] // ''}}

subtest 'actual scalar and aggregate binding references agree completely without numeric inference' => sub {
    my $result=prove_bindings();
    my $expected={
        W=>[],STATIC=>[],MODE=>[],ITEMS=>[],
        FORWARD=>[reference('W')],CHAIN=>[reference('FORWARD')],
        CONFIG=>[reference('W'),reference('ITEMS')],COPY=>[reference('CONFIG')],
        LEAF=>[reference('CONFIG','.flag')],LANE=>[reference('CONFIG','.lanes[1]')],
        SUM=>[reference('W')],REPEATED=>[reference('W'),reference('W')],
    };
    is($json->encode($result->{reference_observations}),$json->encode($expected),'independent complete reference census retains immediate roots, paths and repeated order');
    is($result->{has_parameter_references},1,'actual mutable dependencies select a relationship-bearing profile');
    is_deeply($result->{environment}{scope},{kind=>'direct_module',owner=>'parameter_default_sources'},'proof preserves original source scope');
    is($json->encode([$raw,$parameters,$sources,$bindings]),$before,'whole caller/source JSON values and kinds are conserved');
    $result->{reference_observations}{FORWARD}[0]{token}='WRONG';
    is_deeply(prove_bindings()->{reference_observations}{FORWARD},[reference('W')],'returned observations are detached');
    $capture{actual}=prove_bindings();
};

subtest 'actual immutable and imported defaults keep static selections distinct from parameters' => sub {
    my $text=q{(?fsm:static_observations (+constants (FIXED 16) (PAIR (8'hA5 8'h3C)))
      (+params (W 16) (SAME FIXED) (ITEMS PAIR) (MATCH (== PAIR PAIR))))};
    my $m=FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm(Lispish::multi(\$text));
    my $result=prove_bindings($m->parameters,$m->parameter_default_sources,$m->parameter_default_bindings);
    is($result->{has_parameter_references},0,'equal numeric static defaults and aggregate comparison do not invent parameter dependencies');
    is_deeply($result->{reference_observations},{W=>[],SAME=>[],ITEMS=>[],MATCH=>[]},'literal independent static census is complete');
    my $generated=FSM::Pipeline::HDLGenerator->new(quiet=>1,debug_level=>0,target_language=>'systemverilog')
        ->generate_hdl_from_file('t/data/ial0-imported-default-bindings.fsm');
    my $imported=$generated->{fsm_module};
    my $old=$json->encode([$imported->parameters,$imported->parameter_default_sources,$imported->parameter_default_bindings]);
    $result=prove_bindings($imported->parameters,$imported->parameter_default_sources,$imported->parameter_default_bindings);
    is_deeply($result->{reference_observations}{ALIAS},[reference('PACKAGE')],'import-valued parameter remains an actual declared root');
    is_deeply($result->{reference_observations}{PACKAGE},[],'captured package constant itself remains immutable');
    is_deeply($result->{reference_observations}{ITEM},[],'captured imported aggregate leaf remains immutable');
    is($json->encode([$imported->parameters,$imported->parameter_default_sources,$imported->parameter_default_bindings]),$old,'actual imported caller JSON kinds are conserved');
    is_deeply(prove_bindings({},{},{}),{environment=>undef,reference_observations=>{},has_parameter_references=>0},'empty coherent source has no invented environment or dependency');
    $capture{imported}=$result;
};

subtest 'missing, forged, reordered and opaque observations refuse before static selection' => sub {
    for my $case (
        ['dropped references',sub {$_[0]{FORWARD}{references}=[]},qr/unbound canonical symbol|reference observations/],
        ['invented reference',sub {$_[0]{W}{references}=[reference('FORWARD')]},qr/reference observations/],
        ['reordered references',sub {$_[0]{CONFIG}{references}=[reverse @{$_[0]{CONFIG}{references}}]},qr/ordered reference observations/],
        ['wrong equal-valued root',sub {$_[1]{FORWARD}{parameter}=$_[1]{FORWARD}{token}='STATIC'},qr/unbound canonical symbol|binding.*observations/],
        ['foreign scope',sub {$_[1]{FORWARD}{scope}{owner}='physical_copy'},qr/foreign.*scope/],
        ['opaque payload',sub {$_[1]{W}={kind=>'payload',value=>{kind=>'scalar_expr',payload=>'(FORWARD + 1)'}}},qr/opaque|scalar.expression/],
        ['symbol disguised as literal',sub {$_[1]{W}{token}='FORWARD'},qr/integer literal|scalar value/],
        ['unknown nested node',sub {$_[1]{SUM}{operands}[0]{kind}='raw_hdl'},qr/canonical.*kind/],
        ['conflicting frozen static',sub {
            my $a=copy($_[1]{STATIC});my $b=copy($a);$b->{value_payload}{payload}=32;
            $_[1]{REPEATED}{operands}=[$a,$b];$_[0]{REPEATED}{references}=[];
        },qr/conflicting.*static|static.*snapshot/],
    ) {
        my ($label,$change,$reason)=@$case;my ($s,$b)=(copy($sources),copy($bindings));$change->($s,$b);
        my $old=$json->encode([$s,$b]);my $ok=eval {prove_bindings(undef,$s,$b);1};my $error=$@;
        ok(!$ok,"$label refuses");like($error,$reason,"$label identifies the violated proof");
        is($json->encode([$s,$b]),$old,"$label leaves complete caller JSON kinds unchanged");
        $capture{refusals}{$label}=$error;
    }
    my $b=copy($bindings);my $cycle={kind=>'operator',operator=>'+',source_operator=>'+'};
    $cycle->{operands}=[$cycle,{kind=>'literal',token=>'1'}];$b->{W}=$cycle;
    my $ok=eval {prove_bindings(undef,undef,$b);1};my $error=$@;
    ok(!$ok,'cyclic graph refuses');like($error,qr/acyclic|cyclic|nesting/,'cycle is rejected before an absence claim');
    $cycle->{operands}=[];
};

if (my $path=$ENV{FSMGEN_BINDING_OBSERVATION_CAPTURE}) {
    open my $out,'>',$path or die $!;print {$out} $json->encode(\%capture),"\n" or die $!;close $out or die $!;
}
done_testing();
