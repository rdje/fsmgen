use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $json = JSON::PP->new->canonical;
my $has_api = $width_class->can('factorized_graph_inference_event');
sub source_state {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->declared_width_binding,
            $s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
sub fixture {
    my ($expression, $tree, $width, %options) = @_;
    my $source = "(?fsm:graph_events (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (D (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $before = source_state($module);
    my $ctx = $options{ctx} // FSM::HDL::FlattenedDT->new;
    my $resolve = $width_class->can('resolve_intermediate_signal_width');
    my $infer = $width_class->can('infer_width_from_intermediate_ast');
    my $collect_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
    my $collect = $collect_class->can('collect_consolidated_intermediate_signals');
    my $assignment_class = ref($ctx->{enable_graph_assignment_support});
    my $native = $assignment_class->can('get_signal_info');
    my (%observed, $all, $hdl, @stack);
    my $is_root = sub {
        my ($name) = @_;
        my $birth = $ctx->{ast_factorizer}->intermediate_width_graph_birth($name);
        return $birth && $json->encode($birth->{expression_tree}) eq $json->encode($tree);
    };
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${assignment_class}::get_signal_info"} = sub {
            return {width => $options{native_width}} if defined($options{native_width})
                && defined($observed{native_name}) && $_[1] eq $observed{native_name};
            return $native->(@_);
        };
        local *{"${width_class}::resolve_intermediate_signal_width"} = sub {
            my ($owner, $name, $info, $rows) = @_;
            my $root = $is_root->($name);
            $observed{native_name} = $name if $root && defined($options{native_width});
            $options{before_resolve}->($owner, $name, $info, $rows, \%observed)
                if $root && !$observed{entered}++ && $options{before_resolve};
            push @stack, $name;
            my $width_result = $resolve->(@_);
            pop @stack;
            if ($root) {
                $observed{name} = $name;
                $observed{resolved_source} = $info->{width_source};
                my $record = eval {$owner->factorized_graph_inference_event($name, $info)};
                $observed{lookup_error} = $@;
                if ($record) {
                    $observed{event} //= $record;
                    $observed{epoch} //= $json->decode($owner->{_graph_inference_events}{$name}{state})->{epoch};
                    push @{$observed{events}}, $record;
                    is($owner->factorized_width_inference_event($name, $info), undef,
                        'graph event does not occupy whole-reference event API');
                    $options{on_event}->($owner, $name, $info, $rows, \%observed)
                        if !$observed{callback}++ && $options{on_event};
                }
            } elsif (@stack && $has_api) {
                my $record = $owner->factorized_graph_inference_event($name, $info);
                $observed{recursive_graph_child} = 1 if $record;
            }
            return $width_result;
        };
        local *{"${width_class}::infer_width_from_intermediate_ast"} = sub {
            my ($owner, $ast, $rows) = @_;
            my $root = @stack && $is_root->($stack[-1])
                && ref($rows->{$stack[-1]}) eq 'HASH'
                && refaddr($rows->{$stack[-1]}{runtime_ast}) == refaddr($ast);
            my $result = $infer->(@_);
            $options{after_infer}->($owner, $stack[-1], $rows->{$stack[-1]}, $rows, \%observed)
                if $root && !$observed{inferred}++ && $options{after_infer};
            return $result;
        };
        local *{"${collect_class}::collect_consolidated_intermediate_signals"} = sub {
            $all = $collect->(@_);
            return $all;
        };
        $hdl = $ctx->generate_systemverilog($module);
    }
    return {observed => \%observed, ctx => $ctx, module => $module, all => $all, hdl => $hdl,
        source_before => $before, source_after => source_state($module)};
}
my $nested = ['+', ['signal','A'], ['*', ['signal','B'], ['signal','C']]];

subtest 'actual first intrinsic graph events are separate from completed policy' => sub {
    my $first = fixture('(+ A (* B C))', $nested, 1);
    ok($first->{observed}{event}, 'actual graph inference emits a held intrinsic event')
        or diag($first->{observed}{lookup_error} // 'no event');
    return unless $has_api;
    for my $op ('+', '-', '*', '/', '%') {
        for my $width (1, 8) {
            my $tree = [$op, ['signal','A'], [$op, ['signal','B'], ['signal','C']]];
            my $p = fixture("($op A ($op B C))", $tree, $width);
            my $record = $p->{observed}{event};
            is($record->{kind}, 'arithmetic_graph_operand_max', 'held graph event has its own kind');
            is($record->{operator}, $op, 'actual canonical arithmetic operator preserves');
            is_deeply($record->{expression_tree}, $tree, 'ordered original expression ownership preserves');
            is($record->{selected_width}, $width, 'selected width is the exact proved operand maximum');
            is_deeply([sort keys %$record], [sort qw(kind operator source_names expression_tree selected_width)],
                'graph record has a closed diagnostic schema');
            is($p->{source_after}, $p->{source_before}, 'source maps and declared width contracts conserve');
            my $name = $p->{observed}{name};
            is($p->{ctx}{backend_sv_intermediate_width_support}->intermediate_width_allocation($name, $p->{all}{$name}),
                undef, 'intrinsic graph event does not complete selected policy');
            is($p->{ctx}{backend_sv_intermediate_width_support}->factorized_graph_inference_event($name, $p->{all}{$name}),
                undef, 'unqualified later registry publications do not refresh graph event');
            my $range = $width == 1 ? '' : '[7:0] ';
            like($p->{hdl}, qr/^  wire \Q$range$name\E;$/m, 'outer graph HDL remains selected numeric range');
        }
    }
};

subtest 'nary duplicate two-child and deeper graph dependencies retain exact trees' => sub {
    plan skip_all => 'graph event API absent' unless $has_api;
    my @cases = (
        ['(+ A B C)', ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']]],
        ['(+ A A A)', ['+', ['+', ['signal','A'], ['signal','A']], ['signal','A']]],
        ['(+ (* A B) (* C D))', ['+', ['*', ['signal','A'], ['signal','B']], ['*', ['signal','C'], ['signal','D']]]],
        ['(+ A (* B (+ C D)))', ['+', ['signal','A'], ['*', ['signal','B'], ['+', ['signal','C'], ['signal','D']]]]],
    );
    for my $case (@cases) {
        for my $width (1, 8) {
            my $p = fixture(@$case, $width);
            is_deeply($p->{observed}{event}{expression_tree}, $case->[1], 'actual nary/transitive graph event retains ordered ownership');
            is($p->{observed}{event}{selected_width}, $width, 'transitive dependency max preserves');
        }
    }
};

subtest 'owned resolver cache reads preserve held events and detached getters' => sub {
    plan skip_all => 'graph event API absent' unless $has_api;
    for my $width (1, 8) {
        fixture('(+ A (* B C))', $nested, $width, on_event => sub {
            my ($owner, $name, $info, $rows, $o) = @_;
            my $record = $owner->factorized_graph_inference_event($name, $info);
            my $before = $json->decode($owner->{_graph_inference_events}{$name}{state});
            my $copy = $owner->factorized_graph_inference_event($name, $info);
            $copy->{expression_tree}[0] = 'WRONG';
            is_deeply($owner->factorized_graph_inference_event($name, $info), $record, 'returned graph record detaches');
            $owner->resolve_intermediate_signal_width($name, $info, $rows, {});
            is_deeply($owner->factorized_graph_inference_event($name, $info), $record, 'actual owned cache/re-inference preserves current graph event');
            my $after = $json->decode($owner->{_graph_inference_events}{$name}{state});
            cmp_ok($after->{revision}, '>', $before->{revision}, 'cache read attests the new actual resolver revision');
            is($owner->factorized_graph_inference_event($name, {%$info}), undef, 'equal copied metadata cannot borrow held event');
            my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
            $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
            is($owner->factorized_graph_inference_event($name, $info), undef, 'matching supported source write revokes held graph proof');
            $owner->resolve_intermediate_signal_width($name, $info, $rows, {});
            is($owner->factorized_graph_inference_event($name, $info), undef, 'later numeric inference cannot revive revoked graph proof');
        });
    }
};

subtest 'native independent floors and changed child proof cannot mint events' => sub {
    plan skip_all => 'graph event API absent' unless $has_api;
    for my $width (1, 8) {
        my $p = fixture('(+ A (* B C))', $nested, $width, native_width => $width);
        is($p->{observed}{event}, undef, 'matching actual native metadata cannot mint a graph event');
        is($p->{observed}{resolved_source}, 'native_signal_metadata', 'ordinary wider native selection preserves') if $width > 1;
    }
    for my $change (
        sub {$_[2]{width} = 16},
        sub {$_[2]{signed} = 1},
        sub {$_[0]{flattened_dt}{ast_factorizer}{intermediate_signals}{$_[1]}{width} = 16},
    ) {
        my $p = fixture('(+ A (* B C))', $nested, 8, before_resolve => $change);
        is($p->{observed}{event}, undef, 'independent cached/result/allocator constraints withhold intrinsic event');
    }
    my $changed = fixture('(+ A (* B C))', $nested, 8, after_infer => sub {
        my ($owner, $name, $info, $rows) = @_;
        my ($child) = grep {$_ ne $name && defined($owner->factorized_width_inference_event($_, $rows->{$_}))} keys %$rows;
        $rows->{$child}{width} = 32;
    });
    is($changed->{observed}{event}, undef, 'numeric parent result cannot borrow independently changed child event');
};

subtest 'changed views abort and actual backend reuse cannot revive old graph proof' => sub {
    plan skip_all => 'graph event API absent' unless $has_api;
    my $first = fixture('(+ A (* B C))', $nested, 8, on_event => sub {
        my ($owner, $name, $info, $rows) = @_;
        $owner->_bind_graph_inference_rows($rows);
        is($owner->factorized_graph_inference_event($name, $info), undef, 'same-row view rebind revokes prior event');
        $owner->resolve_intermediate_signal_width($name, $info, $rows, {});
        is($owner->factorized_graph_inference_event($name, $info), undef, 'cache lookup cannot recreate proof after a new view');
        $owner->_abort_factorized_width_inference;
        is_deeply($owner->{_graph_inference_events}, {}, 'abort clears every held graph event');
    });
    my $second = fixture('(+ A (* B C))', $nested, 8, ctx => $first->{ctx});
    ok($second->{observed}{event}, 'fresh successful backend reuse captures its new actual intrinsic event');
    cmp_ok($second->{observed}{epoch}, '>', $first->{observed}{epoch}, 'actual new generation uses a later epoch');
    my $owner = $second->{ctx}{backend_sv_intermediate_width_support};
    my $old_name = $first->{observed}{name};
    is($owner->factorized_graph_inference_event($old_name, $first->{all}{$old_name}), undef,
        'retained earlier metadata cannot borrow the new generation');
};

subtest 'a read shares child validation and still rejects changes behind cached graph children' => sub {
    plan skip_all => 'graph event API absent' unless $has_api;
    my $tree = ['+', ['+', ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']], ['signal','D']], ['signal','A']];
    fixture('(+ A B C D A)', $tree, 8, on_event => sub {
        my ($owner, $name, $info) = @_;
        my $class = 'FSM::IntermediateWidthGraphInferenceSupport';
        my $prepare = $class->can('prepare_inference');
        my %calls;
        {
            no warnings 'redefine';
            no strict 'refs';
            local *{"${class}::prepare_inference"} = sub {
                my ($invocant, %args) = @_;
                ++$calls{$args{signal_name}};
                return $prepare->(@_);
            };
            ok($owner->factorized_graph_inference_event($name, $info), 'actual transitive graph remains current');
        }
        cmp_ok(scalar(keys %calls), '>', 1, 'read validates actual transitive graph children');
        is_deeply([sort {$a <=> $b} values %calls], [(1) x scalar(keys %calls)],
            'each graph is fully re-derived once within the read operation');
    });
    my $two = ['+', ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']],
        ['+', ['+', ['signal','B'], ['signal','C']], ['signal','D']]];
    fixture('(+ (+ A B C) (+ B C D))', $two, 8, on_event => sub {
        my ($owner, $name, $info, $rows) = @_;
        my $holder = $owner->{_graph_inference_events}{$name};
        my $frame = $json->decode($holder->{state});
        my $later = $frame->{dependencies}[1]{source_name};
        my $get = $width_class->can('factorized_graph_inference_event');
        my $changed;
        {
            no warnings 'redefine';
            no strict 'refs';
            local *{"${width_class}::factorized_graph_inference_event"} = sub {
                my $record = $get->(@_);
                if ($_[1] eq $later && $record && !$changed++) {
                    my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
                    $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
                }
                return $record;
            };
            is($owner->factorized_graph_inference_event($name, $info), undef,
                'final shallow proof sweep rejects mutation hidden behind a cached graph child');
        }
        ok($changed, 'actual later graph getter performed the source write');
    });
};
done_testing();
