use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;
use FSM::SourceLiteralWidthAllocationSupport;

my $class = 'FSM::SourceLiteralWidthAllocationSupport';
my $json = JSON::PP->new->canonical;

sub fixture {
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $manager = $adapter->{signal_manager};
    $manager->register_signal($_, width => 8) for qw(A B);
    return ($adapter->{expression_builder}, $manager);
}
sub current {
    my ($manager, $event) = @_;
    return $class->current_core(signal => $manager->get_signal($event->{signal_name}), holder => $event->{holder});
}

subtest 'named reference and role transitions refresh current births but never escaped capsules' => sub {
    my ($builder, $manager) = fixture();
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        my $result = $builder->parse_expression(['|', 'A', 'B', '256']);
        my $event = $builder->{_source_literal_width_allocation_capture}[0];
        my $old = $json->decode($json->encode($event->{holder}));
        my $literal = $result->signal->driving_ast->right;
        my $before = $json->encode([$literal->value, $literal->width, $literal->radix]);
        $builder->_register_unannotated_reference($result->signal->name);
        ok(current($manager, $event), 'exact bare helper reference carries its current birth');
        ok(!defined($class->current_core(signal => $result->signal, holder => $old)), 'old escaped capsule stays revoked');
        $builder->_set_analyzed_signal_role($result->signal, 'INTERNAL_INTERMEDIATE');
        ok(current($manager, $event), 'actual intermediate role assignment carries current birth');
        $builder->_register_unannotated_reference('A');
        ok(current($manager, $event), 'matching source reference write carries only the named transition');
        $builder->_set_analyzed_signal_role($manager->get_signal('A'), 'INPUT');
        ok(current($manager, $event), 'actual independent source role assignment carries current birth');
        is($json->encode([$literal->value, $literal->width, $literal->radix]), $before, 'raw source literal kinds and data preserve');
        return $result;
    });
    ok(current($manager, $packet->{source_literal_events}[0]), 'completed capture retains its transported current holder');
};

subtest 'actual Parser and facade completion preserve current fixed and mutable literal births' => sub {
    my $capture = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_capture_intermediate_width_allocations');
    for my $facade (0, 1) {for my $width (1, 8) {for my $mutable (0, 1) {
        my $packet;
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_capture_intermediate_width_allocations = sub {
            $packet = $capture->(@_); return $packet;
        };
        my $params = $mutable ? "(+params (W $width))" : '';
        my $slot = $mutable ? '(param W)' : $width;
        my $source = "(?fsm:transition $params (+size (A $slot) (B $slot) (DATA 1) (OTHER 1))"
            .' (idle (<(| A B 256) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $parsed = scalar Lispish::multi(\$source);
        my $module = $facade ? $adapter->parse_fsm($parsed) : $adapter->{parser}->parse_fsm($parsed);
        my $event = $packet->{source_literal_events}[0];
        ok($event, 'actual Parser or facade captures the literal birth');
        my $record = current($adapter->{signal_manager}, $event);
        ok($record && !defined($record->{selected_width}),
            'actual metadata and optional analyzer completion retain unresolved intrinsic intent');
        if ($mutable) {
            my $source_signal = $adapter->{signal_manager}->get_signal('A');
            ok($source_signal->declared_width_requirements && $source_signal->declared_width_binding,
                'currentness includes actual independently published mutable leaf requirements and binding');
        }
        my $helper = $adapter->{signal_manager}->get_signal($event->{signal_name});
        ok(!exists($helper->{_source_literal_width_allocation}),
            'transport alone does not install a completed source policy');
    }}}
};

subtest 'external matching writes failed setters extra writes and foreign membership cannot refresh' => sub {
    for my $write (
        sub {my ($b, $m, $h) = @_; $m->register_signal('A', width => 8)},
        sub {my ($b, $m, $h) = @_; $h->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE')},
        sub {my ($b, $m, $h) = @_; eval {$b->_set_published_width_metadata($m->get_signal('A'), 'binding', {})}},
        sub {my ($b, $m, $h) = @_; $b->_allocation_transition($h, 'signal_role', 'INTERNAL_INTERMEDIATE', sub {
            $h->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE'); $h->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE');
        })},
        sub {my ($b, $m, $h) = @_; $b->_allocation_transition($h, 'signal_role', 'INTERNAL_INTERMEDIATE', sub {
            $h->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE'); $h->driving_ast->right->{value} = '257';
        })},
        sub {my ($b, $m, $h) = @_; $b->_allocation_transition($h, 'signal_role', 'INTERNAL_INTERMEDIATE', sub {
            $h->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE');
            $m->get_signal('A')->{_declared_width_source} = {independent => 8};
        })},
        sub {my ($b, $m, $h) = @_; $b->_allocation_transition($h, undef, undef, sub {
            $h->set_attribute('signal_role', 'INTERNAL_INTERMEDIATE');
        }, {kind => 'future'})},
        sub {my ($b, $m, $h) = @_; $m->{signal_registry}{A} = FSM::CoreAST::Signal->new(name => 'A', width => 8);
            $b->_set_analyzed_signal_role($h, 'INTERNAL_INTERMEDIATE')},
    ) {
        my ($builder, $manager) = fixture();
        my $packet = $builder->_capture_intermediate_width_allocations(sub {
            my $result = $builder->parse_expression(['|', 'A', 'B', '256']);
            $write->($builder, $manager, $result->signal);
            return $result;
        });
        ok(!defined(current($manager, $packet->{source_literal_events}[0])),
            'only a still-current exact sanctioned transition can carry the birth');
    }
};

subtest 'shared sources and duplicate slots carry each current event independently' => sub {
    my ($builder, $manager) = fixture();
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['|', 'A', 'A', '256']);
        $builder->parse_expression(['^', 'A', 'B', '256']);
        $builder->_set_analyzed_signal_role($manager->get_signal('A'), 'INPUT');
        return 1;
    });
    is(scalar(@{$packet->{source_literal_events}}), 2, 'both actual fresh helper events retain');
    ok(current($manager, $_), 'every shared-source event and repeated slot remains current') for @{$packet->{source_literal_events}};
};

done_testing();
