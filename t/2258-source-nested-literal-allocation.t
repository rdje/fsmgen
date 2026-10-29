use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::SourceLiteralWidthAllocationSupport;
use Lispish;

my $json = JSON::PP->new->canonical;
my $class = 'FSM::SourceLiteralWidthAllocationSupport';
sub fixture {
    my ($bits) = @_;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $manager = $adapter->{signal_manager};
    $manager->register_signal('A', width => $bits // 8);
    $manager->register_signal('B', width => 16, width_declared => 1);
    return ($adapter->{expression_builder}, $manager);
}
sub children {
    my ($manager, $events) = @_;
    return {phase => 'birth', lookup => sub {
        my ($reference) = @_;
        my $signal = $reference->signal;
        return unless refaddr($manager->{signal_registry}{$signal->{name}} // {}) == refaddr($signal);
        my ($event) = grep {$_->{signal_name} eq $signal->{name}} @$events;
        return $event ? $event->{holder} : undef;
    }};
}
sub current {
    my ($manager, $events, $event) = @_;
    return $class->current_core(signal => $manager->get_signal($event->{signal_name}),
        holder => $event->{holder}, children => children($manager, $events));
}

subtest 'actual allocation resolves a child before registering its parent' => sub {
    for my $bits (1, 8) {for my $sized (0, 1) {
        my ($builder, $manager) = fixture($bits);
        my $expression = ['^', ['|', 'A', $sized ? "9'b100000000" : '256'], 'B'];
        my $before = $json->encode($expression);
        my @registered;
        my $register = FSM::Adapter::FSMGenFull::SignalManager->can('register_signal');
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::SignalManager::register_signal = sub {
            my ($self, $name, %args) = @_;
            push @registered, {%args} if $args{is_intermediate};
            return $register->(@_);
        };
        my $packet = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression($expression)});
        my $events = $packet->{source_literal_events} // [];
        is(scalar(@$events), 2, 'direct child and actual fresh parent both carry literal births');
        is($registered[-1]{width}, $sized ? 16 : undef, 'registration receives exact width or genuinely absent width');
        is($packet->{value}->signal->width, $sized ? 16 : 1, 'unresolved child never lends compatibility width to parent');
        is($manager->get_signal('B')->width, 16, 'independent declared floor preserves');
        is($json->encode($expression), $before, 'caller source and JSON kinds preserve');
        next unless @$events == 2;
        my $record = current($manager, $events, $events->[-1]);
        ok($record, 'current actual parent joins current child birth');
        next unless $record;
        is($record->{selected_width}, $sized ? 16 : undef, 'source exact nullable width preserves');
        is_deeply($record->{expression_tree}, ['^', $events->[0]{holder}{record}{expression_tree}, ['signal', 'B']],
            'record expands actual original source while keeping typed child edges');
        is_deeply($packet->{events}, [], 'unknown child cannot create old binary max intent') unless $sized;
    }}
};

subtest 'actual named writes transport every nested birth child first' => sub {
    my ($builder, $manager) = fixture();
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        my $result = $builder->parse_expression(['&', ['^', ['|', 'A', '256'], 'B'], 'A']);
        my $events = $builder->{_source_literal_width_allocation_capture};
        is(scalar(@$events), 3, 'all actual nested allocations are journaled');
        my $escaped = $json->decode($json->encode($events));
        $builder->_set_analyzed_signal_role($manager->get_signal('A'), 'INPUT');
        $builder->_register_unannotated_reference($events->[0]{signal_name});
        for my $event (@$events) {
            ok(current($manager, $events, $event), 'exact named reference and source role operations preserve parent intent');
        }
        ok(!current($manager, $escaped, $escaped->[-1]), 'escaped capsules stay stale');
        return $result;
    });
    ok(current($manager, $packet->{source_literal_events}, $packet->{source_literal_events}[-1]),
        'capture restores only its scope, not the current raw proof');
};

subtest 'stale missing copied foreign or independently constrained child cannot lend a width or birth' => sub {
    for my $change (
        sub {my ($b, $m, $c) = @_; $c->set_attribute('signal_role', 'intermediate')},
        sub {my ($b, $m, $c) = @_; $b->{_source_literal_width_allocation_capture} = []},
        sub {my ($b, $m, $c) = @_; $c->{_declared_width_source} = {independent => 1}},
        sub {my ($b, $m, $c) = @_; $m->{signal_registry}{A} = FSM::CoreAST::Signal->new(name => 'A', width => 8)},
        sub {my ($b, $m, $c) = @_; eval {$c->set_declared_width_binding({})}},
        sub {
            my ($b, $m, $c) = @_;
            my ($foreign) = fixture();
            my $packet = $foreign->_capture_intermediate_width_allocations(sub {$foreign->parse_expression(['|', 'A', '256'])});
            $b->{_source_literal_width_allocation_capture}[0]{holder} = $packet->{source_literal_events}[0]{holder};
        },
    ) {
        my ($builder, $manager) = fixture();
        $builder->_capture_intermediate_width_allocations(sub {
            my $child = $builder->parse_expression(['|', 'A', '256'])->signal;
            $change->($builder, $manager, $child);
            my $parent = $builder->finalize_nary_expression('^', [FSM::CoreAST::SignalRef->new($child),
                FSM::CoreAST::SignalRef->new($manager->get_signal('B'))]);
            my $events = $builder->{_source_literal_width_allocation_capture};
            ok(!grep({$_->{signal_name} eq $parent->signal->name} @$events), 'unproved child creates no parent literal intent');
            ok(!grep({$_->{signal_name} eq $parent->signal->name} @{$builder->{_intermediate_width_allocation_capture}}),
                'unproved literal child cannot borrow old binary intent');
            return $parent;
        });
    }
};

subtest 'ordinary independent references and scalar wrappers retain their rules' => sub {
    my ($builder, $manager) = fixture();
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        my $child = $builder->parse_expression(['|', 'A', '256']);
        is($builder->infer_exact_expression_width(FSM::CoreAST::SignalRef->new($manager->get_signal('B'))), 16,
            'independent declaration remains exact');
        for my $scalar (FSM::CoreAST::UnaryOp->new(operator => '!', operand => $child),
            FSM::CoreAST::BinaryOp->new('==', $child, FSM::CoreAST::Literal->new('0'))) {
            is($builder->infer_exact_expression_width($scalar), 1, 'scalar result does not inherit unknown operand width');
        }
        return $builder->parse_expression(['&', 'A', 'B']);
    });
    is($packet->{value}->signal->width, 16, 'ordinary binary selected maximum preserves');
    is(scalar(@{$packet->{events}}), 1, 'ordinary binary keeps its own allocation family');
    my $nested = $builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['^', ['&', 'A', 'B'], 'B']);
    });
    is($nested->{value}->signal->width, 16, 'current nonliteral child retains ordinary max policy');
    is(scalar(@{$nested->{events}}), 2, 'both nonliteral binary proofs preserve');
};

subtest 'actual Parser and facade keep nested births through fixed and mutable completion writes' => sub {
    my $capture = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_capture_intermediate_width_allocations');
    for my $facade (0, 1) {for my $bits (1, 8) {for my $mutable (0, 1) {for my $sized (0, 1) {
        my $packet;
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_capture_intermediate_width_allocations = sub {
            $packet = $capture->(@_); return $packet;
        };
        my $params = $mutable ? "(+params (W $bits))" : '';
        my $slot = $mutable ? '(param W)' : $bits;
        my $literal = $sized ? "9'b100000000" : '256';
        my $source = "(?fsm:nested_allocation $params (+size (A $slot) (B 16) (DATA 1) (OTHER 1))"
            ." (idle (<(^ (| A $literal) B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $manager = $adapter->{signal_manager};
        my $raw = scalar Lispish::multi(\$source);
        my $before = $json->encode($raw);
        $facade ? $adapter->parse_fsm($raw) : $adapter->{parser}->parse_fsm($raw);
        is($json->encode($raw), $before, 'complete caller source preserves');
        my $events = $packet->{source_literal_events} // [];
        is(scalar(@$events), 2, 'both literal births survive actual validation and metadata operations');
        for my $event (@$events) {
            ok(current($manager, $events, $event), 'actual parsed birth remains current');
        }
        if ($mutable) {
            my $a = $manager->get_signal('A');
            ok($a->declared_width_binding && $a->declared_width_requirements,
                'real mutable leaf metadata completes before birth validation');
        }
        is($manager->get_signal('B')->width, 16, 'independent fixed floor remains');
    }}}}
};

done_testing();
