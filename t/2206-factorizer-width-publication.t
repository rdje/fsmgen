use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Scalar::Util qw(refaddr);
use FSM::CoreAST;
use FSM::HDL::FlattenedDT;
use FSM::Adapter::FSMGenFull::SignalManager;
my $json = JSON::PP->new->canonical;
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
    my ($width,%options)=@_;
    my $module=model($width,$options{operator}//'&');
    my $backend=FSM::HDL::FlattenedDT->new;
    my $normalize=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport->can('normalize_consolidated_intermediate_metadata');
    my $sync=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('sync_consolidated_signals_to_registry');
    my $finish=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('_finish_factorized_registry_copy');
    my ($name,$all,@observations,$hdl);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata=sub {
            my ($self,$rows)=@_;$all=$rows;
            ($name)=grep {my $b=$self->{flattened_dt}{ast_factorizer}->intermediate_width_allocation_birth($_);
                $b && $json->encode($b->{source_names}) eq '["A","B"]'} keys %$rows;
            die "actual candidate absent\n" unless defined $name;
            $options{before}->($self->{flattened_dt},$name,$rows->{$name}) if $options{before};
            $normalize->(@_);
            my $owner=$self->{flattened_dt}{backend_sv_intermediate_width_support};
            push @observations,{phase=>'normalization',event=>scalar($owner->factorized_width_inference_event($name,$rows->{$name}))};
            $options{after}->($self->{flattened_dt},$name,$rows->{$name}) if $options{after};
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::sync_consolidated_signals_to_registry=sub {
            my ($self,$rows)=@_;my $result=$sync->(@_);
            if (defined $name) {
                my $ctx=$self->{flattened_dt};my $owner=$ctx->{backend_sv_intermediate_width_support};
                push @observations,{phase=>'registry',event=>scalar($owner->factorized_width_inference_event($name,$rows->{$name}))};
                $options{synced}->($ctx,$name,$rows->{$name}) if $options{synced};
            }
            return $result;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::_finish_factorized_registry_copy=sub {
            $options{during_copy}->(@_) if $options{during_copy} && defined($name) && $_[1] eq $name;
            return $finish->(@_);
        } if $finish;
        $hdl=$backend->generate_systemverilog($module);
    }
    return {observations=>\@observations,backend=>$backend,module=>$module,name=>$name,all=>$all,hdl=>$hdl};
}
sub expected {{kind=>'binary_operand_max',operator=>$_[0],source_names=>['A','B'],selected_width=>$_[1]}}
subtest 'actual normalization and registry rebuild preserve held inference events' => sub {
    for my $width (1,8) {for my $op ('&','|','^') {
        my $p=probe($width,operator=>$op);
        is_deeply([map {$_->{phase}} @{$p->{observations}}],['normalization','registry'],'actual two owned boundaries observed');
        for my $o (@{$p->{observations}}) {is_deeply($o->{event},expected($op,$width),"$o->{phase} preserves actual intrinsic event")}
        like($p->{hdl},$width==1?qr/wire \Q$p->{name}\E;/ : qr/wire \[7:0\] \Q$p->{name}\E;/,'ordinary numeric declaration preserves');
    }}
};
subtest 'independent floors and copied metadata cannot acquire events through owned publication' => sub {
    for my $where ('info','canonical','registered') {
        my $p=probe(8,before=>sub {
            my ($ctx,$name,$info)=@_;my $row=$where eq 'info'?$info:$where eq 'canonical'?$ctx->{ast_factorizer}{intermediate_signals}{$name}:$ctx->{intermediate_signals}{$name};
            $row->{width}=8;$row->{width_source}='cached_width';
        });
        ok(!(grep {defined $_->{event}} @{$p->{observations}}),'equal independent width supplies no proof');
    }
    for my $mutate (
        sub {my($ctx)=@_;my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {my($ctx,$name)=@_;$ctx->{intermediate_signals}{$name}={%{$ctx->{intermediate_signals}{$name}}}},
        sub {my($ctx,$name,$info)=@_;$info->{constraints}=['independent']},
        sub {my($ctx,$name)=@_;$ctx->{ast_factorizer}{intermediate_signals}{$name}{width_source}='independent'},
    ) {
        my $p=probe(8,after=>$mutate);
        ok(defined($p->{observations}[0]{event}),'event exists before unsupported change');
        is($p->{observations}[1]{event},undef,'registry rebuild cannot revive stale/copied/independent state');
    }
};
subtest 'source or replacement mutation inside owned copy cannot be rebased' => sub {
    plan skip_all=>'copy transition API absent' unless FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('_finish_factorized_registry_copy');
    for my $mutate (
        sub {my($owner)=@_;my $a=$owner->{flattened_dt}{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {$_[4]{width}=32},
        sub {$_[4]{constraints}=['new constraint']},
        sub {my($owner,$name)=@_;$owner->{flattened_dt}{intermediate_signals}{$name}={%{$_[4]}}},
    ) {
        my $p=probe(8,during_copy=>$mutate);
        ok($p->{observations}[0]{event},'current event before copy');
        is($p->{observations}[1]{event},undef,'unsupported copy-window change cannot refresh');
    }
};
subtest 'copied lookup and public source writes revoke after exact registry handoff' => sub {
    my $checked;
    probe(8,synced=>sub {
        my($ctx,$name,$info)=@_;my $owner=$ctx->{backend_sv_intermediate_width_support};
        my $event=$owner->factorized_width_inference_event($name,$info);
        ok($event,'handoff reaches lifecycle checks');return unless $event;
        $checked=1;$event->{source_names}[0]='WRONG';
        is_deeply($owner->factorized_width_inference_event($name,$info),expected('&',8),'lookup detaches');
        is($owner->factorized_width_inference_event($name,{%$info}),undef,'equal metadata clone cannot borrow event');
        ok(eval {$json->encode($owner->{_width_inference_events});1},'stored capsules contain only JSON data');
        my $m=FSM::Adapter::FSMGenFull::SignalManager->new;$m->{signal_registry}{A}=$ctx->{fsm_module}->signals->{A};$m->register_signal('A',width=>8);
        is($owner->factorized_width_inference_event($name,$info),undef,'matching public source write revokes');
    });
    ok($checked,'actual completed copy was checked');
};
done_testing();
