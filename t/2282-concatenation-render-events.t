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

my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $recovery_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport';
my $render = $recovery_class->can('render_intermediate_signal_expression');
my $recover = $recovery_class->can('resolve_intermediate_signal_runtime_ast');
my $resolve = $width_class->can('resolve_intermediate_signal_width');
my $ast_render = \&FSM::Synthesis::EnableGraph::ASTSupport::ast_to_systemverilog;
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
my $json = JSON::PP->new->canonical;
for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalRecoverySupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native render owner is loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($mutable, $expression) = @_;
    my $params = $mutable ? '(+params (W 8) (X 3))' : '';
    my ($a, $b) = $mutable ? ('(param W)', '(param X)') : (8, 3);
    my $source = "(?fsm:render $params (+size (A $a) (B $b) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}
our ($ACTIVE, $AFTER);

subtest 'actual typed render inside dependency resolution carries the same event' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            for my $case (['(concat A B)', 11], ['(concat B A A)', 19],
                ["(concat A (concat B 4'b0101))", 15]) {
                my ($module, $raw) = fixture($mutable, $case->[0]);
                my $caller = $json->encode($raw);
                my $backend = FSM::HDL::FlattenedDT->new;
                my ($seen, $callback, $weak_view, $retained, $owner, $name, $row);
                {
                    no warnings 'redefine';
                    local *FSM::Synthesis::EnableGraph::ASTSupport::ast_to_systemverilog = sub {
                        if ($ACTIVE && $_[1] == $ACTIVE->{row}{ast}) {
                            is($ACTIVE->{owner}->concatenation_inference_event($ACTIVE->{name}, $ACTIVE->{row}), undef,
                                'intrinsic authority is withheld during actual AST renderer');
                            $callback++;
                        }
                        return $ast_render->(@_);
                    };
                    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::render_intermediate_signal_expression = sub {
                        my ($recovery, $n, $info) = @_;
                        return $render->(@_) unless ref($info->{ast}) eq 'FSM::CoreAST::Concatenation' && !$seen;
                        ($owner, $name, $row) = ($backend->{backend_sv_intermediate_width_support}, $n, $info);
                        $weak_view = $owner->_current_graph_inference_rows; weaken($weak_view);
                        my $before = $owner->concatenation_inference_event($n, $info);
                        ok($before, 'owned width publication arrives current at nested render');
                        local $ACTIVE = {owner => $owner, name => $n, row => $info};
                        my $expression = $render->(@_);
                        is_deeply($owner->concatenation_inference_event($n, $info), $before, 'typed render annotations preserve the same event');
                        is($before->{selected_width}, $case->[1], 'independent numeric sum preserves');
                        is($info->{rendered_expression}, $expression, 'actual renderer return is installed');
                        is($info->{rendered_expression_source}, 'substituted_ast', 'original runtime source labels the render');
                        $retained = copy($owner->{_concatenation_inference_events}{$n});
                        my $calls = $callback;
                        is($render->(@_), $expression, 'cached render returns identical expression');
                        is($callback, $calls, 'cached render calls no AST renderer');
                        is_deeply($owner->concatenation_inference_event($n, $info), $before, 'cached no-write read preserves held authority');
                        is($owner->intermediate_width_allocation($n, $info), undef, 'rendering grants no completed policy');
                        $seen++;
                        return $expression;
                    };
                    my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                    is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed success and mutable sum refusal preserve') or diag $@;
                }
                is($seen, 1, 'actual first typed render observed');
                is($callback, 1, 'one actual root renderer callback observed');
                is($json->encode($raw), $caller, 'complete caller source preserves');
                ok(!defined($weak_view), 'detached render holder and retained row do not retain view');
                is($owner->concatenation_inference_event($name, $row), undef, 'later annotations or expired view remain unqualified');
            }
        }
    }
};

subtest 'renderer and recovery mutations cannot refresh or remint authority' => sub {
    for my $mode (qw(row_metadata source revision foreign_runtime registry_identity late_getter throwing missing_event)) {
        my ($module) = fixture(0, '(concat A B)');
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($seen, $mutated) = (0, 0);
        my $lhs;
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result = $prepare->(@_);
                if ($ACTIVE && $AFTER && $mode eq 'late_getter') { $lhs->{_width} = 2; $mutated++ }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_runtime_ast = sub {
                my $result = $recover->(@_);
                if ($ACTIVE && $mode eq 'foreign_runtime' && ref($result) eq 'FSM::CoreAST::Concatenation') {
                    $mutated++;
                    return FSM::CoreAST::Concatenation->new(reverse @{$result->{operands}});
                }
                return $result;
            };
            local *FSM::Synthesis::EnableGraph::ASTSupport::ast_to_systemverilog = sub {
                my $top = $ACTIVE && ref($_[1]) eq 'FSM::CoreAST::Concatenation';
                my $result = $ast_render->(@_);
                if ($top) {
                    $ACTIVE->{row}{expression} = 'changed' if $mode eq 'row_metadata';
                    $lhs->{_width} = 2 if $mode eq 'source';
                    $ACTIVE->{owner}{_width_inference_revisions}{$ACTIVE->{name}}++ if $mode eq 'revision';
                    $backend->{intermediate_signals}{$ACTIVE->{name}} = {%{$backend->{intermediate_signals}{$ACTIVE->{name}}}} if $mode eq 'registry_identity';
                    die "renderer callback failed\n" if $mode eq 'throwing';
                    $AFTER = 1;
                }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::render_intermediate_signal_expression = sub {
                my ($recovery, $name, $row) = @_;
                return $render->(@_) unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation' && !$seen;
                my $owner = $backend->{backend_sv_intermediate_width_support};
                ok($owner->concatenation_inference_event($name, $row), "$mode starts current");
                my $registered = $backend->{intermediate_signals}{$name};
                my $expression = $row->{expression};
                $lhs = $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};
                delete $owner->{_concatenation_inference_events}{$name} if $mode eq 'missing_event';
                local $ACTIVE = {owner => $owner, name => $name, row => $row};
                local $AFTER = 0;
                my $result;
                my $ok = eval {$result = $render->(@_); 1};
                my $error = $@;
                $AFTER = 0;
                is($ok ? 1 : 0, $mode eq 'throwing' ? 0 : 1, "$mode callback result preserves");
                is($error, "renderer callback failed\n", 'exact renderer exception propagates') if $mode eq 'throwing';
                is($owner->concatenation_inference_event($name, $row), undef, "$mode cannot refresh");
                ok(!exists($owner->{_concatenation_inference_events}{$name}), "$mode leaves no holder");
                ok($mutated, "$mode actual callback mutation exercised") if $mode =~ /foreign_runtime|late_getter/;
                $lhs->{_width} = 1;
                $row->{expression} = $expression;
                $backend->{intermediate_signals}{$name} = $registered;
                $resolve->($owner, $name, $row, $owner->_current_graph_inference_rows);
                is($owner->concatenation_inference_event($name, $row), undef, "$mode clean repeat cannot remint");
                $seen++;
                # A thrown callback is observed directly, then ordinary typed
                # rendering may continue with the spent event still absent.
                $ACTIVE = undef;
                return $ok ? $result : $render->(@_);
            };
            ok(eval {$backend->generate_systemverilog($module); 1}, "$mode ordinary continuation preserves") or diag $@;
        }
        is($seen, 1, "$mode actual render exercised");
    }
};

done_testing();
