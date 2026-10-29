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

my $class = 'FSM::SourceLiteralWidthAllocationSupport';
my $json = JSON::PP->new->canonical;
sub fixture {
    my ($sized) = @_;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $manager = $adapter->{signal_manager};
    $manager->register_signal('A', width => 8);
    $manager->register_signal('B', width => 16, width_declared => 1);
    my $builder = $adapter->{expression_builder};
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['&', ['^', ['|', 'A', $sized ? "9'b100000000" : '256'], 'B'], 'A']);
    });
    return ($builder, $manager, $packet);
}
sub publish {
    my ($builder, $packet) = @_;
    $builder->_publish_intermediate_width_allocations(
        $packet->{events}, $packet->{source_tree_events}, $packet->{source_literal_events});
}
sub birth_children {
    my ($events) = @_;
    return {phase => 'birth', lookup => sub {
        my ($event) = grep {$_->{signal_name} eq $_[0]->signal->name} @$events;
        return $event ? $event->{holder} : undef;
    }};
}
sub source {
    my (%args) = @_;
    my $bits = $args{bits} // 8;
    my $slot = $args{mutable} ? '(param W)' : $bits;
    my $params = $args{mutable} ? "(+params (W $bits))" : '';
    my $literal = $args{sized} ? "9'b100000000" : '256';
    return "(?fsm:nested_publication $params (+size (A $slot) (B 16) (DATA 1) (OTHER 1))"
        ." (idle (<(& (^ (| A $literal) B) A) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse {
    my ($adapter, $facade, $text) = @_;
    my $raw = scalar Lispish::multi(\$text);
    return $facade ? $adapter->parse_fsm($raw) : $adapter->{parser}->parse_fsm($raw);
}

subtest 'completion installs current nested policy without changing original births or epochs' => sub {
    for my $sized (0, 1) {
        my ($builder, $manager, $packet) = fixture($sized);
        my $events = $packet->{source_literal_events};
        my $before = $json->encode($events);
        my @signals = map {$manager->get_signal($_->{signal_name})} @$events;
        my $epochs = $json->encode([map {$_->_intermediate_width_allocation_revision} @signals]);
        publish($builder, $packet);
        for my $index (0 .. $#$events) {
            my $signal = $signals[$index];
            my $policy = $signal->source_literal_width_allocation;
            is_deeply($policy, $events->[$index]{holder}{record}, 'completed actual helper preserves expanded raw source intent');
            ok($class->current_core(signal => $signal, holder => $events->[$index]{holder}, children => birth_children($events)),
                'original provisional capsule stays current only under its birth contract');
        }
        is($json->encode($events), $before, 'completion does not rewrite escaped birth capsules or JSON kinds');
        is($json->encode([map {$_->_intermediate_width_allocation_revision} @signals]), $epochs, 'all source epochs preserve');
        my $last = $signals[-1]->source_literal_width_allocation;
        if ($last) {
            $last->{expression_tree}[1][1][2][1]{value} = 'changed';
            is_deeply($signals[-1]->source_literal_width_allocation, $events->[-1]{holder}{record}, 'completed getter detaches');
        }
        $manager->register_signal('A', width => 8);
        ok(!grep({defined $_->source_literal_width_allocation} @signals), 'matching source write revokes all completed levels');
    }
};

subtest 'actual Parser and facade publish nested policy after complete normal validation' => sub {
    my $capture = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_capture_intermediate_width_allocations');
    my $publisher = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_publish_intermediate_width_allocations');
    for my $facade (0, 1) {for my $bits (1, 8) {for my $mutable (0, 1) {for my $sized (0, 1) {
        my ($packet, $boundary);
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_capture_intermediate_width_allocations = sub {
            $packet = $capture->(@_); return $packet;
        };
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_publish_intermediate_width_allocations = sub {
            my ($builder, undef, undef, $events) = @_;
            $boundary = 1;
            for my $event (@$events) {
                my $signal = $builder->{signal_manager}->get_signal($event->{signal_name});
                ok(!defined $signal->source_literal_width_allocation, 'no provisional birth leaks before publication');
                is($signal->get_attribute('signal_role'), 'INTERNAL_INTERMEDIATE', 'facade roles complete before publication') if $facade;
            }
            return $publisher->(@_);
        };
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $text = source(bits => $bits, mutable => $mutable, sized => $sized);
        my $raw = scalar Lispish::multi(\$text);
        my $before = $json->encode($raw);
        my $module = $facade ? $adapter->parse_fsm($raw) : $adapter->{parser}->parse_fsm($raw);
        ok($boundary, 'normal completion owns publication');
        is($json->encode($raw), $before, 'complete caller source and kinds preserve');
        my $events = $packet->{source_literal_events};
        is(scalar(@$events), 3, 'complete actual nested birth chain retains');
        for my $event (@$events) {
            my $signal = $adapter->{signal_manager}->get_signal($event->{signal_name});
            is_deeply($signal->source_literal_width_allocation, $event->{holder}{record}, 'actual Parser/facade completed nested intent is current');
            is($signal->width, $sized ? ($event == $events->[0] ? 9 : 16) : 1, 'explicit and unresolved widths remain distinct');
            is(refaddr($module->signals->{$signal->name}), refaddr($signal), 'facade attaches actual source helper') if $facade;
        }
    }}}}
};

subtest 'a newly current replacement child cannot impersonate the original completed edge' => sub {
    for my $change (
        sub {
            my ($m, $child) = @_;
            $child->set_source_literal_width_allocation($child->source_literal_width_allocation);
            ok($child->source_literal_width_allocation, 'matching explicit replacement is independently current at its new epoch');
        },
        sub {
            my ($m, $child) = @_;
            $child->{_source_literal_width_allocation}{record}{selected_width} = '9';
            ok($child->source_literal_width_allocation, 'changed child record kind is independently numerically current');
        },
        sub {my ($m, $child) = @_; delete $child->{_source_literal_width_allocation}},
        sub {my ($m, $child) = @_; $m->{signal_registry}{$child->name} = FSM::CoreAST::Signal->new(name => $child->name, width => 9)},
    ) {
        my ($builder, $manager, $packet) = fixture(1);
        my $events = $packet->{source_literal_events};
        my $publisher = FSM::CoreAST::Signal->can('_publish_staged_source_literal_width_allocation');
        my $changed = 0;
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::_publish_staged_source_literal_width_allocation = sub {
            my ($signal) = @_;
            if ($signal->name eq $events->[1]{signal_name} && !$changed++) {
                $change->($manager, $manager->get_signal($events->[0]{signal_name}));
            }
            return $publisher->(@_);
        };
        publish($builder, $packet);
        ok($changed, 'replacement occurs after direct child installation before parent publication');
        ok(!defined $packet->{value}->signal->source_literal_width_allocation,
            'source epoch or exact installed capsule mismatch withholds all dependent publication');
    }
};

subtest 'completed capture fences late installed-child removal and raw source writes' => sub {
    my $capture = $class->can('_capture');
    my $width = FSM::CoreAST::Signal->can('width');
    for my $remove_policy (0, 1) {
        my ($builder, $manager, $packet) = fixture();
        my $events = $packet->{source_literal_events};
        my $changed = 0;
        no warnings 'redefine';
        local *FSM::SourceLiteralWidthAllocationSupport::_capture = sub {
            my ($signal, $children) = @_;
            if ($signal->name eq $events->[1]{signal_name} && ($children->{phase} // '') eq 'completed') {
                local *FSM::CoreAST::Signal::width = sub {
                    my ($source) = @_;
                    if ($source->name eq 'B' && !$changed++) {
                        if ($remove_policy) {
                            delete $manager->get_signal($events->[0]{signal_name})->{_source_literal_width_allocation};
                        } else {
                            $manager->get_signal('A')->{_declared_width_source} = {independent => 8};
                        }
                    }
                    return $width->(@_);
                };
                return $capture->(@_);
            }
            return $capture->(@_);
        };
        publish($builder, $packet);
        ok($changed, 'late write occurs during actual completed child validation');
        ok(!defined $packet->{value}->signal->source_literal_width_allocation, 'completed raw/capsule barrier withholds dependent policy');
    }
};

subtest 'late analysis and partial nested publication failures revoke policy and permit reuse' => sub {
    for my $facade (0, 1) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $publisher = FSM::CoreAST::Signal->can('_publish_staged_source_literal_width_allocation');
        my $seen = 0;
        {
            no warnings 'redefine';
            local *FSM::CoreAST::Signal::_publish_staged_source_literal_width_allocation = sub {
                die "nested publication interrupted\n" if $seen++ == 2;
                return $publisher->(@_);
            };
            ok(!eval {parse($adapter, $facade, source()); 1}, 'actual late publication fails');
            like($@, qr/nested publication interrupted/, 'original failure diagnostic preserves');
        }
        ok(!grep({defined $_->source_literal_width_allocation} values %{$adapter->{signal_manager}{signal_registry}}),
            'failure cleanup revokes every partially installed policy');
        parse($adapter, $facade, source());
        is(scalar(grep {defined $_->source_literal_width_allocation} values %{$adapter->{signal_manager}{signal_registry}}), 3,
            'same source can complete afresh after failure');
        my @old = grep {defined $_->source_literal_width_allocation} values %{$adapter->{signal_manager}{signal_registry}};
        ok(!eval {parse($adapter, $facade, '(?future:invalid)'); 1}, 'failed reuse rejects invalid root');
        ok(!grep({defined $_->source_literal_width_allocation} @old), 'failed reuse also revokes escaped completed helpers');
    }
};

done_testing();
