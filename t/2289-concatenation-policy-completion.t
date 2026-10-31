use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(weaken refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $width = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $collector = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
my $builder = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
my $renderer = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport';
my $complete = $width->can('_complete_factorized_width_inference');
my $prune = $collector->can('prune_sampled_value_intermediate_chains');
my $build = $builder->can('build_prepared_consolidated_intermediate_block');
my $render = $renderer->can('render_prepared_consolidated_intermediate_block');
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
my $event = $width->can('concatenation_inference_event');
my $resolve = $width->can('resolve_intermediate_signal_width');
my $has_policy = $width->can('factorized_concatenation_width_allocation');
my $json = JSON::PP->new->canonical;
my $path = 'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm';
is($INC{$path}, "perl/$path", 'actual native completion owner loaded');
{
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}
ok($has_policy, 'separate completed concatenation policy API exists');

sub fixture {
    my (%options) = @_;
    my $backend = $options{backend} // FSM::HDL::FlattenedDT->new;
    my $params = $options{mutable} ? '(+params (W 8) (X 3))' : '';
    my ($a, $b) = $options{mutable} ? ('(param W)', '(param X)') : (8, 3);
    my $action = $options{rhs}
        ? '(= (DATA (concat A B))) (= (OTHER (concat B A A)))'
        : '(<(concat A B) (= (DATA 1))) (<(concat B A A) (= (OTHER 1)))';
    my $source = "(?fsm:concat_policy $params (+size (A $a) (B $b) (DATA 11) (OTHER 19))"
        . " (idle $action (-> idle)))";
    my $raw = scalar Lispish::multi(\$source);
    my $caller = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my (%observed, $block, $weak_view, $owner, $rows, $error, $hdl, $active);
    our $late_active;
    my $snapshot = sub {
        my (%events, %policies);
        for my $name (sort keys %$rows) {
            next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
            $events{$name} = scalar($owner->concatenation_inference_event($name, $rows->{$name}));
            $policies{$name} = $has_policy
                ? scalar($owner->factorized_concatenation_width_allocation($name, $rows->{$name})) : undef;
        }
        return {events => \%events, policies => \%policies};
    };
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${collector}::prune_sampled_value_intermediate_chains"} = sub {
            my $result = $prune->(@_);
            $options{prune}->(@_) if $options{prune};
            return $result;
        };
        local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
            my $result = $prepare->(@_);
            if ($late_active && !$observed{late} && $options{late}) {
                my ($name) = sort keys %{$observed{before}{events}};
                $rows->{$name}{late_completion_write} = 1;
                $observed{late}++;
            }
            return $result;
        };
        local *{"${width}::concatenation_inference_event"} = sub {
            my ($w, $name) = @_;
            my @names = sort keys %{$observed{before}{events} || {}};
            local $late_active = $active && @names && $name eq $names[-1];
            return $event->(@_);
        };
        local *{"${width}::resolve_intermediate_signal_width"} = sub {
            my ($w, $name, $row, $supplied_rows) = @_;
            my $held = exists($w->{_concatenation_inference_events}{$name});
            my $result = $resolve->(@_);
            if ($held && !exists($w->{_concatenation_inference_events}{$name})) {
                push @{$observed{resolver_revocations}}, {
                    name => $name, caller => (caller)[0],
                    supplied_view => ref($supplied_rows) ? sprintf('%x', refaddr($supplied_rows)) : undef,
                    canonical_view => sprintf('%x', refaddr($w->_current_graph_inference_rows)),
                };
            }
            return $result;
        };
        local *{"${width}::_complete_factorized_width_inference"} = sub {
            ($owner, $rows) = @_;
            $weak_view = $rows; weaken($weak_view);
            $observed{before} = $snapshot->();
            $options{before}->($owner, $rows, \%observed) if $options{before};
            die "concat collection failure\n" if $options{fail_collection};
            $active = 1;
            $complete->(@_);
            $active = 0;
            $observed{holders} = [sort keys %{$owner->{_concatenation_inference_events}}];
            $observed{after} = $snapshot->();
        };
        local *{"${builder}::build_prepared_consolidated_intermediate_block"} = sub {
            my $result = $build->(@_);
            $block = $result if $options{retain};
            $observed{prepared} = $snapshot->();
            $options{prepared}->($owner, $result, \%observed) if $options{prepared};
            return $result;
        };
        local *{"${renderer}::render_prepared_consolidated_intermediate_block"} = sub {
            die "concat rendering failure\n" if $options{fail_render};
            return $render->(@_);
        };
        eval {
            $hdl = ($options{language} // '') eq 'verilog'
                ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module);
            1;
        } or $error = $@;
    }
    is($json->encode($raw), $caller, 'complete caller preserves');
    my $result = {backend => $backend, module => $module, owner => $owner, observed => \%observed,
        block => $block, weak_view => $weak_view, error => $error, hdl => $hdl};
    weaken($result->{weak_view}) if $result->{weak_view};
    return $result;
}

subtest 'actual successful collection exposes original detached policy with bounded ownership' => sub {
    plan skip_all => 'completed concatenation API absent' unless $has_policy;
    for my $mutable (0, 1) {
        for my $rhs (0, 1) {
            for my $language (qw(systemverilog verilog)) {
                my $p = fixture(mutable => $mutable, rhs => $rhs, language => $language, retain => 1);
                if ($mutable && !$rhs) {
                    like($p->{error}, qr/requires proved symbolic sum range/, 'mutable guard retains contextual symbolic refusal');
                } else {
                    is($p->{error}, undef, 'supported fixed guard or inline RHS generation succeeds');
                }
                my $before = $p->{observed}{before};
                my $after = $p->{observed}{after};
                is(scalar(keys %{$before->{events}}), $rhs ? 0 : 2, 'independent actual candidate population');
                is_deeply([values %{$before->{policies}}], [(undef) x keys(%{$before->{events}})],
                    'held intrinsic events supply no early policy');
                is_deeply($after->{policies}, $before->{events}, 'completion exposes same original records without recapture');
                is_deeply($after->{events}, $before->{events}, 'original intrinsic records preserve');
                next if $rhs;
                is_deeply([sort {$a <=> $b} map {$_->{selected_width}} values %{$after->{policies}}], [11, 19],
                    'ordered independent operand sums preserve');
                if ($mutable) {
                    ok(!exists($p->{owner}{_width_inference_complete}), 'later symbolic refusal clears completed authority');
                    is_deeply($p->{owner}{_concatenation_inference_events}, {}, 'later failure clears all event holders');
                    next;
                }
                my $owner = $p->{owner};
                my @rows;
                for my $name (sort keys %{$after->{policies}}) {
                    my $row = $p->{block}{all_intermediate_signals}{$name};
                    push @rows, $row;
                    is_deeply($p->{observed}{prepared}{policies}{$name}, $after->{policies}{$name},
                        'actual retained block owns current policy view');
                    is($owner->intermediate_width_allocation($name, $row), undef, 'whole-reference allocation family preserves');
                }
                is(refaddr($owner->_current_graph_inference_rows), refaddr($p->{block}{all_intermediate_signals}),
                    'retained actual block preserves original weak map lifetime');
                is(scalar @{$p->{observed}{resolver_revocations} || []}, 0,
                    'actual filtered declaration resolver preserves both original events');
                for my $name (keys %{$after->{policies}}) {
                    is_deeply(scalar($owner->factorized_concatenation_width_allocation($name,
                        $p->{block}{all_intermediate_signals}{$name})), $after->{policies}{$name},
                        'original completed numeric policy remains current after actual declaration rendering');
                }
                delete $p->{block};
                ok(!defined($p->{weak_view}), 'retained rows and detached policies cannot retain original map');
                is($owner->_current_graph_inference_rows, undef, 'expired canonical view withholds policy');
            }
        }
    }
};

subtest 'completion prunes removed stale and late-mutated events without minting' => sub {
    plan skip_all => 'completed concatenation API absent' unless $has_policy;
    for my $mode (qw(metadata registered source missing_event late removed)) {
        my $removed;
        my $p = fixture(retain => 1, late => $mode eq 'late',
            prune => $mode eq 'removed' ? sub {
                my ($support, $rows) = @_;
                ($removed) = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                delete $rows->{$removed};
            } : undef,
            before => sub {
                my ($owner, $rows, $o) = @_;
                my ($name) = sort keys %{$o->{before}{events}};
                $rows->{$name}{independent_floor} = 1 if $mode eq 'metadata';
                $owner->{flattened_dt}{intermediate_signals}{$name}{width}++ if $mode eq 'registered';
                my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
                $a->{_width}++ if $mode eq 'source';
                delete $owner->{_concatenation_inference_events}{$name} if $mode eq 'missing_event';
            });
        my $o = $p->{observed};
        ok($o->{late}, 'later semantic callback actually changes earlier row') if $mode eq 'late';
        my ($name) = sort keys %{$o->{before}{events}};
        if ($mode eq 'removed') {
            ok(defined($removed), 'actual prune boundary removes candidate before final sync');
            ok(!(grep {$_ eq $removed} @{$o->{holders}}), 'removed event is not retained at completion');
        } else {
            is($o->{after}{policies}{$name}, undef, "$mode cannot supply completed policy");
            ok(!(grep {$_ eq $name} @{$o->{holders}}), "$mode original holder is pruned or remains absent");
        }
    }
};

subtest 'failure reset source writes and later generations revoke old policy and recover' => sub {
    plan skip_all => 'completed concatenation API absent' unless $has_policy;
    for my $failure (qw(fail_collection fail_render)) {
        my $p = fixture($failure => 1, retain => 1);
        like($p->{error}, qr/^concat (?:collection|rendering) failure\n/, 'exact controlled failure propagates');
        ok(!exists($p->{owner}{_width_inference_complete}), 'failure clears completion');
        is_deeply($p->{owner}{_concatenation_inference_events}, {}, 'failure clears event holders');
        is_deeply($p->{owner}{_concatenation_source_frames}, {}, 'failure clears original source holders');
        my $q = fixture(backend => $p->{backend}, retain => 1);
        is($q->{error}, undef, 'failed backend clean generation recovers');
        is_deeply($q->{observed}{after}{policies}, $q->{observed}{before}{events}, 'new successful collection publishes fresh original policy');
    }
    my ($old_name, $old_row);
    my $p = fixture(retain => 1, prepared => sub {
        my ($owner, $block, $o) = @_;
        ($old_name) = sort keys %{$o->{after}{policies}};
        $old_row = $block->{all_intermediate_signals}{$old_name};
        ok($owner->factorized_concatenation_width_allocation($old_name, $old_row), 'source mutation control begins with current completed policy');
        is($owner->factorized_concatenation_width_allocation($old_name, {%$old_row}), undef, 'equal foreign row cannot borrow current policy');
        my $copy = $owner->factorized_concatenation_width_allocation($old_name, $old_row);
        $copy->{source_contract}{expression_tree}[0] = 'foreign';
        is_deeply(scalar($owner->factorized_concatenation_width_allocation($old_name, $old_row)), $o->{after}{policies}{$old_name},
            'actual accessor returns detached nested data');
        $owner->{flattened_dt}{fsm_module}->signals->{A}{_width}++;
        is($owner->factorized_concatenation_width_allocation($old_name, $old_row), undef, 'source width change revokes current completed policy');
    });
    my $owner = $p->{owner};
    my ($name) = sort keys %{$p->{observed}{after}{policies}};
    my $row = $p->{block}{all_intermediate_signals}{$name};
    my $q = fixture(backend => $p->{backend}, retain => 1);
    is($q->{error}, undef, 'fresh generation succeeds while old block remains owned');
    is($owner->factorized_concatenation_width_allocation($name, $row), undef, 'old row cannot borrow later completion');
    $owner->_abort_factorized_width_inference;
    for my $current (keys %{$q->{observed}{after}{policies}}) {
        is($owner->factorized_concatenation_width_allocation($current, $q->{block}{all_intermediate_signals}{$current}), undef,
            'explicit reset withholds otherwise retained policy');
    }
};

done_testing();
