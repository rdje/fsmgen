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
unless ($class->can('prepare_source_tree_declaration')) {
    fail('actual source-tree declaration intent API exists');
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
    return $class->prepare_source_tree_declaration(
        (map {$_ => $in->{$_}} qw(flattened_dt signal_name signal_info target_language expression)), %override);
}
sub child_names {
    my ($in) = @_;
    return grep {$_ ne $in->{signal_name} && ($in->{all}{$_}{source} // '') eq 'fsmgen_parsing'} sort keys %{$in->{all}};
}
subtest 'actual source-tree and binary helpers expand to original ordered leaves' => sub {
    for my $case (
        ['(& A B (| A B C))', ['&',['&',['signal','A'],['signal','B']],['|',['|',['signal','A'],['signal','B']],['signal','C']]], [qw(A B A B C)]],
        ['(& A B (| A C))', ['&',['&',['signal','A'],['signal','B']],['|',['signal','A'],['signal','C']]], [qw(A B A C)]],
        ['(^ (| A B C) (& A C) A)', ['^',['^',['|',['|',['signal','A'],['signal','B']],['signal','C']],['&',['signal','A'],['signal','C']]],['signal','A']], [qw(A B C A C A)]],
    ) {
        for my $width (1,8) {
            my $in = fixture($width,$case->[0]);
            my $before = $json->encode($in->{snapshot});
            my $plan = eval {prepare($in)};
            ok($plan, 'actual nested source helper prepares') or diag($@);
            next unless $plan;
            is_deeply($plan->{expression_tree},$case->[1],'authored operator association expands through typed edges');
            is_deeply($plan->{leaf_names},$case->[2],'every original occurrence remains ordered including duplicates');
            is_deeply($plan->{source_names},$in->{snapshot}{target_intermediates}{$in->{signal_name}}{source_tree_origin}{source_names},'current local edges stay distinct from original leaves');
            is($plan->{width},$width,'independent selected root maximum preserves');
            is($plan->{profile},'symbolic','all original mutable relationships agree');
            is($plan->{width_plan}{is_vector},1,'default-one mutable range retains vector rank');
            is($json->encode($in->{snapshot}),$before,'complete native caller snapshot preserves kinds');
            my $saved = $json->encode($plan);
            $plan->{expression_tree}[0]='WRONG'; $plan->{leaf_names}[0]='WRONG';
            is($json->encode(prepare($in)),$saved,'returned expanded tree and original leaf data detach');
            ok(!exists($plan->{nodes}) && !exists($plan->{node_order}),'source-only intent attests no selected-target child inventory');
        }
    }
    my $fixed=fixture(8,'(& A B (| A C))','8','4','2');
    my $plan=prepare($fixed);
    is($plan->{profile},'fixed','independent fixed widths across helper edges preserve');
    is($plan->{width},8,'maximum of expanded independent fixed leaves agrees');
    is($plan->{width_plan},undef,'fixed graph invents no symbolic relationship');
};
sub dag_fixture {
    my ($levels) = @_;
    local $configure = sub {
        my ($module)=@_;
        my ($root)=grep {$_->get_attribute('is_intermediate')} values %{$module->signals};
        my $base=FSM::CoreAST::Signal->new(name=>'intermediate_proof_base',width=>1,type=>'wire',
            attributes=>{is_intermediate=>1,signal_role=>'INTERNAL_INTERMEDIATE'},driving_ast=>$root->driving_ast);
        $base->set_source_bitwise_tree_width_allocation($root->source_bitwise_tree_width_allocation);
        $module->add_signal($base);
        my $previous=$base;
        for my $index (1..$levels) {
            my $node=$index==$levels ? $root : FSM::CoreAST::Signal->new(
                name=>"intermediate_proof_helper_$index",width=>1,type=>'wire',attributes=>{is_intermediate=>1,signal_role=>'INTERNAL_INTERMEDIATE'});
            my $pair=FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($previous),
                FSM::CoreAST::SignalRef->new($previous));
            $node->set_driving_ast(FSM::CoreAST::BinaryOp->new('&',$pair,FSM::CoreAST::SignalRef->new($module->signals->{A})));
            my $name=$previous->name;
            $node->set_source_bitwise_tree_width_allocation({kind=>'source_bitwise_tree_operand_max',
                operator=>'&',source_names=>[$name,$name,'A'],selected_width=>1,
                expression_tree=>['&',['&',['signal',$name],['signal',$name]],['signal','A']]});
            $module->add_signal($node) unless $index==$levels;
            $previous=$node;
        }
    };
    return fixture(1,'(& A B C)');
}
subtest 'actual shared helper references retain each occurrence' => sub {
    my $shared=dag_fixture(1);
    my $plan=prepare($shared);
    is_deeply($plan->{leaf_names},[qw(A B C A B C A)],'shared helper expands separately at each source occurrence');
    my $local=$shared->{snapshot}{target_intermediates}{$shared->{signal_name}}{source_tree_origin}{source_names};
    is($local->[0],$local->[1],'explicit actual Core graph has one helper referenced by both slots');
};
subtest 'child copies absent attachments foreign typed edges and independent contracts refuse' => sub {
    for my $mutate (
        sub {my ($in,$child)=@_; $in->{all}{$child}={%{$in->{all}{$child}}}},
        sub {my ($in,$child)=@_; delete $in->{all}{$child}},
        sub {my ($in,$child)=@_; delete $in->{flattened_dt}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$child}},
        sub {my ($in,$child)=@_; $in->{all}{$child}{rendered_expression}='A ^ B ^ C'},
        sub {my ($in,$child)=@_; $in->{all}{$child}{width}=32},
        sub {my ($in,$child)=@_; $in->{all}{$child}{signed}=1},
        sub {my ($in,$child)=@_; $in->{all}{$child}{declared_type_name}='opaque'},
        sub {my ($in,$child)=@_; my $ast=$in->{flattened_dt}{fsm_module}->signals->{$child}->driving_ast; $ast->{operands}[0]=$ast},
        sub {my ($in,$child)=@_; my $s=$in->{flattened_dt}{fsm_module}->signals->{$child}; $s->driving_ast->left->left->{signal}=$in->{flattened_dt}{fsm_module}->signals->{$in->{signal_name}}},
        sub {my ($in,$child)=@_; my $s=$in->{flattened_dt}{fsm_module}->signals->{$child}; $s->driving_ast->left->left->{signal}=FSM::CoreAST::Signal->new(name=>'A',width=>8,type=>'wire')},
    ) {
        my $in=fixture(8,'(& A B (| A B C))'); my ($child)=child_names($in);
        $mutate->($in,$child);
        ok(!eval {prepare($in);1},'incoherent child source association refuses');
    }
    my $binary=fixture(8,'(& A B (| A C))'); my ($child)=child_names($binary);
    delete $binary->{flattened_dt}{backend_sv_intermediate_width_support}{_source_width_allocation_events}{$child};
    ok(!eval {prepare($binary);1},'binary child needs its own actual completed attachment');
    my $different=fixture(8,'(& A B (| A B C))','(param W)','(param W)','(param COPY)');
    ok(!eval {prepare($different);1},'original leaf hidden behind binary helper cannot borrow equal-default alias');
    like($@,qr/identical mutable operand contracts/,'canonical relationship owns the original alias diagnostic');
};
subtest 'late child writes after relationships and final source reads cannot escape' => sub {
    my $relationship=$class->can('prepare_source_tree_operand_relationship');
    for my $binary (0,1) {
        my $in=fixture(8,$binary ? '(& A B (| A C))' : '(& A B (| A B C))');
        my ($child)=child_names($in); my ($changed,$result);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::prepare_source_tree_operand_relationship=sub {
                my $plan=$relationship->(@_);
                $in->{all}{$child}{rendered_expression}='A ^ C' unless $changed++;
                return $plan;
            };
            $result=eval {prepare($in)};
        }
        ok($changed && !$result && length($@),'late tree/binary selected child text refuses equal-range intent');
    }
    my $snapshot=$class->can('_capture_source_state');
    for my $change (
        sub {my ($in,$child)=@_; $in->{all}{$child}{state_model}='late child state'},
        sub {my ($in,$child)=@_; delete $in->{flattened_dt}{fsm_module}->signals->{$child}{_source_bitwise_tree_width_allocation}},
        sub {my ($in,$child)=@_; delete $in->{flattened_dt}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$child}},
        sub {my ($in,$child)=@_; $in->{all}{$child}={%{$in->{all}{$child}}}},
        sub {delete $_[0]{all}},
        sub {$_[0]{flattened_dt}{fsm_module}->set_parameter('COPY',{value=>8})},
        sub {$_[0]{flattened_dt}{assignment_analysis}{OTHER}{lhs_ast}->signal->{constraints}=['late unrelated constraint']},
    ) {
        my $in=fixture(8,'(& A B (| A B C))'); my ($child)=child_names($in);
        my ($reads,$result,$error);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::_capture_source_state=sub {
                my $state=$snapshot->(@_);
                $change->($in,$child) if ++$reads==2;
                return $state;
            };
            $result=eval {prepare($in)}; $error=$@;
        }
        is($reads,2,'child mutation follows final complete canonical source snapshot');
        ok(!$result && length($error),'final child metadata and policy fence rejects a last-read change');
    }
};
sub dimensions {
    my ($tree)=@_;
    return (0,1) if $tree->[0] eq 'signal';
    my ($ld,$ln)=dimensions($tree->[1]); my ($rd,$rn)=dimensions($tree->[2]);
    return (1+($ld>$rd?$ld:$rd),1+$ln+$rn);
}
subtest 'expanded depth and occurrence budgets count through actual helper edges' => sub {
    my $nested='(| A B C)';
    $nested="(& A B $nested)" for 1..62;
    my $in=fixture(1,$nested);
    my $plan=prepare($in);
    is((dimensions($plan->{expression_tree}))[0],64,'actual expanded original tree at 64 levels qualifies');
    my $over=fixture(1,"(& A B $nested)");
    ok(!eval {prepare($over);1},'expanded original tree at 65 levels refuses');
    like($@,qr/bounded expanded source tree/,'depth refusal identifies the expanded proof boundary');
    my $bounded=dag_fixture(9);
    is((dimensions(prepare($bounded)->{expression_tree}))[1],4093,
        '4093 expanded occurrences qualify from a small actual shared Core DAG');
    my $over_nodes=dag_fixture(10);
    ok(!eval {prepare($over_nodes);1},'shared expanded occurrences cannot evade the 4095-node budget');
    like($@,qr/bounded expanded source tree/,'occurrence refusal identifies the bounded expansion');
};
subtest 'recursive source intent keeps the caller row view weak' => sub {
    my $in=fixture(8,'(& A B (| A C))'); my $rows=$in->{all}; weaken($rows);
    my $plan=prepare($in); my $encoded=$json->encode($plan);
    delete $in->{all};
    is($rows,undef,'recursive proof and detached plan retain no caller row container');
    is($json->encode($plan),$encoded,'held expanded plan remains a detached historical value');
    ok(!eval {prepare($in);1},'held plan and root row cannot revive child currentness');
};
done_testing();
