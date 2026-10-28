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
my $class='FSM::DirectDeclaredWidthSupport';my $json=JSON::PP->new->canonical;
my $has_api=$class->can('prepare_binary_intermediate_range');
{ package Local::PlanPolicy; sub intermediate_width_allocation {return $_[0]{policy}} }
sub raw_module {
    my($module,$manager)=@_;my %s=map {$_=>$manager->get_signal($_)} qw(A B DATA OTHER);
    my $condition=FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($s{A}),FSM::CoreAST::SignalRef->new($s{B}));
    my @actions=map {FSM::CoreAST::Assignment->new(target=>FSM::CoreAST::SignalRef->new($s{$_}),source=>FSM::CoreAST::Literal->new('1'))} qw(DATA OTHER);
    my $branch=FSM::CoreAST::ConditionalBranch->new(condition=>$condition,branches=>[{condition=>$condition,actions=>\@actions}]);
    my $tree=FSM::CoreAST::DecisionTree->new(name=>'idle',elements=>[$branch,FSM::CoreAST::StateTransitionFSM->new(target_state=>'idle')]);
    return FSM::CoreAST::FSMModule->new(name=>$module->name,signals=>\%s,states=>[FSM::CoreAST::State->new(name=>'idle',decision_trees=>[$tree])],
        parameters=>$module->parameters,_parameter_default_sources=>$module->parameter_default_sources,_parameter_default_bindings=>$module->parameter_default_bindings);
}
sub fixture {
    my($kind,$width,$left,$right)=@_;$left//='(param W)';$right//=$left;
    my $text="(?fsm:range_join (+params (W $width) (COPY W) (SAME $width)) (+size (A $left) (B $right) (DATA 1) (OTHER 1)) (idle (<(& A B) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $adapter=FSM::Adapter::FSMGenFull->new;my $module=$adapter->parse_fsm(scalar Lispish::multi(\$text));
    $module=raw_module($module,$adapter->{signal_manager}) if $kind eq 'factorized';
    my $ctx=FSM::HDL::FlattenedDT->new;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my($all,$name);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            $all=$collect->(@_);($name)=grep {my $shape=FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($all->{$_}{ast});$shape && $json->encode($shape->{source_names}) eq '["A","B"]'} keys %$all;return $all;
        };
        local $ctx->{declared_width_declaration_capture}=$capture;$ctx->generate_systemverilog($module);
    }
    die "no actual binary candidate\n" unless defined $name;
    return {flattened_dt=>$ctx,signal_name=>$name,signal_info=>$all->{$name},target_language=>'systemverilog',%{$capture->snapshot}};
}
sub prepare {$class->prepare_binary_intermediate_range(%{$_[0]})}
sub caller_state {
    my($in)=@_;my $ctx=$in->{flattened_dt};my $m=$ctx->{fsm_module};
    return $json->encode([$in->{target_namespace},$in->{target_declarations},$in->{target_intermediates},$m->parameters,$m->parameter_default_sources,$m->parameter_default_bindings,
        {map {my $s=$m->signals->{$_};$_=>[$s->width,$s->declared_width_binding,$s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
subtest 'actual source and factorizer events join only identical frozen operand ranges' => sub {
    my $first=fixture('source',1);my $plan=eval {prepare($first)};
    ok($plan,'private current-context range join exists and succeeds') or diag $@;return unless $has_api;
    for my $kind ('source','factorized') {for my $width (1,8) {for my $language ('systemverilog','verilog') {
        my $in=fixture($kind,$width);$in->{target_language}=$language;my $before=caller_state($in);my $p=prepare($in);
        is($p->{profile},'symbolic','actual identical mutable relationship yields private symbolic data');
        is($p->{allocation_role},$kind eq 'source'?'source_intermediate':'factorized_intermediate','actual source and generated roles stay distinct');
        is($p->{target_name},$in->{signal_name},'actual selected declaration owns range');
        is_deeply($p->{operand_targets},['A','B'],'actual ordered operand membership retains');
        is_deeply($p->{width_plan}{width_contract}{expression},['param','W'],'frozen relationship retains the selected root');
        is($p->{width_plan}{is_vector},1,'default-one range retains vector rank');
        is(caller_state($in),$before,'complete caller source/default/target fields preserve kinds');
        $p->{width_plan}{width_contract}{expression}[1]='WRONG';
        is(prepare($in)->{width_plan}{width_contract}{expression}[1],'W','returned private range deeply detaches');
    }}}
};
subtest 'equal defaults static floors and independent result constraints refuse' => sub {
    plan skip_all=>'range API absent' unless $has_api;
    for my $right ('(param COPY)','(param SAME)','8','(+ (param W) 0)') {
        ok(!eval {my $in=fixture('source',8,'(param W)',$right);prepare($in);1},'unproved same-default operand relation refuses during emission or private proof');
    }
    my $in=fixture('factorized',8);$in->{target_declarations}{$in->{signal_name}}{width}=32;
    ok(!eval {prepare($in);1},'independent target result floor cannot borrow intrinsic policy');
    $in=fixture('source',8);delete $in->{target_intermediates}{$in->{signal_name}}{width_allocation};
    ok(!eval {prepare($in);1},'missing actual allocation field refuses');
};
subtest 'copied foreign stale text and incomplete target records cannot attest provenance' => sub {
    plan skip_all=>'range API absent' unless $has_api;
    for my $change (
        sub {$_[0]{signal_info}={%{$_[0]{signal_info}}}},
        sub {$_[0]{flattened_dt}=FSM::HDL::FlattenedDT->new},
        sub {my($in)=@_;my $a=$in->{flattened_dt}{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {my($in)=@_;$in->{target_intermediates}{$in->{signal_name}}{expression}='A | B'},
        sub {delete $_[0]{target_declarations}{A}},
        sub {$_[0]{target_intermediates}{$_[0]{signal_name}}{width_allocation}{source_names}=['B','A']},
        sub {$_[0]{target_namespace}{signals}=[]},
        sub {my($in)=@_;$in->{flattened_dt}{backend_sv_intermediate_width_support}=bless {policy=>$in->{target_intermediates}{$in->{signal_name}}{width_allocation},flattened_dt=>$in->{flattened_dt}},'Local::PlanPolicy'},
    ) {
        my $in=fixture('source',8);$change->($in);ok(!eval {prepare($in);1},'current object/text/allocation/namespace mismatch refuses');
    }
};
subtest 'source changes inside proof cannot borrow a previously valid relationship' => sub {
    plan skip_all=>'range API absent' unless $has_api;
    my $relationship=$class->can('prepare_binary_operand_relationship');
    for my $change (
        sub {my($in)=@_;my $a=$in->{flattened_dt}{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {$_[0]{flattened_dt}{fsm_module}{parameters}{W}=9},
    ) {
        my $in=fixture('source',8);my $changed;
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_binary_operand_relationship=sub {
                my $result=$relationship->(@_);$change->($in) unless $changed++;return $result;
            };
            ok(!eval {prepare($in);1},'post-source-proof mutation refuses before a private range returns');
        }
        ok($changed,'actual relationship proof ran before mutation');
    }
};
subtest 'fixed scalar controls stay fixed and no VHDL helper profile is admitted' => sub {
    plan skip_all=>'range API absent' unless $has_api;
    for my $kind ('source','factorized') {for my $width (1,8) {
        my $in=fixture($kind,$width,"$width","$width");my $p=prepare($in);
        is($p->{profile},'fixed','actual fixed operands retain numeric profile');is($p->{width_plan},undef,'fixed helper gets no symbolic range');
    }}
    my $in=fixture('source',1);$in->{target_language}='vhdl';ok(!eval {prepare($in);1},'source-only VHDL relationship does not admit a binary helper');
};
done_testing();
