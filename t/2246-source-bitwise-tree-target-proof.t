use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken refaddr);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $class = 'FSM::DirectDeclaredWidthSupport';
my $json = JSON::PP->new->canonical;
unless ($class->can('prepare_source_tree_intermediate_range')) {
    fail('complete selected source-tree target API exists');
    done_testing();
    exit;
}
our $configure;
sub fixture {
    my ($width, $expression, @sizes) = @_;
    $expression //= '(& A B C)';
    @sizes = ('(param W)') x 3 unless @sizes;
    my $text = "(?fsm:source_intent (+params (W $width) (COPY W))"
        . " (+size (A $sizes[0]) (B $sizes[1]) (C $sizes[2]) (DATA 1) (OTHER 1))"
        . " (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module = FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    $configure->($module) if $configure;
    my $ctx = FSM::HDL::FlattenedDT->new;
    my $capture = FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect = FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        ->can('collect_consolidated_intermediate_signals');
    my ($all, $hdl);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals = sub {
            $all = $collect->(@_);
            return $all;
        };
        local $ctx->{declared_width_declaration_capture} = $capture;
        $hdl = $ctx->generate_systemverilog($module);
    }
    my $snapshot = $capture->snapshot;
    my @names = grep {exists($snapshot->{target_intermediates}{$_}{source_tree_width_allocation})}
        sort keys %{$snapshot->{target_intermediates}};
    my %child = map {$_ => 1} map {@{$snapshot->{target_intermediates}{$_}{source_tree_width_allocation}{source_names}}} @names;
    my @roots = grep {!$child{$_}} @names;
    die "fixture requires exactly one selected source-tree root\n" unless @roots == 1;
    my $name = $roots[0];
    return {flattened_dt => $ctx, signal_name => $name, signal_info => $all->{$name}, all => $all,
        target_language => 'systemverilog', expression => $snapshot->{target_intermediates}{$name}{expression},
        hdl => $hdl, snapshot => $snapshot};
}
sub prepare {
    my ($in, %override) = @_;
    return $class->prepare_source_tree_intermediate_range(
        (map {$_ => $in->{$_}} qw(flattened_dt signal_name signal_info target_language)),
        (map {$_ => $in->{snapshot}{$_}} qw(target_namespace target_declarations target_intermediates)), %override);
}
sub child_names {
    my ($in) = @_;
    return grep {$_ ne $in->{signal_name} && ($in->{all}{$_}{source} // '') eq 'fsmgen_parsing'} sort keys %{$in->{all}};
}
subtest 'complete selected tree and binary child targets independently agree with source intent' => sub {
    for my $expression ('(& A B C)', '(& A B (| A B C))', '(^ (| A B C) (& A C) A)') {
        for my $width (1,8) {
            my $in=fixture($width,$expression);
            my $before=$json->encode($in->{snapshot});
            my $plan=eval {prepare($in)};
            ok($plan,'actual complete selected target proof prepares') or diag($@);
            next unless $plan;
            my $intent=$class->prepare_source_tree_declaration(
                map {$_ => $in->{$_}} qw(flattened_dt signal_name signal_info target_language expression));
            my %root=%$plan; delete @root{qw(nodes node_order)};
            is_deeply(\%root,$intent,'independent target root agrees with separate current source intent');
            is_deeply($plan->{nodes}{$in->{signal_name}},$intent,'root inventory contains the complete detached intent');
            my @children=child_names($in);
            is_deeply([sort @{$plan->{node_order}}],[sort ($in->{signal_name},@children)],'every actual reachable selected child occurs exactly once');
            is($plan->{node_order}[-1],$in->{signal_name},'postorder places root after its children');
            is($plan->{width_plan}{is_vector},1,'mutable default-one target keeps vector rank');
            is($json->encode($in->{snapshot}),$before,'whole caller snapshot and JSON kinds conserve');
            my $saved=$json->encode($plan);
            $plan->{nodes}{$in->{signal_name}}{leaf_names}[0]='CORRUPT';
            is($json->encode(prepare($in)),$saved,'complete returned child plans detach');
        }
    }
    my $fixed=fixture(8,'(& A B (| A C))','8','4','2');
    my $plan=prepare($fixed);
    is($plan->{profile},'fixed','fixed independent leaf widths remain fixed');
    is($plan->{width_plan},undef,'fixed root invents no mutable range');
    is($plan->{width},8,'fixed root retains its independently selected maximum');
};
subtest 'one physical shared child keeps every authored occurrence and one inventory entry' => sub {
    local $configure=sub {
        my ($module)=@_;
        my ($root)=grep {$_->get_attribute('is_intermediate')} values %{$module->signals};
        my $child=FSM::CoreAST::Signal->new(name=>'shared_proof_child',width=>1,type=>'wire',
            attributes=>{is_intermediate=>1,signal_role=>'INTERNAL_INTERMEDIATE'},driving_ast=>$root->driving_ast);
        $child->set_source_bitwise_tree_width_allocation($root->source_bitwise_tree_width_allocation);
        $module->add_signal($child);
        my $pair=FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($child),FSM::CoreAST::SignalRef->new($child));
        $root->set_driving_ast(FSM::CoreAST::BinaryOp->new('&',$pair,FSM::CoreAST::SignalRef->new($module->signals->{A})));
        $root->set_source_bitwise_tree_width_allocation({kind=>'source_bitwise_tree_operand_max',operator=>'&',
            source_names=>['shared_proof_child','shared_proof_child','A'],selected_width=>1,
            expression_tree=>['&',['&',['signal','shared_proof_child'],['signal','shared_proof_child']],['signal','A']]});
    };
    my $in=fixture(1); my $plan=prepare($in);
    is_deeply($plan->{leaf_names},[qw(A B C A B C A)],'original ordered shared leaves are expanded at each typed edge');
    is_deeply($plan->{node_order},['shared_proof_child',$in->{signal_name}],'physical child appears once before root');
    is_deeply($plan->{nodes}{shared_proof_child}{leaf_names},[qw(A B C)],'child retains its own complete original leaf proof');
    delete $in->{snapshot}{target_intermediates}{shared_proof_child};
    ok(!eval {prepare($in);1},'both shared slots still require the actual selected child event');
};
subtest 'each child needs complete selected event declaration and physical membership' => sub {
    for my $change (
        sub {my ($in,$child)=@_; delete $in->{snapshot}{target_intermediates}{$child}},
        sub {my ($in,$child)=@_; delete $in->{snapshot}{target_intermediates}{$child}{source_tree_width_allocation}},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_intermediates}{$child}{source_tree_origin}{operator}='^';
            $in->{snapshot}{target_intermediates}{$child}{source_tree_origin}{expression_tree}[0]='^'},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_intermediates}{$child}{extra}=1},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_declarations}{$child}{width}=1},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_declarations}{$child}{signed}=1},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_declarations}{$child}{state_model}='state'},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_declarations}{$child}{width_origin}={kind=>'register_next',source_name=>'A'}},
        sub {my ($in,$child)=@_; @{$in->{snapshot}{target_namespace}{signals}}=grep {$_ ne $child} @{$in->{snapshot}{target_namespace}{signals}}},
        sub {$_[0]{snapshot}{target_namespace}{identifier_map}{A}='B'},
        sub {$_[0]{snapshot}{target_intermediates}{A}={expression=>'A'}},
        sub {my ($in,$child)=@_; $in->{all}{$child}={%{$in->{all}{$child}}}},
        sub {my ($in,$child)=@_; delete $in->{flattened_dt}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$child}},
    ) {
        my $in=fixture(8,'(& A B (| A B C))'); my ($child)=child_names($in);
        $change->($in,$child);
        ok(!eval {prepare($in);1},'incoherent selected child/original target refuses');
        ok(length($@),'refusal has a diagnostic');
    }
    my $in=fixture(8,'(& A B (| A C))'); my ($child)=child_names($in);
    delete $in->{snapshot}{target_intermediates}{$child}{width_allocation};
    ok(!eval {prepare($in);1},'binary child cannot borrow a parent source-tree policy');
    my $foreign=fixture(8,'(& A B (| A B C))');
    ok(!eval {prepare($in,signal_info=>$foreign->{signal_info});1},'foreign actual context root refuses');
    my $alias=fixture(8,'(& A B (| A B C))','(param W)','(param W)','(param COPY)');
    ok(!eval {prepare($alias);1},'equal-default alias behind child needs its own complete original contract');
};
subtest 'complete inputs and current source ownership recheck after the final source read' => sub {
    my $capture=$class->can('_capture_source_state');
    my $probe=fixture(8,'(& A B (| A B C))'); my $count=0;
    {
        no warnings 'redefine';
        local *FSM::DirectDeclaredWidthSupport::_capture_source_state=sub {++$count; return $capture->(@_)};
        prepare($probe);
    }
    ok($count,'probe identifies final source snapshot in the exact preparation path');
    for my $change (
        sub {$_[0]{snapshot}{target_namespace}{identifier_map}{unused}='late'},
        sub {$_[0]{snapshot}{target_declarations}{A}{extra}=JSON::PP::true},
        sub {my ($in,$child)=@_; $in->{snapshot}{target_intermediates}{$child}{expression}='late'},
        sub {my ($in,$child)=@_; $in->{all}{$child}{state_model}='late'},
        sub {my ($in,$child)=@_; delete $in->{flattened_dt}{fsm_module}->signals->{$child}{_source_bitwise_tree_width_allocation}},
        sub {my ($in,$child)=@_; delete $in->{flattened_dt}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$child}},
        sub {$_[0]{flattened_dt}{fsm_module}->set_parameter('COPY',{value=>8})},
        sub {$_[0]{flattened_dt}{assignment_analysis}{OTHER}{lhs_ast}->signal->{constraints}=['late']},
        sub {delete $_[0]{all}},
    ) {
        my $in=fixture(8,'(& A B (| A B C))'); my ($child)=child_names($in);
        my ($reads,$result,$error)=(0);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::_capture_source_state=sub {
                my $state=$capture->(@_);
                $change->($in,$child) if ++$reads==$count;
                return $state;
            };
            $result=eval {prepare($in)}; $error=$@;
        }
        is($reads,$count,'mutation occurs after the final source snapshot');
        ok(!$result && length($error),'last-read input/source/policy/lifetime change cannot hide behind equal ranges');
    }
};
subtest 'proof and held plain plans cannot revive expired caller row membership' => sub {
    my $in=fixture(8,'(& A B (| A C))'); my $weak=$in->{all}; weaken($weak);
    my $plan=prepare($in); my $saved=$json->encode($plan);
    delete $in->{all};
    is($weak,undef,'proof retains no caller row-map ownership');
    is($json->encode($plan),$saved,'detached historical plan survives without source objects');
    ok(!eval {prepare($in);1},'held root plan cannot authorize expired child membership');
    my $fresh=fixture(8,'(& A B (| A C))');
    ok(prepare($fresh),'fresh current generation still prepares');
};
done_testing();
