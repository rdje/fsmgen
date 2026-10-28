use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull::SignalManager;
use FSM::Adapter::FSMGenFull::ExpressionBuilder;
use FSM::IntermediateWidthAllocationSupport;

my $json = JSON::PP->new->canonical;
sub fixture {
    my ($width) = @_;
    my $manager = FSM::Adapter::FSMGenFull::SignalManager->new;
    my $a = $manager->register_signal('A', width => $width // 8);
    my $b = $manager->register_signal('B', width => $width // 8);
    my $builder = FSM::Adapter::FSMGenFull::ExpressionBuilder->new(signal_manager => $manager);
    return ($builder, $manager, $a, $b);
}
sub current {
    my ($manager, $event) = @_;
    return FSM::IntermediateWidthAllocationSupport->current_core(
        signal => $manager->get_signal($event->{signal_name}), holder => $event->{holder});
}
my $has_capture = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_capture_intermediate_width_allocations');
subtest 'actual fresh allocator stages detached intent without publication' => sub {
    my ($builder, $manager) = fixture;
    my $packet = eval {$builder->_capture_intermediate_width_allocations(sub {
        return $builder->parse_expression(['&', 'A', 'B']);
    })};
    ok(!$@, 'actual expression builder has scoped birth capture') or diag $@;
    return unless $has_capture;
    is(scalar @{$packet->{events}}, 1, 'one actual binary allocation has one event');
    my $event = $packet->{events}[0];
    is($event->{signal_name}, $packet->{value}->signal->name, 'event names actual allocated result');
    is_deeply(current($manager, $event), {
        kind => 'binary_operand_max', operator => '&', source_names => ['A', 'B'], selected_width => 8,
    }, 'actual allocator supplies binary max policy');
    ok(!defined($packet->{value}->signal->intermediate_width_allocation), 'staging publishes no Core policy');
    ok(eval {$json->encode($packet->{events}); 1}, 'journal contains only plain JSON and scalar identities');
    ok(!exists($builder->{_intermediate_width_allocation_capture}), 'scope leaves no builder journal');
    my ($weak_a, $weak_h) = ($manager->get_signal('A'), $packet->{value}->signal);
    weaken($weak_a); weaken($weak_h);
    my $events = $packet->{events};
    # Isolate the journal from the independently owned legacy fanout cycle.
    $_->{fanout_signals} = [] for ($manager->get_signal('A'), $manager->get_signal('B'));
    undef $packet; undef $builder; undef $manager;
    ok(!defined($weak_a) && !defined($weak_h), 'retained journal owns neither helper nor source graph');
};
subtest 'fresh names and bounded eligible shapes preserve ordinary allocation' => sub {
    plan skip_all => 'capture API absent' unless $has_capture;
    for my $width (1, 8) {
        for my $operator ('&', '|', '^') {
            my ($builder, $manager, $a, $b) = fixture($width);
            my $op_name = {'&' => 'and', '|' => 'or', '^' => 'xor'}->{$operator};
            my $occupied = $manager->register_signal("intermediate_${op_name}_A_B_1", width => 32);
            my ($ordinary, undef, $oa, $ob) = fixture($width);
            $ordinary->parse_expression([$operator, 'A', 'B']) for 1 .. 2;
            my $before = $json->encode([$oa->attributes, $ob->attributes, $oa->width, $ob->width]);
            my $packet = $builder->_capture_intermediate_width_allocations(sub {
                return [map {$builder->parse_expression([$operator, 'A', 'B'])} 1 .. 2];
            });
            is(scalar @{$packet->{events}}, 2, 'each actual allocation gets an independent event');
            isnt($packet->{events}[0]{signal_name}, $packet->{events}[1]{signal_name}, 'repeated expressions get fresh names');
            ok(current($manager, $packet->{events}[0]), 'qualified bare source registration preserves earlier current event');
            ok(current($manager, $packet->{events}[1]), 'latest fresh allocation remains current');
            isnt($packet->{events}[0]{signal_name}, $occupied->name, 'fresh allocator skips occupied actual candidate');
            is($occupied->width, 32, 'occupied opaque signal preserves its independent floor');
            is($json->encode([$a->attributes, $b->attributes, $a->width, $b->width]), $before,
                'actual caller width and attributes preserve');
        }
    }
    for my $shape (['&', 'A', 'B', 'A'], ['&', 'A', '3']) {
        my ($builder) = fixture;
        my $packet = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression($shape)});
        is_deeply($packet->{events}, [], 'n-ary/literal shapes gain no binary whole-reference policy');
    }
    for my $attributes ({signed => 1}, {declared_type_name => 'word_t'}, {width => 0}) {
        my ($builder, $manager, $a) = fixture;
        if (exists $attributes->{width}) {$a->{_width} = 0}
        else {$manager->register_signal('A', %$attributes)}
        my $packet = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression(['&', 'A', 'B'])});
        is_deeply($packet->{events}, [], 'signed/named/unknown operand is withheld');
    }
    my ($builder, $manager, $a) = fixture;
    $builder->parse_expression(['&', 'A', 'B']);
    ok(!exists($a->{_intermediate_width_allocation_revision}), 'ordinary uncaptured allocation adds no source tracker');
};
subtest 'supported helper and operand writes cannot revive staged intent' => sub {
    plan skip_all => 'capture API absent' unless $has_capture;
    for my $mutate (
        sub {my ($m, $h) = @_; $m->register_signal($h->name, width => 8)},
        sub {my ($m, $h) = @_; $h->set_driving_ast($h->driving_ast)},
        sub {my ($m) = @_; $m->register_signal('A', width => 8)},
        sub {my ($m) = @_; $m->register_signal('B', type => 'wire')},
        sub {my ($m) = @_; $m->get_signal('A')->set_attribute('signal_role', 'INPUT')},
    ) {
        my ($builder, $manager) = fixture;
        my $packet = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression(['&', 'A', 'B'])});
        my $event = $json->decode($json->encode($packet->{events}[0]));
        ok(current($manager, $event), 'staged event initially current');
        $mutate->($manager, $packet->{value}->signal);
        ok(!defined(current($manager, $event)), 'matching-state helper/operand mutation revokes old birth');
    }
    my ($builder, $manager) = fixture;
    eval {$builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['&', 'A', 'B']); die "source failed\n";
    })};
    like($@, qr/source failed/, 'callback failure preserves original error');
    ok(!exists($builder->{_intermediate_width_allocation_capture}), 'failure discards partial staging');
    my $retry = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression(['|', 'A', 'B'])});
    is(scalar @{$retry->{events}}, 1, 'retry has only its own birth');
    is(current($manager, $retry->{events}[0])->{operator}, '|', 'retry cannot borrow prior failed operator');
};
subtest 'explicit holder also anchors source revisions and rejects slices' => sub {
    my ($builder, $manager, $a, $b) = fixture;
    my $h = $builder->parse_expression(['&', 'A', 'B'])->signal;
    my $record = {kind => 'binary_operand_max', operator => '&', source_names => ['A', 'B'], selected_width => 8};
    $h->set_intermediate_width_allocation($record);
    $manager->register_signal('A', width => 8);
    ok(!defined($h->intermediate_width_allocation), 'matching source registry write revokes installed intent');
    $h->set_driving_ast(FSM::CoreAST::BinaryOp->new('&',
        FSM::CoreAST::SignalRef->new($a, slice => [0, 0]), FSM::CoreAST::SignalRef->new($b)));
    ok(!eval {$h->set_intermediate_width_allocation($record); 1}, 'sliced operand cannot assert whole-source maximum');
};
done_testing();
