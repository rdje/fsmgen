use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr isweak weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $class = 'FSM::IntermediateWidthGraphInferenceSupport';
my $width_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $json = JSON::PP->new->canonical;
my $has_api = $class->can('prepare_input');
sub expected_tree {
    return ['+', ['*', ['signal','A'], ['signal','B']], ['*', ['signal','C'], ['signal','D']]]
        if $_[0] eq 'two_children';
    return $_[0] eq 'nested'
        ? ['+', ['signal','A'], ['*', ['signal','B'], ['signal','C']]]
        : ['+', ['+', ['signal','A'], ['signal','B']], ['signal','C']];
}
sub source_state {
    my ($m) = @_;
    return $json->encode([$m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {my $s = $m->signals->{$_}; $_ => [$s->width, $s->declared_width_binding,
            $s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
sub fixture {
    my ($kind, $width, %options) = @_;
    my $expression = $kind eq 'nested' ? '(+ A (* B C))'
        : $kind eq 'two_children' ? '(+ (* A B) (* C D))' : '(+ A B C)';
    my $source = "(?fsm:graph_frames (+params (W $width))"
        . ' (+size (A (param W)) (B (param W)) (C (param W)) (D (param W)) (DATA 1) (OTHER 1))'
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$source));
    my $before = source_state($module);
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $infer = $width_class->can('infer_width_from_intermediate_ast');
    my (%observed, $hdl);
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${width_class}::infer_width_from_intermediate_ast"} = sub {
            my ($owner, $ast, $registry) = @_;
            my ($name) = grep {
                my $info = $registry->{$_};
                my $birth = $ctx->{ast_factorizer}->intermediate_width_graph_birth($_);
                $birth && ref($info) eq 'HASH' && !defined($info->{width})
                    && refaddr($info->{ast}) == refaddr($ast)
                    && $json->encode($birth->{expression_tree}) eq $json->encode(expected_tree($kind));
            } keys %{$registry // {}};
            return $infer->(@_) unless defined($name) && !$observed{seen}++;
            my $info = $registry->{$name};
            my @keys = sort keys %$owner;
            my $input = eval {$class->prepare_input(width_support => $owner, signal_name => $name,
                signal_info => $info, signal_registry => $registry, native_signal_info => undef,
                track => $options{track} ? 1 : 0)};
            $observed{error} = $@;
            $observed{input} = $input;
            $observed{input_query_read_only} = $json->encode(\@keys) eq $json->encode([sort keys %$owner]);
            $observed{view_is_weak} = isweak($owner->{_graph_inference_rows}) ? 1 : 0;
            $observed{view_matches_actual} = $owner->can('_current_graph_inference_rows')
                && $owner->_current_graph_inference_rows == $registry ? 1 : 0;
            my $width_result = $infer->(@_);
            if ($has_api) {
                my $before_ready = $json->encode([sort keys %$owner]);
                my $ready = $class->prepare_frame(width_support => $owner, input => $input);
                $observed{ready} = $ready;
                $observed{ready_query_read_only} = $before_ready eq $json->encode([sort keys %$owner]);
                $options{after_child}->($owner, $name, $info, $registry, $input, \%observed)
                    if $options{after_child};
            }
            $observed{name} = $name;
            $observed{width_before_publication} = $info->{width};
            return $width_result;
        };
        $hdl = $ctx->generate_systemverilog($module);
    }
    return {observed => \%observed, ctx => $ctx, module => $module, hdl => $hdl,
        source_before => $before, source_after => source_state($module)};
}

subtest 'actual unresolved parent and ready child proof yield detached private frames' => sub {
    my $first = fixture('nested', 1);
    ok($first->{observed}{input}, 'actual normalization exposes a private pending graph input')
        or diag($first->{observed}{error} // 'missing frame');
    return unless $has_api;
    for my $kind ('nary', 'nested') {
        for my $width (1, 8) {
            my $p = fixture($kind, $width);
            my $o = $p->{observed};
            is($o->{input}{kind}, 'arithmetic_graph_input', 'pending input is a separate closed phase');
            is($o->{ready}{kind}, 'arithmetic_graph_inference_frame', 'current child proof yields a ready frame');
            is($o->{ready}{expected_width}, $width, 'observed sources and child event prove the intrinsic max');
            is($o->{width_before_publication}, undef, 'ready proof precedes parent selected-width publication');
            ok($o->{view_is_weak} && $o->{view_matches_actual}, 'non-owning view is the exact actual normalization registry');
            ok($o->{input_query_read_only} && $o->{ready_query_read_only}, 'private queries create no event or owner fields');
            ok(eval {$json->encode([$o->{input}, $o->{ready}]); 1}, 'complete pending and ready frames contain only JSON data');
            is($p->{source_after}, $p->{source_before}, 'source maps, width contracts and scalar kinds conserve');
            my $name = $o->{name};
            my $range = $width == 1 ? '' : '[7:0] ';
            like($p->{hdl}, qr/^  wire \Q$range$name\E;$/m, 'private frame alone leaves outer graph HDL numeric');
        }
    }
};

subtest 'owned child cache reads preserve the stable kernel at defaults one and eight' => sub {
    plan skip_all => 'graph frame API absent' unless $has_api;
    for my $width (1, 8) {
        my $p = fixture('nested', $width, after_child => sub {
            my ($owner, $name, $info, $registry, $input, $observed) = @_;
            my ($child) = grep {$_ ne $name && defined($owner->factorized_width_inference_event($_, $registry->{$_}))}
                keys %$registry;
            ok(defined($child), 'actual whole-source dependency event exists');
            $owner->resolve_intermediate_signal_width($child, $registry->{$child}, $registry, {});
            $observed->{after_cache} = $class->prepare_frame(width_support => $owner, input => $input);
        });
        is_deeply($p->{observed}{after_cache}, $p->{observed}{ready}, 'exact owned cache transition preserves stable source/dependency proof');
    }
};

subtest 'copied rows maps foreign epochs and absent child proof cannot supply ready frames' => sub {
    plan skip_all => 'graph frame API absent' unless $has_api;
    fixture('nested', 8, after_child => sub {
        my ($owner, $name, $info, $registry, $input) = @_;
        for my $override (
            {signal_info => {%$info}},
            {signal_registry => {%$registry}},
            {native_signal_info => {width => 8}},
        ) {
            is($class->prepare_input(width_support => $owner, signal_name => $name, signal_info => $info,
                signal_registry => $registry, native_signal_info => undef, %$override), undef,
                'same-value copied or independently native input is not actual unresolved ownership');
        }
        {
            my $registered = $owner->{flattened_dt}{intermediate_signals}{$name};
            ok(ref($registered) eq 'HASH', 'actual registered parent row exists before publication');
            local $registered->{width} = 32;
            is($class->prepare_input(width_support => $owner, signal_name => $name, signal_info => $info,
                signal_registry => $registry, native_signal_info => undef), undef,
                'registered independent width cannot borrow unresolved collected ownership');
        }
        {
            my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
            local $a->{name} = 'WRONG';
            is($class->prepare_input(width_support => $owner, signal_name => $name, signal_info => $info,
                signal_registry => $registry, native_signal_info => undef), undef,
                'module key cannot substitute for its actual source Signal name');
        }
        my $other = FSM::HDL::FlattenedDT->new;
        is($class->prepare_frame(width_support => $other->{backend_sv_intermediate_width_support}, input => $input), undef,
            'foreign context cannot borrow the frame');
        my ($child) = grep {$_ ne $name && defined($owner->factorized_width_inference_event($_, $registry->{$_}))}
            keys %$registry;
        {
            local $owner->{_width_inference_events}{$child};
            is($class->prepare_frame(width_support => $owner, input => $input), undef, 'matching numeric child without its actual held event refuses');
        }
        {
            local $registry->{$child} = {%{$registry->{$child}}};
            is($class->prepare_frame(width_support => $owner, input => $input), undef, 'copied live child row cannot borrow the prior dependency');
        }
        {
            local $registry->{$child}{width} = 32;
            is($class->prepare_frame(width_support => $owner, input => $input), undef, 'independent child floor cannot borrow intrinsic proof');
        }
        $owner->_bind_graph_inference_rows($registry);
        is($class->prepare_frame(width_support => $owner, input => $input), undef, 'same-map rebind cannot refresh an older pending input');
    });
};

subtest 'returned data detaches and matching supported source writes revoke ready proof' => sub {
    plan skip_all => 'graph frame API absent' unless $has_api;
    fixture('nested', 8, track => 1, after_child => sub {
        my ($owner, $name, $info, $registry, $input, $observed) = @_;
        my $before = $class->prepare_frame(width_support => $owner, input => $input);
        $before->{shape}{source_names}[0] = 'WRONG';
        my $fresh = $class->prepare_frame(width_support => $owner, input => $input);
        is_deeply($fresh, $observed->{ready}, 'returned shape and dependency proof are detached');
        my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
        $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
        is($class->prepare_frame(width_support => $owner, input => $input), undef,
            'matching direct-source write cannot borrow the earlier pending input');
    });
    fixture('nested', 8, after_child => sub {
        my ($owner, $name, $info, $registry, $input) = @_;
        my $current = $width_class->can('factorized_width_inference_event');
        my $changed;
        {
            no warnings 'redefine';
            no strict 'refs';
            local *{"${width_class}::factorized_width_inference_event"} = sub {
                my $record = $current->(@_);
                if ($record && !$changed++) {
                    my $b = $owner->{flattened_dt}{fsm_module}->signals->{B};
                    $b->set_attribute('width_declared', $b->get_attribute('width_declared'));
                }
                return $record;
            };
            is($class->prepare_frame(width_support => $owner, input => $input), undef,
                'source mutation during child proof cannot return a ready frame');
        }
        ok($changed, 'actual current child proof was observed before mutation');
    });
    fixture('two_children', 8, after_child => sub {
        my ($owner, $name, $info, $registry, $input, $observed) = @_;
        my @children = map {$_->{source_name}} @{$observed->{ready}{dependencies}};
        my $current = $width_class->can('factorized_width_inference_event');
        my $changed;
        {
            no warnings 'redefine';
            no strict 'refs';
            local *{"${width_class}::factorized_width_inference_event"} = sub {
                my $record = $current->(@_);
                if ($_[1] eq $children[1] && $record && !$changed++) {
                    my $a = $owner->{flattened_dt}{fsm_module}->signals->{A};
                    $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
                }
                return $record;
            };
            is($class->prepare_frame(width_support => $owner, input => $input), undef,
                'later sibling read cannot hide mutation of an already-read child source');
        }
        ok($changed, 'actual second child read changed the earlier child source');
    });
};

subtest 'row locators retain no registry and abort clears their current association' => sub {
    plan skip_all => 'graph frame API absent' unless $has_api;
    my $p = fixture('nary', 1);
    my $owner = $p->{ctx}{backend_sv_intermediate_width_support};
    my $weak;
    {
        my $rows = {};
        $owner->_bind_graph_inference_rows($rows);
        ok(isweak($owner->{_graph_inference_rows}), 'owner stores a weak registry association');
        $weak = $rows;
        weaken($weak);
    }
    ok(!defined($weak), 'view does not retain its registry');
    is($owner->_current_graph_inference_rows, undef, 'collected registry lifetime is required');
    $owner->_abort_factorized_width_inference;
    ok(!exists($owner->{_graph_inference_rows}), 'abort removes the non-owning locator');
};
done_testing();
