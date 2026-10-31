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

my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $recovery_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport';
my $dependencies = $recovery_class->can('resolve_intermediate_signal_dependencies');
my $recover = $recovery_class->can('resolve_intermediate_signal_runtime_ast');
my $fallback = $recovery_class->can('extract_intermediate_signals_from_runtime_ast_miss');
my $extract = \&FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast;
my $resolve = $width_class->can('resolve_intermediate_signal_width');
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
my $json = JSON::PP->new->canonical;
for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native dependency owner is loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}
sub fixture {
    my ($mutable, $expression) = @_;
    my $params = $mutable ? '(+params (W 8) (X 3))' : '';
    my ($a, $b) = $mutable ? ('(param W)', '(param X)') : (8, 3);
    my $source = "(?fsm:dependencies $params (+size (A $a) (B $b) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}
our ($ACTIVE, $AFTER);

subtest 'actual dependency publication preserves held events and cached reads' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            for my $expression ('(concat A B)', '(concat B A A)', "(concat A (concat B 4'b0101))") {
                my ($module, $raw) = fixture($mutable, $expression);
                my $caller = $json->encode($raw);
                my $backend = FSM::HDL::FlattenedDT->new;
                my ($seen, $callbacks, $owner, $name, $row, $weak_view, $retained);
                {
                    no warnings 'redefine';
                    local *FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast = sub {
                        if ($ACTIVE) {
                            is($ACTIVE->{owner}->concatenation_inference_event($ACTIVE->{name}, $ACTIVE->{row}), undef,
                                'event withheld through actual extraction callbacks');
                            $callbacks++;
                        }
                        return $extract->(@_);
                    };
                    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_dependencies = sub {
                        my ($recovery, $n, $info) = @_;
                        return $dependencies->(@_) unless ref($info->{ast}) eq 'FSM::CoreAST::Concatenation' && !$seen;
                        ($owner, $name, $row) = ($backend->{backend_sv_intermediate_width_support}, $n, $info);
                        my $before = $owner->concatenation_inference_event($n, $info);
                        ok($before, 'width publication arrives current');
                        $weak_view = $owner->_current_graph_inference_rows; weaken($weak_view);
                        local $ACTIVE = {owner => $owner, name => $n, row => $info};
                        my @names = $dependencies->(@_);
                        is_deeply(\@names, [], 'whole module operands have no intermediate dependencies');
                        is_deeply($info->{dependency_signal_names}, \@names, 'exact returned ordered names published');
                        is($info->{dependency_source}, 'substituted_ast', 'original runtime source published');
                        ok(!exists($info->{dependency_fallback_source}), 'empty fallback leaves no tag');
                        is_deeply($owner->concatenation_inference_event($n, $info), $before, 'same intrinsic event survives publication');
                        $retained = $json->decode($json->encode($owner->{_concatenation_inference_events}{$n}));
                        my ($calls, $array) = ($callbacks, $info->{dependency_signal_names});
                        is_deeply([$dependencies->(@_)], \@names, 'cached dependency return preserves');
                        is(refaddr($info->{dependency_signal_names}), refaddr($array), 'cached read retains actual array identity');
                        is($callbacks, $calls, 'cached read invokes no extraction');
                        is_deeply($owner->concatenation_inference_event($n, $info), $before, 'cached no-write read retains authority');
                        is($owner->intermediate_width_allocation($n, $info), undef, 'dependency carry grants no completed policy');
                        $seen++;
                        return @names;
                    };
                    my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                    is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed success and mutable sum refusal preserve') or diag $@;
                }
                is($seen, 1, 'actual first dependency publication observed');
                ok($callbacks, 'actual extractor exercised');
                is($json->encode($raw), $caller, 'complete caller source preserved');
                ok(!defined($weak_view), 'plain holder and retained row do not retain view');
                is($owner->concatenation_inference_event($name, $row), undef, 'expired view withholds');
            }
        }
    }
};

subtest 'exact ordered callback returns and narrow fallback publication' => sub {
    for my $mode (qw(no_fallback known_fallback unknown_fallback)) {
        my ($module) = fixture(0, '(concat A B)');
        my $backend = FSM::HDL::FlattenedDT->new;
        my $seen = 0;
        {
            no warnings 'redefine';
            local *FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast = sub {
                return ('dep_z', 'dep_a', 'dep_z', $mode eq 'no_fallback' ? (undef, '') : ()) if $ACTIVE;
                return $extract->(@_);
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::extract_intermediate_signals_from_runtime_ast_miss = sub {
                return $fallback->(@_) unless $ACTIVE;
                return () if $mode eq 'no_fallback';
                $_[2]{dependency_fallback_source} = $mode eq 'known_fallback' ? 'rendered_expression_fallback' : 'foreign_fallback';
                return ('dep_a', 'dep_b', 'dep_b');
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_dependencies = sub {
                my ($recovery, $name, $row) = @_;
                return $dependencies->(@_) unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation' && !$seen;
                my $owner = $backend->{backend_sv_intermediate_width_support};
                my $before = $owner->concatenation_inference_event($name, $row);
                ok($before, "$mode starts current");
                local $ACTIVE = {owner => $owner, name => $name, row => $row};
                my @names = $dependencies->(@_);
                my @expected = ('dep_z', 'dep_a', $mode eq 'no_fallback' ? () : 'dep_b');
                is_deeply(\@names, \@expected, 'actual ordered deduplication preserves');
                is_deeply($row->{dependency_signal_names}, \@expected, 'actual array carries ordered callback returns');
                is_deeply(scalar($owner->concatenation_inference_event($name, $row)), $mode eq 'unknown_fallback' ? undef : $before,
                    'only narrow known fallback label carries');
                $seen++;
                $ACTIVE = undef;
                return @names;
            };
            ok(eval {$backend->generate_systemverilog($module); 1}, "$mode ordinary numeric generation preserves") or diag $@;
        }
        is($seen, 1, "$mode actual publication observed");
    }
};

subtest 'callbacks and late reads cannot refresh or remint dependency authority' => sub {
    for my $mode (qw(row_metadata source revision registry_identity foreign_runtime early_array missing_event throwing fallback_throwing late_array late_values late_source late_tag late_getter)) {
        my ($module) = fixture(0, '(concat A B)');
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($seen, $mutated) = (0, 0);
        my $lhs;
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result = $prepare->(@_);
                if ($ACTIVE && $AFTER && ref($ACTIVE->{row}{dependency_signal_names}) eq 'ARRAY') {
                    my $row = $ACTIVE->{row};
                    $row->{dependency_signal_names} = [@{$row->{dependency_signal_names}}] if $mode eq 'late_array';
                    $row->{dependency_signal_names}[0] = 'foreign_dep' if $mode eq 'late_values';
                    $row->{dependency_source} = 'foreign_source' if $mode eq 'late_source';
                    $row->{dependency_fallback_source} = 'foreign_fallback' if $mode eq 'late_tag';
                    $lhs->{_width} = 2 if $mode eq 'late_getter';
                    $mutated++ if $mode =~ /^late_/;
                }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_runtime_ast = sub {
                my $result = $recover->(@_);
                if ($ACTIVE && $mode eq 'foreign_runtime' && defined($ACTIVE->{row}{rendered_expression})) {
                    $mutated++;
                    return FSM::CoreAST::Concatenation->new(reverse @{$result->{operands}});
                }
                return $result;
            };
            local *FSM::Synthesis::EnableGraph::SignalSupport::extract_intermediate_signals_from_ast = sub {
                my @result = $extract->(@_);
                if ($ACTIVE) {
                    $ACTIVE->{row}{expression} = 'changed' if $mode eq 'row_metadata';
                    $lhs->{_width} = 2 if $mode eq 'source';
                    $ACTIVE->{owner}{_width_inference_revisions}{$ACTIVE->{name}}++ if $mode eq 'revision';
                    $backend->{intermediate_signals}{$ACTIVE->{name}} = {%{$backend->{intermediate_signals}{$ACTIVE->{name}}}} if $mode eq 'registry_identity';
                    $ACTIVE->{row}{dependency_signal_names} = [] if $mode eq 'early_array';
                    die "dependency callback failed\n" if $mode eq 'throwing';
                }
                return @result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::extract_intermediate_signals_from_runtime_ast_miss = sub {
                die "fallback callback failed\n" if $ACTIVE && $mode eq 'fallback_throwing';
                my @result = $fallback->(@_);
                $AFTER = 1 if $ACTIVE;
                return @result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_dependencies = sub {
                my ($recovery, $name, $row) = @_;
                return $dependencies->(@_) unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation' && !$seen;
                my $owner = $backend->{backend_sv_intermediate_width_support};
                ok($owner->concatenation_inference_event($name, $row), "$mode starts current");
                # Render first so foreign-runtime hostility targets dependency recovery.
                $recovery->render_intermediate_signal_expression($name, $row);
                my $registered = $backend->{intermediate_signals}{$name};
                my $expression = $row->{expression};
                $lhs = $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};
                delete $owner->{_concatenation_inference_events}{$name} if $mode eq 'missing_event';
                local $ACTIVE = {owner => $owner, name => $name, row => $row};
                local $AFTER = 0;
                my @names;
                my $ok = eval {@names = $dependencies->(@_); 1};
                my $error = $@;
                $AFTER = 0;
                my $throws = $mode =~ /throwing$/;
                is($ok ? 1 : 0, $throws ? 0 : 1, "$mode callback result preserves");
                is($error, $mode eq 'throwing' ? "dependency callback failed\n" : "fallback callback failed\n", 'exact callback exception propagates') if $throws;
                is($owner->concatenation_inference_event($name, $row), undef, "$mode cannot refresh");
                ok(!exists($owner->{_concatenation_inference_events}{$name}), "$mode leaves no holder");
                ok($mutated, "$mode actual callback exercised") if $mode =~ /^late_|foreign_runtime/;
                $lhs->{_width} = 1;
                $row->{expression} = $expression;
                $backend->{intermediate_signals}{$name} = $registered;
                $ACTIVE = undef;
                delete @{$row}{qw(dependency_signal_names dependency_source dependency_fallback_source)};
                $resolve->($owner, $name, $row, $owner->_current_graph_inference_rows);
                @names = $dependencies->($recovery, $name, $row);
                is($owner->concatenation_inference_event($name, $row), undef, "$mode clean repeat cannot remint");
                $seen++;
                return @names;
            };
            ok(eval {$backend->generate_systemverilog($module); 1}, "$mode ordinary continuation preserves") or diag $@;
        }
        is($seen, 1, "$mode actual dependency resolution observed");
    }
};

done_testing();
