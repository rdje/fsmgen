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
my @families = (
    ['_intermediate_width_allocation_capture', 'FSM::IntermediateWidthAllocationSupport'],
    ['_source_bitwise_tree_width_allocation_capture', 'FSM::SourceBitwiseTreeWidthSupport'],
    ['_source_literal_width_allocation_capture', 'FSM::SourceLiteralWidthAllocationSupport'],
);

sub captured {
    my ($callback) = @_;
    my $adapter = FSM::Adapter::FSMGenFull->new;
    $adapter->{signal_manager}->register_signal($_, width => 8) for qw(ALPHA BETA GAMMA);
    my $builder = $adapter->{expression_builder};
    $builder->_capture_intermediate_width_allocations(sub {
        $builder->parse_expression(['&', qw(ALPHA BETA GAMMA)]);
        $builder->parse_expression(['|', qw(ALPHA BETA)]);
        $builder->parse_expression(['^', 'ALPHA', "8'd3"]);
        $callback->($adapter, $builder);
    });
}

sub records {
    my ($adapter, $builder) = @_;
    my $children = $builder->_source_literal_birth_children;
    my @records;
    for my $family (@families) {
        my ($key, $class) = @$family;
        for my $event (@{$builder->{$key}}) {
            my $signal = $adapter->{signal_manager}->get_signal($event->{signal_name});
            my $registered = $key eq $families[0][0] ? $builder->_allocation_registry_matches($signal)
                : $key eq $families[1][0] ? $builder->_source_tree_allocation_registry_matches($signal)
                : $builder->_source_literal_allocation_registry_matches($signal, $children);
            push @records, $registered ? $class->current_core(
                signal => $signal, holder => $event->{holder}, children => $children) : undef;
        }
    }
    return \@records;
}

sub all_current {
    my ($records) = @_;
    return @$records >= 3 && !grep {!defined($_)} @$records;
}

sub width_reads {
    my ($callback) = @_;
    my $original = FSM::CoreAST::Signal->can('width');
    my $reads = 0;
    {
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::width = sub {++$reads; goto &$original};
        $callback->();
    }
    return $reads;
}

subtest 'repeated actual scalar reads preserve journals without revalidation' => sub {
    captured(sub {
        my ($adapter, $builder) = @_;
        my $before = records($adapter, $builder);
        ok(all_current($before), 'all three real allocation families start current');
        my $journals = $json->encode([map {$builder->{$_->[0]}} @families]);
        my $usage = $json->encode($adapter->{signal_manager}->get_all_signal_usages);
        my $signal = $adapter->{signal_manager}->get_signal('ALPHA');
        my @references;
        is(width_reads(sub {
            push @references, $builder->parse_scalar_expression('ALPHA') for 1 .. 3;
        }), 0, 'same-value bare scalar reads perform no Core width proof reads');
        ok(!grep({ref($_) ne 'FSM::CoreAST::SignalRef' || refaddr($_->signal) != refaddr($signal)} @references),
            'every read retains the actual registered physical source');
        is($json->encode([map {$builder->{$_->[0]}} @families]), $journals,
            'complete holder records, revision snapshots and scalar kinds stay identical');
        is($json->encode(records($adapter, $builder)), $json->encode($before),
            'all complete live policies remain identical and current');
        is($json->encode($adapter->{signal_manager}->get_all_signal_usages), $usage,
            'all usage fields and contexts stay identical');
    });
};

subtest 'actual flag changes and output markers still write and validate' => sub {
    captured(sub {
        my ($adapter, $builder) = @_;
        my $signal = $adapter->{signal_manager}->get_signal('ALPHA');
        cmp_ok(width_reads(sub {$builder->parse_scalar_expression('ALPHA>')}), '>', 0,
            'an output marker still takes complete dependent validation');
        ok($signal->get_attribute('is_output'), 'the marker updates the real flag');
        ok($adapter->{signal_manager}->get_signal_usage('ALPHA')->{has_output_marker}, 'marker usage is recorded');
        ok(all_current(records($adapter, $builder)), 'sanctioned marker write transports all policies');
        cmp_ok(width_reads(sub {$builder->parse_scalar_expression('ALPHA')}), '>', 0,
            'clearing a true output flag is a real validated write');
        is($signal->get_attribute('is_output'), '', 'the bare reference restores the exact empty flag');
        ok(all_current(records($adapter, $builder)), 'actual flag clearing preserves current policies');
    });
};

subtest 'new, missing and annotated registrations retain ordinary behavior' => sub {
    captured(sub {
        my ($adapter, $builder) = @_;
        my $fresh = $builder->parse_scalar_expression('FRESH');
        is(refaddr($fresh->signal), refaddr($adapter->{signal_manager}->get_signal('FRESH')), 'new signal is registered');
        ok(exists $adapter->{signal_manager}{signal_usage}{FRESH}, 'new usage is initialized');
        my $signal = $adapter->{signal_manager}->get_signal('ALPHA');
        delete $signal->{attributes}{is_output};
        $builder->parse_scalar_expression('ALPHA');
        ok(exists($signal->{attributes}{is_output}) && defined($signal->{attributes}{is_output}),
            'an absent flag receives its explicit native value');
        my $revision = $signal->_intermediate_width_allocation_revision;
        $builder->parse_scalar_expression("ALPHA'8");
        cmp_ok($signal->_intermediate_width_allocation_revision, '>', $revision,
            'an explicit matching width still performs its original revoking write');
        ok(!grep({defined($_)} @{records($adapter, $builder)}), 'annotations cannot heal stale source policy');
    });
};

subtest 'external writes, changed holders and foreign sources cannot be healed' => sub {
    for my $case (qw(write holder registry)) {
        captured(sub {
            my ($adapter, $builder) = @_;
            if ($case eq 'write') {
                $adapter->{signal_manager}->register_signal('ALPHA', width => 8);
            } elsif ($case eq 'holder') {
                $_->{holder}{state} = 'changed snapshot' for map {@{$builder->{$_->[0]}}} @families;
            } else {
                $adapter->{signal_manager}{signal_registry}{ALPHA} = FSM::CoreAST::Signal->new(
                    name => 'ALPHA', width => 8, attributes => {is_output => ''});
            }
            my $reference = $builder->parse_scalar_expression('ALPHA');
            is(refaddr($reference->signal), refaddr($adapter->{signal_manager}->get_signal('ALPHA')),
                "$case uses the actual current registry");
            ok(!grep({defined($_)} @{records($adapter, $builder)}), "$case cannot borrow validity from a no-op read");
        });
    }
};

{
    package ScalarReadTestManager;
    our @ISA = ('FSM::Adapter::FSMGenFull::SignalManager');
    sub register_signal {++$_[0]{observed_registrations}; goto &FSM::Adapter::FSMGenFull::SignalManager::register_signal}
    package ScalarReadTestSignal;
    our @ISA = ('FSM::CoreAST::Signal');
    package ScalarReadTestFlag;
    sub TIESCALAR {bless {value => $_[1], stores => 0}, $_[0]}
    sub FETCH {$_[0]{value}}
    sub STORE {++$_[0]{stores}; $_[0]{value} = $_[1]}
}

subtest 'subclasses and tied flag storage keep their actual write path' => sub {
    for my $case (qw(manager signal tied_flag)) {
        captured(sub {
            my ($adapter, $builder) = @_;
            my $signal = $adapter->{signal_manager}->get_signal('ALPHA');
            my $flag;
            bless $adapter->{signal_manager}, 'ScalarReadTestManager' if $case eq 'manager';
            bless $signal, 'ScalarReadTestSignal' if $case eq 'signal';
            if ($case eq 'tied_flag') {
                tie $signal->{attributes}{is_output}, 'ScalarReadTestFlag', '';
                $flag = tied($signal->{attributes}{is_output});
            }
            my $revision = $signal->_intermediate_width_allocation_revision;
            cmp_ok(width_reads(sub {$builder->parse_scalar_expression('ALPHA')}), '>', 0,
                "$case retains the ordinary live proof path");
            cmp_ok($signal->_intermediate_width_allocation_revision, '>', $revision, "$case still performs a real write");
            is($adapter->{signal_manager}{observed_registrations}, 1, 'subclass callback runs') if $case eq 'manager';
            is($flag->{stores}, 1, 'tied output setter runs exactly once') if $flag;
        });
    }
};

done_testing();
