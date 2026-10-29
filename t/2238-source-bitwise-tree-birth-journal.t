use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::SourceBitwiseTreeWidthSupport;

my $json = JSON::PP->new->canonical;
sub fixture {
    my ($width) = @_; $width //= 8;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    $adapter->{signal_manager}->register_signal($_, width => $width) for qw(A B C);
    return $adapter;
}
sub capture {
    my ($adapter, $callback) = @_;
    return $adapter->{expression_builder}->_capture_intermediate_width_allocations($callback);
}
sub current {
    my ($adapter, $event) = @_;
    return unless $event;
    my $builder = $adapter->{expression_builder};
    my $signal = $adapter->{signal_manager}->get_signal($event->{signal_name});
    return unless $builder->_source_tree_allocation_registry_matches($signal);
    return FSM::SourceBitwiseTreeWidthSupport->current_core(signal => $signal, holder => $event->{holder});
}
sub events {return $_[0]{source_tree_events} // []}
sub source {
    my ($width) = @_;
    return "(?fsm:source_tree_birth (+params (W $width))"
        ." (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1) (THIRD 1))"
        ." (idle (<(& A B C) (= (DATA 1)) (= (OTHER 1)))"
        ." (<(| C A A) (= (THIRD 1))) (-> idle)))";
}
sub parse_phases {
    my ($adapter, $text) = @_;
    my $module = $adapter->{parser}->parse_fsm(scalar Lispish::multi(\$text));
    $adapter->{signal_analyzer}->analyze_signal_roles($module);
    $adapter->{signal_analyzer}->generate_fsm_interface($module);
    return $module;
}
sub selected {
    my ($module) = @_;
    return {parameters => $module->parameters, defaults => $module->parameter_default_sources,
        bindings => $module->parameter_default_bindings,
        signals => {map {my $s = $module->signals->{$_}; $_ => {
            width => $s->width, type => $s->type, attributes => $s->attributes,
            binding => $s->declared_width_binding, requirements => $s->declared_width_requirements,
        }} keys %{$module->signals}}};
}

subtest 'actual n-ary birth has a separate detached journal with no publication' => sub {
    my $adapter = fixture();
    my $packet = capture($adapter, sub {$adapter->{expression_builder}->parse_expression(['&', qw(A B C)])});
    is(scalar @{events($packet)}, 1, 'actual fresh source tree has one separate birth');
    return unless @{events($packet)};
    is_deeply($packet->{events}, [], 'old binary bucket remains exact');
    my $event = events($packet)->[0];
    is($event->{signal_name}, $packet->{value}->signal->name, 'birth names actual fresh helper');
    is_deeply(current($adapter, $event), {
        kind => 'source_bitwise_tree_operand_max', operator => '&', selected_width => 8,
        source_names => [qw(A B C)],
        expression_tree => ['&', ['&', ['signal','A'], ['signal','B']], ['signal','C']],
    }, 'actual original tree and all ordered leaf slots bind');
    ok(!defined($packet->{value}->signal->source_bitwise_tree_width_allocation), 'staging installs no Core policy');
    ok(eval {$json->encode(events($packet)); 1}, 'journal is plain detached data');
    ok(!exists($adapter->{expression_builder}{_source_bitwise_tree_width_allocation_capture}), 'new capture scope restores');
    my ($weak_a, $weak_h) = ($adapter->{signal_manager}->get_signal('A'), $packet->{value}->signal);
    weaken($weak_a); weaken($weak_h);
    my $held = events($packet);
    $_->{fanout_signals} = [] for values %{$adapter->{signal_manager}{signal_registry}};
    undef $packet; undef $adapter;
    ok(!defined($weak_a) && !defined($weak_h), 'retained journal does not own the source graph');
};

my $available = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_source_tree_allocation_registry_matches');
subtest 'exact actual Parser and Analyzer transitions preserve current births' => sub {
    plan skip_all => 'source tree journal absent' unless $available;
    for my $width (1, 8) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $packet = capture($adapter, sub {parse_phases($adapter, source($width))});
        is(scalar @{events($packet)}, 2, 'actual source stages two independent trees');
        for my $event (@{events($packet)}) {
            my $record = current($adapter, $event);
            ok($record, 'bare references, declared width publication and roles preserve only current birth');
            is($record && $record->{selected_width}, $width, 'selected width preserves');
            my $helper = $adapter->{signal_manager}->get_signal($event->{signal_name});
            is($helper->get_attribute('signal_role'), 'INTERNAL_INTERMEDIATE', 'actual canonical role follows');
            ok(!defined($helper->source_bitwise_tree_width_allocation), 'completion publication remains separate');
        }
        is_deeply(current($adapter, events($packet)->[1])->{source_names}, [qw(C A A)], 'duplicates and source order preserve');
        my $ordinary = FSM::Adapter::FSMGenFull->new;
        is($json->encode(selected($packet->{value})), $json->encode(selected(parse_phases($ordinary, source($width)))),
            'ordinary numeric/attribute/parameter/width metadata and JSON kinds preserve');
    }
};

subtest 'fresh repeated, nested and negated source helpers keep distinct births' => sub {
    plan skip_all => 'source tree journal absent' unless $available;
    for my $operator ('&','|','^','!&') {
        my $adapter = fixture();
        my $packet = capture($adapter, sub {
            return [map {$adapter->{expression_builder}->parse_expression([$operator, qw(A B C)])} 1..2];
        });
        is(scalar @{events($packet)}, 2, 'each fresh base helper has a distinct source tree event');
        isnt(events($packet)->[0]{signal_name}, events($packet)->[1]{signal_name}, 'repeated expressions keep fresh names');
        ok(current($adapter, $_), 'later bare-reference writes preserve earlier eligible source tree') for @{events($packet)};
        is($packet->{value}[0]->operator, '!', 'negated n-ary retains scalar logical NOT wrapper') if $operator eq '!&';
    }
    my $adapter = fixture();
    my $packet = capture($adapter, sub {
        $adapter->{expression_builder}->parse_expression(['&', ['|', qw(A B C)], 'C', 'A']);
    });
    is(scalar @{events($packet)}, 2, 'actual dependent inner and outer source tree births remain separate');
    ok(current($adapter, $_), 'actual nested helper dependencies remain current') for @{events($packet)};
};

subtest 'external, annotated and unexpected writes cannot borrow a later transition' => sub {
    plan skip_all => 'source tree journal absent' unless $available;
    for my $change (
        sub {$_[0]{signal_manager}->register_signal('C', width => 8)},
        sub {$_[0]{signal_manager}->get_signal('A')->set_attribute('signal_role','INPUT')},
        sub {$_[0]{expression_builder}->parse_expression("C'8")},
        sub {$_[0]{signal_manager}->get_signal('C')->add_constraint({kind=>'independent_floor',width=>8})},
        sub {$_[0]{signal_manager}{signal_registry}{C} = FSM::CoreAST::Signal->new(name=>'C',width=>8)},
    ) {
        my $adapter = fixture();
        my $packet = capture($adapter, sub {
            my $reference = $adapter->{expression_builder}->parse_expression(['&', qw(A B C)]);
            $change->($adapter);
            $adapter->{expression_builder}->parse_expression('C');
            $adapter->{expression_builder}->_set_analyzed_signal_role($reference->signal, 'INTERNAL_INTERMEDIATE');
            return $reference;
        });
        ok(!defined(current($adapter, events($packet)->[0])), 'later sanctioned operations cannot revive old birth');
    }
    my $adapter = fixture();
    my $original = FSM::Adapter::FSMGenFull::SignalManager->can('register_signal');
    my $packet = capture($adapter, sub {
        my $reference = $adapter->{expression_builder}->parse_expression(['&', qw(A B C)]);
        {
            no warnings 'redefine';
            local *FSM::Adapter::FSMGenFull::SignalManager::register_signal = sub {
                my ($manager, $name, @args) = @_;
                my $result = $original->($manager, $name, @args);
                $original->($manager, 'C', width => 8) if $name eq 'A';
                return $result;
            };
            $adapter->{expression_builder}->parse_expression('A');
        }
        return $reference;
    });
    ok(!defined(current($adapter, events($packet)->[0])), 'extra matching write to third leaf cannot be laundered');
};

subtest 'unsupported and ordinary profiles keep the old packet and tracker shape' => sub {
    plan skip_all => 'source tree journal absent' unless $available;
    for my $shape (['&',qw(A B)], ['&','A','B','3'], ['&','A[7:0]','B','C']) {
        my $adapter = fixture();
        my $packet = capture($adapter, sub {$adapter->{expression_builder}->parse_expression($shape)});
        ok(!exists($packet->{source_tree_events}), 'no optional source tree bucket without a qualified birth');
    }
    my $adapter = fixture();
    $adapter->{signal_manager}->register_signal('C', signed => 1);
    my $packet = capture($adapter, sub {$adapter->{expression_builder}->parse_expression(['&',qw(A B C)])});
    ok(!exists($packet->{source_tree_events}), 'signed leaf withholds source tree intent');
    my $foreign = fixture();
    my $other_c = FSM::CoreAST::Signal->new(name => 'C', width => 8);
    my @refs = map {FSM::CoreAST::SignalRef->new($_)}
        ($foreign->{signal_manager}->get_signal('A'), $foreign->{signal_manager}->get_signal('B'), $other_c);
    my $foreign_packet = capture($foreign, sub {
        $foreign->{expression_builder}->finalize_nary_expression('&', \@refs);
    });
    ok(!exists($foreign_packet->{source_tree_events}), 'a foreign same-name Core leaf cannot stage a registry-owned birth');
    ok(!exists($other_c->{_intermediate_width_allocation_revision}), 'refused foreign leaf gains no tracker');
    my $ordinary = fixture();
    $ordinary->{expression_builder}->parse_expression(['&',qw(A B C)]);
    ok(!exists($_->{_intermediate_width_allocation_revision}), 'uncaptured source gains no revision tracker')
        for values %{$ordinary->{signal_manager}{signal_registry}};
};

subtest 'capture failure and retry restore both journal scopes' => sub {
    plan skip_all => 'source tree journal absent' unless $available;
    my $adapter = fixture();
    eval {capture($adapter, sub {
        $adapter->{expression_builder}->parse_expression(['&',qw(A B C)]);
        die "after tree birth\n";
    })};
    like($@, qr/after tree birth/, 'original failure propagates');
    ok(!exists($adapter->{expression_builder}{_intermediate_width_allocation_capture})
        && !exists($adapter->{expression_builder}{_source_bitwise_tree_width_allocation_capture}), 'both scoped journals disappear');
    my $retry = capture($adapter, sub {$adapter->{expression_builder}->parse_expression(['|',qw(A B C)])});
    is(scalar @{events($retry)}, 1, 'retry retains only its own fresh birth');
    is(current($adapter, events($retry)->[0])->{operator}, '|', 'failed old operator cannot leak into retry');
};

done_testing();
