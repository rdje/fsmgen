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

my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
for my $path ('FSM/ConcatenationInferenceSupport.pm',
    'FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm') {
    is($INC{$path}, "perl/$path", 'actual native publication owner is loaded');
    open my $source, '<', $INC{$path} or die $!;
    binmode $source;
    local $/;
    note("loaded $INC{$path} sha256=" . sha256_hex(<$source>));
}
my $publication = $class->can('_with_factorized_width_publication');
my $resolve = $class->can('resolve_intermediate_signal_width');
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($mutable, $expression) = @_;
    my $params = $mutable ? '(+params (W 8) (X 3))' : '';
    my ($a, $b) = $mutable ? ('(param W)', '(param X)') : (8, 3);
    my $source = "(?fsm:publication $params (+size (A $a) (B $b) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}

subtest 'actual publication carries only the current independent sum event' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            for my $case (['(concat A B)', 11, ['A', 'B']],
                ['(concat B A A)', 19, ['B', 'A', 'A']],
                ["(concat A (concat B 4'b0101))", 15, ['A', 'B']]) {
                my ($module, $raw) = fixture($mutable, $case->[0]);
                my $caller = $json->encode($raw);
                my $backend = FSM::HDL::FlattenedDT->new;
                my ($seen, $weak_view, $retained, $owner, $name, $row);
                {
                    no warnings 'redefine';
                    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_with_factorized_width_publication = sub {
                        my ($width, $n, $info, $publish) = @_;
                        return $publication->(@_) unless ref($info->{ast}) eq 'FSM::CoreAST::Concatenation';
                        ($owner, $name, $row) = ($width, $n, $info);
                        $weak_view = $width->_current_graph_inference_rows; weaken($weak_view);
                        my $before = $width->concatenation_inference_event($n, $info);
                        ok($before, 'intrinsic event exists before actual publication');
                        $publication->($width, $n, $info, sub {
                            is($width->concatenation_inference_event($n, $info), undef,
                                'authority is withheld while owned publication executes');
                            $publish->();
                        });
                        my $event = $width->concatenation_inference_event($n, $info);
                        is_deeply($event, $before, 'owned width/source publication retains the same event');
                        is($event->{selected_width}, $case->[1], 'independent numeric sum preserves');
                        is_deeply($event->{source_contract}{source_names}, $case->[2], 'ordered repeated source contracts preserve');
                        is_deeply([map {defined($_->{width_plan}) ? 1 : 0} @{$event->{source_contract}{operands}}],
                            [map {$mutable ? 1 : 0} @{$case->[2]}], 'independent fixed/mutable plans preserve');
                        for my $registered ($backend->{intermediate_signals}{$n}, $backend->{ast_factorizer}{intermediate_signals}{$n}) {
                            is($registered->{width}, $case->[1], 'actual registry receives selected width');
                            is($registered->{width_source}, $info->{width_source}, 'actual registry receives source label');
                        }
                        $retained = copy($width->{_concatenation_inference_events}{$n});
                        if ($event) {
                            $event->{source_contract}{source_names}[0] = 'foreign';
                            is_deeply($width->concatenation_inference_event($n, $info), $before, 'returned data detaches');
                            is($resolve->($width, $n, $info, $weak_view), $case->[1], 'held repeat after publication preserves numeric selection');
                            is_deeply($width->concatenation_inference_event($n, $info), $before, 'held repeat retains published event');
                        }
                        is($width->intermediate_width_allocation($n, $info), undef, 'publication grants no completed policy');
                        $seen++;
                    };
                    my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module); 1};
                    is($ok ? 1 : 0, $mutable ? 0 : 1, 'fixed success and mutable generic refusal preserve') or diag $@;
                }
                is($seen, 1, 'one actual concatenation publication observed');
                is($json->encode($raw), $caller, 'complete caller source preserves');
                ok(!defined($weak_view), 'detached holder and retained row do not extend view lifetime');
                is($owner->concatenation_inference_event($name, $row), undef, 'later writes or expired view grant no authority');
            }
        }
    }
};

subtest 'unrelated publication writes cannot refresh authority or remint on a clean repeat' => sub {
    for my $mode (qw(row_metadata allocator_metadata registry_metadata nested_identity
        source allocator_width registry_source registry_map registry_identity allocator_identity revision foreign_row stale_before missing_event tampered_event throwing late_getter)) {
        my ($module) = fixture(0, '(concat A B)');
        my $backend = FSM::HDL::FlattenedDT->new;
        my ($seen, $late, $mutated) = (0, 0, 0);
        my $lhs;
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result = $prepare->(@_);
                if ($late && $mode eq 'late_getter') { $lhs->{_width} = 2; $mutated++ }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
                my ($width, $n, $info) = @_;
                if (ref($info->{ast}) eq 'FSM::CoreAST::Concatenation' && !$seen) {
                    # Unknown plain metadata is bound before intrinsic capture.
                    $info->{publication_metadata} //= {slots => ['original']};
                }
                return $resolve->(@_);
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_with_factorized_width_publication = sub {
                my ($width, $n, $info, $publish) = @_;
                return $publication->(@_) unless ref($info->{ast}) eq 'FSM::CoreAST::Concatenation';
                my $rows = $width->_current_graph_inference_rows;
                ok($width->concatenation_inference_event($n, $info), "$mode starts with actual intrinsic authority");
                $lhs = $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};
                my $allocator = $backend->{ast_factorizer}{intermediate_signals}{$n};
                my $registered = $backend->{intermediate_signals}{$n};
                my $registry = $backend->{intermediate_signals};
                my ($selected_width, $selected_source) = @{$info}{qw(width width_source)};
                my $nested = $info->{publication_metadata};
                my $expression = $info->{expression};
                $info->{expression} = 'stale' if $mode eq 'stale_before';
                delete $width->{_concatenation_inference_events}{$n} if $mode eq 'missing_event';
                $width->{_concatenation_inference_events}{$n}{record}{selected_width}++ if $mode eq 'tampered_event';
                my $actual = $mode eq 'foreign_row' ? {%$info} : $info;
                my $ok = eval {
                    $publication->($width, $n, $actual, sub {
                        $publish->();
                        $info->{expression} = 'changed' if $mode eq 'row_metadata';
                        $allocator->{expression} = 'changed' if $mode eq 'allocator_metadata';
                        $registered->{expression} = 'changed' if $mode eq 'registry_metadata';
                        $info->{publication_metadata} = copy($nested) if $mode eq 'nested_identity';
                        $lhs->{_width} = 2 if $mode eq 'source';
                        $allocator->{width}++ if $mode eq 'allocator_width';
                        $registered->{width_source} = 'independent_floor' if $mode eq 'registry_source';
                        $backend->{intermediate_signals} = {%$registry} if $mode eq 'registry_map';
                        $backend->{intermediate_signals}{$n} = {%$registered} if $mode eq 'registry_identity';
                        $backend->{ast_factorizer}{intermediate_signals}{$n} = {%$allocator} if $mode eq 'allocator_identity';
                        $width->{_width_inference_revisions}{$n}++ if $mode eq 'revision';
                        die "publication callback failed\n" if $mode eq 'throwing';
                        $late = 1 if $mode eq 'late_getter';
                    });
                    1;
                };
                my $error = $@;
                $late = 0;
                is($ok ? 1 : 0, $mode eq 'throwing' ? 0 : 1, "$mode callback result preserves");
                is($error, "publication callback failed\n", 'exact callback exception propagates') if $mode eq 'throwing';
                is($width->concatenation_inference_event($n, $info), undef, "$mode cannot refresh");
                ok(!exists($width->{_concatenation_inference_events}{$n}), "$mode installs no stale holder");
                ok($mutated, 'actual final source getter mutation exercised') if $mode eq 'late_getter';
                # Restore only after observing refusal. Clean later reads must
                # not mint again at a spent intrinsic branch.
                $lhs->{_width} = 1;
                $info->{expression} = $expression;
                $info->{publication_metadata} = $nested;
                $backend->{intermediate_signals} = $registry;
                $backend->{intermediate_signals}{$n} = $registered;
                for my $target ($info, $registered, $allocator) {
                    @{$target}{qw(width width_source)} = ($selected_width, $selected_source);
                }
                $backend->{ast_factorizer}{intermediate_signals}{$n} = $allocator;
                $resolve->($width, $n, $info, $rows);
                is($width->concatenation_inference_event($n, $info), undef, "$mode clean repeat cannot remint");
                $seen++;
            };
            ok(eval {$backend->generate_systemverilog($module); 1}, "$mode permits ordinary continuation") or diag $@;
        }
        is($seen, 1, "$mode actual publication exercised");
    }
};

done_testing();
