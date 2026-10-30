use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::HDL::FlattenedDT;
use FSM::ConcatenationSourceObservationSupport;
use FSM::ConcatenationSourceWidthSupport;

# Read observations around real production calls. Localized wrappers preserve
# context and errors; they never install a concatenation inference event.
my $mode = shift(@ARGV) // 'observe';
die "unknown control\n" unless $mode =~ /\A(?:observe|native|cache|reread|recovery_mutation|metadata_mutation|late_mutation)\z/;
my $json = JSON::PP->new->canonical;
my $prefix = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::';
our $collection;
my @collections;
our ($ACTIVE, $INFER, $OBSERVING);
sub identity { ref($_[0]) ? sprintf('%x', refaddr($_[0])) : undef }
sub copy { $json->decode($json->encode($_[0])) }
sub concat { ref($_[0]) eq 'HASH' && ref($_[0]{ast}) eq 'FSM::CoreAST::Concatenation' }
sub args {
    my ($name) = @_;
    my $ctx = $collection->{ctx};
    return (factorizer => $ctx->{ast_factorizer}, signal_name => $name,
        fsm_module => $ctx->{fsm_module}, assignment_analysis => $ctx->{assignment_analysis},
        target_language => 'systemverilog');
}
sub observe {
    my ($stage, $rows) = @_;
    return unless $collection;
    local $OBSERVING = 1;
    my $ctx = $collection->{ctx};
    my $width = $ctx->{backend_sv_intermediate_width_support};
    for my $name (sort keys %{$rows // {}}) {
        my $row = $rows->{$name};
        next unless concat($row);
        if ($stage eq 'normalization_entry') {
            my $frame = FSM::ConcatenationSourceObservationSupport->capture(args($name));
            die "missing original normalization frame\n" unless $frame;
            my $plan = FSM::ConcatenationSourceWidthSupport->prepare(args($name), observation => $frame);
            $collection->{frames}{$name} = {raw => $frame, canonical => $plan};
        }
        my $frozen = $collection->{frames}{$name};
        my $raw = $frozen && FSM::ConcatenationSourceObservationSupport->current(args($name), holder => $frozen->{raw});
        my $canonical = $frozen && FSM::ConcatenationSourceWidthSupport->current(args($name), holder => $frozen->{canonical});
        my $allocator = $ctx->{ast_factorizer}{intermediate_signals}{$name};
        my $registered = $ctx->{intermediate_signals}{$name};
        push @{$collection->{trace}}, {stage => $stage, name => $name,
            module => identity($ctx->{fsm_module}), backend => identity($ctx), width_owner => identity($width),
            row => identity($row), allocator => identity($allocator), registered => identity($registered),
            ast => identity($row->{ast}), runtime => identity($row->{runtime_ast}),
            allocator_ast => identity($allocator->{ast}), row_view => identity($width->{_graph_inference_rows}),
            epoch => $width->{_width_inference_epoch}, revision => $width->{_width_inference_revisions}{$name},
            complete => $width->{_width_inference_complete}, width => $row->{width},
            width_source => $row->{width_source}, allocator_width => $allocator->{width},
            allocator_source => $allocator->{width_source}, registered_width => $registered->{width},
            registered_source => $registered->{width_source},
            raw_current => $raw ? JSON::PP::true : JSON::PP::false,
            canonical_current => $canonical ? JSON::PP::true : JSON::PP::false};
    }
}
sub mutate {
    my ($phase) = @_;
    return if $OBSERVING || !$collection || $collection->{mutated};
    return unless $mode eq $phase . '_mutation';
    my $lhs = $collection->{ctx}{assignment_analysis}{OTHER}{lhs_ast};
    die 'missing normalized nonoperand' unless ref($lhs) eq 'FSM::CoreAST::SignalRef';
    my $signal = $lhs->{signal};
    my $old = $signal->{_width};
    $collection->{restore} = sub { $signal->{_width} = $old };
    $signal->{_width} = 2;
    $collection->{mutated} = $phase;
}

# Apply one localized symbol at a time, then unwind every wrapper on return.
sub hooks {
    my ($entries, $body) = @_;
    return $body->() unless @$entries;
    my ($entry, @rest) = @$entries;
    no strict 'refs';
    no warnings 'redefine';
    my $original = \&{$entry->[0]};
    local *{$entry->[0]} = $entry->[1]->($original);
    return hooks(\@rest, $body);
}
sub around {
    my ($original, $before, $after) = @_;
    return sub {
        $before->(@_);
        my $want = wantarray;
        if (!defined $want) { $original->(@_); $after->(@_); return }
        if ($want) { my @result = $original->(@_); $after->(@_); return @result }
        my $result = $original->(@_); $after->(@_); return $result;
    };
}
my @hooks = (
    [$prefix . 'ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals', sub {
        my ($original) = @_;
        return sub {
            my ($owner) = @_;
            die 'nested collection' if $collection;
            local $collection = {ctx => $owner->{flattened_dt}, trace => [], frames => {}, inference => []};
            my $rows;
            my $ok = eval { $rows = $original->(@_); observe('collection_return', $rows); 1 };
            my $error = $@;
            $collection->{restore}->() if $collection->{restore};
            die $error unless $ok;
            push @collections, {trace => $collection->{trace}, frozen => $collection->{frames},
                inference => $collection->{inference}, mutated => $collection->{mutated}};
            return $rows;
        };
    }],
    [$prefix . 'ConsolidatedIntermediateSupport::merge_ast_factorization_signals', sub {
        around($_[0], sub {}, sub { observe('merge_return', $_[1]) });
    }],
    [$prefix . 'ConsolidatedIntermediateSupport::sync_consolidated_signals_to_registry', sub {
        around($_[0], sub { observe($_[2] ? 'replacement_before' : 'sync_before', $_[1]) },
            sub { observe($_[2] ? 'replacement_after' : 'sync_after', $_[1]) });
    }],
    [$prefix . 'ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata', sub {
        around($_[0], sub { observe('normalization_entry', $_[1]) }, sub { observe('normalization_return', $_[1]) });
    }],
    [$prefix . 'IntermediateSignalWidthSupport::_bind_graph_inference_rows', sub {
        around($_[0], sub {}, sub { observe('epoch_bound', $_[1]) });
    }],
    [$prefix . 'IntermediateSignalRecoverySupport::resolve_intermediate_signal_runtime_ast', sub {
        around($_[0], sub { if (concat($_[2])) { mutate('recovery'); observe('recovery_before', {$_[1] => $_[2]}) } },
            sub { observe('recovery_after', {$_[1] => $_[2]}) if concat($_[2]) });
    }],
    [$prefix . 'IntermediateSignalWidthSupport::resolve_intermediate_signal_width', sub {
        my ($original) = @_;
        return sub {
            my ($owner, $name, $row) = @_;
            local $ACTIVE = concat($row) ? {name => $name, row => $row} : undef;
            if ($ACTIVE) {
                # A controlled equal numeric cache remains an independent constraint.
                $row->{width} = FSM::CoreExpressionWidthSupport->infer_width($row->{ast}) if $mode eq 'cache';
                observe('resolve_before', {$name => $row});
            }
            my $result = $original->(@_);
            observe('resolve_after', {$name => $row}) if $ACTIVE;
            if ($ACTIVE && $mode eq 'reread') {
                $result = $original->(@_);
                observe('reread_after', {$name => $row});
            }
            return $result;
        };
    }],
    ['FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info', sub {
        my ($original) = @_;
        return sub {
            if ($ACTIVE && $_[1] eq $ACTIVE->{name}) {
                mutate('metadata');
                observe('metadata_callback', {$ACTIVE->{name} => $ACTIVE->{row}});
                return {width => FSM::CoreExpressionWidthSupport->infer_width($ACTIVE->{row}{ast})} if $mode eq 'native';
            }
            return $original->(@_);
        };
    }],
    [$prefix . 'IntermediateSignalWidthSupport::infer_width_from_intermediate_ast', sub {
        my ($original) = @_;
        return sub {
            local $INFER = $ACTIVE && identity($_[1]) eq identity($ACTIVE->{row}{runtime_ast});
            if ($INFER) {
                push @{$collection->{inference}}, $ACTIVE->{name};
                observe('intrinsic_before', {$ACTIVE->{name} => $ACTIVE->{row}});
            }
            my $result = $original->(@_);
            observe('intrinsic_after', {$ACTIVE->{name} => $ACTIVE->{row}}) if $INFER;
            return $result;
        };
    }],
    ['FSM::CoreAST::Signal::width', sub {
        my ($original) = @_;
        return sub { mutate('late') if $INFER; return $original->(@_) };
    }],
    [$prefix . 'IntermediateSignalWidthSupport::_with_factorized_width_publication', sub {
        around($_[0], sub { observe('publication_before', {$_[1] => $_[2]}) if concat($_[2]) },
            sub { observe('publication_after', {$_[1] => $_[2]}) if concat($_[2]) });
    }],
    [$prefix . 'IntermediateSignalWidthSupport::_complete_factorized_width_inference', sub {
        around($_[0], sub { observe('completion_before', $_[1]) }, sub { observe('completion_after', $_[1]) });
    }],
);
my $native = '';
hooks(\@hooks, sub {
    open my $capture, '>', \$native or die $!;
    local *STDOUT = $capture;
    my $loaded = do './docs/audits/concat-guard-capture-20261030/probe.pl';
    die $@ if $@;
    die $! unless defined $loaded;
});
print $json->pretty->encode({mode => $mode, native => decode_json($native), collections => \@collections});
