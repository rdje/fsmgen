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
my $has_api = FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('factorized_width_inference_event');
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
    my ($width,%options)=@_;my $op=$options{operator}//'&';
    my $module=model($width,$op);my $backend=FSM::HDL::FlattenedDT->new;
    my $normal=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport->can('normalize_consolidated_intermediate_metadata');
    my $resolve=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('resolve_intermediate_signal_width');
    my $infer=FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport->can('infer_width_from_intermediate_ast');
    my (@observations,$target,$mutated);
    my ($ok,$error,$hdl);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateNormalizationSupport::normalize_consolidated_intermediate_metadata=sub {
            my ($self,$all)=@_;
            ($target)=grep {my $birth=$self->{flattened_dt}{ast_factorizer}->intermediate_width_allocation_birth($_);
                $birth && $birth->{operator} eq $op && $json->encode($birth->{source_names}) eq '["A","B"]'} keys %$all;
            die "fixture has no actual binary candidate\n" unless defined $target;
            $options{before_normalize}->($self->{flattened_dt},$target,$all->{$target}) if $options{before_normalize};
            return $normal->(@_);
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::infer_width_from_intermediate_ast=sub {
            my ($self,$ast)=@_;my $returned=$infer->(@_);
            if ($options{during_inference} && !$mutated && defined($target)
                    && refaddr($ast)==refaddr($self->{flattened_dt}{ast_factorizer}{intermediate_signals}{$target}{ast})) {
                $mutated=1;$options{during_inference}->($self->{flattened_dt});
            }
            return $returned;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport::resolve_intermediate_signal_width=sub {
            my ($self,$name,$info)=@_;return $resolve->(@_) unless defined($target) && $name eq $target;
            my $before={width=>$info->{width},source=>$info->{width_source}};
            my $returned=$resolve->(@_);
            my $event=eval {$self->factorized_width_inference_event($name,$info)};my $event_error=$@;
            $options{on_observation}->($self,$name,$info,$event) if $options{on_observation};
            push @observations,{before=>$before,returned=>$returned,event=>$event,error=>$event_error,after_source=>$info->{width_source}};
            return $returned;
        };
        $ok=eval {$hdl=$backend->generate_systemverilog($module);1};$error=$@;
    }
    return {ok=>$ok,error=>$error,hdl=>$hdl,observations=>\@observations,backend=>$backend,module=>$module,target=>$target};
}
sub expected {{kind=>'binary_operand_max',operator=>$_[0],source_names=>['A','B'],selected_width=>$_[1]}}
subtest 'actual intrinsic branch records a current selected event before cache/normalization handoff' => sub {
    my $first=probe(8);
    ok($first->{ok},'actual raw-Core native generation succeeds') or diag $first->{error};
    my ($observation)=@{$first->{observations}};
    ok($observation && $observation->{event},'actual first AST inference supplies selected allocation event')
        or diag($observation ? $observation->{error} : 'missing actual width observation');
    return unless $has_api;
    for my $width (1,8) {for my $operator ('&','|','^') {
        my $p=probe($width,operator=>$operator);
        ok($p->{ok},'canonical scalar/wider native generation preserves') or diag $p->{error};
        my ($initial)=@{$p->{observations}};
        is_deeply($initial->{event},expected($operator,$width),'actual canonical intrinsic max event retains selected width and order');
        ok(!defined($initial->{before}{width}) && $initial->{before}{source} eq 'unresolved_factorization_ast','event comes from actual unresolved input');
        is_deeply([map {$_->{event}} @{$p->{observations}}[1..$#{$p->{observations}}]],[(expected($operator,$width)) x $#{$p->{observations}}],'qualified later cache/copy calls preserve the original event');
    }}
};
subtest 'independent cached/native/canonical/registered constraints withhold even at equal defaults' => sub {
    plan skip_all=>'inference API absent' unless $has_api;
    for my $floor (1,8,32) {
        for my $where ('info','canonical','registered','native') {
            my $p=probe(8,before_normalize=>sub {
                my ($ctx,$name,$info)=@_;
                if ($where eq 'native') {$ctx->{fsm_module}->signals->{$name}=FSM::CoreAST::Signal->new(name=>$name,width=>$floor);return}
                my $row=$where eq 'info'?$info:$where eq 'canonical'?$ctx->{ast_factorizer}{intermediate_signals}{$name}:$ctx->{intermediate_signals}{$name};
                $row->{width}=$floor;$row->{width_source}='cached_width';
            });
            ok(@{$p->{observations}}>0,'real width kernel sees independent constraint');
            ok(!(grep {defined($_->{event})} @{$p->{observations}}),'independent floor supplies no intrinsic allocation event');
            if ($where eq 'info' && $floor>1) {is($p->{observations}[0]{returned},$floor,'legacy cached numeric selection preserves')}
        }
    }
};
subtest 'unknown membership, signed sources and stale birth cannot borrow an inference event' => sub {
    plan skip_all=>'inference API absent' unless $has_api;
    for my $change (
        sub {my($ctx)=@_;delete $ctx->{fsm_module}->signals->{A}},
        sub {my($ctx)=@_;$ctx->{fsm_module}->signals->{A}{signed}=1},
        sub {my($ctx,$name)=@_;$ctx->{ast_factorizer}{intermediate_signals}{$name}{ast}{operator}='|'},
    ) {
        my $p=probe(8,before_normalize=>$change);
        ok(@{$p->{observations}}>0,'actual kernel is reached with the unsupported/currentness control');
        ok(!(grep {defined($_->{event})} @{$p->{observations}}),'unsupported or stale actual input withholds');
    }
};
subtest 'events detach, bind exact metadata and revoke matching supported source writes' => sub {
    plan skip_all=>'inference API absent' unless $has_api;
    for my $mutate (
        sub {my($ctx)=@_;my $a=$ctx->{fsm_module}->signals->{A};$a->set_attribute('width_declared',$a->get_attribute('width_declared'))},
        sub {my($ctx)=@_;my $m=FSM::Adapter::FSMGenFull::SignalManager->new;$m->{signal_registry}{A}=$ctx->{fsm_module}->signals->{A};$m->register_signal('A',width=>8)},
    ) {
        my $checked;
        my $p=probe(8,on_observation=>sub {
            my ($owner,$name,$info,$event)=@_;return unless $event && !$checked++;
            $event->{source_names}[0]='WRONG';
            is_deeply($owner->factorized_width_inference_event($name,$info),expected('&',8),'getter deeply detaches');
            is($owner->factorized_width_inference_event($name,{%$info}),undef,'equal copied metadata cannot borrow actual observation identity');
            ok(eval {$json->encode($owner->{_width_inference_events});1},'complete stored event map contains plain data only');
            $mutate->($owner->{flattened_dt});
            is($owner->factorized_width_inference_event($name,$info),undef,'matching public source write revokes event currentness');
        });
        ok($checked,'actual intrinsic event reaches lifecycle control');
    }
    my $p=probe(8,during_inference=>sub {
        my ($ctx)=@_;my $m=FSM::Adapter::FSMGenFull::SignalManager->new;
        $m->{signal_registry}{A}=$ctx->{fsm_module}->signals->{A};$m->register_signal('A',width=>8);
    });
    ok(@{$p->{observations}}>0 && !(grep {defined($_->{event})} @{$p->{observations}}),'matching source mutation inside actual inference cannot launder the event');
};
done_testing();
