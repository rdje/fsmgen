use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::CoreAST;
use FSM::Adapter::FSMGenFull::SignalManager;

my $json=JSON::PP->new->canonical;
my $has_api=FSM::CoreAST::Signal->can('intermediate_width_allocation')
    && FSM::CoreAST::Signal->can('set_intermediate_width_allocation');
sub record {{kind=>'binary_operand_max',operator=>'&',source_names=>['A','B'],selected_width=>$_[0] // 8}}
sub helper {
    my ($width,$left_width,$right_width)=@_;$width//=8;$left_width//=8;$right_width//=8;
    my $manager=FSM::Adapter::FSMGenFull::SignalManager->new;
    my $a=$manager->register_signal('A',width=>$left_width);
    my $b=$manager->register_signal('B',width=>$right_width);
    my $h=$manager->register_signal('H',width=>$width,is_intermediate=>1,type=>'wire');
    my $ast=FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($a),FSM::CoreAST::SignalRef->new($b));
    $h->set_driving_ast($ast);return ($h,$a,$b,$manager,$ast);
}
sub capsule {my($h)=@_;$json->decode($json->encode($h->{_intermediate_width_allocation}))}

subtest 'equal selected widths install nothing; explicit current contract detaches without another owner graph' => sub {
    my ($h)=helper();my $keys=join(',',sort keys %$h);
    my $value=eval {$h->intermediate_width_allocation};
    ok(!$@,'opaque equal-width Core helper has an allocation getter') or diag $@;
    return unless $has_api;
    ok(!defined($value),'matching selected widths alone install no allocation contract');
    $h->clear_intermediate_width_allocation;
    is(join(',',sort keys %$h),$keys,'ordinary getter/clear add no fields before explicit installation');
    my $input=record('8');my $before=$json->encode($input);
    is($h->set_intermediate_width_allocation($input),$h,'explicit setter preserves Core chaining');
    is($json->encode($input),$before,'caller record and numeric-string JSON kind preserve');
    is_deeply($h->intermediate_width_allocation,$input,'current record retains the supplied allocation contract');
    $input->{source_names}[0]='WRONG';
    my $out=$h->intermediate_width_allocation;$out->{source_names}[1]='FOREIGN';
    is_deeply($h->intermediate_width_allocation,record('8'),'both input and output nested data detach');
    $h->is_vector;
    is_deeply($h->intermediate_width_allocation,record('8'),'ordinary width inspection preserves the current allocation and supplied JSON kinds');
    ok(eval {$json->encode($h->{_intermediate_width_allocation});1},'complete internal capsule is plain JSON with no retained owner graph');
    for my $op ('&','|','^') {
        for my $width (1,8) {
            my ($h,$a,$b)=helper($width,$width,$width);
            $h->set_driving_ast(FSM::CoreAST::BinaryOp->new($op,FSM::CoreAST::SignalRef->new($b),FSM::CoreAST::SignalRef->new($a)));
            my $policy={%{record($width)},operator=>$op,source_names=>['B','A']};
            $h->set_intermediate_width_allocation($policy);
            is_deeply($h->intermediate_width_allocation,$policy,'canonical operations, scalar/wider widths and both ordered slots preserve');
        }
    }
    my ($duplicate,$a)=helper();
    $duplicate->set_driving_ast(FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($a),FSM::CoreAST::SignalRef->new($a)));
    $duplicate->set_intermediate_width_allocation({%{record()},source_names=>['A','A']});
    is_deeply($duplicate->intermediate_width_allocation->{source_names},['A','A'],'duplicate slots retain one actual source identity');
};

subtest 'supported writes revoke matching-state policies and escaped capsules stay stale' => sub {
    plan skip_all=>'allocation API absent' unless $has_api;
    for my $write (
        sub {my($h,$a,$b,$m,$ast)=@_;$h->set_driving_ast($ast)},
        sub {$_[0]->set_attribute('is_intermediate',1)},
        sub {$_[0]->add_constraint({kind=>'opaque_width',value=>8})},
        sub {my($h,$a,$b,$m)=@_;$m->register_signal('H',width=>8)},
        sub {my($h,$a,$b,$m)=@_;$m->register_signal('H',type=>'wire')},
        sub {my($h,$a,$b,$m)=@_;$m->register_signal('H',_declared_width_source=>undef)},
        sub {eval {$_[0]->set_declared_width_requirements({})}},
        sub {eval {$_[0]->set_declared_width_binding({})}},
    ) {
        my @fixture=helper();my $h=$fixture[0];$h->set_intermediate_width_allocation(record());my $old=capsule($h);
        $write->(@fixture);
        ok(!defined($h->intermediate_width_allocation),'public relevant write clears current allocation even when numeric state matches');
        $h->{_intermediate_width_allocation}=$old;
        ok(!defined($h->intermediate_width_allocation),'escaped old capsule cannot revive after a supported write');
    }
    my ($h,$a,$b,$m)=helper();$h->set_intermediate_width_allocation(record());
    $m->register_signal('H',attributes=>{debug_label=>'unrelated'});
    is_deeply($h->intermediate_width_allocation,record(),'unrelated diagnostic attributes preserve a current allocation');
};

subtest 'foreign identity and private shape divergence withhold policy instead of numeric re-derivation' => sub {
    plan skip_all=>'allocation API absent' unless $has_api;
    my ($h,$a,$b)=helper();$h->set_intermediate_width_allocation(record());
    my ($other)=helper();$other->{_intermediate_width_allocation}=capsule($h);
    ok(!defined($other->intermediate_width_allocation),'a separate equal-width Signal cannot borrow the capsule');
    for my $mutate (
        sub {$_[0]->{_width}=9},
        sub {$_[0]->{signed}=1},
        sub {$_[2]->{_width}=9},
        sub {$_[0]->driving_ast->{operator}='|'},
        sub {$_[0]->driving_ast->{operands}[1]=FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'B',width=>8))},
    ) {
        my @fixture=helper();my $h=$fixture[0];$h->set_intermediate_width_allocation(record());
        $mutate->(@fixture);
        ok(!defined($h->intermediate_width_allocation),'current actual shape/object divergence withholds the old contract');
    }
};

subtest 'closed replacement, opaque context and exact decimal maximum preserve independent constraints' => sub {
    plan skip_all=>'allocation API absent' unless $has_api;
    my ($h)=helper();
    for my $bad ({},[],{ %{record()},extra=>1 },{ %{record()},operator=>'&&' },
        { %{record()},source_names=>['A'] },{ %{record()},source_names=>['A','FOREIGN'] },
        { %{record()},selected_width=>0 },{ %{record()},selected_width=>9 }) {
        $h->set_intermediate_width_allocation(record());
        ok(!eval {$h->set_intermediate_width_allocation($bad);1},'malformed or incoherent supplied record refuses');
        ok(!defined($h->intermediate_width_allocation),'failed replacement exposes no old record');
    }
    for my $attribute ([is_output=>1],[is_aux_output=>1],[width_declared=>1],[signal_role=>'input']) {
        my ($h)=helper();$h->set_attribute(@$attribute);
        ok(!eval {$h->set_intermediate_width_allocation(record());1},'authored or conflicting role cannot borrow intermediate allocation');
    }
    my ($conflict,$a)=helper();
    $conflict->set_driving_ast(FSM::CoreAST::BinaryOp->new('&',FSM::CoreAST::SignalRef->new($a),
        FSM::CoreAST::SignalRef->new(FSM::CoreAST::Signal->new(name=>'A',width=>8))));
    ok(!eval {$conflict->set_intermediate_width_allocation({%{record()},source_names=>['A','A']});1},
        'distinct source objects claiming one name cannot borrow duplicate-slot identity');
    my ($wide)=helper(32,8,8);
    ok(!eval {$wide->set_intermediate_width_allocation(record(32));1},'context-widened result cannot assert an intrinsic maximum');
    ok(!defined($wide->intermediate_width_allocation),'opaque context remains unqualified');
    my ($big)=helper('18446744073709551617','18446744073709551616','18446744073709551617');
    ok(eval {$big->set_intermediate_width_allocation(record('18446744073709551617'));1},'positive decimal width relation remains exact beyond machine integer precision') or diag $@;
    is_deeply($big->intermediate_width_allocation,record('18446744073709551617'),'exact large selected width retains its string kind');
    ok(!eval {$big->set_intermediate_width_allocation(record('18446744073709551616'));1},'adjacent unequal large widths cannot borrow equality');
    ok(!defined($big->intermediate_width_allocation),'failed large-width replacement clears old policy');
};
done_testing();
