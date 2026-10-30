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

my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
unless ($width_class->can('concatenation_generation_sources')) {
    fail('original generation source freeze exists');
    done_testing();
    exit;
}
require FSM::ConcatenationGenerationSourceSupport;
my $api = 'FSM::ConcatenationGenerationSourceSupport';
my $json = JSON::PP->new->canonical;
sub clone { $json->decode($json->encode($_[0])) }
sub fixture {
    my ($mutable) = @_;
    my $params = $mutable ? '(+params (W 8))' : '';
    my $width = $mutable ? '(param W)' : '8';
    my $source = "(?fsm:freeze $params (+size (A $width) (B 3) (DATA 1) (OTHER 1))"
        . ' (idle (<(concat A B) (= (DATA 1))) (<(concat B A) (= (OTHER 1))) (-> idle)))';
    my $raw = scalar Lispish::multi(\$source);
    return (FSM::Adapter::FSMGenFull->new->parse_fsm($raw), $raw);
}
my $normalize = \&FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata;
my $bind = $width_class->can('_bind_graph_inference_rows');
my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
our ($IN_BIND, $INPUTS, $MUTATED);

subtest 'actual original frames precede callbacks and retain source-only scope' => sub {
    for my $mutable (0, 1) {
        for my $language (qw(systemverilog verilog)) {
            my ($module, $raw) = fixture($mutable);
            my $caller = $json->encode($raw);
            my $backend = FSM::HDL::FlattenedDT->new;
            my (@held, $weak_view, $observed, $width_owner);
            {
                no warnings 'redefine';
                local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata = sub {
                    my ($normalizer, $rows) = @_;
                    my $result = $normalize->(@_);
                    $width_owner = $normalizer->{flattened_dt}{backend_sv_intermediate_width_support};
                    my @names = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                    is(scalar(@names), 2, 'both actual concat candidates observed');
                    $weak_view = $rows; weaken($weak_view);
                    for my $name (@names) {
                        my $row = $rows->{$name};
                        my $frame = $width_owner->concatenation_generation_sources($name, $row);
                        ok($frame, 'original frame survives recovery, inference and numeric publication');
                        is($frame->{kind}, 'concatenation_generation_sources', 'source-only record');
                        is($frame->{binding}{epoch}, $width_owner->{_width_inference_epoch}, 'actual epoch bound');
                        is($frame->{binding}{row}, sprintf('%x',refaddr($row)), 'actual merged row bound');
                        is($frame->{binding}{row_view}, sprintf('%x',refaddr($rows)), 'actual original view bound');
                        is_deeply([sort @{$frame->{sources}{record}{source_names}}], ['A','B'], 'source membership retains');
                        is_deeply([sort map {$_->{width}} @{$frame->{sources}{record}{operands}}], [3,8], 'independent widths retain');
                        is($row->{width}, 11, 'numeric sum remains independently inferred');
                        is($width_owner->factorized_width_inference_event($name,$row), undef, 'source frame mints no max event');
                        is($width_owner->factorized_graph_inference_event($name,$row), undef, 'source frame mints no graph event');
                        is($width_owner->intermediate_width_allocation($name,$row), undef, 'source frame supplies no completed policy');
                        is($width_owner->concatenation_generation_sources($name,{%$row}),undef,'equal copied row refuses');
                        {
                            local $row->{runtime_ast}='malformed';
                            my @warnings;local $SIG{__WARN__}=sub {push @warnings,@_};
                            is($width_owner->concatenation_generation_sources($name,$row),undef,'malformed runtime identity refuses');
                            is_deeply(\@warnings,[],'malformed identity withholds without numeric coercion');
                        }
                        my $copy = clone($frame); $copy->{binding}{epoch}++;
                        is($api->current(width_support=>$width_owner,signal_name=>$name,signal_info=>$row,holder=>$copy),undef,'foreign epoch refuses');
                        $copy=clone($frame);$copy->{sources}{record}{operands}[0]{width}=99;
                        is($api->current(width_support=>$width_owner,signal_name=>$name,signal_info=>$row,holder=>$copy),undef,'tampered source holder refuses');
                        my $lhs = $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal};
                        {
                            local $lhs->{_width}=2;
                            is($width_owner->concatenation_generation_sources($name,$row),undef,'changed nonoperand source revokes original frame');
                            is($width_owner->concatenation_generation_sources($name,$row),undef,'lookup cannot recapture changed source');
                        }
                        is_deeply($width_owner->concatenation_generation_sources($name,$row),$frame,'unchanged source after scoped control retains original observation');
                        $copy->{binding}{row}='changed';
                        is_deeply($width_owner->concatenation_generation_sources($name,$row),$frame,'detached edits change no installed holder');
                        push @held, [$name,$row,$frame];
                    }
                    $observed++;
                    return $result;
                };
                my $ok = eval {$language eq 'verilog' ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module);1};
                if ($mutable) { ok(!$ok,'mutable target sum remains refused');like($@,qr/concatenation|symbolic/i,'context identifies unsupported sum') }
                else { ok($ok,'fixed generation remains successful') or diag $@ }
            }
            is($observed,1,'actual normalization observed once');
            is($json->encode($raw),$caller,'complete caller source preserves');
            ok(!defined($weak_view),'retained row and plain holder do not retain original view');
            for my $held (@held) {
                my ($name,$row,$frame)=@$held;
                is($width_owner->concatenation_generation_sources($name,$row),undef,'registry replacement or expired view withholds');
                is($api->current(width_support=>$width_owner,signal_name=>$name,signal_info=>$row,holder=>$frame),undef,'external holder cannot revive completed initial binding');
            }
        }
    }
};

subtest 'complete candidate inputs freeze before any canonical getter and cannot refresh' => sub {
    my $input = $api->can('prepare_input');
    for my $control (qw(positive callback cache signed rebind abort)) {
        my ($module) = fixture(0);
        my $backend = FSM::HDL::FlattenedDT->new;
        my $seen=0;
        {
            no warnings 'redefine';
            local *FSM::ConcatenationGenerationSourceSupport::prepare_input=sub {
                $INPUTS++ if $IN_BIND;
                return $input->(@_);
            };
            local *FSM::DirectDeclaredWidthSupport::prepare_module=sub {
                if ($IN_BIND) { is($INPUTS,2,'all original raw candidate scopes freeze before semantic reads') }
                my $result=$prepare->(@_);
                if ($IN_BIND && $control eq 'callback' && !$MUTATED++) {
                    $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal}{_width}=2;
                }
                return $result;
            };
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_bind_graph_inference_rows=sub {
                my ($owner,$rows)=@_;
                local $IN_BIND=1; local $INPUTS=0;local $MUTATED=0;
                my @names=sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                $rows->{$_}{width}=11 for $control eq 'cache'?@names:();
                $module->{signals}{A}{signed}=1 if $control eq 'signed';
                my $result=$bind->(@_);
                $module->{signals}{A}{signed}=0 if $control eq 'signed';
                my $expected=$control eq 'callback'||$control eq 'cache'||$control eq 'signed'?0:2;
                is(scalar(keys %{$owner->{_concatenation_source_frames}}),$expected,"$control installed source membership");
                if ($control eq 'callback') {
                    $backend->{assignment_analysis}{OTHER}{lhs_ast}{signal}{_width}=1;
                    $bind->(@_);
                    is(scalar(keys %{$owner->{_concatenation_source_frames}}),0,'same-epoch rebind cannot recapture after callback failure');
                } elsif ($control eq 'rebind'||$control eq 'abort') {
                    my $name=$names[0];my $frame=$owner->concatenation_generation_sources($name,$rows->{$name});
                    ok($frame,'original frame exists before invalidation');
                    $control eq 'abort' ? $owner->_abort_factorized_width_inference : $bind->(@_);
                    is($owner->concatenation_generation_sources($name,$rows->{$name}),undef,'abort or new view revision revokes original frame');
                    $bind->(@_);
                    is($owner->concatenation_generation_sources($name,$rows->{$name}),undef,'rebind never revives spent epoch');
                }
                $seen++;
                return $result;
            };
            my $ok=eval {$backend->generate_systemverilog($module);1};
            ok($ok,"$control leaves ordinary fixed generation available") or diag $@;
        }
        is($seen,1,"$control actual installed binding exercised");
    }
};

subtest 'same backend fixed failure fixed reuse never revives an earlier source frame' => sub {
    my $backend=FSM::HDL::FlattenedDT->new;
    my ($old,$seen);
    for my $mutable (0,1,0) {
        my ($module)=fixture($mutable);
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata=sub {
                my ($normalizer,$rows)=@_;
                my $result=$normalize->(@_);
                my $owner=$backend->{backend_sv_intermediate_width_support};
                my ($name)=sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
                my $frame=$owner->concatenation_generation_sources($name,$rows->{$name});
                ok($frame,'fresh actual generation has its original source frame');
                is($api->current(width_support=>$owner,signal_name=>$name,signal_info=>$rows->{$name},holder=>$old),undef,
                    'earlier detached holder cannot bind the new generation') if $old;
                $old=$frame;$seen++;
                return $result;
            };
            my $ok=eval {$backend->generate_systemverilog($module);1};
            is($ok?1:0,$mutable?0:1,'fixed success and mutable refusal preserve across reuse');
        }
    }
    is($seen,3,'success failure and clean recovery all reach actual normalization');
};

done_testing();
