use strict;
use warnings;
no warnings 'once';
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr weaken);
use Digest::SHA qw(sha256_hex);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $width = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $builder = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediatePreparedBlockSupport';
my $renderer = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateRenderingSupport';
my $complete = $width->can('_complete_factorized_width_inference');
my $build = $builder->can('build_prepared_consolidated_intermediate_block');
my $render = $renderer->can('render_prepared_consolidated_intermediate_block');
my $prepare_sum = FSM::ConcatenationSourceWidthSupport->can('prepare_sum');
my $available = $width->can('factorized_concatenation_sum');
my $json = JSON::PP->new->canonical;
my $path = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm';
open my $source, '<', $path or die "$path: $!";
{local $/; diag('loaded ' . $path . ' sha256=' . sha256_hex(<$source>))}
close $source;
ok($available, 'separate original completed concatenation sum accessor exists');
sub copy { $json->decode($json->encode($_[0])) }

# Interpret actual emitted arithmetic independently. Golden widths below use
# the fixed source's two A slots, one B slot and four literal bits.
sub expression {
    my ($tokens, $values) = @_;
    my $token = shift @$tokens;
    die 'missing arithmetic token' unless defined $token;
    return 0 + $token if $token =~ /^\d+$/;
    return $values->{$token} if exists $values->{$token};
    die 'unexpected arithmetic token' unless $token eq '(';
    my $left = expression($tokens, $values);
    my $op = shift @$tokens;
    my $right = expression($tokens, $values);
    die 'missing arithmetic close' unless shift(@$tokens) eq ')';
    return $left + $right if $op eq '+';
    return $left - $right if $op eq '-';
    die 'unexpected arithmetic operator';
}
sub range_width {
    my ($text, %values) = @_;
    die 'missing packed range' unless $text =~ /^\[(.*):0\] $/;
    my $body = $1;
    my @tokens = $body =~ /(\d+|[A-Z]\w*|[()+\-])/g;
    (my $compact = $body) =~ s/\s//g;
    die 'unrecognized range syntax' unless join('', @tokens) eq $compact;
    my $width = expression(\@tokens, \%values) + 1;
    die 'unconsumed range tokens' if @tokens;
    return $width;
}

sub fixture {
    my (%options) = @_;
    my $backend = $options{backend} // FSM::HDL::FlattenedDT->new;
    my $params = $options{mutable} ? '(+params (W 1) (X 3))' : '';
    my ($a, $b) = $options{mutable} ? ('(param W)', '(param X)') : (1, 3);
    my $action = $options{rhs}
        ? '(= (DATA (concat A B A))) (= (OTHER (concat B A)))'
        : '(<(concat A (concat B 0b1010) A) (= (DATA 1))) (<(concat B A) (= (OTHER 1)))';
    my $text = "(?fsm:concat_completed $params (+size (A $a) (B $b) (DATA 5) (OTHER 4))"
        . " (idle $action (-> idle)))";
    my $raw = scalar Lispish::multi(\$text);
    my $caller = $json->encode($raw);
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm($raw);
    my (%observed, $owner, $rows, $block, $weak_view, $error, $hdl);
    my $snapshot = sub {
        my %sums;
        for my $name (sort keys %$rows) {
            next unless ref($rows->{$name}{ast}) eq 'FSM::CoreAST::Concatenation';
            $sums{$name} = $available ? scalar($owner->factorized_concatenation_sum($name, $rows->{$name})) : undef;
        }
        return \%sums;
    };
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${width}::_complete_factorized_width_inference"} = sub {
            ($owner, $rows) = @_;
            $weak_view = $rows; weaken($weak_view);
            $observed{before} = $snapshot->();
            $complete->(@_);
            $observed{after} = $snapshot->();
            die "completed sum collection failure\n" if $options{fail_collection};
        };
        local *{"${builder}::build_prepared_consolidated_intermediate_block"} = sub {
            my $result = $build->(@_);
            $block = $result if $options{retain};
            $observed{prepared} = $snapshot->();
            $options{prepared}->($owner, $rows, \%observed) if $options{prepared};
            return $result;
        };
        local *{"${renderer}::render_prepared_consolidated_intermediate_block"} = sub {
            die "completed sum rendering failure\n" if $options{fail_render};
            return $render->(@_);
        };
        eval {
            $hdl = ($options{language} // '') eq 'verilog'
                ? $backend->generate_verilog($module) : $backend->generate_systemverilog($module);
            1;
        } or $error = $@;
    }
    is($json->encode($raw), $caller, 'complete caller input preserves');
    my $result = {backend => $backend, module => $module, owner => $owner,
        observed => \%observed, block => $block, weak_view => $weak_view, error => $error, hdl => $hdl};
    weaken($result->{weak_view}) if $result->{weak_view};
    return $result;
}

subtest 'actual completed and prepared events join independent ordered source sums' => sub {
    plan skip_all => 'completed sum accessor absent' unless $available;
    for my $mutable (0, 1) {
        for my $rhs (0, 1) {
            for my $language (qw(systemverilog verilog)) {
                my $p = fixture(mutable => $mutable, rhs => $rhs, language => $language, retain => 1);
                my $o = $p->{observed};
                is(scalar(keys %{$o->{before}}), $rhs ? 0 : 2, 'actual independent candidate membership');
                is_deeply([values %{$o->{before}}], [(undef) x keys(%{$o->{before}})],
                    'intrinsic events cannot borrow future completion');
                is_deeply($o->{prepared}, $o->{after}, 'prepared boundary preserves current original sum join');
                for my $name (sort keys %{$o->{after}}) {
                    my $joined = $o->{after}{$name};
                    ok($joined, 'actual completed original event has independent sum');
                    next unless $joined;
                    is_deeply([sort keys %$joined], [qw(allocation sum)], 'detached closed result');
                    is($joined->{allocation}{kind}, 'concatenation_sum_inference', 'original inference identity');
                    my $sum = $joined->{sum};
                    is($sum->{kind}, 'concatenation_source_sum', 'separate canonical source sum identity');
                    my $nested = @{$sum->{terms}} == 4;
                    is($sum->{width}, $nested ? '9' : '4', 'independent literal and repeated-slot numeric oracle');
                    like($json->encode($sum->{width}), qr/^"/, 'sum width retains decimal-string JSON kind');
                    is($joined->{allocation}{selected_width}, $nested ? 9 : 4, 'independent intrinsic numeric agreement');
                    is_deeply([map {$_->{name}} grep {$_->{kind} eq 'signal'} @{$sum->{terms}}],
                        $nested ? [qw(A B A)] : [qw(B A)], 'original ordered source slots preserve');
                    is($sum->{is_vector}, 1, 'concat result retains packed rank');
                    is($sum->{terms}[$nested ? 0 : 1]{is_vector}, $mutable ? 1 : 0,
                        'width-one operand preserves its independent rank');
                    if ($nested) {
                        is_deeply($sum->{terms}[2]{literal}, {value=>'1010', width=>4, radix=>'binary'}, 'original literal value width radix preserve');
                    }
                    if ($mutable) {
                        like($sum->{range_text}, qr/W/, 'original W dependency retained');
                        like($sum->{range_text}, qr/X/, 'independent X dependency retained');
                        is(scalar(() = $sum->{range_text} =~ /\bW\b/g), $nested ? 2 : 1, 'repeated source contributes repeated W slot');
                        for my $override ([1,1], [2,7], [16,1], [4,256]) {
                            my ($w, $x) = @$override;
                            is(range_width($sum->{range_text}, W=>$w, X=>$x), $nested ? 2*$w+$x+4 : $x+$w,
                                'completed range follows independent source-slot override oracle');
                        }
                    } else {
                        is($sum->{range_text}, undef, 'fixed sum gains no symbolic range');
                    }
                }
                if ($mutable && !$rhs) {
                    like($p->{error}, qr/requires proved symbolic sum range/, 'mutable target refusal remains separately owned');
                    ok(!exists($p->{owner}{_width_inference_complete}), 'later failure clears completion');
                } else {
                    is($p->{error}, undef, 'fixed guards and inline RHS preserve native generation');
                }
                delete $p->{block};
                ok(!defined($p->{weak_view}), 'detached joins do not own weak row view');
            }
        }
    }
};

subtest 'original row source holders and completed epoch survive every late read' => sub {
    plan skip_all => 'completed sum accessor absent' unless $available;
    for my $mode (qw(row registered source nonoperand event source_holder event_map source_map complete epoch view sum_width sum_contract exception)) {
        my $p = fixture(retain => 1, prepared => sub {
            my ($owner, $rows) = @_;
            my ($name) = sort grep {ref($rows->{$_}{ast}) eq 'FSM::CoreAST::Concatenation'} keys %$rows;
            my $row = $rows->{$name};
            ok($owner->factorized_concatenation_sum($name, $row), "$mode starts with genuine current completed sum");
            my $called = 0;
            no warnings 'redefine';
            local *FSM::ConcatenationSourceWidthSupport::prepare_sum = sub {
                my $sum = $prepare_sum->(@_);
                $called++;
                $row->{late_unowned_annotation} = 1 if $mode eq 'row';
                $owner->{flattened_dt}{intermediate_signals}{$name}{late_unowned_annotation} = 1 if $mode eq 'registered';
                $owner->{flattened_dt}{fsm_module}{signals}{A}{_width}++ if $mode eq 'source';
                # DATA is an assignment-owned nonoperand, carried by the raw
                # assignment analysis rather than necessarily module.signals.
                if ($mode eq 'nonoperand') {
                    my $lhs = $owner->{flattened_dt}{assignment_analysis}{DATA}{lhs_ast};
                    die 'actual DATA Core LHS absent' unless ref($lhs) eq 'FSM::CoreAST::SignalRef';
                    $lhs->{signal}{_width}++;
                }
                $owner->{_concatenation_inference_events}{$name}{record}{selected_width}++ if $mode eq 'event';
                $owner->{_concatenation_source_frames}{$name} = copy($owner->{_concatenation_source_frames}{$name}) if $mode eq 'source_holder';
                $owner->{_concatenation_inference_events} = {%{$owner->{_concatenation_inference_events}}} if $mode eq 'event_map';
                $owner->{_concatenation_source_frames} = {%{$owner->{_concatenation_source_frames}}} if $mode eq 'source_map';
                delete $owner->{_width_inference_complete} if $mode eq 'complete';
                $owner->{_width_inference_epoch}++ if $mode eq 'epoch';
                $owner->{_graph_inference_rows_revision}++ if $mode eq 'view';
                $sum->{record}{width} = '999' if $mode eq 'sum_width';
                $sum->{sources}{record}{operands}[0]{name} = 'FOREIGN' if $mode eq 'sum_contract';
                die "late sum getter failure\n" if $mode eq 'exception';
                return $sum;
            };
            is($owner->factorized_concatenation_sum($name, $row), undef,
                "$mode final complete barrier withholds changed join");
            is($called, 1, "$mode actual canonical sum callback reached once");
        });
        # Mutating nonoperand width can affect later native generation; this
        # test claims only the accessor's refusal, not a compiler repair.
    }
};

subtest 'missing foreign stale and reset authority cannot be minted and clean reuse recovers' => sub {
    plan skip_all => 'completed sum accessor absent' unless $available;
    for my $mode (qw(missing_event missing_source foreign_row detached failure_collection failure_render)) {
        my ($old_name, $old_row, $old_owner);
        my $p = fixture(retain => 1, fail_collection => $mode eq 'failure_collection', fail_render => $mode eq 'failure_render', prepared => sub {
            my ($owner, $rows, $o) = @_;
            my ($name) = sort keys %{$o->{after}};
            my $row = $rows->{$name};
            ($old_name, $old_row, $old_owner) = ($name, $row, $owner);
            delete $owner->{_concatenation_inference_events}{$name} if $mode eq 'missing_event';
            delete $owner->{_concatenation_source_frames}{$name} if $mode eq 'missing_source';
            if ($mode eq 'detached') {
                my $copy = $owner->factorized_concatenation_sum($name, $row);
                $copy->{sum}{terms}[0]{name} = 'FOREIGN';
                $copy->{allocation}{source_contract}{expression_tree}[0] = 'FOREIGN';
                is_deeply(scalar($owner->factorized_concatenation_sum($name, $row)), $o->{after}{$name}, 'returned nested records detach');
            } elsif ($mode eq 'foreign_row') {
                is($owner->factorized_concatenation_sum($name, {%$row}), undef, 'equal foreign row refuses current authority');
            } elsif ($mode =~ /^missing/) {
                is($owner->factorized_concatenation_sum($name, $row), undef, "$mode stays absent without minting");
            }
        });
        like($p->{error}, qr/^completed sum (?:collection|rendering) failure\n/, 'original failure propagates') if $mode =~ /^failure/;
        my $q = fixture(backend => $p->{backend}, retain => 1);
        is($q->{error}, undef, 'same backend clean reuse recovers');
        ok(!grep(!defined($_), values %{$q->{observed}{after}}), 'fresh completed generation has its own sums');
        is($old_owner->factorized_concatenation_sum($old_name, $old_row), undef, 'old row cannot borrow later completed epoch') if $old_owner;
        $q->{owner}->_abort_factorized_width_inference;
        my ($name) = sort keys %{$q->{observed}{after}};
        is($q->{owner}->factorized_concatenation_sum($name, $q->{block}{all_intermediate_signals}{$name}), undef, 'reset revokes retained current sum');
    }
};

done_testing();
