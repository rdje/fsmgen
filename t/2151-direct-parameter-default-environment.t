use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;

my $helper = 'FSM::ParameterDefaultEnvironmentSupport';
my $loaded = eval {require FSM::ParameterDefaultEnvironmentSupport; 1};
ok($loaded, 'shared captured-source environment helper exists') or do {diag($@); done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy {return $json->decode($json->encode($_[0]))}
my $raw=Lispish::multi('t/data/ial0-parameter-default-sources.fsm');
my $module=FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm($raw);
my ($parameters,$sources,$bindings)=($module->parameters,$module->parameter_default_sources,$module->parameter_default_bindings);
my $before=$json->encode([$raw,$parameters,$sources,$bindings]);
my %capture;
sub build {
    return $helper->build_direct_environment(parameters=>$_[0] // $parameters,
        sources=>$_[1] // $sources, bindings=>$_[2] // $bindings,
        (defined($_[3]) ? (validate_declaration_name=>$_[3]) : ()));
}

subtest 'actual captured records preserve source ownership and alphabetical ties' => sub {
    my @names;
    my $environment=build(undef,undef,undef,sub {is(scalar(@_),1,'target validator gets exactly one name');push @names,$_[0]});
    my $expected=[qw(CHAIN CONFIG COPY FORWARD ITEMS LANE LEAF MODE REPEATED STATIC SUM W)];
    is_deeply($environment->{scope},{kind=>'direct_module',owner=>'parameter_default_sources'},'actual original lexical owner survives');
    is_deeply($environment->{declaration_order},$expected,'independent complete source membership has stable alphabetical ties');
    is_deeply(\@names,$expected,'target policy is invoked at each original per-declaration boundary');
    is($json->encode($environment->{parameters}),$json->encode($parameters),'all normalized parameter values and JSON kinds survive');
    is($json->encode([$raw,$parameters,$sources,$bindings]),$before,'complete caller/source records are unchanged');
    my $physical=FSM::CoreAST::FSMModule->new(name=>'physical_copy',parameters=>$parameters,
        _parameter_default_sources=>$sources,_parameter_default_bindings=>$bindings);
    is(build($physical->parameters,$physical->parameter_default_sources,$physical->parameter_default_bindings)->{scope}{owner},
        'parameter_default_sources','physical rename cannot replace the captured lexical owner');
    $physical->set_parameter('W',$parameters->{W},$sources->{W});
    my $ok=eval {build($physical->parameters,$physical->parameter_default_sources,$physical->parameter_default_bindings);1};
    ok(!$ok,'actual declaration replacement invalidates captured membership');like($@,qr/complete.*membership/,'stale capture cannot invent a replacement');
    is_deeply(build({},{},{}),undef,'empty coherent declarations have no invented source scope');
    $capture{environment}=$environment;
};

subtest 'source/type/reference and target-policy failures preserve callers' => sub {
    for my $case (
        ['missing source',sub {delete $_[1]{W}},qr/complete.*membership/],
        ['missing binding',sub {delete $_[2]{W}},qr/complete.*membership/],
        ['foreign owner',sub {$_[1]{W}{source_module}='other'},qr/foreign source scope/],
        ['invalid kind',sub {$_[0]{W}{value_kind}='unknown'},qr/normalized declaration/],
        ['raw binding',sub {$_[2]{W}{kind}='raw_hdl'},qr/canonical binding/],
        ['wrong reference token',sub {$_[1]{FORWARD}{references}[0]{token}='SAME'},qr/inconsistent reference/],
        ['undeclared root',sub {$_[1]{FORWARD}{references}[0]{parameter}='MISSING';$_[1]{FORWARD}{references}[0]{token}='MISSING'},qr/inconsistent reference/],
        ['Boolean source owner',sub {$_[1]{W}{source_module}=JSON::PP::true},qr/actual source declaration/],
    ) {
        my ($label,$change,$reason)=@$case;my ($p,$s,$b)=(copy($parameters),copy($sources),copy($bindings));
        $change->($p,$s,$b);my $old=$json->encode([$p,$s,$b]);
        my $ok=eval {build($p,$s,$b);1};my $error=$@;
        ok(!$ok,"$label refuses");like($error,$reason,"$label identifies its boundary");
        is($json->encode([$p,$s,$b]),$old,"$label preserves complete caller JSON kinds");
        $capture{refusals}{$label}=$error;
    }
    my $s=copy($sources);$s->{CHAIN}{references}=['bad observation'];
    my $ok=eval {build(undef,$s,undef,sub {die "selected target policy refuses\n"});1};
    ok(!$ok,'target policy refuses before reference-body validation');like($@,qr/selected target policy/,'original target-policy order is retained');
    my $p=copy($parameters);$p->{CHAIN}{value_kind}='unknown';
    $ok=eval {build($p,undef,undef,sub {die "selected target policy refuses\n"});1};
    ok(!$ok,'source/type validation precedes target policy');like($@,qr/normalized declaration/,'original earlier validation wins');
    $ok=eval {build(undef,undef,undef,{});1};
    ok(!$ok,'non-code target validator refuses');like($@,qr/validator.*callback/,'callback contract is explicit');
};

subtest 'target-independent validation neither applies target reservation nor retains callbacks' => sub {
    my $text='(?fsm:neutral_names (+params (wire 16)))';
    my $m=FSM::Adapter::FSMGenFull->new(debug=>0)->parse_fsm(Lispish::multi(\$text));
    is_deeply(build($m->parameters,$m->parameter_default_sources,$m->parameter_default_bindings)->{declaration_order},
        ['wire'],'target-specific reservation remains the consuming backend policy');
    for my $refusal (0,1) {
        my ($weak,$retained);
        {
            my $owner={};$weak=$owner;weaken($weak);
            my $callback=sub {my $held=$owner;die "intentional callback refusal\n" if $refusal};
            my $ok=eval {$retained=build(undef,undef,undef,$callback);1};
            is($ok ? 1 : 0,$refusal ? 0 : 1,'callback reaches the intended success/refusal boundary');
        }
        ok(!defined($weak),'returned environment or refusal does not retain the transient callback owner');
    }
};

if (my $path=$ENV{FSMGEN_DIRECT_ENVIRONMENT_CAPTURE}) {
    open my $out,'>',$path or die $!;print {$out} $json->encode(\%capture),"\n" or die $!;close $out or die $!;
}
done_testing();
