use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::HDL::FlattenedDT;

my $json=JSON::PP->new->canonical;
my $class='FSM::HDL::FlattenedDT::Backend::SystemVerilog::IntermediateSignalWidthSupport';
my $available=$class->can('source_bitwise_tree_width_allocation');
sub policy {
    my ($owner,$name,$info)=@_;
    return $available ? scalar($owner->source_bitwise_tree_width_allocation($name,$info)) : undef;
}
sub probe {
    my ($width,%options)=@_;my $op=$options{operator}//'&';
    my $text="(?fsm:tree_attachment (+params (W $width))"
        ." (+size (A (param W)) (B (param W)) (C (param W)) (DATA 1) (OTHER 1))"
        ." (idle (<($op A B C) (= (DATA 1)) (= (OTHER 1))) (-> idle)))";
    my $module=FSM::Adapter::FSMGenFull->new->parse_fsm(scalar Lispish::multi(\$text));
    my $backend=FSM::HDL::FlattenedDT->new;
    my $collect=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport->can('collect_consolidated_intermediate_signals');
    my $render=FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport->can('render_consolidated_intermediate_declarations');
    my ($all,$name,$at_collection,$hdl,$ok,$error);
    {
        no warnings 'redefine';
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateSupport::collect_consolidated_intermediate_signals=sub {
            my $self=shift;$all=$collect->($self,@_);
            ($name)=grep {($all->{$_}{source}//'') eq 'fsmgen_parsing'} keys %$all;
            die "actual source tree absent\n" unless defined $name;
            $at_collection=policy($backend->{backend_sv_intermediate_width_support},$name,$all->{$name});
            return $all;
        };
        local *FSM::HDL::FlattenedDT::Backend::SystemVerilog::ConsolidatedIntermediateDeclarationSupport::render_consolidated_intermediate_declarations=sub {
            my $result=$render->(@_);die "after tree collection\n" if $options{fail};return $result;
        };
        $ok=eval {$hdl=$backend->generate_systemverilog($module);1};$error=$@;
    }
    return {module=>$module,backend=>$backend,name=>$name,all=>$all,at_collection=>$at_collection,hdl=>$hdl,ok=>$ok,error=>$error};
}
sub expected {
    my ($width,$op)=@_;$op//='&';
    return {kind=>'source_bitwise_tree_operand_max',operator=>$op,selected_width=>$width,
        source_names=>[qw(A B C)],expression_tree=>[$op,[$op,['signal','A'],['signal','B']],['signal','C']]};
}

subtest 'actual successful collection attaches separate current source tree policy' => sub {
    for my $width (1,8) {for my $op ('&','|','^') {
        my $p=probe($width,operator=>$op);
        ok($p->{ok},'actual n-ary source generation succeeds') or diag $p->{error};
        is_deeply($p->{at_collection},expected($width,$op),'completed actual collection exposes separate tree policy');
        next unless $available;
        my $owner=$p->{backend}{backend_sv_intermediate_width_support};my $info=$p->{all}{$p->{name}};
        is_deeply(policy($owner,$p->{name},$info),expected($width,$op),'ordinary declaration cache reads preserve attachment');
        is($info->{width_source},$width==1?'defining_ast':'native_signal_metadata','existing one/wide numeric source branch preserves');
        ok(!defined($owner->intermediate_width_allocation($p->{name},$info)),'old binary getter does not acquire source tree family');
        unlike($p->{hdl},qr/wire\s+\[\(W - 1\):0\]\s+\Q$p->{name}\E\b/,'attachment alone emits no new symbolic helper range');
    }}
};

subtest 'complete root leaf row and registry identities bind current attachment' => sub {
    plan skip_all=>'source tree attachment absent' unless $available;
    for my $change (
        sub {my $p=shift;$p->{all}{$p->{name}}={%{$p->{all}{$p->{name}}}}},
        sub {my $p=shift;$p->{backend}{intermediate_signals}{$p->{name}}={%{$p->{backend}{intermediate_signals}{$p->{name}}}}},
        sub {my $p=shift;$p->{module}{signals}={%{$p->{module}->signals}}},
        sub {my $p=shift;$p->{backend}{intermediate_signals}={%{$p->{backend}{intermediate_signals}}}},
        sub {$_[0]{module}->signals->{C}=FSM::CoreAST::Signal->new(name=>'C',width=>8)},
        sub {my $p=shift;my $c=$p->{module}->signals->{C};$c->set_attribute('width_declared',$c->get_attribute('width_declared'))},
        sub {$_[0]{module}->signals->{C}{_width}=9},
        sub {$_[0]{all}{$_[0]{name}}{runtime_ast}=FSM::CoreAST::Literal->new('1')},
        sub {$_[0]{all}{$_[0]{name}}{constraints}=['independent']},
        sub {$_[0]{all}{$_[0]{name}}{width_source}='foreign'},
        sub {$_[0]{backend}{intermediate_signals}{$_[0]{name}}{state_model}='binary'},
    ) {
        my $p=probe(8);ok($p->{at_collection},'actual baseline tree attachment exists');
        $change->($p);
        ok(!defined(policy($p->{backend}{backend_sv_intermediate_width_support},$p->{name},$p->{all}{$p->{name}})),
            'copied foreign changed or constrained current state cannot borrow attachment');
    }
};

subtest 'attachment data detaches and foreign contexts or capsules cannot supply completion' => sub {
    plan skip_all=>'source tree attachment absent' unless $available;
    my $p=probe(8);my $owner=$p->{backend}{backend_sv_intermediate_width_support};my $name=$p->{name};my $info=$p->{all}{$name};
    my $record=policy($owner,$name,$info);$record->{expression_tree}[1][1][1]='WRONG';
    is_deeply(policy($owner,$name,$info),expected(8),'returned nested policy deeply detaches');
    ok(eval {$json->encode($owner->{_source_bitwise_tree_allocation_events});1},'stored complete map is plain JSON with no owner references');
    my $foreign=FSM::HDL::FlattenedDT->new;
    $foreign->{fsm_module}=$p->{module};$foreign->{intermediate_signals}=$p->{backend}{intermediate_signals};
    my $other=$foreign->{backend_sv_intermediate_width_support};
    is(policy($other,$name,$info),undef,'actual Core objects without owned collection supply no completed attachment');
    $other->{_width_inference_epoch}=$owner->{_width_inference_epoch};
    $other->{_width_inference_complete}=$owner->{_width_inference_complete};
    $other->{_source_bitwise_tree_allocation_events}=$json->decode($json->encode($owner->{_source_bitwise_tree_allocation_events}));
    is(policy($other,$name,$info),undef,'copied capsule and equal epoch cannot impersonate another context');
    my $replacement=$class->new(flattened_dt=>$p->{backend});
    $replacement->{$_}=$owner->{$_} for qw(_width_inference_epoch _width_inference_complete);
    $replacement->{_source_bitwise_tree_allocation_events}=$json->decode($json->encode($owner->{_source_bitwise_tree_allocation_events}));
    is(policy($replacement,$name,$info),undef,'an unregistered width owner clone cannot borrow completed state');
    $p->{backend}{backend_sv_intermediate_width_support}=$replacement;
    is(policy($replacement,$name,$info),undef,'a replacement width owner cannot reuse another owner capsule');
    is(policy($owner,$name,$info),undef,'a displaced width owner cannot serve completed policy');
};

subtest 'failure reset and new generations clear previous completed tree attachments' => sub {
    plan skip_all=>'source tree attachment absent' unless $available;
    my $failed=probe(8,fail=>1);
    ok(!$failed->{ok},'actual post-collection generation failure occurs');
    like($failed->{error},qr/after tree collection/,'original generation error survives');
    is_deeply($failed->{backend}{backend_sv_intermediate_width_support}{_source_bitwise_tree_allocation_events},{},'abort clears partial tree attachments');
    my $p=probe(8);my $ctx=$p->{backend};my $owner=$ctx->{backend_sv_intermediate_width_support};my $info=$p->{all}{$p->{name}};
    $ctx->{orchestrator}->reset_generation_state;
    is(policy($owner,$p->{name},$info),undef,'reset withholds previous tree policy');
    is_deeply($owner->{_source_bitwise_tree_allocation_events},{},'reset clears stored plain map');
    ok(defined($ctx->generate_systemverilog($p->{module})),'same backend generates freshly after reset');
    is(policy($owner,$p->{name},$info),undef,'old exact row cannot borrow a new generation');
};

subtest 'a source membership change during validation cannot escape the return check' => sub {
    plan skip_all=>'source tree attachment absent' unless $available;
    my $p=probe(8);my $source=$p->{module}->signals->{C};my $fired=0;
    my $original=FSM::CoreAST::Signal->can('width');
    {
        no warnings 'redefine';
        local *FSM::CoreAST::Signal::width=sub {
            my $self=shift;
            if (!$fired && $self == $source
                && ((caller(1))[3]//'') eq 'FSM::SourceBitwiseTreeWidthSupport::prepare_source_intermediate') {
                $fired=1;
                $p->{module}->signals->{C}=FSM::CoreAST::Signal->new(name=>'C',width=>8);
            }
            return $original->($self,@_);
        };
        ok(!defined(policy($p->{backend}{backend_sv_intermediate_width_support},$p->{name},$p->{all}{$p->{name}})),
            'late same-name equal-width source membership swap withholds policy');
    }
    ok($fired,'swap occurs during the actual attachment width validation read');
};

done_testing();
