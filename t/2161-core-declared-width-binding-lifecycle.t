use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::Adapter::FSMGenFull::SignalManager;

ok(FSM::CoreAST::Signal->can('declared_width_binding')
    && FSM::CoreAST::Signal->can('set_declared_width_binding'),
    'private Core width binding holder exists') or do {done_testing(); exit};
my $json = JSON::PP->new->canonical;
sub copy { return $json->decode($json->encode($_[0])) }
my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
my $module = $adapter->parse_fsm(Lispish::multi('t/corpus/direct_size_parameter_selection.fsm'));
my $source_signal = $adapter->{signal_manager}->get_signal('SELECTED');
my $source = $source_signal->declared_width_source;
my $capture = $adapter->{parser}->capture_declared_width_contract(signal_name => 'SELECTED',
    width_token => $source->{expression}, scope => {kind => 'direct_module', owner => 'direct_size_parameter_selection'});
my $binding = {%{$capture->{width_capture}}, signal => $source->{signal}, expression => $source->{expression}};
my $expected_json = $json->encode({width => 16, scope => {kind => 'direct_module', owner => 'direct_size_parameter_selection'},
    signal => 'SELECTED', expression => ['param', ['W']],
    binding => {kind => 'reference', observation_index => 0, value_expression => {kind => 'literal', token => '16'}},
    observations => [{lookup => 'parameter', kind => 'parameter', token => 'W', parameter => 'W', suffix => '',
        value_payload => {kind => 'scalar', payload => '16'}}]});
is($json->encode($binding), $expected_json, 'real opt-in producer supplies the independently expected envelope');
sub signal {
    return FSM::CoreAST::Signal->new(name => 'physical_copy', width => 16,
        _declared_width_source => copy($source), _declared_width_binding => copy($binding), @_);
}

subtest 'plain holder detaches callers/getters and ordinary constructors remain unbound' => sub {
    my $ordinary = FSM::CoreAST::Signal->new(name => 'ordinary', width => 16, _declared_width_source => copy($source));
    is($ordinary->declared_width_binding, undef, 'ordinary constructor without supplied binding remains unbound');
    ok(!exists $ordinary->{_declared_width_binding}, 'ordinary constructor adds no metadata field');
    my $input = copy($binding); my $s = signal(_declared_width_binding => $input);
    is($json->encode($s->declared_width_binding), $expected_json, 'copied physical name retains original declaration identity');
    $input->{scope}{owner} = 'WRONG'; $input->{observations}[0]{value_payload}{payload} = '99';
    is($json->encode($s->declared_width_binding), $expected_json, 'caller mutation cannot rewrite stored provenance');
    my $got = $s->declared_width_binding; $got->{expression}[1][0] = 'ALIAS';
    is($json->encode($s->declared_width_binding), $expected_json, 'getter result is independent');
    is($s->width, 16, 'numeric width unchanged');
    is($json->encode($s->declared_width_source), $json->encode($source), 'old source getter keeps exact JSON kinds');
    $s->set_declared_width_binding(undef);
    is($s->declared_width_binding, undef, 'explicit clear removes binding');
    ok(!exists $s->{_declared_width_binding}, 'clear leaves no stale private field');
};

subtest 'source, effective width and named types must agree with the stored envelope' => sub {
    is(signal(width => 17)->declared_width_binding, undef, 'a different effective width cannot borrow the declaration binding');
    is(signal(_declared_width_source => undef)->declared_width_binding, undef, 'missing declaration origin supplies no binding');
    is(signal(declared_type_name => 'W')->declared_width_binding, undef, 'named-type state supplies no symbolic binding');
    is(signal(declared_type_spec => {kind => 'bits', width => 16})->declared_width_binding, undef, 'explicit type specification supplies no symbolic binding');
    my $s = signal(); $s->{_width} = 32;
    is($s->declared_width_binding, undef, 'getter withholds metadata after private width divergence');
    $s = signal(); $s->{_declared_width_source}{expression} = ['param', ['ALIAS']];
    is($s->declared_width_binding, undef, 'same-valued different source identity cannot borrow metadata');
};

subtest 'failed replacement clears old binding and refuses non-plain or malformed envelopes' => sub {
    my @bad = ([], { %$binding, extra => 1 }, { %$binding, scope => {kind => 'composition_top', owner => 'top'} },
        { %$binding, observations => {} }, { %$binding, width => 'not_a_width' }, { %$binding, width => '16' },
        { %$binding, binding => {callback => sub {1}} });
    my $cycle = {}; $cycle->{self} = $cycle; push @bad, { %$binding, binding => $cycle };
    for my $invalid (@bad) {
        my $s = signal(); my $before = $json->encode([$s->width, $s->declared_width_source]);
        my $ok = eval {$s->set_declared_width_binding($invalid); 1};
        ok(!$ok, 'malformed replacement refuses');
        like($@, qr/Declared width binding/, 'refusal names the private boundary');
        is($s->declared_width_binding, undef, 'failed replacement exposes no old or partial binding');
        is($json->encode([$s->width, $s->declared_width_source]), $before, 'old numeric/source state unchanged');
        $s->set_declared_width_binding(copy($binding));
        is($json->encode($s->declared_width_binding), $expected_json, 'subsequent valid replacement is independent');
    }
    delete $cycle->{self};
};

subtest 'registry refinement and explicit declaration replacement invalidate only private binding state' => sub {
    my $m = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $s = $m->register_signal('data', width => 16, _declared_width_source => copy($source),
        _declared_width_binding => copy($binding));
    is($json->encode($s->declared_width_binding), $expected_json, 'fresh coherent binding installs');
    $m->register_signal('data', is_output => 1);
    is($json->encode($s->declared_width_binding), $expected_json, 'role-only refinement preserves width relationship');
    $m->register_signal('data', width => 8, declared_type_name => undef, declared_type_spec => undef);
    is($s->width, 16, 'ordinary smaller inference leaves effective width unchanged');
    is($json->encode($s->declared_width_binding), $expected_json, 'unchanged effective width and absent type preserve the binding');
    $m->register_signal('data', width => 32);
    is($s->width, 32, 'legacy max-width refinement still updates the actual shared object');
    is($s->declared_width_binding, undef, 'effective width refinement invalidates binding');
    is($json->encode($s->declared_width_source), $json->encode($source), 'legacy source snapshot is preserved');
    $m->register_signal('data', width => 8, _declared_width_binding => copy($binding));
    is($s->width, 32, 'smaller registration never shrinks legacy width');
    is($s->declared_width_binding, undef, 'incoherent fresh metadata is not installed');
    my $other = $m->register_signal('other', width => 16, _declared_width_source => copy($source),
        _declared_width_binding => copy($binding));
    my $replacement = copy($source); $replacement->{expression} = ['param', ['ALIAS']];
    $m->register_signal('other', _declared_width_source => $replacement);
    is($other->width, 16, 'same-valued replacement preserves numeric width');
    is($other->declared_width_binding, undef, 'explicit source replacement invalidates despite equal widths');
    $replacement = copy($source);
    $m->register_signal('other', _declared_width_source => $replacement, _declared_width_binding => copy($binding));
    is($json->encode($other->declared_width_binding), $expected_json, 'coherent source plus fresh binding reinstalls');
    $m->register_signal('other', declared_type_spec => {kind => 'bits', width => 16});
    is($other->declared_width_binding, undef, 'explicit type replacement invalidates');
    $m->register_signal('other', declared_type_spec => undef, _declared_width_binding => copy($binding));
    my $third = $m->register_signal('third', width => 16, _declared_width_source => copy($source),
        _declared_width_binding => copy($binding));
    $m->clear_declared_width_bindings;
    is($other->declared_width_binding, undef, 'whole-registry clear supports failed source transactions');
    is($third->declared_width_binding, undef, 'whole-registry clear covers another actual Signal too');
    $m->clear_declared_width_bindings;
    is($other->width, 16, 'repeated clear does not touch ordinary fields');
};

subtest 'held plain records retain no manager or signal owner' => sub {
    my ($weak_manager, $weak_signal, $held);
    {
        my $m = FSM::Adapter::FSMGenFull::SignalManager->new;
        my $s = $m->register_signal('data', width => 16, _declared_width_source => copy($source),
            _declared_width_binding => copy($binding));
        $weak_manager = $m; weaken($weak_manager); $weak_signal = $s; weaken($weak_signal);
        $held = $s->declared_width_binding;
    }
    ok(!defined($weak_manager), 'plain getter result does not retain manager');
    ok(!defined($weak_signal), 'plain getter result does not retain Signal');
    is($json->encode($held), $expected_json, 'held detached result remains complete');
};
done_testing();
