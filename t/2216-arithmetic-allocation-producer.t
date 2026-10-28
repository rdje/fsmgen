use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $json = JSON::PP->new->canonical;
my $shared = 'FSM::IntermediateWidthAllocationSupport';

sub fixture {
    my ($operator, $width, %options) = @_;
    my $size = $options{fixed} ? "$width" : '(param W)';
    my $source = "(?fsm:arithmetic_policy (+params (W $width)) "
        . "(+size (A $size) (B $size) (DATA 1) (OTHER 1)) "
        . "(idle (<($operator A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $adapter = FSM::Adapter::FSMGenFull->new;
    my $module = $adapter->parse_fsm(scalar Lispish::multi(\$source));
    if ($options{raw}) {
        my %signals = map {$_ => $module->signals->{$_} // $adapter->{signal_manager}->get_signal($_)} qw(A B DATA OTHER);
        my $condition = FSM::CoreAST::BinaryOp->new($operator,
            map {FSM::CoreAST::SignalRef->new($signals{$_})} qw(A B));
        my @actions = map {FSM::CoreAST::Assignment->new(
            target => FSM::CoreAST::SignalRef->new($signals{$_}), source => FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
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
    my $normal_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport';
    my $collect_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
    my $normal = $normal_class->can('normalize_consolidated_intermediate_metadata');
    my $collect = $collect_class->can('collect_consolidated_intermediate_signals');
    my ($name, $all, $initial, $hdl);
    {
        no warnings 'redefine';
        no strict 'refs';
        local *{"${normal_class}::normalize_consolidated_intermediate_metadata"} = sub {
            my ($owner, $rows) = @_;
            ($name) = grep {
                my $ast = $rows->{$_}{ast};
                $ast && $ast->can('operator') && $ast->operator eq $operator;
            } keys %$rows;
            die "actual arithmetic candidate missing\n" unless defined $name;
            unless ($initial) {
                $initial = {width => $rows->{$name}{width}, source => $rows->{$name}{width_source},
                    birth => $ctx->{ast_factorizer}->intermediate_width_allocation_birth($name)};
                $options{before_normalize}->($ctx, $name, $rows->{$name}) if $options{before_normalize};
            }
            return $normal->(@_);
        };
        local *{"${collect_class}::collect_consolidated_intermediate_signals"} = sub {
            $all = $collect->(@_);
            return $all;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $hdl = $ctx->generate_systemverilog($module);
    }
    return {ctx => $ctx, module => $module, capture => $capture, snapshot => $capture->snapshot,
        name => $name, info => $all->{$name}, initial => $initial, hdl => $hdl};
}
sub current_policy {
    my ($p, $info) = @_;
    return $p->{ctx}{backend_sv_intermediate_width_support}->intermediate_width_allocation(
        $p->{name}, $info // $p->{info});
}
sub policy {
    my ($op, $width) = @_;
    return {kind => 'binary_operand_max', operator => $op, source_names => ['A','B'], selected_width => $width};
}
subtest 'actual arithmetic allocator and intrinsic inference publish current private policies' => sub {
    for my $operator ('+', '-', '*', '/', '%') {
        for my $width (1, 8) {
            my $p = fixture($operator, $width);
            is_deeply($p->{initial}{birth}, {kind => 'binary_operand_max_candidate',
                operator => $operator, source_names => ['A','B']}, 'real unresolved arithmetic birth preserves ordered operands');
            ok(!defined($p->{initial}{width}) && $p->{initial}{source} eq 'unresolved_factorization_ast',
                'birth precedes any selected width');
            is_deeply(current_policy($p), policy($operator, $width), 'actual completed intrinsic-max policy is current');
            is_deeply($p->{snapshot}{target_intermediates}{$p->{name}}, {expression => "A $operator B"},
                'producer does not invent arithmetic target origins or range admission');
        }
    }
};
subtest 'generic max syntax leaves the bitwise-only origin boundary unchanged' => sub {
    ok($shared->can('binary_operand_max_shape'), 'separate typed max-shape boundary exists');
    return unless $shared->can('binary_operand_max_shape');
    for my $operator ('+', '-', '*', '/', '%') {
        my $ast = FSM::AST::BinaryOp->new($operator,
            FSM::AST::SignalRef->new('B'), FSM::AST::SignalRef->new('A'));
        is_deeply($shared->binary_operand_max_shape($ast), {operator => $operator, source_names => ['B','A']},
            'closed arithmetic shape retains actual ordered whole references');
        is($shared->binary_whole_signal_shape($ast), undef, 'arithmetic does not become a bitwise origin');
    }
    my $a = FSM::CoreAST::Signal->new(name => 'A', width => 8);
    my $core = FSM::CoreAST::BinaryOp->new('+',
        FSM::CoreAST::SignalRef->new($a), FSM::CoreAST::SignalRef->new($a));
    is_deeply($shared->binary_operand_max_shape($core), {operator => '+', source_names => ['A','A']},
        'Core arithmetic retains duplicate ordered source slots');
    for my $operator ('&&','==','<<','**') {
        my $ast = FSM::AST::BinaryOp->new($operator,
            FSM::AST::SignalRef->new('A'), FSM::AST::SignalRef->new('B'));
        is($shared->binary_operand_max_shape($ast), undef, 'other relationship families cannot borrow max shape');
    }
};
subtest 'existing raw bitwise factorizer withholds opaque operand constraints' => sub {
    my $p = fixture('&', 8, raw => 1, before_normalize => sub {
        $_[0]{fsm_module}->signals->{A}{constraints}=['opaque'];
    });
    is(current_policy($p), undef, 'existing bitwise frame cannot claim the unconstrained operand profile');
};
subtest 'opaque constraints and copied or revoked objects cannot mint arithmetic policy' => sub {
    plan skip_all => 'arithmetic shape absent' unless $shared->can('binary_operand_max_shape');
    for my $case (
        ['cached_equal', sub {my ($ctx, $name, $info) = @_; $info->{width}=8; $info->{width_source}='cached_width'}],
        ['independent_wider', sub {my ($ctx, $name, $info) = @_; $info->{width}=32; $info->{width_source}='independent'}],
        ['signed_source', sub {$_[0]{fsm_module}->signals->{A}{signed}=1}],
        ['constrained_source', sub {$_[0]{fsm_module}->signals->{A}{constraints}=['opaque']}],
    ) {
        my ($label, $change) = @$case;
        my $p = fixture('+', 8, before_normalize => $change);
        is(current_policy($p), undef, "$label withholds current provenance");
    }
    my $p = fixture('+', 8);
    is(current_policy($p, {%{$p->{info}}}), undef, 'equal copied metadata does not inherit actual identity');
    my $copy = current_policy($p); $copy->{source_names}[0]='FOREIGN';
    is_deeply(current_policy($p), policy('+', 8), 'returned policy deeply detaches');
    my $a = $p->{module}->signals->{A};
    $a->set_attribute('width_declared', $a->get_attribute('width_declared'));
    is(current_policy($p), undef, 'matching supported source write revokes arithmetic policy');
};
subtest 'failed generation clears private arithmetic policy and reuse recovers' => sub {
    plan skip_all => 'arithmetic shape absent' unless $shared->can('binary_operand_max_shape');
    my $p = fixture('+', 8, fixed => 1);
    is_deeply(current_policy($p), policy('+', 8), 'fixed arithmetic still has an intrinsic allocation policy');
    my $tail = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    {
        no warnings 'redefine'; no strict 'refs';
        local *{"${tail}::generate_systemverilog_tail"}=sub {die "after arithmetic collect\n"};
        local $p->{ctx}{declared_width_declaration_capture}=$p->{capture};
        ok(!eval {$p->{ctx}->generate_systemverilog($p->{module}); 1}, 'actual post-collect generation failure propagates');
    }
    is(current_policy($p), undef, 'failure exposes no prior or partially completed policy');
    ok(!eval {$p->{capture}->snapshot; 1}, 'failed collector exposes no prior complete events');
    my $collect_class = 'FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport';
    my $collect = $collect_class->can('collect_consolidated_intermediate_signals');
    my $fresh;
    {
        no warnings 'redefine'; no strict 'refs';
        local *{"${collect_class}::collect_consolidated_intermediate_signals"} = sub {
            my $all = $collect->(@_); $fresh=$all->{$p->{name}}; return $all;
        };
        local $p->{ctx}{declared_width_declaration_capture}=$p->{capture};
        ok($p->{ctx}->generate_systemverilog($p->{module}), 'same backend and collector recover');
    }
    is_deeply(current_policy($p, $fresh), policy('+', 8), 'reused generation publishes only its current actual row');
    is(current_policy($p), undef, 'prior-generation metadata cannot borrow the new policy');
};
done_testing();
