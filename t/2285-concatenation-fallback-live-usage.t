use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $class = 'FSM::Synthesis::EnableGraph::FactorizationSupport';
my $resolve = $class->can('resolve_intermediate_signal_live_usage');
my $referenced = $class->can('is_signal_referenced_in_substitutions');
my $used = $class->can('is_signal_actually_used_in_final_expressions');
my $prepare = FSM::DirectDeclaredWidthSupport->can('prepare_module');
my $json = JSON::PP->new->canonical;
for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'FSM/Synthesis/EnableGraph/FactorizationSupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native fallback owner loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}

sub fixture {
    my ($mutable) = @_;
    my $params = $mutable ? '(+params (W 8))' : '';
    my $width = $mutable ? '(param W)' : 8;
    my $source = "(?fsm:fallback $params (+size (A $width) (B 3) (DATA 1) (OTHER 1))"
        . ' (idle (<(concat A B) (= (DATA 1))) (<(concat B A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}

sub events {
    my ($owner, $rows, $names) = @_;
    return [map {scalar $owner->concatenation_inference_event($_, $rows->{$_})} @$names];
}

our ($QUERY, $GETTER);
sub check_query {
    my ($which) = @_;
    $QUERY->($which) if $QUERY;
}

subtest 'actual fallback carries original events across both queries and cached reads' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            my ($module, $raw) = fixture($mutable);
            my $caller = $json->encode($raw);
            my $backend = FSM::HDL::FlattenedDT->new;
            my ($seen, $owner, $weak_view, @retained, @queries);
            {
                no warnings 'redefine';
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::is_signal_referenced_in_substitutions = sub {
                    check_query('substitutions'); return $referenced->(@_);
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::is_signal_actually_used_in_final_expressions = sub {
                    check_query('final'); return $used->(@_);
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                    my ($factor, $rows) = @_;
                    $owner = $backend->{backend_sv_intermediate_width_support};
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    is(scalar @names, 2, 'two actual concat rows arrive before bulk annotations');
                    my $before = events($owner, $rows, \@names);
                    ok($before->[0] && $before->[1], 'original current dependency events');
                    $weak_view = $rows; weaken($weak_view);
                    for my $name (@names) {
                        my $row = $rows->{$name};
                        local $QUERY = sub {
                            push @queries, $_[0];
                            is_deeply(events($owner, $rows, \@names), [undef, undef], 'every event withheld during either actual query');
                        };
                        my $result = $resolve->($factor, $name, $row);
                        is_deeply([@$row{qw(referenced_in_substitutions used_in_final_expressions
                            live_usage_evidence_state live_usage_source)}], [@$result{qw(referenced_in_substitutions
                            used_in_final_expressions evidence_state source)}], 'actual return and exact writes agree');
                        is_deeply(events($owner, $rows, \@names), $before, 'same original events survive single-row writes');
                        my $snapshot = $json->encode($owner->{_concatenation_inference_events});
                        my $metadata = $json->encode([@$row{qw(referenced_in_substitutions used_in_final_expressions
                            live_usage_evidence_state live_usage_source)}]);
                        { local $QUERY = sub {fail('cached read must not query')};
                          is_deeply($resolve->($factor, $name, $row), $result, 'cached return preserves') }
                        is($json->encode($owner->{_concatenation_inference_events}), $snapshot, 'cached read does not replace holders');
                        is($json->encode([@$row{qw(referenced_in_substitutions used_in_final_expressions
                            live_usage_evidence_state live_usage_source)}]), $metadata, 'cached read writes no metadata');
                        is($owner->intermediate_width_allocation($name, $row), undef, 'fallback grants no completed allocation policy');
                        push @retained, [$name, $row, $json->decode($snapshot)];
                    }
                    $seen++;
                    return {};
                };
                my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed generation and mutable symbolic refusal preserve') or diag $@;
            }
            is($seen, 1, 'actual prepared fallback boundary observed');
            is_deeply(\@queries, [qw(substitutions final substitutions final)], 'both original queries execute in order per uncached row');
            is($json->encode($raw), $caller, 'complete caller input preserves');
            ok(!defined($weak_view), 'retained rows and detached holders do not retain view');
            is($owner->concatenation_inference_event($_->[0], $_->[1]), undef, 'expired weak view withholds') for @retained;
        }
    }
};

subtest 'independent real root populations select each fallback boolean pair' => sub {
    for my $pair ([0, 0, 'none'], [1, 0, 'substitutions'], [0, 1, 'final_expressions'],
        [1, 1, 'substitutions_and_final_expressions']) {
        my ($module) = fixture(0);
        my $backend = FSM::HDL::FlattenedDT->new;
        my $seen;
        {
            no warnings 'redefine';
            local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                my ($factor, $rows) = @_;
                my $owner = $backend->{backend_sv_intermediate_width_support};
                my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                my $before = events($owner, $rows, \@names);
                my $ref = FSM::HDL::IntermediateSignalRef->new(signal_name => $names[0]);
                local $backend->{ast_factorizer}{ast_expressions} = $pair->[0] ? [{ast => $ref, context => 'fallback_test'}] : [];
                local $backend->{state_enables} = {};
                local $backend->{dt_enables} = {};
                local $backend->{lhs_assignments} = $pair->[1] ? {DATA => [{rhs => $ref}]} : {};
                # Preserve the original source-scope map identity while
                # selecting only substitution and final-RHS roots for usage.
                my @saved;
                for my $analysis (values %{$backend->{assignment_analysis}}) {
                    push @saved, [$analysis, $analysis->{rhs_groups}];
                    $analysis->{rhs_groups} = {};
                }
                is_deeply($resolve->($factor, $names[0], $rows->{$names[0]}), {
                    referenced_in_substitutions => $pair->[0], used_in_final_expressions => $pair->[1],
                    evidence_state => $pair->[2], source => 'ast_live_usage_metadata'}, 'actual queries derive independent root pair');
                is_deeply(events($owner, $rows, \@names), $before, 'actual pair carries both original events');
                ok(!exists($rows->{$names[1]}{referenced_in_substitutions}), 'other uncached row gains no annotation');
                $_->[0]{rhs_groups} = $_->[1] for @saved;
                $seen++;
                return {};
            };
            eval {$backend->generate_systemverilog($module)};
        }
        is($seen, 1, 'independent actual root case observed');
    }
};

subtest 'query and validation callbacks cannot refresh foreign stale changed or spent proof' => sub {
    for my $which (qw(substitutions final)) {
        for my $mode (qw(row overwritten_boolean other_row container source revision registry missing stale
            copied_row foreign_name missing_row early_getter late_getter late_other_row throwing)) {
            my ($module) = fixture(0);
            my $backend = FSM::HDL::FlattenedDT->new;
            my ($seen, $changed, $getters) = (0, 0, 0);
            {
                no warnings 'redefine';
                local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                    my $result = $prepare->(@_);
                    my %args = @_[1 .. $#_];
                    $GETTER->($args{signal_name}) if $GETTER;
                    return $result;
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::is_signal_referenced_in_substitutions = sub {
                    check_query('substitutions'); return $referenced->(@_);
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::is_signal_actually_used_in_final_expressions = sub {
                    check_query('final'); return $used->(@_);
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                    my ($factor, $rows) = @_;
                    my $owner = $backend->{backend_sv_intermediate_width_support};
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    my ($name, $other) = @names;
                    ok(!grep(!defined($_), @{events($owner, $rows, \@names)}), "$which/$mode starts current");
                    delete $owner->{_concatenation_inference_events}{$name} if $mode eq 'missing';
                    $rows->{$name}{stale} = 1 if $mode eq 'stale';
                    my $supplied = $mode eq 'copied_row' ? {%{$rows->{$name}}} : $mode eq 'missing_row' ? undef : $rows->{$name};
                    local $QUERY = sub {
                        return unless $_[0] eq $which && !$changed++;
                        $rows->{$name}{hostile} = 1 if $mode eq 'row';
                        $rows->{$name}{referenced_in_substitutions} = 17 if $mode eq 'overwritten_boolean';
                        $rows->{$other}{hostile} = 1 if $mode eq 'other_row';
                        $rows->{$name}{dependency_signal_names} = [@{$rows->{$name}{dependency_signal_names}}] if $mode eq 'container';
                        $module->{signals}{A}{signed} = 1 if $mode eq 'source';
                        $owner->{_width_inference_revisions}{$name}++ if $mode eq 'revision';
                        $backend->{intermediate_signals} = {%{$backend->{intermediate_signals}}} if $mode eq 'registry';
                        die "fallback query failure\n" if $mode eq 'throwing';
                    };
                    local $GETTER = sub {
                        if ($mode eq 'early_getter' && !$getters++) {
                            is(scalar keys %{$owner->{_concatenation_inference_events}}, 0, 'all holders removed before first semantic getter');
                            $rows->{$other}{hostile} = 1;
                        }
                        return unless $mode =~ /^late_/ && exists($rows->{$name}{live_usage_source})
                            && ($_[0] // '') eq $other && !$getters++;
                        $rows->{$name}{hostile} = 1 if $mode eq 'late_getter';
                        $rows->{$name}{used_in_final_expressions} = 19 if $mode eq 'late_other_row';
                    };
                    my $ok = eval {$resolve->($factor, $mode eq 'foreign_name' ? 'foreign' : $name, $supplied); 1};
                    if ($mode eq 'throwing') {ok(!$ok, 'query exception propagates'); like($@, qr/fallback query failure/, 'same query error')}
                    else {ok($ok, 'ordinary fallback still returns') or diag $@}
                    my $current = events($owner, $rows, \@names);
                    ok(!defined($current->[$mode eq 'other_row' || $mode eq 'early_getter' ? 1 : 0]), 'changed foreign or missing event cannot refresh');
                    local $QUERY;
                    local $GETTER;
                    delete @{$rows->{$name}}{qw(hostile stale)};
                    delete $rows->{$other}{hostile};
                    $module->{signals}{A}{signed} = 0;
                    ok(eval {$resolve->($factor, $name, $rows->{$name}); 1}, 'clean later ordinary retry available');
                    is($owner->concatenation_inference_event($name, $rows->{$name}), undef, 'clean retry cannot remint spent authority');
                    $seen++;
                    return {};
                };
                eval {$backend->generate_systemverilog($module)};
            }
            is($seen, 1, "$which/$mode actual fallback observed");
            # An independent new generation must still be usable after failure.
            if ($mode eq 'throwing') {
                ok(eval {$backend->generate_systemverilog($module); 1}, 'same backend recovers in a clean new generation') or diag $@;
            }
        }
    }
};

subtest 'invalid names cached rows and legacy providers retain ordinary contracts' => sub {
    for my $provider (undef, bless({}, 'FallbackLegacyWidthProvider')) {
        my $factor = $class->new(flattened_dt => {backend_sv_intermediate_width_support => $provider});
        no warnings 'redefine';
        local *FSM::Synthesis::EnableGraph::FactorizationSupport::is_signal_referenced_in_substitutions = sub {return 7};
        local *FSM::Synthesis::EnableGraph::FactorizationSupport::is_signal_actually_used_in_final_expressions = sub {return 0};
        my $row = {referenced_in_substitutions => 7, used_in_final_expressions => 0,
            live_usage_evidence_state => 'custom', live_usage_source => 'custom_source'};
        my $snapshot = $json->encode($row);
        for my $name (undef, '') {
            is_deeply($resolve->($factor, $name, $row), {referenced_in_substitutions => 0,
                used_in_final_expressions => 0, evidence_state => 'none', source => 'ast_live_usage_metadata'}, 'invalid-name default');
        }
        is_deeply($resolve->($factor, 'cached', $row), {referenced_in_substitutions => 1,
            used_in_final_expressions => 0, evidence_state => 'custom', source => 'custom_source'}, 'cached return normalizes only returned booleans');
        is($json->encode($row), $snapshot, 'invalid and cached calls write nothing');
        for my $uncached (undef, [], {used_in_final_expressions => 99}) {
            is_deeply($resolve->($factor, 'ordinary', $uncached), {referenced_in_substitutions => 1,
                used_in_final_expressions => 0, evidence_state => 'substitutions', source => 'ast_live_usage_metadata'}, 'legacy fallback query contract');
        }
    }
};

done_testing();
