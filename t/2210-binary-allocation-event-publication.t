use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $json=JSON::PP->new->canonical;
sub model {
    my ($width,$op) = @_;
    my %s = map {$_=>FSM::CoreAST::Signal->new(name=>$_,width=>/^[AB]$/?$width:1)} qw(A B DATA OTHER);
    my $condition=FSM::CoreAST::BinaryOp->new($op,FSM::CoreAST::SignalRef->new($s{A}),FSM::CoreAST::SignalRef->new($s{B}));
    my @actions=map {FSM::CoreAST::Assignment->new(target=>FSM::CoreAST::SignalRef->new($s{$_}),source=>FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
    my $branch=FSM::CoreAST::ConditionalBranch->new(condition=>$condition,branches=>[{condition=>$condition,actions=>\@actions}]);
    my $tree=FSM::CoreAST::DecisionTree->new(name=>'idle',elements=>[$branch,FSM::CoreAST::StateTransitionFSM->new(target_state=>'idle')]);
    return FSM::CoreAST::FSMModule->new(name=>'inference',signals=>\%s,states=>[FSM::CoreAST::State->new(name=>'idle',decision_trees=>[$tree])]);
}
sub expected {{kind=>'binary_operand_max',operator=>$_[0],source_names=>['A','B'],selected_width=>$_[1]}}
sub probe {
    my($kind,$width,%options)=@_;my $op=$options{operator}//'&';my($module,$adapter);
    if ($kind eq 'source') {
        my $text="(?fsm:publication (+params (W $width)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1)) (idle (<($op A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
        $adapter=FSM::Adapter::FSMGenFull->new;$module=$adapter->parse_fsm(scalar Lispish::multi(\$text));
    } else {$module=model($width,$op)}
    $options{before}->($module) if $options{before};
    my $ctx=FSM::HDL::FlattenedDT->new;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my $lookup=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('intermediate_width_allocation');
    my($all,$name,$hdl,$changed);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            $all=$collect->(@_);($name)=grep {my $shape=FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($all->{$_}{ast});$shape && $json->encode($shape->{source_names}) eq '["A","B"]'} keys %$all;
            die "actual candidate absent\n" unless defined $name;
            $options{collected}->($ctx,$name,$all->{$name},$all,$adapter) if $options{collected};return $all;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::intermediate_width_allocation=sub {
            my $record=$lookup->(@_);
            if ($record && $options{during_lookup} && !$changed++) {$options{during_lookup}->($ctx)}
            return $record;
        };
        local $ctx->{declared_width_declaration_capture}=$capture;
        $hdl=$ctx->generate_systemverilog($module);
    }
    return {ctx=>$ctx,module=>$module,adapter=>$adapter,capture=>$capture,snapshot=>$capture->snapshot,hdl=>$hdl,all=>$all,name=>$name,changed=>$changed};
}
subtest 'actual source and factorizer selected events carry only their current policies' => sub {
    for my $kind ('source','raw') {for my $width (1,8) {for my $op ('&','|','^') {
        my $p=probe($kind,$width,operator=>$op);my $row=$p->{snapshot}{target_intermediates}{$p->{name}};
        is_deeply($row->{width_allocation},expected($op,$width),'actual selected event retains current intrinsic allocation');
        my %old=%$row;delete $old{width_allocation};
        is_deeply(\%old,{expression=>"A $op B",bitwise_origin=>{kind=>'binary_bitwise',operator=>$op,source_names=>['A','B']}},'only the owned field extends the existing event');
        my $copy=$p->{capture}->snapshot;$copy->{target_intermediates}{$p->{name}}{width_allocation}{source_names}[0]='WRONG' if $row->{width_allocation};
        is($p->{capture}->snapshot->{target_intermediates}{$p->{name}}{width_allocation}{source_names}[0],'A','actual target policy deeply detaches');
    }}}
};
subtest 'copied stale typed or revoked metadata gains no allocation field' => sub {
    for my $kind ('source','raw') {
        for my $change (
            sub {my($ctx,$n,$info,$all)=@_;$all->{$n}={%$info}},
            sub {my($ctx,$n)=@_;$ctx->{intermediate_signals}{$n}={%{$ctx->{intermediate_signals}{$n}}}},
            sub {my($ctx)=@_;my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
            sub {my($ctx,$n,$info)=@_;$info->{state_model}='independent'},
            sub {my($ctx,$n,$info)=@_;$info->{rendered_expression}='A | B'},
        ) {
            my $p=probe($kind,8,collected=>$change);my $row=$p->{snapshot}{target_intermediates}{$p->{name}};
            ok(!exists($row->{width_allocation}),'unknown copy/state/source/rendering cannot borrow current policy');
        }
    }
};
subtest 'independent result floors and unsupported operand profiles preserve legacy capture' => sub {
    for my $kind ('source','raw') {
        my $p=probe($kind,8,collected=>sub {
            my($ctx,$n,$info,$all,$adapter)=@_;
            if ($adapter) {$adapter->{signal_manager}->register_signal($n,width=>32)} else {$info->{width}=32;$info->{width_source}='independent'}
        });
        is($p->{snapshot}{target_declarations}{$p->{name}}{width},32,'actual independent wider declaration remains selected');
        ok(!exists($p->{snapshot}{target_intermediates}{$p->{name}}{width_allocation}),'same operands do not imply intrinsic policy under a wider result');
    }
    for my $change (sub {$_[0]->signals->{A}{signed}=1},sub {$_[0]->signals->{A}{constraints}=['opaque']}) {
        my $p=probe('raw',8,before=>$change);
        ok(!exists($p->{snapshot}{target_intermediates}{$p->{name}}{width_allocation}),'unsupported actual operand profile retains old origin/text without policy');
    }
};
subtest 'matching supported mutation inside publication cannot launder current proof' => sub {
    for my $kind ('source','raw') {
        my $p=probe($kind,8,during_lookup=>sub {my($ctx)=@_;my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))});
        ok($p->{changed},'actual current policy lookup reached');
        ok(!exists($p->{snapshot}{target_intermediates}{$p->{name}}{width_allocation}),'final currentness check withholds after matching source mutation');
    }
};
subtest 'failed generation and reuse cannot expose an earlier completed policy event' => sub {
    my $render=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport->can('render_consolidated_intermediate_assignments');
    for my $kind ('source','raw') {
        my $p=probe($kind,8);my $ctx=$p->{ctx};my $capture=$p->{capture};my $error;
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateAssignmentSupport::render_consolidated_intermediate_assignments=sub {
                my $hdl=$render->(@_);die "injected post-event failure\n";
            };
            local $ctx->{declared_width_declaration_capture}=$capture;
            ok(!eval {$ctx->generate_systemverilog($p->{module});1},'generation fails after actual new event capture');$error=$@;
        }
        like($error,qr/injected post-event failure/,'original failure preserves');
        ok(!eval {$capture->snapshot;1},'failed reuse exposes no previous or partial completed snapshot');
        {
            local $ctx->{declared_width_declaration_capture}=$capture;
            ok(defined($ctx->generate_systemverilog($p->{module})),'fresh retry completes on the same backend');
        }
        my @current=grep {exists $_->{width_allocation}} values %{$capture->snapshot->{target_intermediates}};
        is(scalar(@current),1,'only current allocation event is published after retry');
        is_deeply($current[0]{width_allocation},expected('&',8),'fresh retry policy remains canonical');
    }
};
done_testing();
