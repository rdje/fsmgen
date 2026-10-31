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

my $factor_class = 'FSM::Synthesis::EnableGraph::FactorizationSupport';
my $prime = $factor_class->can('prime_intermediate_signal_live_usage');
my $extract = \&FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast;
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
my $json = JSON::PP->new->canonical;
for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'FSM/Synthesis/EnableGraph/FactorizationSupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native bulk owner loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}

sub fixture {
    my ($mutable) = @_;
    my $params = $mutable ? '(+params (W 8))' : '';
    my $a = $mutable ? '(param W)' : 8;
    my $source = "(?fsm:bulk $params (+size (A $a) (B 3) (DATA 1) (OTHER 1))"
        . ' (idle (<(concat A B) (= (DATA 1))) (<(concat B A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}

our ($ACTIVE, $GETTER);
sub events {
    my ($owner, $rows, $names) = @_;
    return [map { scalar $owner->concatenation_inference_event($_, $rows->{$_}) } @$names];
}

subtest 'actual multi-row bulk priming carries original events and cached reads' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            my ($module, $raw) = fixture($mutable);
            my $caller = $json->encode($raw);
            my $backend = FSM::HDL::FlattenedDT->new;
            my ($seen, $callbacks, $weak_view, $owner, @retained);
            {
                no warnings 'redefine';
                local *FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast = sub {
                    if ($ACTIVE) {
                        is_deeply(events(@$ACTIVE), [undef, undef], 'all events withheld before every global root callback');
                        $callbacks++;
                    }
                    return $extract->(@_);
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                    my ($factor, $rows) = @_;
                    $owner = $backend->{backend_sv_intermediate_width_support};
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    is(scalar @names, 2, 'two distinct actual concatenation rows');
                    my $before = events($owner, $rows, \@names);
                    ok($before->[0] && $before->[1], 'both original dependency events arrive current');
                    $weak_view = $rows; weaken($weak_view);
                    my $summary;
                    { local $ACTIVE = [$owner, $rows, \@names]; $summary = $prime->(@_) }
                    is_deeply(events($owner, $rows, \@names), $before, 'same original intrinsic events survive all bulk writes');
                    is($summary->{signal_count}, scalar keys %$rows, 'summary preserves complete supplied population');
                    for my $name (@names) {
                        my $row = $rows->{$name};
                        is($row->{live_usage_source}, 'ast_live_usage_metadata', 'actual bulk source');
                        my ($r, $u) = @$row{qw(referenced_in_substitutions used_in_final_expressions)};
                        is($row->{live_usage_evidence_state}, $r ? ($u ? 'substitutions_and_final_expressions' : 'substitutions')
                            : ($u ? 'final_expressions' : 'none'), 'state agrees with exact actual boolean pair');
                        is($owner->intermediate_width_allocation($name, $row), undef, 'bulk carry grants no completed policy');
                        push @retained, [$name, $row, $json->decode($json->encode($owner->{_concatenation_inference_events}{$name}))];
                    }
                    my $cached = $json->encode([map {$rows->{$_}{live_usage_evidence_state}} @names]);
                    is_deeply($prime->(@_), $summary, 'cached no-write priming preserves summary');
                    is($json->encode([map {$rows->{$_}{live_usage_evidence_state}} @names]), $cached, 'cached values preserve');
                    is_deeply(events($owner, $rows, \@names), $before, 'cached complete view preserves held authority');
                    $seen++;
                    return $summary;
                };
                my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed generation and mutable symbolic refusal preserve') or diag $@;
            }
            is($seen, 1, 'actual bulk boundary exercised');
            ok($callbacks, 'actual root extraction exercised');
            is($json->encode($raw), $caller, 'complete caller input preserved');
            ok(!defined($weak_view), 'plain holders and retained rows do not retain view');
            is($owner->concatenation_inference_event($_->[0], $_->[1]), undef, 'expired view withholds') for @retained;
        }
    }
};

subtest 'actual root populations distinguish every boolean pair and mixed cached rows' => sub {
    for my $cached (0, 1) {
        for my $pair ([0, 0, 'none'], [1, 0, 'substitutions'], [0, 1, 'final_expressions'],
            [1, 1, 'substitutions_and_final_expressions']) {
            my ($module) = fixture(0);
            my $backend = FSM::HDL::FlattenedDT->new;
            my $seen;
            {
                no warnings 'redefine';
                my $bind = $backend->{backend_sv_intermediate_width_support}->can('_bind_graph_inference_rows');
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_bind_graph_inference_rows = sub {
                    my ($owner, $rows) = @_;
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    if ($cached) {
                        @{$rows->{$names[1]}}{qw(referenced_in_substitutions used_in_final_expressions live_usage_evidence_state live_usage_source)}
                            = (7, 0, 'custom_state', 'custom_source');
                    }
                    return $bind->(@_);
                };
                local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                    my ($factor, $rows) = @_;
                    my $owner = $backend->{backend_sv_intermediate_width_support};
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    my $before = events($owner, $rows, \@names);
                    my $ref = FSM::HDL::IntermediateSignalRef->new(signal_name => $names[0]);
                    local $backend->{ast_factorizer}{ast_expressions} = $pair->[0] ? [{ast => $ref}] : [];
                    local $backend->{state_enables} = {};
                    local $backend->{dt_enables} = {};
                    local $backend->{lhs_assignments} = $pair->[1] ? {DATA => [{rhs => $ref}]} : {};
                    # Shared enable roots are outside this independently selected
                    # substitution-only/final-only population.
                    my @saved;
                    for my $row (values %{$backend->{assignment_analysis}}) {
                        push @saved, [$row, $row->{rhs_groups}];
                        $row->{rhs_groups} = {};
                    }
                    my $summary = $prime->(@_);
                    $_->[0]{rhs_groups} = $_->[1] for @saved;
                    is_deeply([@{$rows->{$names[0]}}{qw(referenced_in_substitutions used_in_final_expressions
                        live_usage_evidence_state live_usage_source)}], [@$pair, 'ast_live_usage_metadata'], 'independent actual roots select exact annotations');
                    is_deeply(events($owner, $rows, \@names), $before, 'both events survive differing row usage');
                    is_deeply([@{$rows->{$names[1]}}{qw(referenced_in_substitutions used_in_final_expressions live_usage_evidence_state live_usage_source)}],
                        $cached ? [7, 0, 'custom_state', 'custom_source'] : [0, 0, 'none', 'ast_live_usage_metadata'],
                        'mixed cached row preserves exact original values while uncached row receives computed values');
                    $seen++;
                    return $summary;
                };
                eval {$backend->generate_systemverilog($module)};
            }
            is($seen, 1, 'actual bulk root population exercised');
        }
    }
};

subtest 'whole-view barriers reject hostile roots, late getters and spent retries' => sub {
    for my $mode (qw(row overwritten_boolean other_row container source revision registry missing stale
        copied_view partial_view early_other_row late_getter late_other_row throwing)) {
        my ($module) = fixture(0);
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($seen, $changed) = (0, 0);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result = $prepare->(@_);
                my %args = @_[1 .. $#_];
                $GETTER->($args{signal_name}) if $GETTER;
                return $result;
            };
            local *FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast = sub {
                if ($ACTIVE && !$changed++) {
                    my ($owner, $rows, $names) = @$ACTIVE;
                    my ($first, $other) = @$names;
                    $rows->{$first}{hostile} = 1 if $mode eq 'row';
                    $rows->{$first}{referenced_in_substitutions} = 17 if $mode eq 'overwritten_boolean';
                    $rows->{$other}{hostile} = 1 if $mode eq 'other_row';
                    $rows->{$first}{dependency_signal_names} = [@{$rows->{$first}{dependency_signal_names}}] if $mode eq 'container';
                    $module->{signals}{A}{signed} = 1 if $mode eq 'source';
                    $owner->{_width_inference_revisions}{$first}++ if $mode eq 'revision';
                    $backend->{intermediate_signals} = {%{$backend->{intermediate_signals}}} if $mode eq 'registry';
                    die "bulk root failure\n" if $mode eq 'throwing';
                }
                return $extract->(@_);
            };
            local *FSM::Synthesis::EnableGraph::FactorizationSupport::prime_intermediate_signal_live_usage = sub {
                my ($factor, $rows) = @_;
                my $owner = $backend->{backend_sv_intermediate_width_support};
                my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                ok(!grep(!defined($_), @{events($owner, $rows, \@names)}), "$mode starts with original current events");
                delete $owner->{_concatenation_inference_events}{$names[0]} if $mode eq 'missing';
                $rows->{$names[0]}{stale} = 1 if $mode eq 'stale';
                my $supplied = $mode eq 'copied_view' ? {%$rows}
                    : $mode eq 'partial_view' ? {$names[0] => $rows->{$names[0]}} : $rows;
                my $result;
                my $getters = 0;
                local $GETTER = sub {
                    if ($mode eq 'early_other_row' && !$getters++) {
                        is(scalar keys %{$owner->{_concatenation_inference_events}}, 0, 'all original holders removed before first semantic getter');
                        $rows->{$names[1]}{hostile} = 1;
                    }
                    # Change an already-checked row only during final validation,
                    # after every row has its real owned annotations.
                    return unless $mode =~ /^late_/ && exists($rows->{$names[0]}{live_usage_source})
                        && exists($rows->{$names[1]}{live_usage_source}) && ($_[0] // '') eq $names[1];
                    return if $getters++;
                    $rows->{$names[0]}{hostile} = 1 if $mode eq 'late_getter';
                    $rows->{$names[0]}{used_in_final_expressions} = 19 if $mode eq 'late_other_row';
                };
                my $ok;
                { local $ACTIVE = [$owner, $rows, \@names]; $ok = eval {$result = $prime->($factor, $supplied); 1} }
                if ($mode eq 'throwing') { ok(!$ok, 'original callback exception propagates'); like($@, qr/bulk root failure/, 'same error') }
                else { ok($ok, "$mode preserves ordinary priming") or diag $@ }
                my $expected = $mode =~ /^(missing|stale|row|overwritten_boolean|other_row|container|revision)$/ ? 1 : 0;
                # Unrelated events may survive row-local divergence; the corrupt
                # event and every globally invalid transaction must withhold.
                my $current = events($owner, $rows, \@names);
                ok(!defined($current->[($mode eq 'other_row' ? 1 : 0)]), "$mode cannot refresh changed/missing proof");
                is_deeply($current, [undef, undef], "$mode invalidates whole transaction") unless $expected;
                local $GETTER;
                delete @{$rows->{$names[0]}}{qw(hostile stale)};
                delete $rows->{$names[1]}{hostile};
                $module->{signals}{A}{signed} = 0;
                my $retry = eval {$prime->($factor, $rows); 1};
                ok($retry, 'ordinary clean cached retry remains available') or diag $@;
                is($owner->concatenation_inference_event($names[0], $rows->{$names[0]}), undef, 'later clean read cannot remint spent event');
                $seen++;
                return $result || {};
            };
            eval {$backend->generate_systemverilog($module)};
        }
        is($seen, 1, "$mode actual bulk call observed");
    }
};

subtest 'invalid inputs and injected legacy provider preserve public contracts' => sub {
    my $factor = $factor_class->new(flattened_dt => {backend_sv_intermediate_width_support => bless({}, 'BulkLegacyWidthProvider')});
    is_deeply($prime->($factor, undef), {signal_count => 0, referenced_in_substitutions => 0,
        used_in_final_expressions => 0}, 'invalid input returns original empty summary');
    my $rows = {cached => {referenced_in_substitutions => 7, used_in_final_expressions => 0, live_usage_source => 'custom'}};
    is_deeply($prime->($factor, $rows), {signal_count => 1, referenced_in_substitutions => 0,
        used_in_final_expressions => 0}, 'legacy provider keeps summary');
    is_deeply($rows->{cached}, {referenced_in_substitutions => 7, used_in_final_expressions => 0,
        live_usage_source => 'custom'}, 'both cached keys skip every annotation write');
};

done_testing();
