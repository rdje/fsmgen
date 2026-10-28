use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;

my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;

sub fixture {
    my ($operator, $width, $left, $right, $kind) = @_;
    $left //= '(param W)';
    $right //= $left;
    my $source = "(?fsm:arithmetic_range (+params (W $width) (COPY W) (SAME $width))"
        . " (+size (A $left) (B $right) (DATA 1) (OTHER 1))"
        . " (idle (<($operator A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $module = $adapter->parse_fsm(scalar Lispish::multi(\$source));
    if (($kind // '') eq 'raw_factorized') {
        my %signals = map {$_ => $adapter->{signal_manager}->get_signal($_)} qw(A B DATA OTHER);
        my $condition = FSM::CoreAST::BinaryOp->new($operator,
            FSM::CoreAST::SignalRef->new($signals{A}), FSM::CoreAST::SignalRef->new($signals{B}));
        my @actions = map {FSM::CoreAST::Assignment->new(
            target => FSM::CoreAST::SignalRef->new($signals{$_}),
            source => FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
        my $branch = FSM::CoreAST::ConditionalBranch->new(condition => $condition,
            branches => [{condition => $condition, actions => \@actions}]);
        my $tree = FSM::CoreAST::DecisionTree->new(name => 'idle', elements => [$branch,
            FSM::CoreAST::StateTransitionFSM->new(target_state => 'idle')]);
        $module = FSM::CoreAST::FSMModule->new(name => $module->name, signals => \%signals,
            states => [FSM::CoreAST::State->new(name => 'idle', decision_trees => [$tree])],
            parameters => $module->parameters, _parameter_default_sources => $module->parameter_default_sources,
            _parameter_default_bindings => $module->parameter_default_bindings);
    }
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        ->can('collect_consolidated_intermediate_signals');
    my ($all, $name, $hdl);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals = sub {
            $all = $collect->(@_);
            ($name) = grep {
                my $shape = FSM::IntermediateWidthAllocationSupport->binary_operand_max_shape($all->{$_}{ast});
                $shape && $shape->{operator} eq $operator
                    && $json->encode($shape->{source_names}) eq '["A","B"]';
            } keys %$all;
            return $all;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $hdl = $ctx->generate_systemverilog($module);
    }
    die "no actual binary candidate\n" unless defined $name;
    return {flattened_dt => $ctx, signal_name => $name, signal_info => $all->{$name},
        target_language => 'systemverilog', hdl => $hdl, %{$capture->snapshot}};
}

sub prepare {return $class->prepare_binary_intermediate_range(%{$_[0]})}

sub caller_state {
    my ($in) = @_;
    my $m = $in->{flattened_dt}{fsm_module};
    return $json->encode([$in->{target_namespace}, $in->{target_declarations}, $in->{target_intermediates},
        $m->parameters, $m->parameter_default_sources, $m->parameter_default_bindings,
        {map {
            my $signal = $m->signals->{$_};
            $_ => [$signal->width, $signal->declared_width_binding, $signal->declared_width_requirements];
        } sort keys %{$m->signals}}]);
}

subtest 'actual arithmetic events privately prove only the frozen operand relationship' => sub {
    for my $operator ('+', '-', '*', '/', '%') {
        for my $width (1, 8) {
            my $in = fixture($operator, $width);
            for my $language ('systemverilog', 'verilog') {
                $in->{target_language} = $language;
                my $before = caller_state($in);
                my $plan = eval {prepare($in)};
                ok($plan, "$operator at default $width has a private $language proof") or diag $@;
                next unless $plan;
                is($plan->{profile}, 'symbolic', 'identical complete mutable operands qualify');
                is($plan->{allocation_role}, 'factorized_intermediate', 'actual allocation role retains');
                is($plan->{target_name}, $in->{signal_name}, 'actual selected result owns the plan');
                is_deeply($plan->{operand_targets}, ['A', 'B'], 'ordered actual operand targets retain');
                is_deeply($plan->{arithmetic_origin}, $in->{target_intermediates}{$in->{signal_name}}{arithmetic_origin},
                    'arithmetic origin retains without a bitwise field');
                ok(!exists($plan->{bitwise_origin}), 'origin families stay distinct');
                is_deeply($plan->{width_plan}{width_contract}{expression}, ['param', 'W'], 'captured mutable root retains');
                is($plan->{width_plan}{is_vector}, 1, 'default one keeps vector rank');
                is(caller_state($in), $before, 'complete caller source and target products preserve JSON kinds');
                $plan->{arithmetic_origin}{source_names}[0] = 'WRONG';
                $plan->{width_plan}{width_contract}{expression}[1] = 'WRONG';
                my $fresh = prepare($in);
                is($fresh->{arithmetic_origin}{source_names}[0], 'A', 'returned origin detaches');
                is($fresh->{width_plan}{width_contract}{expression}[1], 'W', 'returned range detaches');
            }
            my $name = $in->{signal_name};
            like($in->{hdl}, qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,
                'actual arithmetic consumer agrees with the independently prepared private range');
        }
    }
};

subtest 'numeric equality and incomplete or foreign actual events cannot supply proof' => sub {
    for my $right ('(param COPY)', '(param SAME)', '8', '(+ (param W) 0)') {
        ok(!eval {my $in = fixture('+', 8, '(param W)', $right); prepare($in); 1},
            'equal defaults, aliases, static floors and different trees refuse during emission or private proof');
    }
    for my $change (
        sub {$_[0]{signal_info} = {%{$_[0]{signal_info}}}},
        sub {$_[0]{flattened_dt} = FSM::HDL::FlattenedDT->new},
        sub {$_[0]{target_intermediates}{$_[0]{signal_name}}{expression} = 'A - B'},
        sub {delete $_[0]{target_intermediates}{$_[0]{signal_name}}{width_allocation}},
        sub {$_[0]{target_intermediates}{$_[0]{signal_name}}{arithmetic_origin}{source_names} = ['B', 'A']},
        sub {$_[0]{target_intermediates}{$_[0]{signal_name}}{bitwise_origin} = {kind => 'binary_bitwise', operator => '&', source_names => ['A', 'B']}},
        sub {$_[0]{target_intermediates}{A} = {expression => 'B + 1'}},
        sub {delete $_[0]{target_declarations}{A}},
        sub {$_[0]{target_declarations}{$_[0]{signal_name}}{width} = 32},
        sub {$_[0]{target_declarations}{$_[0]{signal_name}}{signed} = 1},
        sub {$_[0]{target_namespace}{signals} = []},
    ) {
        my $in = fixture('+', 8);
        $change->($in);
        ok(!eval {prepare($in); 1}, 'copied, foreign, stale, typed or incomplete target inputs refuse');
    }
};

subtest 'late source or target changes invalidate the entire private proof' => sub {
    my $relationship = $class->can('prepare_binary_operand_relationship');
    for my $change (
        sub {
            my $a = $_[0]{flattened_dt}{fsm_module}->signals->{A};
            $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
        },
        sub {$_[0]{flattened_dt}{fsm_module}{parameters}{W} = 9},
        sub {$_[0]{target_declarations}{$_[0]{signal_name}}{width} = 32},
    ) {
        my $in = fixture('+', 8);
        my $changed;
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_binary_operand_relationship = sub {
                my $result = $relationship->(@_);
                $change->($in) unless $changed++;
                return $result;
            };
            ok(!eval {prepare($in); 1}, 'a change after source preparation cannot borrow the first observation');
        }
        ok($changed, 'the actual source relationship was observed before mutation');
    }
    ok(eval {prepare(fixture('+', 8)); 1}, 'a fresh complete generation remains usable after refusals');
};

subtest 'fixed arithmetic keeps independent numeric data and VHDL remains outside admission' => sub {
    for my $width (1, 8) {
        my $in = fixture('+', $width, "$width", "$width");
        my $plan = eval {prepare($in)};
        ok($plan, 'actual fixed arithmetic prepares') or diag $@;
        next unless $plan;
        is($plan->{profile}, 'fixed', 'fixed arithmetic stays fixed');
        is($plan->{width_plan}, undef, 'fixed arithmetic has no generic range');
    }
    my $in = fixture('+', 1);
    $in->{target_language} = 'vhdl';
    ok(!eval {prepare($in); 1}, 'private arithmetic preparation admits no binary VHDL helper');
};

subtest 'complete target inputs cannot change behind an equal derived plan' => sub {
    my $relationship = $class->can('prepare_binary_operand_relationship');
    for my $case (['&', 'source'], ['&', 'raw_factorized'], ['+', 'source']) {
        my ($operator, $kind) = @$case;
        for my $change (
            sub {$_[0]{target_declarations}{$_[0]{signal_name}}{width} = 32},
            sub {$_[0]{target_declarations}{$_[0]{signal_name}}{signed} = 1},
            sub {$_[0]{target_intermediates}{$_[0]{signal_name}}{expression} = 'A - B'},
        ) {
            my $in = fixture($operator, 8, undef, undef, $kind);
            my $changed;
            {
                no warnings 'redefine';
                local *FSM::DirectDeclaredWidthSupport::prepare_binary_operand_relationship = sub {
                    my $result = $relationship->(@_);
                    $change->($in) unless $changed++;
                    return $result;
                };
                ok(!eval {prepare($in); 1}, "$operator $kind proof rejects changed complete target inputs");
            }
            ok($changed, 'actual source proof ran before target mutation');
        }
    }
};
done_testing();
