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
my $available = $width->can('_concatenation_resolver_projection');
my $json = JSON::PP->new->canonical;
my $path = 'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm';
open my $source, '<', $path or die "$path: $!";
{local $/; diag('loaded ' . $path . ' sha256=' . sha256_hex(<$source>))}
close $source;
ok($available, 'bounded held-event filtered projection protocol exists');
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
            $sums{$name} = scalar($owner->factorized_concatenation_sum($name, $rows->{$name}));
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

subtest 'actual declaration rendering retains completed sums through filtered canonical aliases' => sub {
    for my $language (qw(systemverilog verilog)) {
        my $p = fixture(retain => 1, language => $language);
        is($p->{error}, undef, 'fixed original native generation succeeds');
        my $rows = $p->{block}{all_intermediate_signals};
        my $filtered = $p->{block}{filtered_signals};
        isnt(refaddr($rows), refaddr($filtered), 'actual declaration map is a distinct projection');
        for my $name (keys %{$p->{observed}{after}}) {
            is(refaddr($rows->{$name}), refaddr($filtered->{$name}), 'actual filtered member aliases original canonical row');
            is_deeply(scalar($p->{owner}->factorized_concatenation_sum($name, $rows->{$name})),
                $p->{observed}{after}{$name}, 'original completed sum survives actual filtered declaration resolution');
        }
        undef $rows;
        undef $filtered;
        delete $p->{block};
        ok(!defined($p->{weak_view}), 'projection carry does not retain canonical weak view');
    }
};

subtest 'only current held events cross stable actual-row subsets' => sub {
    plan skip_all => 'projection protocol absent' unless $available;
    for my $mode (qw(subset full_alias copied_row extra missing_selected absent_event absent_source native_empty native_width)) {
        fixture(retain => 1, prepared => sub {
            my ($owner, $rows, $o) = @_;
            my @names = sort keys %{$o->{after}};
            my $name = $names[0];
            my $row = $rows->{$name};
            my $projection = $mode eq 'full_alias' ? {%$rows} : {$name => $row};
            $projection->{$name} = {%$row} if $mode eq 'copied_row';
            $projection->{FOREIGN} = {} if $mode eq 'extra';
            delete $projection->{$name} if $mode eq 'missing_selected';
            delete $owner->{_concatenation_inference_events}{$name} if $mode eq 'absent_event';
            delete $owner->{_concatenation_source_frames}{$name} if $mode eq 'absent_source';
            my $native = \&FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info;
            no warnings 'redefine';
            local *FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info = sub {
                return {} if $_[1] eq $name && $mode eq 'native_empty';
                return {width => $row->{width}} if $_[1] eq $name && $mode eq 'native_width';
                return $native->(@_);
            };
            my $value = $owner->resolve_intermediate_signal_width($name, $row, $projection);
            is($value, $o->{after}{$name}{allocation}{selected_width}, "$mode numeric width preserves");
            my $current = $owner->factorized_concatenation_sum($name, $row);
            if ($mode eq 'subset' || $mode eq 'full_alias') {
                is_deeply($current, $o->{after}{$name}, "$mode aliases retain original source and allocation");
                is($owner->_concatenation_resolver_projection($name, $row, []), undef, 'non-map projection refuses without callbacks');
                my $oversized = {$name => $row, map {('extra' . $_) => {}} 1 .. FSM::CoreExpressionWidthSupport::MAX_NODES()};
                is($owner->_concatenation_resolver_projection($name, $row, $oversized), undef, 'complete projection member bound refuses excess');
            } else {
                is($current, undef, "$mode cannot restore or mint proof");
                ok(!exists($owner->{_concatenation_inference_events}{$name}), "$mode event stays absent");
            }
        });
    }
};

subtest 'entry projection and withheld proof survive every early and late callback' => sub {
    plan skip_all => 'projection protocol absent' unless $available;
    for my $mode (qw(early_remove late_remove late_add late_copy source row registered proof_map)) {
        my $p = fixture(retain => 1, prepared => sub {
            my ($owner, $rows, $o) = @_;
            my @names = sort keys %{$o->{after}};
            my ($name, $other) = @names;
            my $row = $rows->{$name};
            my $projection = {$name => $row, $other => $rows->{$other}};
            my ($changed, $native_calls, $withheld) = (0,0,0);
            my $native = \&FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info;
            my $prepare = \&FSM::DirectDeclaredWidthSupport::prepare_module;
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_module = sub {
                my $result = $prepare->(@_);
                if ($mode eq 'early_remove' && !$changed) {
                    delete $projection->{$other};
                    $changed++;
                }
                return $result;
            };
            local *FSM::Synthesis::EnableGraph::AssignmentSupport::get_signal_info = sub {
                my $result = $native->(@_);
                if ($_[1] eq $name) {
                    $native_calls++;
                    $withheld++ unless exists($owner->{_concatenation_inference_events}{$name});
                    delete $projection->{$other} if $mode eq 'late_remove';
                    $projection->{FOREIGN} = {} if $mode eq 'late_add';
                    $projection->{$other} = {%{$rows->{$other}}} if $mode eq 'late_copy';
                    $owner->{flattened_dt}{fsm_module}{signals}{A}{_width}++ if $mode eq 'source';
                    $row->{late_foreign_annotation} = 1 if $mode eq 'row';
                    $owner->{flattened_dt}{intermediate_signals}{$name}{late_foreign_annotation} = 1 if $mode eq 'registered';
                    $owner->{_concatenation_inference_events} = {} if $mode eq 'proof_map';
                }
                return $result;
            };
            my $value = $owner->resolve_intermediate_signal_width($name, $row, $projection);
            is($value, $o->{after}{$name}{allocation}{selected_width}, "$mode numeric path retains its original cached result");
            is($native_calls, 1, "$mode actual native getter reached once");
            is($withheld, 1, "$mode event withheld throughout native callback");
            is($changed, 1, 'early canonical getter actually removes a different supplied member') if $mode eq 'early_remove';
            is($owner->factorized_concatenation_sum($name, $row), undef, "$mode changed projection/source cannot refresh original proof");
            ok(!exists($owner->{_concatenation_inference_events}{$name}), "$mode original event remains absent");
        });
        my $q = fixture(backend => $p->{backend}, retain => 1);
        is($q->{error}, undef, "$mode same-backend clean generation recovers");
        for my $name (keys %{$q->{observed}{after}}) {
            ok($q->{owner}->factorized_concatenation_sum($name, $q->{block}{all_intermediate_signals}{$name}),
                "$mode fresh declaration projection has its own current join");
        }
    }
};

done_testing();
