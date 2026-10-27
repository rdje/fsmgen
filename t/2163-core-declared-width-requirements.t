use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken refaddr);
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull::SignalManager;

ok(FSM::CoreAST::Signal->can('declared_width_requirements')
    && FSM::CoreAST::Signal->can('set_declared_width_requirements'),
    'private Core requirement holder exists') or do { done_testing(); exit };
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
my $scope = {kind => 'direct_module', owner => 'original_header'};
my $capture = {
    scope => copy($scope), width => 8,
    binding => {kind => 'reference', observation_index => 0,
        value_expression => {kind => 'literal', token => '8'}},
    observations => [{lookup => 'parameter', kind => 'parameter', token => 'X',
        parameter => 'X', suffix => '', value_payload => {kind => 'scalar', payload => '8'}}],
};
my $explicit = {kind => 'declaration', signal => 'next_data', expression => ['param', ['X']],
    width => 8, width_capture => copy($capture), declared_type_name => undef, declared_type_spec => undef};
my $generated = {kind => 'generated', signal => 'data', expression => '16',
    width => 16, width_capture => undef, declared_type_name => undef, declared_type_spec => undef};
my $record = {scope => copy($scope), width => 16, requirements => [copy($explicit), copy($generated)]};
my $expected = $json->encode($record);
my $legacy_source = {signal => 'data', expression => ['param', ['W']], resolved_width => 16};
sub signal {
    FSM::CoreAST::Signal->new(name => 'next_data', width => 16,
        _declared_width_source => copy($legacy_source), _declared_width_requirements => copy($record), @_)
}
sub old_state { $json->encode([$_[0]->width, $_[0]->declared_width_source,
    $_[0]->declared_type_name, $_[0]->declared_type_spec]) }

subtest 'separate authored and generated requirements survive detached storage' => sub {
    my $ordinary = FSM::CoreAST::Signal->new(name => 'ordinary', width => 16);
    is($ordinary->declared_width_requirements, undef, 'ordinary object has no inferred provenance');
    ok(!exists $ordinary->{_declared_width_requirements}, 'ordinary constructor adds no field');
    my $input = copy($record);
    my $s = signal(_declared_width_requirements => $input);
    is($json->encode($s->declared_width_requirements), $expected, 'complete independent envelope is retained');
    is($s->declared_width_binding, undef, 'multiple requirements do not fabricate one coherent binding');
    my $before = old_state($s);
    $input->{requirements}[0]{width_capture}{observations}[0]{parameter} = 'W';
    my $got = $s->declared_width_requirements;
    $got->{scope}{owner} = 'renamed'; $got->{requirements}[0]{expression}[1][0] = 'W';
    is($json->encode($s->declared_width_requirements), $expected, 'caller and getter mutations cannot replace X with equal-default W');
    $s->{name} = 'physical_rename';
    is($json->encode($s->declared_width_requirements), $expected, 'physical naming does not rebind lexical origin');
    is(old_state($s), $before, 'all old numeric/source/type getters are unchanged');
    $s->clear_declared_width_requirements;
    is($s->declared_width_requirements, undef, 'explicit clear removes provenance');
    ok(!exists $s->{_declared_width_requirements_state}, 'clear removes the installation anchor too');
};

subtest 'literal, named-type and inferred generated snapshots remain distinct' => sub {
    for my $entry (
        {%$generated, kind => 'declaration', signal => 'next_data'},
        {%$generated, kind => 'declaration', signal => 'next_data', expression => 'word_t',
            declared_type_name => 'word_t', declared_type_spec => {kind => 'bits', width => 16}},
        {%$generated, expression => undef},
    ) {
        my $r = {scope => copy($scope), width => 16, requirements => [$entry]};
        my $s = signal(_declared_width_requirements => $r);
        is($json->encode($s->declared_width_requirements), $json->encode($r), 'snapshot keeps its exact branch and JSON kinds');
    }
    my $one = {scope => copy($scope), width => 1,
        requirements => [{%$generated, width => 1, expression => '1'}]};
    my $s = signal(width => 1, _declared_width_requirements => $one);
    is($json->encode($s->declared_width_requirements), $json->encode($one), 'one-bit observation remains explicit');
};

subtest 'failed replacements clear old data and refuse malformed or executable input' => sub {
    my @bad = ([], {%$record, extra => 1}, {%$record, requirements => []}, {%$record, width => '16'},
        {%$record, width => 32}, {%$record, scope => {kind => 'composition_top', owner => 'top'}});
    for my $change (
        {kind => 'unknown'}, {width => '8'}, {expression => undef}, {extra => 1},
        {width_capture => {%$capture, width => 4}},
        {width_capture => {%$capture, scope => {kind => 'direct_module', owner => 'other'}}},
        {declared_type_name => 'word_t'},
        {declared_type_name => 'word_t', declared_type_spec => {kind => 'bits', width => 8}},
        {expression => [sub {1}]},
    ) { push @bad, {%$record, requirements => [{%$explicit, %$change}, copy($generated)]} }
    my $cycle = []; push @$cycle, $cycle;
    push @bad, {%$record, requirements => [{%$explicit, expression => $cycle}, copy($generated)]};
    for my $bad (@bad) {
        my $s = signal(); my $before = old_state($s);
        ok(!eval {$s->set_declared_width_requirements($bad); 1}, 'invalid replacement refuses');
        like($@, qr/Declared width requirements/, 'refusal names the private boundary');
        is($s->declared_width_requirements, undef, 'failed replacement exposes neither old nor partial records');
        is(old_state($s), $before, 'failed replacement preserves old fields');
        $s->set_declared_width_requirements(copy($record));
        is($json->encode($s->declared_width_requirements), $expected, 'valid retry is independent');
    }
    @$cycle = ();
    my $s = signal(); $s->set_declared_width_requirements(undef);
    is($s->declared_width_requirements, undef, 'undefined replacement explicitly clears');
};

subtest 'actual width/source/type divergence withholds stale snapshots' => sub {
    is(signal(width => 32)->declared_width_requirements, undef, 'incoherent effective width is never installed');
    for my $mutate (
        sub {$_[0]->{_width} = 32},
        sub {$_[0]->{_declared_width_source}{expression} = ['param', ['SAME_VALUE']]},
        sub {$_[0]->{declared_type_name} = 'word_t'},
        sub {$_[0]->{declared_type_spec} = {kind => 'bits', width => 16}},
    ) {
        my $s = signal(); $mutate->($s);
        is($s->declared_width_requirements, undef, 'getter withholds a privately diverged installation');
    }
};

subtest 'manager replacements and whole-registry invalidation cover actual shared objects' => sub {
    my $m = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $s = $m->register_signal('next_data', width => 16, _declared_width_source => copy($legacy_source),
        _declared_width_requirements => copy($record));
    is($json->encode($s->declared_width_requirements), $expected, 'fresh manager installation works');
    is(refaddr($m->register_signal('next_data', width => 8, is_output => 1,
        declared_type_name => undef, declared_type_spec => undef)), refaddr($s), 'legacy refinements retain actual identity');
    is($json->encode($s->declared_width_requirements), $expected, 'smaller inference, role and absent type keep provenance');
    for my $replacement (
        {width => 32}, {_declared_width_source => copy($legacy_source)},
        {_declared_width_source => undef}, {declared_type_name => 'word_t'},
        {declared_type_spec => {kind => 'bits', width => 16}},
    ) {
        my $local = FSM::Adapter::FSMGenFull::SignalManager->new;
        my $actual = $local->register_signal('next_data', width => 16, _declared_width_source => copy($legacy_source),
            _declared_width_requirements => copy($record));
        $local->register_signal('next_data', %$replacement);
        is($actual->declared_width_requirements, undef, 'actual replacement clears requirements even at the same width/source');
        ok(!exists $actual->{_declared_width_requirements}, 'no hidden record can revive after later matching values');
    }
    my $other = $m->register_signal('other', width => 16, _declared_width_requirements => copy($record));
    $m->clear_declared_width_bindings;
    is($s->declared_width_requirements, undef, 'existing transaction-clear API clears new metadata');
    is($other->declared_width_requirements, undef, 'whole actual registry is covered');
    is($s->width, 16, 'whole-registry clearing preserves numeric geometry');
};

subtest 'held plain records do not retain owners' => sub {
    my ($weak_manager, $weak_signal, $held);
    {
        my $m = FSM::Adapter::FSMGenFull::SignalManager->new;
        my $s = $m->register_signal('next_data', width => 16, _declared_width_requirements => copy($record));
        $weak_manager = $m; weaken($weak_manager); $weak_signal = $s; weaken($weak_signal);
        $held = $s->declared_width_requirements;
    }
    ok(!defined($weak_manager) && !defined($weak_signal), 'plain result retains neither manager nor Signal');
    is($json->encode($held), $expected, 'complete detached result remains usable');
};
done_testing();
