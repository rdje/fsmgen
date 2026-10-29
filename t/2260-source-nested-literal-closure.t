use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(blessed refaddr weaken);
use Lispish;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull;

my $json = JSON::PP->new->canonical;
sub fixture {
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $manager = $adapter->{signal_manager};
    $manager->register_signal('A', width => 8);
    $manager->register_signal('B', width => 16, width_declared => 1);
    return ($adapter->{expression_builder}, $manager);
}
sub reference { FSM::CoreAST::SignalRef->new($_[0]) }
sub publish {
    my ($builder, $packet) = @_;
    $builder->_publish_intermediate_width_allocations($packet->{events},
        $packet->{source_tree_events}, $packet->{source_literal_events});
}

# Independent whole-object census: preserve every raw key and JSON scalar kind,
# replacing owner edges with typed identities instead of recursively following
# the pre-existing Core fanout graph. Only intended allocation policy is omitted.
sub plain {
    my ($value) = @_;
    return $value if JSON::PP::is_bool($value);
    return [ref($value), sprintf('%x', refaddr($value))] if blessed($value);
    return [map {plain($_)} @$value] if ref($value) eq 'ARRAY';
    return {map {$_ => plain($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return $value;
}
sub snapshot {
    my ($manager) = @_;
    my (%signals, %nodes);
    my @pending;
    for my $name (sort keys %{$manager->{signal_registry}}) {
        my $signal = $manager->{signal_registry}{$name};
        my %raw = %$signal;
        delete @raw{qw(_intermediate_width_allocation _source_bitwise_tree_width_allocation _source_literal_width_allocation)};
        $signals{$name} = plain(\%raw);
        push @pending, $signal->{driving_ast} if blessed($signal->{driving_ast});
    }
    while (my $node = shift @pending) {
        my $id = sprintf('%x', refaddr($node));
        next if exists $nodes{$id};
        $nodes{$id} = {class => ref($node), fields => plain({%$node})};
        my @values = values %$node;
        while (@values) {
            my $value = shift @values;
            if (blessed($value)) {
                push @pending, $value unless $value->isa('FSM::CoreAST::Signal') || JSON::PP::is_bool($value);
            } elsif (ref($value) eq 'ARRAY') {push @values, @$value}
            elsif (ref($value) eq 'HASH') {push @values, values %$value}
        }
    }
    return {signals => \%signals, nodes => \%nodes};
}

subtest 'real repeated and shared child edges publish through a deeper source chain' => sub {
    for my $sized (0, 1) {
        my ($builder, $manager) = fixture();
        my $packet = $builder->_capture_intermediate_width_allocations(sub {
            my $child = $builder->parse_expression(['|', 'A', $sized ? "9'b100000000" : '256']);
            my $repeated = $builder->finalize_nary_expression('^', [reference($child->signal), reference($child->signal)]);
            my $other = $builder->finalize_nary_expression('|', [reference($child->signal), reference($manager->get_signal('B'))]);
            my $root = $builder->finalize_nary_expression('&', [$repeated, $other]);
            $root = $builder->finalize_nary_expression('^', [$root, reference($manager->get_signal('B'))]) for 1 .. 5;
            $builder->_set_analyzed_signal_role($manager->get_signal('A'), 'INPUT');
            return $root;
        });
        my $before = $json->encode(snapshot($manager));
        publish($builder, $packet);
        is($json->encode(snapshot($manager)), $before, 'all raw source fields, AST slots, edges and kinds conserve');
        for my $event (@{$packet->{source_literal_events}}) {
            is_deeply($manager->get_signal($event->{signal_name})->source_literal_width_allocation,
                $event->{holder}{record}, 'actual repeated/shared/deeper completed relationship remains current');
        }
        my $repeated = $manager->get_signal($packet->{source_literal_events}[1]{signal_name});
        my $state = $json->decode($repeated->{_source_literal_width_allocation}{state});
        is(scalar @{$state->{children}}, 2, 'both repeated typed reference slots remain explicit');
        isnt($state->{children}[0]{reference_identity}, $state->{children}[1]{reference_identity}, 'distinct slots retain distinct actual AST identities');
        is($state->{children}[0]{signal_identity}, $state->{children}[1]{signal_identity}, 'shared child retains one actual lifetime');
        is($packet->{value}->signal->width, $sized ? 16 : 1, 'independent floor never resolves an unknown literal');
        $repeated->{driving_ast}{operands}[1] = reference($repeated->{driving_ast}{operands}[0]->signal);
        ok(!defined $packet->{value}->signal->source_literal_width_allocation, 'equal replacement slot revokes every dependent original edge');
    }
};

subtest 'actual mutable Parser/facade publication conserves complete source objects and original input' => sub {
    my $publisher = FSM::Adapter::FSMGenFull::ExpressionBuilder->can('_publish_intermediate_width_allocations');
    for my $facade (0, 1) {
        my $adapter = FSM::Adapter::FSMGenFull->new;
        my $text = '(?fsm:conservation (+params (W 8)) (+size (A (param W)) (B 16) (DATA 1) (OTHER 1))'
            .' (idle (<(^ (| A 256) B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))';
        my $raw = scalar Lispish::multi(\$text);
        my $input = $json->encode($raw);
        my $observed;
        no warnings 'redefine';
        local *FSM::Adapter::FSMGenFull::ExpressionBuilder::_publish_intermediate_width_allocations = sub {
            my ($builder) = @_;
            my $before = snapshot($builder->{signal_manager});
            my $returned = $publisher->(@_);
            is($json->encode(snapshot($builder->{signal_manager})), $json->encode($before), 'complete source census agrees across publication');
            $observed = $before;
            return $returned;
        };
        $facade ? $adapter->parse_fsm($raw) : $adapter->{parser}->parse_fsm($raw);
        ok($observed, 'actual normal publication boundary is observed');
        is($json->encode($raw), $input, 'original whole parameter/source input and JSON kinds preserve');
        my $wrong = $json->decode($json->encode($observed));
        my ($literal) = grep {$_->{class} eq 'FSM::CoreAST::Literal'} values %{$wrong->{nodes}};
        ok($literal, 'independent census includes actual raw literal');
        $literal->{fields}{value} = '256';
        isnt($json->encode($wrong), $json->encode($observed), 'saved string-for-integer kind mutation fails whole-object equality');
    }
};

subtest 'actual source depth bound withholds excess intent and subsequent capture still works' => sub {
    my ($builder, $manager) = fixture();
    my $packet = $builder->_capture_intermediate_width_allocations(sub {
        my $root = $builder->parse_expression(['|', 'A', '256']);
        $root = $builder->finalize_nary_expression('^', [$root, reference($manager->get_signal('B'))]) for 2 .. 33;
        return $root;
    });
    ok(!grep({$_->{signal_name} eq $packet->{value}->signal->name} @{$packet->{source_literal_events}}),
        'combined source depth prevents a fresh excess parent birth');
    is_deeply($packet->{events}, [], 'over-bound unknown child cannot create binary max intent');
    publish($builder, $packet);
    ok(!defined $packet->{value}->signal->source_literal_width_allocation, 'provisional or partial policy cannot qualify excess depth');
    my $fresh = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression(['|', 'A', '256'])});
    publish($builder, $fresh);
    ok($fresh->{value}->signal->source_literal_width_allocation, 'bounded failure does not poison independent subsequent capture');
};

subtest 'actual source capsules retain no additional owner graph' => sub {
    my ($builder, $manager) = fixture();
    my $packet = $builder->_capture_intermediate_width_allocations(sub {$builder->parse_expression(['^', ['|', 'A', '256'], 'B'])});
    publish($builder, $packet);
    my $root = $packet->{value}->signal;
    my $escaped = $json->decode($json->encode($packet->{source_literal_events}));
    my $weak = $root; weaken($weak);
    # Existing Core fanout cycles have separate ownership (.31). Remove only
    # these fixture edges to test whether the new source capsules retain owners.
    $_->{fanout_signals} = [] for values %{$manager->{signal_registry}};
    undef $root; undef $packet; undef $builder; undef $manager;
    ok(!defined $weak, 'escaped detached birth capsules retain no actual root');
    ok($escaped && @$escaped, 'capsules survive independently as plain JSON');
};

done_testing();
