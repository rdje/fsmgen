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

my $support = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
my $width = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $sync = $support->can('sync_consolidated_signals_to_registry');
my $graphs = $width->can('_finish_graph_registry_copies');
my $resolve = $width->can('resolve_intermediate_signal_width');
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
my $json = JSON::PP->new->canonical;
for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateSupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native registry owner loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}

sub fixture {
    my ($mutable) = @_;
    my $params = $mutable ? '(+params (W 8) (X 3))' : '';
    my ($a, $b) = $mutable ? ('(param W)', '(param X)') : (8, 3);
    my $source = "(?fsm:registry $params (+size (A $a) (B $b) (DATA 1) (OTHER 1))"
        . ' (idle (<(concat A B) (= (DATA 1))) (<(concat B A A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}

{
    package Local::RegistryContextProvider;
    sub _checkpoint_graph_registry_copies {return {}}
    sub _finish_graph_registry_copies {
        my $self = shift;
        push @{$self->{contexts}}, !defined(wantarray) ? 'void' : wantarray ? 'list' : 'scalar';
        return wantarray ? (7, 8) : 9;
    }
    sub _checkpoint_concatenation_registry_copies {return {}}
    sub _finish_concatenation_registry_copies {return 99}
}

subtest 'optional provider return and graph callback contexts preserve' => sub {
    my $provider = bless {contexts => []}, 'Local::RegistryContextProvider';
    my $collector = $support->new(flattened_dt => {backend_sv_intermediate_width_support => $provider});
    my @list = $sync->($collector, {}, 1);
    my $scalar = $sync->($collector, {}, 1);
    $sync->($collector, {}, 1);
    is_deeply(\@list, [7, 8], 'original graph callback list result preserves');
    is($scalar, 9, 'original graph callback scalar result preserves');
    is_deeply($provider->{contexts}, [qw(list scalar void)], 'original graph callback receives each caller context');
    my $plain = $support->new(flattened_dt => {});
    my @plain_list = $sync->($plain, {}, 1);
    is_deeply(\@plain_list, [undef], 'absent optional graph provider preserves its false expression result');
    is(scalar($sync->($plain, {}, 1)), undef, 'absent optional scalar result preserves');
};

subtest 'actual reset and subsequent merge carry original paired source and intrinsic proof' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            my ($module, $raw) = fixture($mutable);
            my $caller = $json->encode($raw);
            my $backend = FSM::HDL::FlattenedDT->new;
            my ($seen, $weak_view, $owner, @retained);
            {
                no warnings 'redefine';
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
                    my ($width_owner, $name, $row) = @_;
                    if (ref($row->{ast}) eq 'FSM::CoreAST::Concatenation' && !defined($row->{width})) {
                        $backend->{intermediate_signals}{$name}{registry_only} = {slots => ['original']};
                    }
                    return $resolve->(@_);
                };
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::sync_consolidated_signals_to_registry = sub {
                    my ($collector, $rows, $replace) = @_;
                    return $sync->(@_) unless $replace;
                    $owner = $backend->{backend_sv_intermediate_width_support};
                    $weak_view = $rows; weaken($weak_view);
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    is(scalar @names, 2, 'actual two-candidate population');
                    my (%events, %sources);
                    for my $name (@names) {
                        $events{$name} = $owner->concatenation_inference_event($name, $rows->{$name});
                        $sources{$name} = $owner->concatenation_generation_sources($name, $rows->{$name});
                        ok($events{$name} && $sources{$name}, 'original normalized source/event pair is current');
                        push @retained, $rows->{$name}, $events{$name}, $sources{$name};
                    }
                    for my $reset (0, 1, 0) {
                        my $old_map = refaddr($backend->{intermediate_signals});
                        my %old_rows = map {$_ => $backend->{intermediate_signals}{$_}} @names;
                        $sync->($collector, $rows, $reset);
                        is(refaddr($backend->{intermediate_signals}) == $old_map ? 1 : 0, $reset ? 0 : 1,
                            'actual map replacement or merge identity preserves');
                        for my $name (@names) {
                            my $row = $rows->{$name};
                            my $event = $owner->concatenation_inference_event($name, $row);
                            my $source = $owner->concatenation_generation_sources($name, $row);
                            is_deeply($event, $events{$name}, 'same original event survives exact registry copy');
                            ok($source, 'same original source frame remains current') or next;
                            is_deeply($source->{sources}, $sources{$name}{sources}, 'original canonical observation and contracts never recapture');
                            my $binding = {%{$source->{binding}}};
                            @{$binding}{qw(registry registered)} = @{$sources{$name}{binding}}{qw(registry registered)};
                            is_deeply($binding, $sources{$name}{binding}, 'all non-registry original bindings preserve');
                            is($source->{binding}{registry}, sprintf('%x', refaddr($backend->{intermediate_signals})), 'actual installed map identity bound');
                            is($source->{binding}{registered}, sprintf('%x', refaddr($backend->{intermediate_signals}{$name})), 'actual installed row identity bound');
                            isnt(refaddr($backend->{intermediate_signals}{$name}), refaddr($old_rows{$name}), 'registry row is an actual new copy');
                            is_deeply($backend->{intermediate_signals}{$name},
                                {($reset ? () : %{$old_rows{$name}}), %$row, name => $name},
                                'complete existing/merged/name copy including independent metadata agrees');
                            is($owner->intermediate_width_allocation($name, $row), undef, 'registry carry grants no completed policy');
                        }
                    }
                    $seen++;
                };
                my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed generation and mutable symbolic refusal preserve') or diag $@;
            }
            is($seen, 1, 'actual final sync boundary observed');
            is($json->encode($raw), $caller, 'complete caller preserves');
            ok(!defined($weak_view), 'retained rows and holders cannot retain weak view');
        }
    }
};

subtest 'post-assignment and later semantic callbacks cannot refresh any original pair' => sub {
    for my $mode (qw(metadata row_identity map_identity partial extra allocator source nested
        late_getter event_map source_map injected_event injected_source copied_view missing_event stale_before throwing)) {
        my ($module) = fixture(0);
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($active, $rows, $owner, $nonoperand, $seen, $mutated, $getters, @names);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result = $prepare->(@_);
                if ($active && $mode eq 'late_getter' && ++$getters == 2) {
                    $rows->{$names[0]}{late_registry_mutation} = 1;
                    $mutated++;
                }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_finish_graph_registry_copies = sub {
                my $result = $graphs->(@_);
                return $result unless $active;
                is_deeply($owner->{_concatenation_inference_events}, {}, 'all intrinsic proof withheld through registry callbacks');
                is_deeply($owner->{_concatenation_source_frames}, {}, 'all source proof withheld through registry callbacks');
                $owner->{_concatenation_inference_events} = {} if $mode eq 'event_map';
                $owner->{_concatenation_source_frames} = {} if $mode eq 'source_map';
                $owner->{_concatenation_inference_events}{foreign} = {} if $mode eq 'injected_event';
                $owner->{_concatenation_source_frames}{foreign} = {} if $mode eq 'injected_source';
                my $name = $names[0];
                my $registered = $backend->{intermediate_signals}{$name};
                $registered->{unknown} = 1 if $mode eq 'metadata';
                $backend->{intermediate_signals}{$name} = {%$registered} if $mode eq 'row_identity';
                $backend->{intermediate_signals} = {%{$backend->{intermediate_signals}}} if $mode eq 'map_identity';
                delete $backend->{intermediate_signals}{$name} if $mode eq 'partial';
                $backend->{intermediate_signals}{foreign} = {} if $mode eq 'extra';
                $backend->{ast_factorizer}{intermediate_signals}{$name}{unknown} = 1 if $mode eq 'allocator';
                $nonoperand->{_width} = 2 if $mode eq 'source';
                $registered->{dependency_signal_names} = [@{$registered->{dependency_signal_names}}] if $mode eq 'nested';
                die "registry carry failure\n" if $mode eq 'throwing';
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::sync_consolidated_signals_to_registry = sub {
                my ($collector, $actual, $replace) = @_;
                return $sync->(@_) unless $replace;
                ($rows, $owner) = ($actual, $backend->{backend_sv_intermediate_width_support});
                $nonoperand = $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};
                is(ref($nonoperand), 'FSM::CoreAST::Signal', 'actual nonoperand LHS Signal selected');
                @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                ok($owner->concatenation_inference_event($_, $rows->{$_}), 'actual original pair starts current') for @names;
                $owner->{_concatenation_inference_events} = {} if $mode eq 'missing_event';
                $rows->{$names[0]}{stale_registry_input} = 1 if $mode eq 'stale_before';
                $active = 1;
                my $ok = eval {$sync->($collector, $mode eq 'copied_view' ? {%$rows} : $rows, $replace); 1};
                my $error = $@;
                $active = 0;
                is($ok ? 1 : 0, $mode eq 'throwing' ? 0 : 1, 'ordinary sync result or original callback exception preserves');
                is($error, "registry carry failure\n", 'exact original sync failure propagates') if $mode eq 'throwing';
                ok($mutated, 'later actual canonical getter changed the earlier candidate') if $mode eq 'late_getter';
                is_deeply($owner->{_concatenation_inference_events}, {}, 'no partial intrinsic holder refresh');
                is_deeply($owner->{_concatenation_source_frames}, {}, 'no partial source holder refresh');
                for my $name (@names) {
                    is($owner->concatenation_inference_event($name, $rows->{$name}), undef, 'current event accessor withholds');
                    is($owner->concatenation_generation_sources($name, $rows->{$name}), undef, 'current source accessor withholds');
                }
                $seen++;
                die $error unless $ok;
            };
            eval {$backend->generate_systemverilog($module)};
        }
        is($seen, 1, "$mode actual registry transaction observed");
        $nonoperand->{_width} = 1;
        ok(eval {$backend->generate_systemverilog($module); 1}, 'same backend clean generation recovers') or diag $@;
    }
};

done_testing();
