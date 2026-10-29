use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::AST::Node;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $json=JSON::PP->new->canonical;
my $recovery_class='FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalRecoverySupport';
my $available=$recovery_class->can('source_bitwise_tree_origin');
sub expected_origin {
    my ($op,$names)=@_;$op//='&';$names//=[qw(A B C)];
    return {kind=>'source_bitwise_tree',operator=>$op,source_names=>[@$names],
        expression_tree=>[$op,[$op,['signal',$names->[0]],['signal',$names->[1]]],['signal',$names->[2]]]};
}
sub runtime_tree {
    my ($op,$names)=@_;$op//='&';$names//=[qw(A B C)];
    return FSM::AST::BinaryOp->new($op,
        FSM::AST::BinaryOp->new($op,map {FSM::AST::SignalRef->new($_)} @$names[0,1]),FSM::AST::SignalRef->new($names->[2]));
}
sub probe {
    my ($width,%options)=@_;my $op=$options{operator}//'&';
    my $expr=$options{expression}//"($op A B C)";
    my $text="(?fsm:tree_event (+params (W $width))"
        ." (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))"
        ." (idle (<$expr (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $adapter=FSM::Adapter::FSMGenFull->new;my $module=$adapter->parse_fsm(scalar Lispish::multi(\$text));
    my $ctx=FSM::HDL::FlattenedDT->new;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my $lookup=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('source_bitwise_tree_width_allocation');
    my ($all,$name,$hdl,$changed,$error,$snapshot,$snapshot_error);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            $all=$collect->(@_);($name)=grep {($all->{$_}{source}//'') eq 'fsmgen_parsing'} sort keys %$all;
            die "actual source tree absent\n" unless defined $name;
            $options{collected}->($ctx,$name,$all->{$name},$all,$adapter) if $options{collected};return $all;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::source_bitwise_tree_width_allocation=sub {
            my $record=$lookup->(@_);
            if ($record && $options{during_lookup} && !$changed++) {$options{during_lookup}->($ctx)}
            return $record;
        };
        local $ctx->{declared_width_declaration_capture}=$capture;
        $hdl=eval {$ctx->generate_systemverilog($module)};
        $error=$@;
    }
    if ($error) {
        eval {$snapshot=$capture->snapshot};
        $snapshot_error=$@;
    } else {
        $snapshot=$capture->snapshot;
    }
    return {ctx=>$ctx,module=>$module,adapter=>$adapter,capture=>$capture,snapshot=>$snapshot,
        hdl=>$hdl,error=>$error,snapshot_error=>$snapshot_error,all=>$all,name=>$name,changed=>$changed};
}
sub prepared {
    my ($info)=@_;my $ctx=FSM::HDL::FlattenedDT->new;my $c=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    $c->begin_module('prepared_tree');$c->record_declaration('ports',{name=>$_,width=>8,signed=>0}) for qw(A B C);
    local $ctx->{declared_width_declaration_capture}=$c;
    my $block={sorted_signals=>['UNRELATED'],filtered_signals=>{UNRELATED=>$info}};
    my $hdl=$ctx->{backend_sv_consolidated_intermediate_declaration_support}->render_consolidated_intermediate_declarations($block);
    $hdl.=$ctx->{backend_sv_consolidated_intermediate_assignment_support}->render_consolidated_intermediate_assignments($block);
    $c->complete;return ($hdl,$c->snapshot);
}

subtest 'actual one and wide source assignments publish separate complete tree metadata' => sub {
    for my $width (1,8) {for my $op ('&','|','^') {
        my $p=probe($width,operator=>$op);my $event=$p->{snapshot}{target_intermediates}{$p->{name}};
        is_deeply($event->{source_tree_origin},expected_origin($op),'actual selected origin retains complete original tree');
        is_deeply($event->{source_tree_width_allocation},
            {%{expected_origin($op)},kind=>'source_bitwise_tree_operand_max',selected_width=>$width},'actual current completed source policy publishes');
        my %old=%$event;delete @old{qw(source_tree_origin source_tree_width_allocation)};
        is_deeply(\%old,{expression=>$event->{expression}},'only separate optional source-tree fields extend legacy event');
        if ($available) {
            my $copy=$p->{capture}->snapshot;$copy->{target_intermediates}{$p->{name}}{source_tree_origin}{source_names}[0]='WRONG';
            is($p->{capture}->snapshot->{target_intermediates}{$p->{name}}{source_tree_origin}{source_names}[0],'A','actual selected tree metadata detaches');
        }
    }}
};

subtest 'typed whole trees preserve repeated slots shared subtrees and supported interfaces' => sub {
    plan skip_all=>'actual source-tree publisher absent' unless $available;
    my $ast=runtime_tree('&',[qw(A B A)]);
    is_deeply(FSM::SourceBitwiseTreeOriginSupport->from_ast($ast),expected_origin('&',[qw(A B A)]),'runtime typed tree preserves repeated leaf slots');
    my $p=probe(8,expression=>'(!& A B C)');
    is_deeply($p->{snapshot}{target_intermediates}{$p->{name}}{source_tree_origin},expected_origin(),'negated n-ary publishes only the bitwise base helper origin');
    for my $expression ("(& A B 8'd3)",'(& A[0:0] B C)') {
        my $other=probe(8,expression=>$expression);
        ok(!exists($other->{snapshot}{target_intermediates}{$other->{name}}{source_tree_origin}),
            'actual literal or sliced source keeps its legacy event without a tree origin');
    }
    my @sources=map {FSM::CoreAST::Signal->new(name=>$_,width=>8)} qw(A B);
    my $inner=FSM::CoreAST::BinaryOp->new('&',map {FSM::CoreAST::SignalRef->new($_)} @sources);
    my $shared=FSM::CoreAST::BinaryOp->new('|',$inner,$inner);
    my $origin=FSM::SourceBitwiseTreeOriginSupport->from_ast($shared);
    is_deeply($origin->{source_names},[qw(A B A B)],'actual repeated subtree is not a cycle and all slots retain');
    my $cycle=FSM::CoreAST::BinaryOp->new('&',$inner,$inner);$cycle->{operands}[0]=$cycle;
    ok(!defined(FSM::SourceBitwiseTreeOriginSupport->from_ast($cycle)),'actual Core cycle withholds');
    my $sliced=FSM::CoreAST::BinaryOp->new('&',$inner,FSM::CoreAST::SignalRef->new($sources[0],slice=>[0,0]));
    ok(!defined(FSM::SourceBitwiseTreeOriginSupport->from_ast($sliced)),'Core slice cannot masquerade as whole leaf');
    my $compatible=FSM::HDL::SubstitutedBinaryOp->new(operator=>'&',left=>runtime_tree('|'),
        right=>FSM::HDL::IntermediateSignalRef->new(signal_name=>'nested_helper'));
    is_deeply(FSM::SourceBitwiseTreeOriginSupport->from_ast($compatible)->{source_names},[qw(A B C nested_helper)],
        'substituted tree uses the compatible reference public interface');
    for my $leaf (FSM::AST::Literal->new('3'),FSM::AST::SignalRef->new('A',is_fsm_state_next=>1),
        FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'STATE',width=>8,state_model=>'binary'))) {
        my $bad=FSM::AST::BinaryOp->new('&',runtime_tree(),$leaf);
        ok(!defined(FSM::SourceBitwiseTreeOriginSupport->from_ast($bad)),'literal or state leaf withholds typed origin');
    }
    my $deep=FSM::AST::SignalRef->new('N0');
    $deep=FSM::AST::BinaryOp->new('&',$deep,FSM::AST::SignalRef->new('N'.$_)) for 1..64;
    ok(FSM::SourceBitwiseTreeOriginSupport->from_ast($deep),'typed shared64-level boundary qualifies');
    $deep=FSM::AST::BinaryOp->new('&',$deep,FSM::AST::SignalRef->new('N65'));
    ok(!defined(FSM::SourceBitwiseTreeOriginSupport->from_ast($deep)),'typed65-level tree withholds');
    my $wide=FSM::AST::SignalRef->new('A');
    $wide=FSM::AST::BinaryOp->new('^',$wide,$wide) for 1..11;
    ok(FSM::SourceBitwiseTreeOriginSupport->from_ast($wide),'shared subtree occurrences count as4095 visited slots');
    $wide=FSM::AST::BinaryOp->new('&',$wide,FSM::AST::SignalRef->new('B'));
    ok(!defined(FSM::SourceBitwiseTreeOriginSupport->from_ast($wide)),'4097 visited slots withhold despite few physical nodes');
};

subtest 'fresh rendering and every selected typed tree agree independently of numeric widths' => sub {
    plan skip_all=>'actual source-tree publisher absent' unless $available;
    my ($hdl,$snapshot)=prepared({source=>'fsmgen_parsing',width=>32,ast=>runtime_tree(),runtime_ast=>runtime_tree()});
    is_deeply($snapshot->{target_intermediates}{UNRELATED}{source_tree_origin},expected_origin(),'arbitrary name and contextual result width retain syntactic tree');
    ok(!exists($snapshot->{target_intermediates}{UNRELATED}{source_tree_width_allocation}),'syntactic shape without completed collection mints no allocation policy');
    my $right=FSM::AST::BinaryOp->new('&',FSM::AST::SignalRef->new('A'),
        FSM::AST::BinaryOp->new('&',FSM::AST::SignalRef->new('B'),FSM::AST::SignalRef->new('C')));
    for my $info (
        {source=>'fsmgen_parsing',width=>8,rendered_expression=>'A & B & C',runtime_ast_resolution_state=>'missing'},
        {source=>'fsmgen_parsing',width=>8,ast=>runtime_tree(),runtime_ast=>runtime_tree(),rendered_expression=>'A | B | C'},
        {source=>'fsmgen_parsing',width=>8,ast=>runtime_tree(),runtime_ast=>$right},
        {source=>'fsmgen_parsing',width=>8,ast=>runtime_tree(),runtime_ast=>runtime_tree(),defining_ast=>runtime_tree('|')},
        {source=>'fsmgen_parsing',width=>1,ast=>runtime_tree('&&'),runtime_ast=>runtime_tree('&&')},
        {source=>'ast_factorization',width=>8,ast=>runtime_tree(),runtime_ast=>runtime_tree()},
    ) {
        my ($actual,$record)=prepared($info);
        ok(!exists($record->{target_intermediates}{UNRELATED}{source_tree_origin}),'stored-only conflicting associated logical or foreign-family data withholds origin');
    }
    my $ctx=FSM::HDL::FlattenedDT->new;my $ast=runtime_tree();my $changed=0;
    my $info={source=>'fsmgen_parsing',width=>8,ast=>$ast,runtime_ast=>$ast};
    my $renderer=$ctx->{enable_graph_ast_support};my $renderer_class=ref($renderer);
    my $original=$renderer->can('ast_to_systemverilog');my $text=$renderer->ast_to_systemverilog($ast);
    {
        no warnings 'redefine';no strict 'refs';
        local *{"${renderer_class}::ast_to_systemverilog"}=sub {
            my ($self,$node,@args)=@_;my $rendered=$original->($self,$node,@args);
            if (!$changed && $node == $ast) {$changed=1;$info->{defining_ast}=runtime_tree('|')}
            return $rendered;
        };
        ok(!defined($ctx->{backend_sv_intermediate_recovery_support}->source_bitwise_tree_origin('UNRELATED',$info,$text)),
            'a selected cache change during fresh rendering cannot escape final origin recheck');
    }
    ok($changed,'cache change occurs during actual selected AST rendering');
};

subtest 'copied revoked constrained or independently widened source rows refuse atomically' => sub {
    plan skip_all=>'actual source-tree publisher absent' unless $available;
    for my $change (
        sub {my ($ctx,$name,$info,$all)=@_;$all->{$name}={%$info}},
        sub {my ($ctx,$name)=@_;$ctx->{intermediate_signals}{$name}={%{$ctx->{intermediate_signals}{$name}}}},
        sub {my ($ctx)=@_;my $c=$ctx->{fsm_module}->signals->{C};$c->set_attribute('width_declared',$c->get_attribute('width_declared'))},
        sub {my ($ctx,$name,$info)=@_;$info->{state_model}='independent'},
        sub {my ($ctx)=@_;$ctx->{fsm_module}->signals->{C}{signed}=1},
        sub {my ($ctx)=@_;$ctx->{fsm_module}->signals->{C}{constraints}=['opaque']},
        sub {my ($ctx,$name,$info,$all,$adapter)=@_;$adapter->{signal_manager}->register_signal($name,width=>32)},
    ) {
        my $p=probe(8,collected=>$change);
        like($p->{error},qr/Direct source bitwise tree range/,'unknown currentness or independent constraint reaches the actual source-tree refusal');
        is($p->{hdl},undef,'refusal returns no HDL artifact');
        ok($p->{snapshot_error} && !defined($p->{snapshot}),'refusal exposes no completed target snapshot');
    }
    my $p=probe(8,during_lookup=>sub {my $ctx=shift;my $c=$ctx->{fsm_module}->signals->{C};$c->set_attribute('width_declared',$c->get_attribute('width_declared'))});
    ok($p->{changed},'actual current tree attachment lookup is reached');
    like($p->{error},qr/Direct source bitwise tree range/,'final currentness recheck refuses matching third-leaf write');
    is($p->{hdl},undef,'late source refusal returns no HDL artifact');
    ok($p->{snapshot_error} && !defined($p->{snapshot}),'late source refusal exposes no completed target snapshot');
};

subtest 'actual post-event failure invalidates capture and same-backend fresh reuse recovers' => sub {
    plan skip_all=>'actual source-tree publisher absent' unless $available;
    my $p=probe(8);my $ctx=$p->{ctx};my $c=$p->{capture};
    my $render=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport->can('render_consolidated_intermediate_assignments');
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport::render_consolidated_intermediate_assignments=sub {
            my $hdl=$render->(@_);die "after selected tree event\n";
        };
        local $ctx->{declared_width_declaration_capture}=$c;
        ok(!eval {$ctx->generate_systemverilog($p->{module});1},'actual failure after assignment event refuses');
        like($@,qr/after selected tree event/,'original failure survives');
    }
    ok(!eval {$c->snapshot;1},'failed generation exposes no previous or partial target snapshot');
    {
        local $ctx->{declared_width_declaration_capture}=$c;
        ok(defined($ctx->generate_systemverilog($p->{module})),'same backend fresh generation succeeds');
    }
    my @events=grep {exists($_->{source_tree_width_allocation})} values %{$c->snapshot->{target_intermediates}};
    is(scalar @events,1,'retry publishes only one current source tree policy');
};

done_testing();
