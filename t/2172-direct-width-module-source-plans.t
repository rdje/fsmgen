use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;

my $class = 'FSM::DirectDeclaredWidthSupport';
ok(eval {require FSM::DirectDeclaredWidthSupport; 1}, 'direct module source-width preparation exists')
    or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($value, $extra, $declarations) = @_;
    $value //= 1; $extra //= ''; $declarations //= "(data (param COPY)) (INPUT $value)";
    my $text = "(?fsm:width_module (+params (W $value) (COPY W) (SAME $value)) $extra"
        ." (+size $declarations) (idle (<-= (data INPUT))))";
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $m = $a->parse_fsm(scalar Lispish::multi(\$text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0);
    my $hdl = $dt->generate_systemverilog($m);
    return ($m, $dt->{assignment_analysis}, $a, $hdl);
}
sub prepare {
    my ($m, $analysis, $language) = @_;
    return $class->prepare_module(fsm_module => $m, assignment_analysis => $analysis,
        target_language => $language // 'systemverilog');
}
sub snapshot {
    my ($m, $analysis) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {$_ => signal_state($m->signals->{$_})} sort keys %{$m->signals}},
        {map {$_ => signal_state($analysis->{$_}{lhs_ast}->signal)} sort keys %$analysis}]);
}
sub signal_state {
    my ($s) = @_;
    return [$s->name, $s->width, $s->signed, $s->state_model, $s->declared_type_name,
        $s->declared_type_spec, $s->declared_width_source, $s->declared_width_binding, $s->declared_width_requirements];
}
sub expected_width_plan {
    my ($value, $language) = @_;
    my $scope = {kind => 'direct_module', owner => 'width_module'};
    return {profile => 'symbolic', target_language => $language, source_scope => $scope,
        source_signal => 'data', width => $value, is_vector => 1, parameter_references => ['COPY'],
        width_contract => {scope => copy($scope), expression => ['param', 'COPY'],
            references => [{kind => 'parameter', token => 'COPY'}]},
        range_text => $language eq 'vhdl' ? '((COPY - 1) downto 0)' : '[(COPY - 1):0] '};
}

subtest 'actual missing module member and propagated output yield complete independent plans' => sub {
    for my $value (1, 8) {
        for my $language ('systemverilog', 'verilog', 'vhdl') {
            my ($m, $analysis) = fixture($value);
            ok(!exists($m->signals->{data}), 'actual data Signal is absent from module membership');
            ok($analysis->{data}{lhs_ast}->signal->declared_width_binding, 'actual normalized lhs retains captured binding');
            my $before = snapshot($m, $analysis);
            my $plan = prepare($m, $analysis, $language);
            my %signals = map {$_ => {name => $_, width => $value,
                signed => 0, state_model => undef, declared_type_name => undef, declared_type_spec => undef,
                width_plan => $_ eq 'INPUT' ? undef : expected_width_plan($value, $language)}} qw(INPUT data next_data);
            is($json->encode($plan), $json->encode({profile => 'symbolic', target_language => $language,
                source_scope => {kind => 'direct_module', owner => 'width_module'},
                signal_order => [qw(INPUT data next_data)], signals => \%signals,
                parameter_references => ['COPY']}), 'whole independently expected detached module plan');
            is(snapshot($m, $analysis), $before, 'all caller source/default/Signal records and JSON kinds preserve');
            $plan->{signals}{data}{width_plan}{source_scope}{owner} = 'WRONG';
            is($analysis->{data}{lhs_ast}->signal->declared_width_binding->{scope}{owner}, 'width_module', 'plan changes cannot rewrite actual capture');
        }
    }
};

subtest 'physical names and shared actual identity do not invent scope or duplicate objects' => sub {
    my ($m, $analysis) = fixture(1);
    $m->{name} = 'physical_copy';
    $m->signals->{data} = $analysis->{data}{lhs_ast}->signal;
    my $plan = prepare($m, $analysis, 'sv');
    is($plan->{target_language}, 'systemverilog', 'language alias canonicalizes');
    is($plan->{source_scope}{owner}, 'width_module', 'source owner remains original header');
    is_deeply($plan->{signal_order}, [qw(INPUT data next_data)], 'same actual Signal reached twice appears once');
    $m->signals->{data} = FSM::CoreAST::Signal->new(name => 'data', width => 1);
    ok(!eval {prepare($m, $analysis); 1}, 'same-name distinct actual objects refuse');
    like($@, qr/distinct.*Signal/, 'ambiguous object identity is named');
};

subtest 'combined mutable and stale captures cannot silently freeze their defaults' => sub {
    my ($m, $analysis) = fixture(8, '', '(data (param COPY)) (next_data 8) (INPUT 8)');
    ok(!defined($m->signals->{next_data}->declared_width_binding), 'real independent auxiliary contribution withholds single binding');
    my $before = snapshot($m, $analysis);
    ok(!eval {prepare($m, $analysis); 1}, 'actual combined mutable requirements refuse');
    like($@, qr/combined.*mutable.*width/, 'combined shape is explicitly pending');
    is(snapshot($m, $analysis), $before, 'combined refusal preserves callers');
    ($m, $analysis) = fixture(8);
    $analysis->{data}{lhs_ast}->signal->clear_declared_width_binding;
    ok(!eval {prepare($m, $analysis); 1}, 'missing coherent mutable binding refuses');
    like($@, qr/(?:missing|coherent).*width.*binding/, 'missing binding is explicit');
    ($m, $analysis) = fixture(8);
    $analysis->{data}{lhs_ast}->signal->{_width} = 16;
    ok(!eval {prepare($m, $analysis); 1}, 'private width divergence cannot freeze stale source');
    like($@, qr/(?:missing|coherent).*width.*binding/, 'stale getter withholding is respected');
    ($m, $analysis) = fixture(8);
    $m->{parameters}{COPY}{value_payload}{payload} = '9';
    ok(!eval {prepare($m, $analysis); 1}, 'actual module default proof rejects stale environment');
    like($@, qr/binding|width|payload/, 'parameter proof refusal remains visible');
};

subtest 'independent fixed named-type and static declarations stay numeric' => sub {
    my ($m, $analysis) = fixture(8, '(+types (type word_t (bits 8)))', '(data word_t) (INPUT 8)');
    my $before = snapshot($m, $analysis);
    my $plan = prepare($m, $analysis, 'vhdl');
    is($plan->{profile}, 'fixed', 'named-type source creates no mutable relationship');
    is_deeply($plan->{parameter_references}, [], 'same-default declarations select no roots');
    ok(!defined($plan->{signals}{data}{width_plan}), 'named type has no fabricated captured width');
    is_deeply($plan->{signals}{data}{declared_type_spec}, {kind => 'bits', width => 8, signed => 0}, 'actual type metadata remains detached');
    is(snapshot($m, $analysis), $before, 'fixed/type records conserve');
    ($m, $analysis) = fixture(8, '(+constants (K 8))', '(data (+ K 0)) (INPUT 8)');
    $plan = prepare($m, $analysis);
    is($plan->{signals}{data}{width_plan}{profile}, 'fixed', 'proved static expression retains fixed rank');
    ok(!defined($plan->{signals}{data}{width_plan}{range_text}), 'static source receives no symbolic text');
    my $static_text = '(?fsm:static_only (+constants (K 8)) (+size (DATA (+ K 0)) (SOURCE 8)) (idle (= (DATA SOURCE))))';
    my $a = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $static_module = $a->parse_fsm(scalar Lispish::multi(\$static_text));
    my $dt = FSM::HDL::FlattenedDT->new(debug => 0); $dt->generate_systemverilog($static_module);
    my $static = prepare($static_module, $dt->{assignment_analysis});
    is($static->{source_scope}{owner}, 'static_only', 'actual static-only capture supplies its original scope without parameters');
    is($static->{signals}{DATA}{width_plan}{profile}, 'fixed', 'empty declared environment proves the actual static capture');
    my $legacy = FSM::CoreAST::FSMModule->new(name => 'legacy', signals => {DATA => FSM::CoreAST::Signal->new(name => 'DATA', width => 8)});
    $plan = prepare($legacy, {});
    is($plan->{source_scope}, undef, 'legacy numeric objects gain no invented source owner');
    is($plan->{signals}{DATA}{width}, 8, 'legacy numeric declaration preserves');
};

subtest 'malformed membership scope and targets refuse with no retained owners' => sub {
    my ($m, $analysis) = fixture(1);
    for my $bad (undef, [], {data => {}}, {data => {lhs_ast => 'data'}}) {
        ok(!eval {prepare($m, $bad); 1}, 'incomplete or malformed backend analysis refuses');
    }
    ok(!eval {prepare($m, $analysis, 'c'); 1}, 'foreign target refuses even before emission');
    my $frame = $analysis->{data}{lhs_ast}->signal->declared_width_binding;
    $frame->{scope}{owner} = 'foreign';
    $analysis->{data}{lhs_ast}->signal->set_declared_width_binding($frame);
    ok(!eval {prepare($m, $analysis); 1}, 'foreign width scope cannot borrow module declarations');
    like($@, qr/scope/, 'scope conflict is named');
    my ($weak_module, $weak_analysis, $weak_signal, $held);
    {
        my $s = FSM::CoreAST::Signal->new(name => 'DATA', width => 1);
        my $owner = FSM::CoreAST::FSMModule->new(name => 'bare', signals => {DATA => $s});
        my $a = {DATA => {lhs_ast => FSM::CoreAST::SignalRef->new($s)}};
        $weak_module = $owner; weaken($weak_module); $weak_analysis = $a; weaken($weak_analysis);
        $weak_signal = $s; weaken($weak_signal);
        $held = prepare($owner, $a);
    }
    ok(!defined($weak_module) && !defined($weak_analysis) && !defined($weak_signal), 'held plan retains no Core or backend graph');
    is($held->{signals}{DATA}{width}, 1, 'detached fixed plan survives owner release');
};
done_testing();
