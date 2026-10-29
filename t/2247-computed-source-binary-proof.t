use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(weaken);
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;
use FSM::DirectDeclaredWidthSupport;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $class='FSM::DirectDeclaredWidthSupport';
my $json=JSON::PP->new->canonical;
unless ($class->can('prepare_computed_source_binary_declaration')
    && $class->can('prepare_computed_source_binary_intermediate_range')) {
    fail('separate computed source binary proof entrypoints exist');
    done_testing(); exit;
}
sub fixture {
    my ($width,$expression,$fixed)=@_;
    $expression //= '(& A B (| (| A B C) C))';
    my $size=$fixed ? '8' : '(param W)';
    my $text="(?fsm:computed_source (+params (W $width) (COPY W))"
        ." (+size (A $size) (B $size) (C $size) (DATA 1) (OTHER 1))"
        ." (idle (<$expression (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module=FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    my $ctx=FSM::HDL::FlattenedDT->new;
    my $capture=FSM::Backend::VerilogFamily::DeclarationCapture->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport
        ->can('collect_consolidated_intermediate_signals');
    my $rows;
    {
        no warnings 'redefine';
        # Exercise actual source/row/event producers only. The demonstrated live
        # binary range consumer still refuses this family until the next slice.
        # This fixture deliberately makes no live symbolic-HDL acceptance claim.
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::PostFlatteningAssemblySupport::_needs_declared_width_preparation=sub {0};
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals
            =sub {$rows=$collect->(@_); return $rows};
        local $ctx->{declared_width_declaration_capture}=$capture;
        $ctx->generate_systemverilog($module);
    }
    my $snapshot=$capture->snapshot;
    my @computed=grep {
        my $event=$snapshot->{target_intermediates}{$_};
        $event->{bitwise_origin} && $event->{width_allocation}
            && grep {$module->signals->{$_}->get_attribute('is_intermediate')} @{$event->{width_allocation}{source_names}};
    } sort keys %{$snapshot->{target_intermediates}};
    die 'fixture needs one computed source binary root' unless @computed==1;
    my $name=$computed[0];
    return {flattened_dt=>$ctx,signal_name=>$name,signal_info=>$rows->{$name},all=>$rows,
        target_language=>'systemverilog',expression=>$snapshot->{target_intermediates}{$name}{expression},snapshot=>$snapshot};
}
sub source {
    my ($in,%extra)=@_;
    return $class->prepare_computed_source_binary_declaration(
        (map {$_=>$in->{$_}} qw(flattened_dt signal_name signal_info target_language expression)),%extra);
}
sub target {
    my ($in,%extra)=@_;
    return $class->prepare_computed_source_binary_intermediate_range(
        (map {$_=>$in->{$_}} qw(flattened_dt signal_name signal_info target_language)),
        (map {$_=>$in->{snapshot}{$_}} qw(target_namespace target_declarations target_intermediates)),%extra);
}
sub child {
    my ($in)=@_;
    my $module=$in->{flattened_dt}{fsm_module};
    return (grep {$module->signals->{$_}->get_attribute('is_intermediate')}
        @{$in->{snapshot}{target_intermediates}{$in->{signal_name}}{width_allocation}{source_names}})[0];
}
subtest 'separate binary roots preserve actual tree or binary child ancestry and root fields' => sub {
    for my $expression ('(& A B (| (| A B C) C))','(& A B (^ (| A B C) C))','(& A B (| (& A B) C))') {
        for my $width (1,8) {
            my $in=fixture($width,$expression); my $before=$json->encode($in->{snapshot});
            my $intent=source($in); my $plan=target($in);
            my %root=%$plan; delete @root{qw(nodes node_order)};
            is_deeply(\%root,$intent,'independent complete-target root agrees with separate source intent');
            my $tree_child=$expression !~ /\(\| \(& A B\) C\)/;
            is_deeply($plan->{leaf_names},$tree_child ? [qw(A B C C)] : [qw(A B C)],'ordered original leaves and repeated C preserve');
            is($plan->{expression_tree}[0],$expression =~ /\(\^ / ? '^' : '|','actual binary root operator preserves');
            is($plan->{width},$width,'selected maximum preserves');
            is($plan->{width_plan}{is_vector},1,'symbolic default one keeps vector rank');
            ok(exists($plan->{width_allocation}) && exists($plan->{bitwise_origin})
                && !exists($plan->{source_tree_width_allocation}),'binary root retains its distinct policy/origin schema');
            is_deeply($plan->{node_order},[child($in),$in->{signal_name}],'each physical child precedes binary root');
            is($json->encode($in->{snapshot}),$before,'full source-selected caller input kinds preserve');
            my $saved=$json->encode($plan); $plan->{nodes}{child($in)}{leaf_names}[0]='WRONG';
            is($json->encode(target($in)),$saved,'nested returned plans detach');
            ok(!eval {$class->prepare_source_tree_declaration(map {$_=>$in->{$_}} qw(flattened_dt signal_name signal_info target_language expression));1},'tree-only source API still rejects binary root');
            ok(!eval {$class->prepare_binary_intermediate_range(
                (map {$_=>$in->{$_}} qw(flattened_dt signal_name signal_info target_language)),%{$in->{snapshot}});1},'old two-original target API keeps its computed-operand refusal');
        }
    }
    my $fixed=fixture(8,undef,1); my $plan=target($fixed);
    is($plan->{profile},'fixed','fixed original widths stay independent');
    is($plan->{width_plan},undef,'fixed binary helper invents no symbolic range');
};
subtest 'each child event declaration current policy and original relationship is required' => sub {
    for my $change (
        sub {my ($in,$name)=@_; delete $in->{snapshot}{target_intermediates}{$name}},
        sub {my ($in,$name)=@_; $in->{snapshot}{target_intermediates}{$name}{source_tree_origin}{operator}='^';
            $in->{snapshot}{target_intermediates}{$name}{source_tree_origin}{expression_tree}[0]='^'},
        sub {my ($in,$name)=@_; $in->{snapshot}{target_declarations}{$name}{width}=1},
        sub {my ($in,$name)=@_; $in->{all}{$name}={%{$in->{all}{$name}}}},
        sub {my ($in,$name)=@_; delete $in->{flattened_dt}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$name}},
        sub {$_[0]{snapshot}{target_namespace}{identifier_map}{C}='B'},
        sub {$_[0]{snapshot}{target_intermediates}{C}={expression=>'C'}},
    ) {
        my $in=fixture(8); $change->($in,child($in));
        ok(!eval {target($in);1},'changed child/physical target refuses independently');
        ok(length($@),'target refusal carries a diagnostic');
    }
    my $in=fixture(8,'(& A B (| (& A B) C))'); my $module=$in->{flattened_dt}{fsm_module};
    my ($original_binary)=grep {
        my $event=$in->{snapshot}{target_intermediates}{$_};
        ($in->{all}{$_}{source} // '') eq 'fsmgen_parsing'
            && $event->{width_allocation} && !grep {$module->signals->{$_}->get_attribute('is_intermediate')}
                @{$event->{width_allocation}{source_names}};
    } keys %{$in->{snapshot}{target_intermediates}};
    ok(defined($original_binary),'fixture contains an actual direct two-original binary helper');
    ok(!eval {source($in,signal_name=>$original_binary,signal_info=>$in->{all}{$original_binary},
        expression=>$in->{snapshot}{target_intermediates}{$original_binary}{expression});1},'computed binary API leaves direct two-original roots with their old owner');
    like($@,qr/actual typed source-helper child/,'refusal names the missing computed provenance');
    my ($tree)=grep {exists($in->{snapshot}{target_intermediates}{$_}{source_tree_width_allocation})}
        keys %{$in->{snapshot}{target_intermediates}};
    ok(!eval {source($in,signal_name=>$tree,signal_info=>$in->{all}{$tree},
        expression=>$in->{snapshot}{target_intermediates}{$tree}{expression});1},'computed binary API cannot borrow a tree root');
};
subtest 'binary-root proof preserves final raw currentness and weak row ownership' => sub {
    my $capture=$class->can('_capture_source_state');
    my $in=fixture(8); my $reads=0;
    {
        no warnings 'redefine';
        local *FSM::DirectDeclaredWidthSupport::_capture_source_state=sub {++$reads; return $capture->(@_)};
        target($in);
    }
    for my $change (
        sub {my ($in,$name)=@_; $in->{all}{$name}{state_model}='late'},
        sub {my ($in,$name)=@_; delete $in->{flattened_dt}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events}{$name}},
        sub {$_[0]{snapshot}{target_declarations}{C}{extra}=JSON::PP::true},
        sub {delete $_[0]{all}},
    ) {
        my $in=fixture(8); my ($count,$plan,$error)=(0);
        {
            no warnings 'redefine';
            local *FSM::DirectDeclaredWidthSupport::_capture_source_state=sub {
                my $state=$capture->(@_); $change->($in,child($in)) if ++$count==$reads; return $state;
            };
            $plan=eval {target($in)}; $error=$@;
        }
        is($count,$reads,'change follows final source snapshot');
        ok(!$plan && length($error),'binary-root proof cannot return stale equal-range state');
    }
    my $weak=$in->{all}; weaken($weak); my $plan=target($in); delete $in->{all};
    is($weak,undef,'binary-root proof and detached plan retain no caller row map');
    ok(!eval {target($in);1},'saved plain plan cannot revive expired child ownership');
};
done_testing();
