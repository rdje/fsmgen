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
my $json=JSON::PP->new->canonical;
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
    my($kind,$width,$left,$right,%options)=@_;$left//='(param W)';$right//=$left;
    my $op=$options{operator}//'&';my $right_name=$options{duplicate}?'A':'B';
    my $text="(?fsm:range_join (+params (W $width) (COPY W) (SAME $width)) (+size (A $left) (B $right) (DATA 1) (OTHER 1)) (idle (<($op A $right_name) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $adapter=FSM::Adapter::FSMGenFull->new;my $module=$adapter->parse_fsm(scalar Lispish::multi(\$text));
    $module=raw_module($module,$adapter->{signal_manager}) if $kind eq 'factorized';
    my $ctx=FSM::HDL::FlattenedDT->new;my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my($all,$name);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            $all=$collect->(@_);($name)=grep {my $shape=FSM::IntermediateWidthAllocationSupport->binary_whole_signal_shape($all->{$_}{ast});$shape && $json->encode($shape->{source_names}) eq $json->encode(['A',$right_name])} keys %$all;return $all;
        };
        local $ctx->{declared_width_declaration_capture}=$capture;$options{before}->($ctx,$module,$capture) if $options{before};
        my $hdl = $options{language} && $options{language} eq 'verilog' ? $ctx->generate_verilog($module) : $ctx->generate_systemverilog($module);
        ${$options{hdl_ref}}=$hdl if $options{hdl_ref};
    }
    die "no actual binary candidate\n" unless defined $name;
    return {capture=>$capture,module=>$module,flattened_dt=>$ctx,signal_name=>$name,signal_info=>$all->{$name},target_language=>'systemverilog',%{$capture->snapshot}};
}

subtest 'actual source and factorizer declarations consume identical symbolic ranges' => sub {
    for my $kind ('source','factorized') {for my $width (1,8) {for my $language ('systemverilog','verilog') {
        my $hdl; my $before;
        my $p=fixture($kind,$width,undef,undef,language=>$language,hdl_ref=>\$hdl,before=>sub {
            $before=source_state($_[1]);
        });
        my $name=$p->{signal_name};
        like($hdl,qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,'actual helper range keeps W and vector rank at default one');
        like($hdl,qr/^  assign \Q$name\E = A & B;/m,'actual assignment retains selected expression');
        is(source_state($p->{module}),$before,'source captures and numeric kinds remain unchanged');
        my $plan=FSM::DirectDeclaredWidthSupport->prepare_binary_intermediate_range(%$p);
        is($plan->{width_plan}{range_text},'[(W - 1):0] ','complete final target proof independently agrees');
        ok(!exists($p->{flattened_dt}{direct_declared_width_emitted_binary_ranges}),'emission ledger leaves the context after generation');
    }}}
};
subtest 'bitwise operator and duplicate operand identities retain selected text' => sub {
    for my $case (['|',0],['^',0],['&',1]) {
        my($op,$duplicate)=@$case;my $hdl;
        my $p=fixture('source',1,undef,undef,operator=>$op,duplicate=>$duplicate,hdl_ref=>\$hdl);
        my $name=$p->{signal_name};my $right=$duplicate?'A':'B';
        like($hdl,qr/^  wire \[\(W - 1\):0\] \Q$name\E;$/m,'operator and duplicate cases keep the symbolic range');
        is_deeply($p->{target_intermediates}{$name}{bitwise_origin}{source_names},['A',$right],'ordered duplicate-preserving operand origin retains');
        my $selected=$duplicate?'A':"A $op $right";
        like($hdl,qr/assign \Q$name\E = \Q$selected\E;/,'selected rendering retains existing idempotence simplification');
    }
};
subtest 'aliases same defaults and fixed operands cannot borrow a mutable range' => sub {
    for my $right ('(param COPY)','(param SAME)','8','(+ (param W) 0)') {
        ok(!eval {fixture('source',8,'(param W)',$right);1},'independent operand contract returns no artifact');
        like($@,qr/identical mutable operand contracts/,'relationship refusal is explicit');
    }
    my $hdl;my $p=fixture('source',8,'8','8',hdl_ref=>\$hdl);
    like($hdl,qr/^  wire \[7:0\] \Q$p->{signal_name}\E;$/m,'fixed helper keeps numeric declaration');
    unlike($hdl,qr/wire \[\(W - 1\):0\] \Q$p->{signal_name}\E;/,'equal default supplies no symbolic helper');
};
subtest 'late changes to event identity range origin or source revoke emitted output' => sub {
    my $tail='FSM::HDL::FlattenedDT::Backend::SystemVerilog::GenerationTailSupport';
    my $generate=$tail->can('generate_systemverilog_tail');
    for my $change (
        sub {my($ctx)=@_;my($name)=keys %{$ctx->{direct_declared_width_emitted_binary_ranges}}; $ctx->{direct_declared_width_emitted_binary_ranges}{$name}{width_plan}{range_text}='[WRONG:0] '},
        sub {my($ctx)=@_;my($name)=keys %{$ctx->{direct_declared_width_emitted_binary_ranges}}; $ctx->{direct_declared_width_emitted_binary_ranges}{$name}{allocation_role}='source_intermediate_WRONG'},
        sub {my($ctx)=@_;my($name)=keys %{$ctx->{direct_declared_width_emitted_binary_ranges}}; $ctx->{declared_width_declaration_capture}{intermediates}{$name}{expression}='A | B'},
        sub {my($ctx)=@_;my($name)=keys %{$ctx->{direct_declared_width_emitted_binary_ranges}}; delete $ctx->{declared_width_declaration_capture}{intermediates}{$name}{width_allocation}},
        sub {my($ctx)=@_;my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
    ) {
        my($ctx,$module,$capture);my $error;
        {
            no strict 'refs';no warnings 'redefine';
            local *{"${tail}::generate_systemverilog_tail"}=sub {
                my $hdl=$generate->(@_);$change->($_[0]{flattened_dt});return $hdl;
            };
            eval {fixture('source',8,undef,undef,before=>sub {($ctx,$module,$capture)=@_})};$error=$@;
        }
        ok($error,'changed emitted proof cannot return HDL');
        like($error,qr/binary|allocation/,'actual final closure reports the conflict');
        ok(!eval {$capture->snapshot;1},'failed closure invalidates complete snapshot');
        local $ctx->{declared_width_declaration_capture}=$capture;
        ok($ctx->generate_systemverilog($module),'backend and collector reuse recover after refusal');
    }
};
sub source_state {
    my($m)=@_;return $json->encode([$m->parameters,$m->parameter_default_sources,$m->parameter_default_bindings,
        {map {my $s=$m->signals->{$_};$_=>[$s->width,$s->declared_width_binding,$s->declared_width_requirements]} sort keys %{$m->signals}}]);
}
done_testing();
