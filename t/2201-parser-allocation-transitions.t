use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::IntermediateWidthAllocationSupport;

my $json = JSON::PP->new->canonical;
my $has_transitions = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_set_analyzed_signal_role');
sub source {
    my ($width) = @_;
    return "(?fsm:allocation_transitions (+params (W $width))"
        ." (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1) (THIRD 1) (FOURTH 1))"
        ." (idle (<(& A B) (= (DATA 1)) (= (OTHER 1)))"
        ." (<(| A B) (= (THIRD 1)) (= (FOURTH 1))) (-> idle)))";
}
sub current {
    my ($adapter, $event) = @_;
    return FSM::IntermediateWidthAllocationSupport->current_core(
        signal => $adapter->{signal_manager}->get_signal($event->{signal_name}), holder => $event->{holder});
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
subtest 'actual Parser metadata publication and Analyzer roles preserve only current birth' => sub {
    for my $width (1, 8) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $packet = $adapter->{expression_builder}->_capture_intermediate_width_allocations(sub {
            parse_phases($adapter, source($width));
        });
        is(scalar @{$packet->{events}}, 2, 'actual source allocates two fresh binary helpers');
        for my $event (@{$packet->{events}}) {
            my $record = current($adapter, $event);
            ok($record, 'actual reference/width-publication/classifier transitions preserve current birth');
            is($record && $record->{selected_width}, $width, 'actual selected width preserves');
            my $helper = $adapter->{signal_manager}->get_signal($event->{signal_name});
            is($helper->get_attribute('signal_role'), 'INTERNAL_INTERMEDIATE', 'actual canonical role survives');
            ok(!defined($helper->intermediate_width_allocation), 'explicit journal still publishes no Core policy');
        }
        my $ordinary = FSM::Adapter::FSMGenFull->new;
        is($json->encode(selected($packet->{value})), $json->encode(selected(parse_phases($ordinary, source($width)))),
            'ordinary numeric/attribute/parameter/width metadata and JSON kinds preserve');
    }
};
subtest 'external and annotated mutations cannot borrow a later qualified transition' => sub {
    plan skip_all => 'qualified transitions absent' unless $has_transitions;
    for my $mutate (
        sub {$_[0]{signal_manager}->register_signal('A', width => 8)},
        sub {$_[0]{signal_manager}->get_signal('A')->set_attribute('signal_role', 'INPUT')},
        sub {$_[0]{expression_builder}->parse_expression("A'8")},
        sub {$_[0]{signal_manager}->get_signal('A')->add_constraint({kind => 'independent_floor', width => 8})},
    ) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $manager = $adapter->{signal_manager};
        $manager->register_signal($_, width => 8) for qw(A B);
        my $packet = $adapter->{expression_builder}->_capture_intermediate_width_allocations(sub {
            my $reference = $adapter->{expression_builder}->parse_expression(['&', 'A', 'B']);
            $mutate->($adapter);
            $adapter->{expression_builder}->parse_expression('A');
            $adapter->{expression_builder}->_set_analyzed_signal_role($reference->signal, 'INTERNAL_INTERMEDIATE');
            return $reference;
        });
        ok(!defined(current($adapter, $packet->{events}[0])), 'later sanctioned operation cannot revive stale birth');
    }
};
subtest 'unexpected changes inside a known operation refuse rebasing' => sub {
    plan skip_all => 'qualified transitions absent' unless $has_transitions;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $manager = $adapter->{signal_manager};
    $manager->register_signal($_, width => 8) for qw(A B);
    my $original = FSM::Adapter::FSMGenFull::SignalManager->can('register_signal');
    my $packet = $adapter->{expression_builder}->_capture_intermediate_width_allocations(sub {
        my $reference = $adapter->{expression_builder}->parse_expression(['&', 'A', 'B']);
        {
            no warnings 'redefine';
            local *FSM::Adapter::FSMGenFull::SignalManager::register_signal = sub {
                my ($self, $name, @args) = @_;
                my $result = $original->($self, $name, @args);
                $original->($self, 'B', width => 8) if $name eq 'A';
                return $result;
            };
            $adapter->{expression_builder}->parse_expression('A');
        }
        $adapter->{expression_builder}->_set_analyzed_signal_role($reference->signal, 'INTERNAL_INTERMEDIATE');
        return $reference;
    });
    ok(!defined(current($adapter, $packet->{events}[0])), 'an extra matching write to another operand cannot launder its revision');
};
subtest 'source failure and standalone analyzer compatibility preserve' => sub {
    my $adapter = FSM::Adapter::FSMGenFull->new;
    eval {$adapter->{expression_builder}->_capture_intermediate_width_allocations(sub {
        parse_phases($adapter, source(8)); die "after source phases\n";
    })};
    like($@, qr/after source phases/, 'original post-phase error propagates');
    ok(!exists($adapter->{expression_builder}{_intermediate_width_allocation_capture}), 'failure drops local candidates');
    my $standalone = FSM::Adapter::FSMGenFull::SignalAnalyzer->new(signal_manager => $adapter->{signal_manager});
    ok(eval {$standalone->analyze_signal_roles($adapter->{parser}->get_fsm_module); 1}, 'standalone Analyzer without journal remains supported');
    ok(!(grep {defined($_->intermediate_width_allocation)} values %{$adapter->{signal_manager}{signal_registry}}),
        'source-phase failure exposes no policy');
};
done_testing();
