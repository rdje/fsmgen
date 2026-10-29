use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;

my $json = JSON::PP->new->canonical;
sub policy {
    my ($signal) = @_;
    return $signal->can('source_literal_width_allocation')
        ? $signal->source_literal_width_allocation : undef;
}
sub fixture {
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $manager = $adapter->{signal_manager};
    $manager->register_signal($_, width => 8) for qw(A B C);
    my $builder = $adapter->{expression_builder};
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['|', 'A', 'B', '256']);
    });
    return ($builder, $manager, $packet->{value}->signal, $packet);
}
sub publish {
    my ($builder, $packet) = @_;
    $builder->_publish_intermediate_width_allocations(
        $packet->{events}, $packet->{source_tree_events}, $packet->{source_literal_events});
}
sub source {
    my (%args) = @_;
    my $width = $args{width} // 8;
    my $params = $args{mutable} ? "(+params (W $width))" : '';
    my $slot = $args{mutable} ? '(param W)' : $width;
    my $literal = $args{sized} ? "9'b100000000" : '256';
    return "(?fsm:literal_publication $params (+size (A $slot) (B $slot) (DATA 1) (OTHER 1))"
        . " (idle (<(| A B $literal) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
}
sub parse {
    my ($adapter, $facade, $text) = @_;
    my $raw = scalar Lispish::multi(\$text);
    return $facade ? $adapter->parse_fsm($raw) : $adapter->{parser}->parse_fsm($raw);
}

subtest 'Core explicit installation detaches records and shares revocation across allocation families' => sub {
    my ($builder, $manager, $helper, $packet) = fixture();
    my $set = $helper->can('set_source_literal_width_allocation');
    ok($set, 'Core exposes explicit literal allocation installation');
    return unless $set;
    my $input = $packet->{source_literal_events}[0]{holder}{record};
    my $before = $json->encode($input);
    is($helper->set_source_literal_width_allocation($input), $helper, 'setter returns its Signal');
    is($json->encode(policy($helper)), $before, 'nullable width and raw source JSON kinds preserve');
    $input->{expression_tree}[2][1]{value} = 'changed';
    my $out = policy($helper); $out->{expression_tree}[2][1]{radix} = 'hex';
    is($json->encode(policy($helper)), $before, 'both input and getter data detach');
    ok(!eval {$helper->set_source_literal_width_allocation({}); 1}, 'malformed replacement throws');
    ok(!defined(policy($helper)), 'failed replacement revokes the previous literal intent');
    $helper->set_source_literal_width_allocation($json->decode($before));
    $helper->clear_intermediate_width_allocation;
    ok(!defined(policy($helper)), 'common clear revokes literal intent');
    $helper->set_source_literal_width_allocation($json->decode($before));
    $helper->set_source_literal_width_allocation(undef);
    ok(!defined(policy($helper)), 'undef explicit replacement clears');
    my $ordinary = FSM::CoreAST::Signal->new(name => 'ORDINARY');
    my $keys = join(',', sort keys %$ordinary);
    ok(!defined(policy($ordinary)), 'ordinary absent lookup withholds');
    $ordinary->clear_intermediate_width_allocation;
    is(join(',', sort keys %$ordinary), $keys, 'absent lookup and common clear create no fields');
};

subtest 'staged publication is current detached and does not advance semantic revisions' => sub {
    my ($builder, $manager, $helper, $packet) = fixture();
    my @objects = ($helper, map {$manager->get_signal($_)} qw(A B));
    my $before = $json->encode([map {$_->_intermediate_width_allocation_revision} @objects]);
    ok(!defined(policy($helper)), 'birth alone exposes no policy');
    publish($builder, $packet);
    is($json->encode(policy($helper)), $json->encode($packet->{source_literal_events}[0]{holder}{record}),
        'current completed publication retains raw source intent');
    is($json->encode([map {$_->_intermediate_width_allocation_revision} @objects]), $before,
        'publication preserves dependent semantic epochs');
    $packet->{source_literal_events}[0]{holder}{record}{expression_tree}[2][1]{value} = 'changed';
    ok(policy($helper), 'escaping and changing the journal cannot mutate installed intent');
    my $binary = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression(['&', 'A', 'B'])});
    publish($builder, $binary);
    ok($binary->{value}->signal->intermediate_width_allocation, 'old optional binary-only call still publishes');
    ok(!defined(policy($binary->{value}->signal)), 'binary publication does not manufacture literal intent');
};

subtest 'actual direct Parser and facade publish only after their complete validation boundary' => sub {
    my $capture = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_capture_intermediate_width_allocations');
    my $publish = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_publish_intermediate_width_allocations');
    for my $facade (0, 1) {for my $width (1, 8) {for my $mutable (0, 1) {for my $sized (0, 1) {
        my ($packet, $at_boundary);
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_capture_intermediate_width_allocations = sub {
            $packet = $capture->(@_); return $packet;
        };
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_publish_intermediate_width_allocations = sub {
            my ($builder, undef, undef, $literal_events) = @_;
            $at_boundary = scalar(@{$literal_events // []});
            for my $event (@{$literal_events // []}) {
                my $helper = $builder->{signal_manager}->get_signal($event->{signal_name});
                ok(!defined(policy($helper)), 'no completed literal policy before final publication');
                is($helper->get_attribute('signal_role'), 'INTERNAL_INTERMEDIATE', 'normal source roles validate before publication')
                    if $facade;
            }
            return $publish->(@_);
        };
        my $text = source(width => $width, mutable => $mutable, sized => $sized);
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $module = parse($adapter, $facade, $text);
        is($at_boundary, 1, 'actual Parser or facade forwards its separate literal packet');
        my $event = $packet->{source_literal_events}[0];
        my $helper = $adapter->{signal_manager}->get_signal($event->{signal_name});
        my $record = policy($helper);
        is($json->encode($record), $json->encode($event->{holder}{record}), 'actual completed source publishes its current literal intent');
        next unless $record;
        is($record->{selected_width}, $sized ? 9 : undef, 'explicit floor and unresolved width remain distinct');
        is($helper->width, $sized ? 9 : 1, 'no target default is installed in Core');
        is($json->encode($record->{expression_tree}), $json->encode(['|', ['|', ['signal', 'A'], ['signal', 'B']],
            ['literal', {value => $sized ? '100000000' : 256, width => $sized ? 9 : undef,
                radix => $sized ? 'binary' : 'decimal'}]]), 'ordered raw literal value size radix and JSON kinds preserve');
        is($facade ? refaddr($module->signals->{$helper->name}) : exists($module->signals->{$helper->name}),
            $facade ? refaddr($helper) : '', 'direct registry and facade module membership stay separate');
        if ($mutable) {
            my $a = $adapter->{signal_manager}->get_signal('A');
            ok($a->declared_width_requirements && $a->declared_width_binding, 'actual independent mutable leaf metadata remains published');
        }
    }}}}
};

subtest 'matching failed and foreign writes cannot publish or retain literal intent' => sub {
    for my $mutate (
        sub {$_[1]->register_signal('A', width => 8)},
        sub {$_[1]->register_signal($_[2]->name, width => 1)},
        sub {$_[2]->set_driving_ast($_[2]->driving_ast)},
        sub {$_[2]->set_attribute('signal_role', $_[2]->get_attribute('signal_role'))},
        sub {eval {$_[2]->set_declared_width_binding({})}},
    ) {
        for my $after (0, 1) {
            my @f = fixture();
            publish($f[0], $f[3]) if $after;
            $mutate->(@f);
            publish($f[0], $f[3]) unless $after;
            ok(!defined(policy($f[2])), 'stale or foreign event cannot install or retain completed intent');
        }
    }
    # A Signal does not own a manager registry. The completion producer joins
    # membership; later consumers must perform their own registry join too.
    for my $root (0, 1) {
        my @f = fixture();
        my $name = $root ? $f[2]->name : 'A';
        $f[1]{signal_registry}{$name} = FSM::CoreAST::Signal->new(name => $name, width => 8);
        publish($f[0], $f[3]);
        ok(!defined(policy($f[2])), 'equal foreign registry root or operand cannot borrow a completed birth');
    }
};

subtest 'publication cannot rebase a staged birth onto a matching write during final preparation' => sub {
    my ($builder, $manager, $helper, $packet) = fixture();
    my $prepare = FSM::SourceLiteralWidthAllocationSupport->can('prepare_core');
    my $changed = 0;
    no warnings 'redefine';
    local *FSM::SourceLiteralWidthAllocationSupport::prepare_core = sub {
        $manager->register_signal('A', width => 8) unless $changed++;
        return $prepare->(@_);
    };
    publish($builder, $packet);
    ok($changed, 'matching write occurs after staged currentness before final preparation');
    ok(!defined(policy($helper)), 'final preparation must preserve the staged epoch rather than adopt a new matching one');
};

subtest 'final registry join rejects a substitution during publication getters' => sub {
    my ($builder, $manager, $helper, $packet) = fixture();
    my $publish = $helper->can('_publish_staged_source_literal_width_allocation');
    ok($publish, 'Core has a private completed literal publisher');
    return unless $publish;
    my $width = FSM::CoreAST::Literal->can('width');
    my $changed = 0;
    no warnings 'redefine';
    local *FSM::CoreAST::Signal::_publish_staged_source_literal_width_allocation = sub {
        local *FSM::CoreAST::Literal::width = sub {
            $manager->{signal_registry}{A} = FSM::CoreAST::Signal->new(name => 'A', width => 8) unless $changed++;
            return $width->(@_);
        };
        return $publish->(@_);
    };
    publish($builder, $packet);
    ok($changed, 'substitution occurs after the builder initial registry proof');
    ok(!defined(policy($helper)), 'post-validation raw registry join withholds foreign publication');
};

subtest 'failed actual Parser or facade validation clears old and staged policies then allows reuse' => sub {
    for my $facade (0, 1) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        parse($adapter, $facade, source());
        my @old = grep {defined(policy($_))} values %{$adapter->{signal_manager}{signal_registry}};
        is(scalar(@old), 1, 'successful predecessor supplies an escaped installed helper');
        my $complete = FSM::Adapter::FSMGenFull::Parser->can('_publish_declared_width_requirements');
        {
            no warnings 'redefine';
            local *FSM::Adapter::FSMGenFull::Parser::_publish_declared_width_requirements = sub {
                $complete->(@_); die "literal validation interrupted\n";
            };
            ok(!eval {parse($adapter, $facade, source(mutable => 1)); 1}, 'actual completion error propagates');
            like($@, qr/literal validation interrupted/, 'original validation error preserves');
        }
        ok(!grep({defined(policy($_))} (@old, values %{$adapter->{signal_manager}{signal_registry}})),
            'failed completion leaves neither escaped old nor partial new intent');
        ok(!exists($adapter->{expression_builder}{_source_literal_width_allocation_capture}), 'no in-flight capture survives failure');
        parse($adapter, $facade, source(width => 1));
        is(scalar(grep {defined(policy($_))} values %{$adapter->{signal_manager}{signal_registry}}), 1,
            'same adapter publishes a fresh policy after failure');
        ok(!eval {parse($adapter, $facade, '(?future:invalid)'); 1}, 'malformed source root rejects');
        ok(!grep({defined(policy($_))} values %{$adapter->{signal_manager}{signal_registry}}), 'early root failure also clears policies');
    }
};

subtest 'facade analysis and partial publication failures expose no completed policy' => sub {
    for my $during_publication (0, 1) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $published = 0;
        my $publish = FSM::CoreAST::Signal->can('_publish_staged_source_literal_width_allocation');
        my $analyze = FSM::Adapter::FSMGenFull::SignalAnalyzer->can('analyze_signal_roles');
        my $text = source();
        $text =~ s/\(<\(\| A B 256\)/(<(^ (| A B 256) (| A B 512))/;
        {
            no warnings 'redefine';
            local *FSM::Adapter::FSMGenFull::SignalAnalyzer::analyze_signal_roles = sub {
                $analyze->(@_);
                die "literal analyzer interrupted\n" unless $during_publication;
            };
            local *FSM::CoreAST::Signal::_publish_staged_source_literal_width_allocation = sub {
                die "literal publication interrupted\n" if $published++;
                return $publish->(@_);
            };
            ok(!eval {parse($adapter, 1, $text); 1}, 'actual late facade phase fails');
            like($@, $during_publication ? qr/literal publication interrupted/ : qr/literal analyzer interrupted/,
                'original phase diagnostic preserves');
        }
        is($published, $during_publication ? 2 : 0, 'analysis precedes publication and partial publication was exercised');
        ok(!grep({defined(policy($_))} values %{$adapter->{signal_manager}{signal_registry}}),
            'cleanup revokes every partially published literal policy');
        parse($adapter, 1, source());
        is(scalar(grep {defined(policy($_))} values %{$adapter->{signal_manager}{signal_registry}}), 1,
            'fresh complete parse succeeds after the late failure');
    }
};

done_testing();
