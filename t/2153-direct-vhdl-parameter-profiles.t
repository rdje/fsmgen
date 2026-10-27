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

my $helper='FSM::Backend::VHDL::DirectParameterEmitter';
my $loaded=eval {require FSM::Backend::VHDL::DirectParameterEmitter;1};
ok($loaded,'direct VHDL profile preparer exists') or do {diag($@);done_testing();exit};
my $json=JSON::PP->new->canonical;
sub copy {return $json->decode($json->encode($_[0]))}
sub parse {my ($text)=@_;return FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm(Lispish::multi(\$text))}
my $module=parse(q{(?fsm:direct_profiles (+system (clock clk))
  (+params (COPY WIDTH) (WIDTH 16) (SAME 16) (_PAD 8'hA5) (TOTAL (+ COPY 2)))
  (+size (data_port 1)) (idle (= (data_port 0))))});
sub namespace {
    return {module_name=>'direct_profiles',identifier_map=>{_PAD=>'PAD'},
        parameter_names=>[qw(COPY WIDTH SAME PAD TOTAL)],ports=>['clk','data_port'],signals=>['state_bits'],constants=>['IDLE'],types=>[]};
}
sub prepare {return $helper->lower_declarations(fsm_module=>$_[0] // $module,
    target_namespace=>$_[1] // namespace(),target_language=>$_[2] // 'vhdl')}
my %capture;

subtest 'only actual related declarations select natural generics' => sub {
    my $ns=namespace();my $old=$json->encode([$module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings,$ns]);
    my $actual=prepare(undef,$ns);
    my $expected={profile=>'mixed',source_scope=>{kind=>'direct_module',owner=>'direct_profiles'},
        parameter_order=>[qw(SAME WIDTH COPY TOTAL PAD)],static_parameters=>[qw(SAME PAD)],
        natural_declarations=>[
            {name=>'WIDTH',type=>'natural',default_text=>16,parameter_references=>[]},
            {name=>'COPY',type=>'natural',default_text=>'WIDTH',parameter_references=>['WIDTH']},
            {name=>'TOTAL',type=>'natural',default_text=>'(COPY + 2)',parameter_references=>['COPY']},
        ]};
    is($json->encode($actual),$json->encode($expected),'independent category/order/type/text expectations preserve named dependencies and static renaming');
    my $p=$module->parameters;$p->{WIDTH}{value_payload}{payload}=99;$p->{WIDTH}{value_text}='99';
    my $physical=FSM::CoreAST::FSMModule->new(name=>'physical_copy',parameters=>$p,
        _parameter_default_sources=>$module->parameter_default_sources,_parameter_default_bindings=>$module->parameter_default_bindings);
    my $renamed=copy($ns);$renamed->{module_name}='physical_copy';
    is($json->encode(prepare($physical,$renamed)),$json->encode($expected),'physical name/cache changes do not replace lexical ownership or captured defaults');
    is($json->encode([$module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings,$ns]),$old,'whole source and namespace callers keep JSON kinds');
    $actual->{natural_declarations}[1]{parameter_references}[0]='WRONG';
    is($json->encode(prepare()),$json->encode($expected),'returned plan arrays are detached');
    $capture{mixed}=prepare();
};

subtest 'actual normalized backend declarations supply the target namespace' => sub {
    my $sv=FSM::HDL::FlattenedDT->new(debug=>0)->generate_systemverilog($module);
    my $normalized=FSM::HDL::FlattenedDT::Backend::VHDL::_normalize_generated_vhdl_identifiers($sv);
    like($normalized,qr/parameter PAD = 8'hA5/,'actual backend normalization maps the unrelated static identifier');
    my $parsed=FSM::HDL::FlattenedDT::Backend::VHDL::_parse_module($normalized);
    my @generics=FSM::HDL::FlattenedDT::Backend::VHDL::_parse_generics($parsed->{parameters});
    my @ports=FSM::HDL::FlattenedDT::Backend::VHDL::_parse_ports($parsed->{ports},{});
    my @signals=FSM::HDL::FlattenedDT::Backend::VHDL::_parse_signal_declarations($parsed->{body},{map {$_->{name}=>1} @ports});
    my @constants=FSM::HDL::FlattenedDT::Backend::VHDL::_parse_constants($parsed->{body});
    my $actual_namespace={module_name=>$parsed->{name},identifier_map=>{_PAD=>'PAD'},
        parameter_names=>[map {$_->{name}} @generics],ports=>[map {$_->{name}} @ports],
        signals=>[map {$_->{name}} @signals],constants=>[map {$_->{name}} @constants],types=>[]};
    is($json->encode(prepare(undef,$actual_namespace)),$json->encode($capture{mixed}),'actual backend namespace produces the independently expected mixed plan');
    $capture{actual_namespace}=$actual_namespace;
};

subtest 'static and legacy profiles retain existing conversion ownership' => sub {
    my $m=parse(q{(?fsm:static_profiles (+params (_PAD 8'hA5) (SAME 16) (NEG -1)))});
    my $ns={module_name=>'static_profiles',identifier_map=>{_PAD=>'PAD'},parameter_names=>[qw(PAD SAME NEG)],ports=>[],signals=>[],constants=>[],types=>[]};
    is_deeply(prepare($m,$ns),{profile=>'static',source_scope=>{kind=>'direct_module',owner=>'static_profiles'},
        parameter_order=>[qw(NEG SAME PAD)],static_parameters=>[qw(NEG SAME PAD)],natural_declarations=>[]},'independent static vector/literal/negative defaults retain their target names and static converter');
    my $legacy=FSM::CoreAST::FSMModule->new(name=>'legacy_profiles',parameters=>{A=>'8',Z=>'32'});
    $ns={module_name=>'legacy_profiles',identifier_map=>{},parameter_names=>[qw(A Z)],ports=>[],signals=>[],constants=>[],types=>[]};
    is_deeply(prepare($legacy,$ns),{profile=>'legacy_static',source_scope=>undef,
        parameter_order=>[qw(A Z)],static_parameters=>[qw(A Z)],natural_declarations=>[]},'legacy programmatic values acquire no invented captured scope');
};

subtest 'actual names, snapshots and unsupported relationships fail closed' => sub {
    for my $case (
        ['case-folded port collision',sub {$_[0]{ports}=['width']},qr/collid/],
        ['generated type collision',sub {$_[0]{types}=['COPY']},qr/collid/],
        ['wrong physical module',sub {$_[0]{module_name}='other'},qr/module.*mapping|module.*identity/],
        ['missing emitted parameter',sub {pop @{$_[0]{parameter_names}}},qr/parameter.*membership/],
        ['duplicate emitted parameter',sub {push @{$_[0]{parameter_names}},'WIDTH'},qr/duplicate|membership/],
        ['renamed related root',sub {$_[0]{identifier_map}{WIDTH}='W';$_[0]{parameter_names}[1]='W'},qr/related.*renam|symbolic.*renam/],
    ) {
        my ($label,$change,$reason)=@$case;my $ns=namespace();$change->($ns);my $old=$json->encode($ns);
        my $ok=eval {prepare(undef,$ns);1};my $error=$@;
        ok(!$ok,"$label refuses");like($error,$reason,"$label identifies the target contract");
        is($json->encode($ns),$old,"$label preserves namespace input");$capture{refusals}{$label}=$error;
    }
    for my $case (
        ['sized related default',"(WIDTH 8'h10) (COPY WIDTH)",qr/decimal|natural/],
        ['mutable aggregate path',"(BASE (8'h01 8'h02)) (COPY BASE[1])",qr/scalar|decimal/],
        ['bitwise relationship',"(WIDTH 16) (COPY (and WIDTH 3))",qr/decimal scalar payload/],
        ['negative intermediate',"(WIDTH 0) (COPY (- WIDTH 1))",qr/negative|portable/],
    ) {
        my ($label,$params,$reason)=@$case;my $m=parse("(?fsm:unsupported_profile (+params $params))");
        my $ns={module_name=>'unsupported_profile',identifier_map=>{},parameter_names=>[sort keys %{$m->parameters}],ports=>[],signals=>[],constants=>[],types=>[]};
        my $ok=eval {prepare($m,$ns);1};my $error=$@;
        ok(!$ok,"$label refuses");like($error,$reason,"$label names the bounded profile");$capture{refusals}{$label}=$error;
    }
    my $stale=FSM::CoreAST::FSMModule->new(name=>'direct_profiles',parameters=>$module->parameters,
        _parameter_default_sources=>$module->parameter_default_sources,_parameter_default_bindings=>$module->parameter_default_bindings);
    $stale->set_parameter('WIDTH',$module->parameters->{WIDTH},$module->parameter_default_sources->{WIDTH});
    my $ok=eval {prepare($stale);1};ok(!$ok,'invalidated captures cannot select static fallback');like($@,qr/membership/,'fresh capture remains required');
    $ok=eval {prepare(undef,undef,'systemverilog');1};ok(!$ok,'wrong target refuses');like($@,qr/VHDL target/,'target is explicit');
    my $sources=$module->parameter_default_sources;my $bindings=$module->parameter_default_bindings;
    $sources->{WIDTH}{expression}=['COPY'];
    $sources->{WIDTH}{references}=[{parameter=>'COPY',token=>'COPY',suffix=>''}];
    $bindings->{WIDTH}={kind=>'parameter',scope=>{kind=>'direct_module',owner=>'direct_profiles'},parameter=>'COPY',token=>'COPY',suffix=>''};
    my $cycle=FSM::CoreAST::FSMModule->new(name=>'direct_profiles',parameters=>$module->parameters,
        _parameter_default_sources=>$sources,_parameter_default_bindings=>$bindings);
    $ok=eval {prepare($cycle);1};ok(!$ok,'coherent captured dependency cycle refuses');like($@,qr/dependency cycle/,'cycle cannot acquire a declaration order');
};

if (my $path=$ENV{FSMGEN_DIRECT_VHDL_PROFILE_CAPTURE}) {
    open my $out,'>',$path or die $!;print {$out} $json->encode(\%capture),"\n" or die $!;close $out or die $!;
}
done_testing();
