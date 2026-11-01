use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::Adapter::FSMGenFull;
use FSM::IntermediateWidthAllocationSupport;
use FSM::SourceBitwiseTreeWidthSupport;
use FSM::SourceLiteralWidthAllocationSupport;

my $json = JSON::PP->new->canonical;
my %families = (
    events => ['_intermediate_width_allocation_capture', 'FSM::IntermediateWidthAllocationSupport'],
    source_tree_events => ['_source_bitwise_tree_width_allocation_capture', 'FSM::SourceBitwiseTreeWidthSupport'],
    source_literal_events => ['_source_literal_width_allocation_capture', 'FSM::SourceLiteralWidthAllocationSupport'],
);

sub fixture {
    my $adapter = FSM::Adapter::FSMGenFull->new;
    $adapter->{signal_manager}->register_signal($_, width => 8)
        for qw(ALPHA BETA GAMMA DELTA OUTSIDE);
    return $adapter;
}

sub event_sets {
    my ($builder) = @_;
    return {map {$_ => $builder->{$families{$_}[0]}} keys %families};
}

sub records {
    my ($adapter) = @_;
    my $builder = $adapter->{expression_builder};
    my $sets = event_sets($builder);
    my $children = $builder->_source_literal_birth_children($sets->{source_literal_events});
    my %records;
    for my $name (sort keys %families) {
        my $class = $families{$name}[1];
        for my $event (@{$sets->{$name}}) {
            my $signal = $adapter->{signal_manager}->get_signal($event->{signal_name});
            my $registered = $name eq 'events'
                ? $builder->_allocation_registry_matches($signal)
                : $name eq 'source_tree_events'
                    ? $builder->_source_tree_allocation_registry_matches($signal)
                    : $builder->_source_literal_allocation_registry_matches($signal, $children);
            $records{$event->{signal_name}} = $registered ? $class->current_core(
                signal => $signal, holder => $event->{holder},
                ($name eq 'source_literal_events' ? (children => $children) : ()),
            ) : undef;
        }
    }
    return \%records;
}

sub all_current {
    my ($records) = @_;
    return scalar(keys %$records) && !grep {!defined($_)} values %$records;
}

sub width_reads {
    my ($adapter, $callback) = @_;
    my %watched = map {refaddr($_) => 1}
        grep {$_->{name} ne 'OUTSIDE'} values %{$adapter->{signal_manager}{signal_registry}};
    my $original = FSM::CoreAST::Signal->can('width');
    my $reads = 0;
    {
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::width = sub {
            ++$reads if $watched{refaddr($_[0])};
            goto &$original;
        };
        $callback->();
    }
    return $reads;
}

sub profiles {
    my ($builder) = @_;
    $builder->parse_expression(['&', qw(ALPHA BETA GAMMA)]);
    $builder->parse_expression(['|', qw(ALPHA DELTA)]);
    $builder->parse_expression(['^', 'ALPHA', "8'd3"]);
}

subtest 'unrelated references do not traverse any captured allocation family' => sub {
    my $adapter = fixture();
    my $builder = $adapter->{expression_builder};
    $builder->_capture_intermediate_width_allocations(sub {
        profiles($builder);
        my $sets = event_sets($builder);
        ok(@{$sets->{$_}} > 0, "$_ has an actual fresh source birth") for sort keys %families;
        my $before = records($adapter);
        ok(all_current($before), 'all actual records are current before the distinguishing read');
        my $journal = $json->encode($sets);
        is(width_reads($adapter, sub {$builder->_register_unannotated_reference('OUTSIDE')}), 0,
            'unrelated reference performs no reads of captured Core widths');
        is($json->encode(event_sets($builder)), $journal,
            'complete detached journals and scalar kinds preserve across the unrelated write');
        is($json->encode(records($adapter)), $json->encode($before),
            'every allocation policy remains identical and current');

        cmp_ok(width_reads($adapter, sub {$builder->_register_unannotated_reference('ALPHA')}), '>', 0,
            'a matching participant write still traverses the actual Core proofs');
        is($json->encode(records($adapter)), $json->encode($before),
            'the sanctioned matching write transports every current family');
        is(width_reads($adapter, sub {$builder->_register_unannotated_reference('OUTSIDE')}), 0,
            'freshly advanced holders still avoid unrelated traversal');
    });
};

subtest 'copied or changed holder snapshots fall back to complete validation' => sub {
    my $adapter = fixture();
    my $builder = $adapter->{expression_builder};
    $builder->_capture_intermediate_width_allocations(sub {
        profiles($builder);
        my $event = event_sets($builder)->{source_tree_events}[0];
        my $original = $event->{holder};
        $event->{holder} = $json->decode($json->encode($original));
        ok(all_current(records($adapter)), 'the detached same-source copy retains its actual policy');
        cmp_ok(width_reads($adapter, sub {$builder->_register_unannotated_reference('OUTSIDE')}), '>', 0,
            'a caller-owned copied holder cannot borrow a cached negative decision');
        ok(all_current(records($adapter)), 'fallback preserves the original copied-holder contract');

        $event->{holder} = $original;
        $original->{state} = 'changed snapshot';
        cmp_ok(width_reads($adapter, sub {$builder->_register_unannotated_reference('OUTSIDE')}), '>', 0,
            'editing a known snapshot invalidates its dependency-selection seal');
        ok(!defined(records($adapter)->{$event->{signal_name}}), 'changed source state still withholds policy');
    });
};

subtest 'matching external writes and foreign registry objects cannot be healed' => sub {
    for my $foreign (0, 1) {
        my $adapter = fixture();
        my $builder = $adapter->{expression_builder};
        $builder->_capture_intermediate_width_allocations(sub {
            profiles($builder);
            ok(all_current(records($adapter)), 'the original complete family starts current');
            if ($foreign) {
                $adapter->{signal_manager}{signal_registry}{ALPHA} =
                    FSM::CoreAST::Signal->new(name => 'ALPHA', width => 8);
            } else {
                $adapter->{signal_manager}->register_signal('ALPHA', width => 8);
            }
            $builder->_register_unannotated_reference('ALPHA');
            my $after = records($adapter);
            ok(!(grep {defined($_)} values %$after),
                'later sanctioned reads cannot revive externally changed or foreign ownership');
        });
    }
};

subtest 'nested literal participant transport keeps complete child ownership' => sub {
    my $adapter = fixture();
    my $builder = $adapter->{expression_builder};
    $builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['^', ['|', 'ALPHA', "8'd3"], 'BETA']);
        my $sets = event_sets($builder);
        cmp_ok(scalar @{$sets->{source_literal_events}}, '>=', 2, 'actual child and parent literal births exist');
        my $before = records($adapter);
        ok(all_current($before), 'child-first source capsules start current');
        is(width_reads($adapter, sub {$builder->_register_unannotated_reference('OUTSIDE')}), 0,
            'nested graphs also avoid unrelated source traversal');
        cmp_ok(width_reads($adapter, sub {$builder->_register_unannotated_reference('ALPHA')}), '>', 0,
            'the original nested leaf remains a real dependency');
        is($json->encode(records($adapter)), $json->encode($before),
            'the matching leaf write preserves complete child/parent policy and JSON kinds');
        is(width_reads($adapter, sub {$builder->_register_unannotated_reference('OUTSIDE')}), 0,
            'transported nested holders retain exact dependency selection');
    });
};

done_testing();
