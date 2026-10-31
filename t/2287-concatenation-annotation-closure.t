use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use Scalar::Util qw(refaddr weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $normal_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
my $resolve = $width_class->can('resolve_intermediate_signal_width');
my $render = $width_class->can('_with_concatenation_render');
my $normalize = $normal_class->can('normalize_consolidated_intermediate_metadata');
my $json = JSON::PP->new->canonical;

for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/ConsolidatedIntermediateNormalizationSupport.pm') {
    is($INC{$path}, "perl/$path", 'actual annotation owner loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}

sub fixture {
    my ($mutable, $rhs, $case) = @_;
    my $params = $mutable ? "(+params (W $case->{a_width}) (X 3))" : '';
    my ($a, $b) = $mutable ? ('(param W)', '(param X)') : ($case->{a_width}, 3);
    my $destination = $rhs ? $case->{sum} : 1;
    my $source = "(?fsm:annotations $params (+size (A $a) (B $b) (DATA $destination) (OTHER 1))"
        . ($rhs ? " (idle (= (DATA $case->{expression})) (= (OTHER 1)) (-> idle)))"
            : " (idle (<$case->{expression} (= (DATA 1)) (= (OTHER 1))) (-> idle)))");
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}

# These sums and ordered occurrences are independent source-shape expectations;
# no helper name, inference output or emitted declaration supplies this oracle.
my @cases = (
    {expression => '(concat A B)', a_width => 8, sum => 11, names => [qw(A B)]},
    {expression => '(concat B A A)', a_width => 8, sum => 19, names => [qw(B A A)]},
    {expression => "(concat A (concat B 4'b0101))", a_width => 8, sum => 15, names => [qw(A B)]},
    {expression => '(concat B A A)', a_width => 1, sum => 5, names => [qw(B A A)]},
);

subtest 'whole annotation sequence preserves actual guard events and inline RHS boundary' => sub {
    for my $case (@cases) {
        for my $rhs (0, 1) {
            for my $mutable (0, 1) {
                for my $language (qw(systemverilog verilog)) {
                    my ($module, $raw) = fixture($mutable, $rhs, $case);
                    my $caller = $json->encode($raw);
                    my $backend = FSM::HDL::FlattenedDT->new;
                    my (%original, %identities, @retained, $weak_view, $owner, $exits);
                    {
                        no warnings 'redefine';
                        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
                            my ($width, $name, $row, $rows) = @_;
                            my $selected = $resolve->(@_);
                            return $selected unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation';
                            return $selected if $exits || exists($original{$name});
                            $owner = $width;
                            $weak_view = $rows; weaken($weak_view);
                            push @retained, $row;
                            my $event = $width->concatenation_inference_event($name, $row);
                            ok($event, 'actual unresolved guard branch yields original event');
                            $original{$name} = $event;
                            $identities{$name} = [map {refaddr($_)} ($row,
                                $backend->{ast_factorizer}{intermediate_signals}{$name},
                                $backend->{intermediate_signals}, $backend->{intermediate_signals}{$name},
                                $module->{signals}, $module->{parameters})];
                            return $selected;
                        };
                        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata = sub {
                            my ($normalizer, $rows) = @_;
                            $normalize->(@_);
                            $exits++;
                            my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                            is(scalar @names, $rhs ? 0 : 1, 'actual guard candidate versus inline RHS applicability');
                            is_deeply([sort keys %original], \@names, 'exit membership equals actually inferred candidates');
                            for my $name (@names) {
                                my $row = $rows->{$name};
                                my $event = $owner->concatenation_inference_event($name, $row);
                                is_deeply($event, $original{$name}, 'same original event survives every owned annotation');
                                is($event->{selected_width}, $case->{sum}, 'independent ordered sum preserves');
                                is_deeply($event->{source_contract}{source_names}, $case->{names}, 'ordered duplicate sources preserve');
                                is_deeply([map {defined($_->{width_plan}) ? 1 : 0} @{$event->{source_contract}{operands}}],
                                    [map {$mutable ? 1 : 0} @{$case->{names}}], 'independent fixed or mutable contracts preserve');
                                is_deeply([map {$_->{width}} @{$event->{source_contract}{operands}}],
                                    [map {$_ eq 'A' ? $case->{a_width} : 3} @{$case->{names}}], 'each original source width preserves');
                                is_deeply([map {$_->{is_vector}} @{$event->{source_contract}{operands}}],
                                    [map {$_ eq 'A' && $case->{a_width} == 1 && !$mutable ? 0 : 1} @{$case->{names}}],
                                    'mutable width one keeps vector rank independently of fixed scalar rank');
                                is_deeply([map {refaddr($_)} ($row,
                                    $backend->{ast_factorizer}{intermediate_signals}{$name},
                                    $backend->{intermediate_signals}, $backend->{intermediate_signals}{$name},
                                    $module->{signals}, $module->{parameters})], $identities{$name},
                                    'original merged allocator registry and source identities preserve');
                                is($row->{width}, $case->{sum}, 'actual width annotation agrees');
                                is($row->{width_source}, 'substituted_ast', 'actual intrinsic source label preserves');
                                is($row->{rendered_expression}, $row->{ast}->to_systemverilog, 'typed rendering agrees');
                                is($row->{rendered_expression_source}, 'substituted_ast', 'typed render source preserves');
                                is_deeply($row->{dependency_signal_names}, [], 'whole Core sources introduce no helper dependency');
                                is($row->{dependency_source}, 'substituted_ast', 'dependency source preserves');
                                is($row->{live_usage_source}, 'ast_live_usage_metadata', 'actual live-usage writer ran');
                                ok(exists($row->{referenced_in_substitutions}) && exists($row->{used_in_final_expressions}),
                                    'both actual usage flags installed');
                                is($owner->intermediate_width_allocation($name, $row), undef, 'no completed allocation policy at normalization exit');
                                is($owner->factorized_width_inference_event($name, $row), undef, 'no binary maximum authority');
                                is($owner->factorized_graph_inference_event($name, $row), undef, 'no arithmetic graph authority');
                            }
                        };
                        my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                        my $error = $@;
                        is($ok ? 1 : 0, $mutable && !$rhs ? 0 : 1, 'native fixed and inline RHS success or mutable helper refusal preserves') or diag $error;
                        like($error, qr/Direct concatenation '[^']+' requires proved symbolic sum range/,
                            'mutable guard retains contextual refusal') if $mutable && !$rhs;
                    }
                    is($exits, 1, 'actual completed normalization observed once');
                    is($json->encode($raw), $caller, 'complete caller preserves');
                    ok(!defined($weak_view), 'retained rows and original records cannot retain the weak view');
                }
            }
        }
    }
};

subtest 'unowned changes during rendering cannot borrow later annotation writes' => sub {
    for my $mode (qw(metadata fallback allocator registry source throwing)) {
        my ($module) = fixture(0, 0, $cases[0]);
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($owner, $name, $row, $calls, $exits);
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_with_concatenation_render = sub {
                my ($width, $n, $info, $ast, $callback) = @_;
                ($owner, $name, $row) = ($width, $n, $info);
                ok($width->concatenation_inference_event($n, $info), "$mode begins with held original authority");
                $calls++;
                return $render->($width, $n, $info, $ast, sub {
                    my $expression = $callback->();
                    $info->{unknown_annotation} = 1 if $mode eq 'metadata';
                    $info->{dependency_fallback_source} = 'unknown_fallback' if $mode eq 'fallback';
                    $backend->{ast_factorizer}{intermediate_signals}{$n}{unknown_annotation} = 1 if $mode eq 'allocator';
                    $backend->{intermediate_signals}{$n}{unknown_annotation} = 1 if $mode eq 'registry';
                    $module->{signals}{A}{signed} = 1 if $mode eq 'source';
                    die "annotation closure failure\n" if $mode eq 'throwing';
                    return $expression;
                });
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata = sub {
                my $ok = eval {$normalize->(@_); 1};
                my $error = $@;
                $exits++;
                is($ok ? 1 : 0, $mode eq 'throwing' ? 0 : 1, 'normalization result preserves');
                if ($mode eq 'throwing') {
                    is($error, "annotation closure failure\n", 'exact original callback error rethrows');
                    is_deeply($owner->{_concatenation_inference_events}, {}, 'wrapper abort clears every partial event');
                }
                is($owner->concatenation_inference_event($name, $row), undef, 'later annotations cannot refresh changed original proof');
                ok(!exists($owner->{_concatenation_inference_events}{$name}), 'spent holder stays absent');
                is($owner->intermediate_width_allocation($name, $row), undef, 'no completed policy leaks');
            };
            eval {$backend->generate_systemverilog($module)};
        }
        is($calls, 1, "$mode actual typed callback exercised once");
        is($exits, 1, "$mode actual normalization exit observed once");
        delete $module->{signals}{A}{signed};
        ok(eval {$backend->generate_systemverilog($module); 1}, 'same backend clean generation recovers') or diag $@;
    }
};

done_testing();
