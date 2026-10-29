use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::SourceLiteralWidthAllocationSupport;

my $json = JSON::PP->new->canonical;
my $holder_class = 'FSM::SourceLiteralWidthAllocationSupport';

sub builder {
    my ($width) = @_;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    $adapter->{signal_manager}->register_signal($_, width => $width // 8) for qw(A B C);
    return ($adapter->{expression_builder}, $adapter->{signal_manager});
}
sub parse {
    my ($builder, $expression) = @_;
    return $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression($expression)});
}

subtest 'actual direct literal births retain a separate raw nullable holder' => sub {
    for my $width (1, 8) {for my $token ('256', "9'b100000000") {
        my ($builder, $manager) = builder($width);
        my $expression = ['|', 'A', 'B', $token];
        my $before = $json->encode($expression);
        my $packet = parse($builder, $expression);
        my $events = $packet->{source_literal_events};
        is(ref($events), 'ARRAY', 'actual source birth supplies a separate optional journal bucket');
        next unless ref($events) eq 'ARRAY';
        is(scalar(@$events), 1, 'exact fresh helper owns its direct literal birth');
        my $event = $events->[0];
        is(join(',', sort keys %$event), 'holder,signal_name', 'event keeps only selected name and detached holder');
        my $helper = $packet->{value}->signal;
        is(refaddr($helper), refaddr($manager->get_signal($event->{signal_name})), 'actual registered helper owns the event');
        my $record = $holder_class->current_core(signal => $helper, holder => $event->{holder});
        ok($record, 'birth is current before source completion transitions');
        next unless $record;
        my $sized = $token =~ /'/;
        is($record->{selected_width}, $sized ? 9 : undef, 'exact explicit width and unresolved unsized width remain distinct');
        is($helper->width, $sized ? 9 : 1, 'no backend literal default is assigned to source');
        is($json->encode($record->{expression_tree}), $json->encode(['|', ['|', ['signal', 'A'], ['signal', 'B']],
            ['literal', {value => $sized ? '100000000' : 256, width => $sized ? 9 : undef,
                radix => $sized ? 'binary' : 'decimal'}]]), 'actual ordered tree and raw literal value width and radix preserve');
        my $literal = $helper->driving_ast->right;
        is($json->encode($record->{expression_tree}[2][1]),
            $json->encode({value => $literal->value, width => $literal->width, radix => $literal->radix}),
            'journal keeps actual parsed Core literal kinds independently of caller token spelling');
        is($json->encode($expression), $before, 'caller expression and scalar kinds preserve');
        is_deeply($packet->{events}, [], 'literal birth does not forge an old binary event');
        ok(!exists($packet->{source_tree_events}), 'literal birth does not forge an all-reference tree event');
        ok(eval {$json->encode($events); 1}, 'journal retains plain JSON rather than owners');
    }}
};

subtest 'ordinary source births conserve old buckets and withhold unsupported direct profiles' => sub {
    my ($builder) = builder();
    my $binary = parse($builder, ['&', 'A', 'B']);
    is(scalar(@{$binary->{events}}), 1, 'old binary allocation bucket preserves');
    ok(!exists($binary->{source_literal_events}), 'nonliteral binary has no literal bucket');
    my $tree = parse($builder, ['^', 'A', 'B', 'C']);
    is(scalar(@{$tree->{source_tree_events}}), 1, 'old all-reference tree bucket preserves');
    ok(!exists($tree->{source_literal_events}), 'nonliteral tree has no literal bucket');
    my $nested = parse($builder, ['^', ['|', 'A', 'B', '256'], 'C']);
    is(scalar(@{$nested->{source_literal_events} // []}), 1, 'only the direct literal child has the currently bounded birth');
    if (my $event = $nested->{source_literal_events}[0]) {
        isnt($event->{signal_name}, $nested->{value}->signal->name, 'outer generated-child reference cannot borrow direct literal ownership');
    }
    for my $expression (['|', 'A[0:0]', '256'], ['|', ['+', 'A', 'B'], '256']) {
        my $packet = parse($builder, $expression);
        ok(!exists($packet->{source_literal_events}), 'sliced or computed direct profile installs no literal event');
    }
};

subtest 'fresh registry ownership distinguishes births from matching old or foreign state' => sub {
    my ($builder, $manager) = builder();
    my $first = parse($builder, ['|', 'A', '256']);
    my $events = $first->{source_literal_events};
    ok(ref($events) eq 'ARRAY' && @$events, 'ownership controls have an actual birth');
    return unless ref($events) eq 'ARRAY' && @$events;
    my $helper = $first->{value}->signal;
    $manager->register_signal($helper->name, width => $helper->width);
    ok(!defined($holder_class->current_core(signal => $helper, holder => $events->[0]{holder})),
        'matching registry write revokes the staged literal birth');
    {
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::generate_intermediate_signal = sub {$helper->name};
        my $packet = parse($builder, ['|', 'A', '256']);
        ok(!exists($packet->{source_literal_events}), 'equal existing registration cannot manufacture a fresh birth');
    }
    {
        my $original = FSM::Adapter::FSMGenFull::SignalManager->can('register_signal');
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::SignalManager::register_signal = sub {
            my ($self, $name, @args) = @_;
            my $signal = $original->(@_);
            if ($signal->get_attribute('is_intermediate')) {
                $self->{signal_registry}{A} = FSM::CoreAST::Signal->new(name => 'A', width => 8);
            }
            return $signal;
        };
        my $packet = parse($builder, ['|', 'A', '256']);
        ok(!exists($packet->{source_literal_events}), 'equal foreign operand registry object cannot borrow source membership');
    }
};

subtest 'actual facade parses observe births before completed publication' => sub {
    my $stage = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_stage_source_literal_width_allocation');
    ok($stage, 'actual builder has an explicit birth staging locus');
    return unless $stage;
    for my $width (1, 8) {for my $mutable (0, 1) {
        my @seen;
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_stage_source_literal_width_allocation = sub {
            my ($self, $signal, @args) = @_;
            my $out = $stage->(@_);
            my $events = $self->{_source_literal_width_allocation_capture};
            for my $event (@{$events // []}) {
                next unless $event->{signal_name} eq $signal->name;
                my $record = $holder_class->current_core(signal => $signal, holder => $event->{holder});
                push @seen, {name => $signal->name, record => $record};
            }
            return $out;
        };
        my $params = $mutable ? "(+params (W $width))" : '';
        my $slot = $mutable ? '(param W)' : $width;
        my $source = "(?fsm:birth $params (+size (A $slot) (B $slot) (DATA 1) (OTHER 1))"
            .' (idle (<(| A B 256) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $module = $adapter->parse_fsm(scalar Lispish::multi(\$source));
        is(scalar(@seen), 1, 'actual fixed/mutable parser and analyzer path observes the literal birth');
        ok($seen[0]{record} && !defined($seen[0]{record}{selected_width}), 'actual source birth preserves unresolved exact width');
        ok($module->signals->{$seen[0]{name}}->source_literal_width_allocation,
            'validated facade completion publishes the independently observed birth');
    }}
};

subtest 'failed capture discards its journal and leaves subsequent capture usable' => sub {
    my ($builder) = builder();
    eval {$builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['|', 'A', '256']); die "source capture failed\n";
    })};
    like($@, qr/source capture failed/, 'callback error propagates');
    ok(!exists($builder->{_source_literal_width_allocation_capture}), 'failed capture leaves no in-flight literal journal');
    my $packet = parse($builder, ['|', 'A', '256']);
    is(scalar(@{$packet->{source_literal_events} // []}), 1, 'fresh capture has only its current successful literal birth');
};

done_testing();
