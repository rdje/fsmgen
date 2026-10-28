use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
my $json=JSON::PP->new->canonical;
my $has_api=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('intermediate_width_allocation');
sub policy {my($owner,$name,$info)=@_;return $has_api?scalar($owner->intermediate_width_allocation($name,$info)):undef}
sub expected {{kind=>'binary_operand_max',operator=>$_[0],source_names=>['A','B'],selected_width=>$_[1]}}
sub model {
    my ($width,$op) = @_;
    my %s = map {$_=>FSM::CoreAST::Signal->new(name=>$_,width=>/^[AB]$/?$width:1)} qw(A B DATA OTHER);
    my $condition=FSM::CoreAST::BinaryOp->new($op,FSM::CoreAST::SignalRef->new($s{A}),FSM::CoreAST::SignalRef->new($s{B}));
    my @actions=map {FSM::CoreAST::Assignment->new(target=>FSM::CoreAST::SignalRef->new($s{$_}),source=>FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
    my $branch=FSM::CoreAST::ConditionalBranch->new(condition=>$condition,branches=>[{condition=>$condition,actions=>\@actions}]);
    my $tree=FSM::CoreAST::DecisionTree->new(name=>'idle',elements=>[$branch,FSM::CoreAST::StateTransitionFSM->new(target_state=>'idle')]);
    return FSM::CoreAST::FSMModule->new(name=>'inference',signals=>\%s,states=>[FSM::CoreAST::State->new(name=>'idle',decision_trees=>[$tree])]);
}
sub probe {
    my($width,%options)=@_;my $op=$options{operator}//'&';
    my $text="(?fsm:attachment (+params (W $width)) (+size (A (param W)) (B (param W)) (DATA 1) (OTHER 1)) (idle (<($op A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module=FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));my $backend=FSM::HDL::FlattenedDT->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my $declarations=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport->can('render_consolidated_intermediate_declarations');
    my($all,$name,$at_collection,$hdl,$ok,$error);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            my($self)=@_;$all=$collect->(@_);($name)=grep {($all->{$_}{source}//'') eq 'fsmgen_parsing'} keys %$all;
            die "actual source helper absent\n" unless defined $name;
            $at_collection=policy($self->{flattened_dt}{backend_sv_intermediate_width_support},$name,$all->{$name});
            return $all;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport::render_consolidated_intermediate_declarations=sub {
            my $result=$declarations->(@_);die "injected post-collection failure\n" if $options{fail};return $result;
        };
        $ok=eval {$hdl=$backend->generate_systemverilog($module);1};$error=$@;
    }
    return {module=>$module,backend=>$backend,name=>$name,all=>$all,at_collection=>$at_collection,hdl=>$hdl,ok=>$ok,error=>$error};
}
subtest 'actual successful source collection attaches current module helper policy' => sub {
    for my $width (1,8) {for my $op ('&','|','^') {
        my $p=probe($width,operator=>$op);ok($p->{ok},'actual source generation succeeds') or diag $p->{error};
        is_deeply($p->{at_collection},expected($op,$width),'actual successful collection exposes current attachment');
        my $owner=$p->{backend}{backend_sv_intermediate_width_support};
        is_deeply(policy($owner,$p->{name},$p->{all}{$p->{name}}),expected($op,$width),'ordinary later declaration reads preserve source attachment');
    }}
};
subtest 'equal copied metadata registries and module objects cannot borrow current source attachment' => sub {
    plan skip_all=>'attachment API absent' unless $has_api;
    for my $mutate (
        sub {my($p)=@_;$p->{all}{$p->{name}}={%{$p->{all}{$p->{name}}}}},
        sub {my($p)=@_;my $ctx=$p->{backend};$ctx->{intermediate_signals}{$p->{name}}={%{$ctx->{intermediate_signals}{$p->{name}}}}},
        sub {my($p)=@_;my $m=$p->{module};$m->signals->{A}=FSM::CoreAST::Signal->new(name=>'A',width=>8)},
        sub {my($p)=@_;my $a=$p->{module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {my($p)=@_;$p->{all}{$p->{name}}{runtime_ast}=FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($p->{module}->signals->{A}),FSM::CoreAST::SignalRef->new($p->{module}->signals->{B}))},
        sub {my($p)=@_;$p->{all}{$p->{name}}{constraints}=['independent']},
        sub {my($p)=@_;$p->{all}{$p->{name}}{width_source}='independent'},
    ) {
        my $p=probe(8);ok($p->{at_collection},'actual baseline attachment exists');$mutate->($p);
        is(policy($p->{backend}{backend_sv_intermediate_width_support},$p->{name},$p->{all}{$p->{name}}),undef,'unsupported identity/state/source change withholds');
    }
};
subtest 'attachment is detached plain data and requires actual completed collection' => sub {
    plan skip_all=>'attachment API absent' unless $has_api;
    my $p=probe(8);my $owner=$p->{backend}{backend_sv_intermediate_width_support};my $name=$p->{name};my $info=$p->{all}{$name};
    my $record=policy($owner,$name,$info);$record->{source_names}[0]='WRONG';
    is_deeply(policy($owner,$name,$info),expected('&',8),'getter deeply detaches');
    ok(eval {$json->encode($owner->{_source_width_allocation_events});1},'complete stored source attachments are plain JSON');
    my $foreign=FSM::HDL::FlattenedDT->new;$foreign->{fsm_module}=$p->{module};$foreign->{intermediate_signals}=$p->{backend}{intermediate_signals};
    is(policy($foreign->{backend_sv_intermediate_width_support},$name,$info),undef,'same actual Core objects without owned collection supply no attachment');
    my $failed=probe(8,fail=>1);ok(!$failed->{ok},'actual later generation failure occurs');like($failed->{error},qr/injected post-collection failure/,'original error preserves');
    is_deeply($failed->{backend}{backend_sv_intermediate_width_support}{_source_width_allocation_events},{},'generation failure clears source attachments');
};
subtest 'generic lookup delegates only existing completed factorizer proof' => sub {
    plan skip_all=>'attachment API absent' unless $has_api;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    for my $width (1,8) {
        my $ctx=FSM::HDL::FlattenedDT->new;my($rows,$name);
        {
            no warnings 'redefine';
            local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
                $rows=$collect->(@_);($name)=grep {($rows->{$_}{source}//'') eq 'ast_factorization'} keys %$rows;return $rows;
            };
            $ctx->generate_systemverilog(model($width,'&'));
        }
        my $owner=$ctx->{backend_sv_intermediate_width_support};
        is_deeply(policy($owner,$name,$rows->{$name}),expected('&',$width),'actual raw-Core completed factorizer policy delegates');
        is_deeply($owner->{_source_width_allocation_events},{},'factorizer metadata invents no Core source attachment');
    }
};
subtest 'reset and repeated generation cannot borrow previous exact metadata' => sub {
    plan skip_all=>'attachment API absent' unless $has_api;
    my $p=probe(8);my $ctx=$p->{backend};my $owner=$ctx->{backend_sv_intermediate_width_support};my $info=$p->{all}{$p->{name}};
    $ctx->{orchestrator}->reset_generation_state;
    is(policy($owner,$p->{name},$info),undef,'explicit reset revokes current attachment');
    is_deeply($owner->{_source_width_allocation_events},{},'reset clears stored plain source state');
    ok(defined($ctx->generate_systemverilog($p->{module})),'same generator can run again');
    is(policy($owner,$p->{name},$info),undef,'old exact metadata cannot borrow new generation');
};
done_testing();
