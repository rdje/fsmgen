use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
unless ($class->can('concatenation_inference_event')) {
    fail('intrinsic concatenation event accessor exists');
    done_testing();
    exit;
}
require FSM::ConcatenationInferenceSupport;
my $api = 'FSM::ConcatenationInferenceSupport';
my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($mutable, $expression) = @_;
    $expression //= '(concat A B)';
    my $params = $mutable ? '(+params (W 8) (X 3))' : '';
    my ($a, $b) = $mutable ? ('(param W)', '(param X)') : (8, 3);
    my $source = "(?fsm:events $params (+size (A $a) (B $b) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}
my $resolve = $class->can('resolve_intermediate_signal_width');
my $infer = $class->can('infer_width_from_intermediate_ast');
my $metadata = \&FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info;
my $recover = \&FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_runtime_ast;
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
our ($ACTIVE, $INFER);

subtest 'actual first intrinsic branch and held repeat preserve independent ordered source contracts' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            for my $case (['(concat A B)', 11, ['A','B']], ['(concat B A A)', 19, ['B','A','A']],
                ["(concat A (concat B 4'b0101))", 15, ['A','B']]) {
                my ($module, $raw) = fixture($mutable, $case->[0]);
                my $caller = $json->encode($raw);
                my $backend = FSM::HDL::FlattenedDT->new;
                my ($seen, $owner, $row, $name, $holder, $weak_view);
                {
                    no warnings 'redefine';
                    local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
                        my ($width, $n, $info, $rows) = @_;
                        return $resolve->(@_) unless ref($info->{ast}) eq 'FSM::CoreAST::Concatenation';
                        return $resolve->(@_) if $seen;
                        ($owner, $row, $name) = ($width, $info, $n);
                        $weak_view = $rows; weaken($weak_view);
                        my $selected = $resolve->(@_);
                        my $event = $width->concatenation_inference_event($n, $info);
                        ok($event, 'actual intrinsic branch installs event');
                        is($event->{kind}, 'concatenation_sum_inference', 'sum has its own event family');
                        is($event->{selected_width}, $case->[1], 'independent shape expectation agrees');
                        is_deeply($event->{source_contract}{source_names}, $case->[2], 'ordered repeated sources preserve');
                        is_deeply([map {defined($_->{width_plan}) ? 1 : 0} @{$event->{source_contract}{operands}}],
                            [map {$mutable ? 1 : 0} @{$case->[2]}], 'independent mutable/fixed source plans retain');
                        is($width->factorized_width_inference_event($n,$info), undef, 'no binary maximum authority');
                        is($width->factorized_graph_inference_event($n,$info), undef, 'no arithmetic graph authority');
                        is($width->intermediate_width_allocation($n,$info), undef, 'no completed collection authority');
                        my $first = copy($width->{_concatenation_inference_events}{$n});
                        $selected = $resolve->(@_);
                        is_deeply($width->concatenation_inference_event($n,$info), $event, 'held cache read carries only the same event');
                        is($info->{width_source}, 'cached_width', 'ordinary cache label preserves');
                        is($width->{_concatenation_inference_events}{$n}{frame}{state}{revision}, '2', 'exact owned repeat revision carries');
                        is($api->current(width_support=>$width,signal_name=>$n,signal_info=>$info,
                            signal_registry=>$rows,holder=>$first),undef,'earlier revision cannot revive');
                        $holder=copy($width->{_concatenation_inference_events}{$n});
                        is($width->concatenation_inference_event($n,{%$info}),undef,'equal copied row refuses');
                        for my $field (qw(expression width_source)) {
                            local $info->{$field} = 'foreign';
                            is($width->concatenation_inference_event($n,$info),undef,"changed $field refuses");
                        }
                        {
                            local $backend->{intermediate_signals}{$n} = {%{$backend->{intermediate_signals}{$n}}};
                            is($width->concatenation_inference_event($n,$info),undef,'equal initial registry replacement refuses');
                        }
                        my $bad=copy($holder);$bad->{record}{selected_width}++;
                        is($api->current(width_support=>$width,signal_name=>$n,signal_info=>$info,
                            signal_registry=>$rows,holder=>$bad),undef,'tampered detached record refuses');
                        is_deeply($width->concatenation_inference_event($n,$info),$event,'detached edits cannot affect installed event');
                        $seen++;
                        return $selected;
                    };
                    my $ok=eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module);1};
                    is($ok?1:0,$mutable?0:1,'fixed success and mutable sum refusal preserve') or diag $@;
                }
                is($seen,1,'one actual concatenation resolver observed');
                is($json->encode($raw),$caller,'complete caller source preserves');
                ok(!defined($weak_view),'plain event and retained row do not retain view');
                is($owner->concatenation_inference_event($name,$row),undef,'publication or expired view withholds');
                is($api->current(width_support=>$owner,signal_name=>$name,signal_info=>$row,
                    signal_registry=>{},holder=>$holder),undef,'external capsule cannot revive view');
            }
        }
    }
};

subtest 'native cache constraints and callback changes cannot mint or refresh' => sub {
    for my $mode (qw(native empty_native zero_native cache scalar_cache signed row_metadata
        recovery_source metadata_source inference_source inference_row inference_revision wrong_sum late_getter)) {
        my ($module) = fixture(0);
        my $backend=FSM::HDL::FlattenedDT->new;
        my ($seen,$mutated)= (0,0);
        my $lhs;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport::resolve_intermediate_signal_runtime_ast = sub {
                if ($mode eq 'recovery_source' && ref($_[2]{ast}) eq 'FSM::CoreAST::Concatenation') {
                    $lhs=$backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};$lhs->{_width}=2;$mutated++;
                }
                return $recover->(@_);
            };
            local *FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info = sub {
                if ($ACTIVE && $_[1] eq $ACTIVE->{name}) {
                    return {width=>11} if $mode eq 'native';
                    return {} if $mode eq 'empty_native';
                    return 0 if $mode eq 'zero_native';
                    if ($mode eq 'metadata_source') { $lhs->{_width}=2;$mutated++ }
                    if ($mode eq 'row_metadata') { $ACTIVE->{row}{expression}='changed';$mutated++ }
                }
                return $metadata->(@_);
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::infer_width_from_intermediate_ast = sub {
                local $INFER=$ACTIVE && refaddr($_[1])==refaddr($ACTIVE->{row}{ast});
                my $result=$infer->(@_);
                if ($INFER) {
                    if ($mode eq 'inference_source') {$lhs->{_width}=2;$mutated++}
                    if ($mode eq 'inference_row') {$ACTIVE->{row}{expression}='changed';$mutated++}
                    if ($mode eq 'inference_revision') {$_[0]{_width_inference_revisions}{$ACTIVE->{name}}++;$mutated++}
                    if ($mode eq 'wrong_sum') {$result=12;$mutated++}
                }
                return $result;
            };
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result=$prepare->(@_);
                if ($ACTIVE && $mode eq 'late_getter') {$lhs->{_width}=2;$mutated++}
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
                my ($width,$name,$row)=@_;
                return $resolve->(@_) unless ref($row->{ast}) eq 'FSM::CoreAST::Concatenation';
                return $resolve->(@_) if $seen;
                local $ACTIVE={name=>$name,row=>$row};
                $lhs=$backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};
                my %original=%$row;
                $row->{width}=11 if $mode eq 'cache';
                $row->{width}=1 if $mode eq 'scalar_cache';
                $row->{signed}=1 if $mode eq 'signed';
                my $selected=$resolve->(@_);
                is($width->concatenation_inference_event($name,$row),undef,"$mode cannot mint");
                ok(!exists($width->{_concatenation_inference_events}{$name}),"$mode installs no event");
                # Restore only after the negative observations. A spent first
                # branch cannot mint on an otherwise clean later read.
                $lhs->{_width}=1;
                %$row=(%original,width=>11,width_source=>'cached_width');
                my $repeat=$resolve->(@_);
                is($width->concatenation_inference_event($name,$row),undef,"$mode clean repeat cannot remint");
                $seen++;
                return $repeat;
            };
            my $ok=eval {$backend->generate_systemverilog($module);1};
            ok($ok,"$mode permits clean ordinary continuation") or diag $@;
        }
        is($seen,1,"$mode actual resolver exercised");
        ok($mutated,"$mode actual mutation exercised") if $mode =~ /source|row|revision|sum|getter/;
    }
};

subtest 'unknown literal numeric fallback supplies no intrinsic authority' => sub {
    my ($module)=fixture(0,"(concat A 4'b0101)");
    my $backend=FSM::HDL::FlattenedDT->new;
    my $seen;
    my $birth=\&FSM::ConcatenationWidthBirthSupport::prepare_birth;
    {
        no warnings 'redefine';
        local *FSM::ConcatenationWidthBirthSupport::prepare_birth = sub {
            my ($class,%args)=@_;
            # The actual built-in producer captures this unknown Core width;
            # no stale already-captured birth is edited afterward.
            $args{factorizer}{intermediate_signals}{$args{signal_name}}{ast}{operands}[1]{width}=undef;
            return $birth->(@_);
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
            my ($owner,$name,$row)=@_;
            my $result=$resolve->(@_);
            if (ref($row->{ast}) eq 'FSM::CoreAST::Concatenation') {
                is($owner->concatenation_inference_event($name,$row),undef,'unknown literal width cannot mint');
                unless ($seen++) {
                    my $sources=$owner->concatenation_generation_sources($name,$row);
                    ok($sources,'unknown literal still has its original current source observation');
                    is($sources->{sources}{record}{expression_tree}[2][1]{width},undef,'literal width is independently unknown');
                }
            }
            return $result;
        };
        ok(eval {$backend->generate_systemverilog($module);1},'ordinary fallback generation preserves') or diag $@;
    }
    ok($seen,'unknown literal actual resolver exercised');
};

subtest 'abort and same backend success failure recovery clear old authority' => sub {
    my $backend=FSM::HDL::FlattenedDT->new;
    my ($old,$seen);
    for my $mode (qw(fixed abort mutable fixed)) {
        my ($module)=fixture($mode eq 'mutable');
        my $generation_seen;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width = sub {
                my ($owner,$name,$row,$rows)=@_;
                my $result=$resolve->(@_);
                if (ref($row->{ast}) eq 'FSM::CoreAST::Concatenation' && !$generation_seen++) {
                    ok($owner->concatenation_inference_event($name,$row),"$mode fresh intrinsic event");
                    is($api->current(width_support=>$owner,signal_name=>$name,signal_info=>$row,
                        signal_registry=>$rows,holder=>$old),undef,'earlier generation cannot bind') if $old;
                    $old=copy($owner->{_concatenation_inference_events}{$name});
                    if ($mode eq 'abort') {
                        $owner->_abort_factorized_width_inference;
                        is_deeply($owner->{_concatenation_inference_events},{},'abort clears installed events');
                        is($owner->concatenation_inference_event($name,$row),undef,'abort cannot expose old event');
                    }
                    $seen++;
                }
                return $result;
            };
            my $ok=eval {$backend->generate_systemverilog($module);1};
            is($ok?1:0,$mode eq 'mutable'?0:1,"$mode backend result preserves") or diag $@;
        }
    }
    is($seen,4,'all reuse boundaries exercised');
};

done_testing();
