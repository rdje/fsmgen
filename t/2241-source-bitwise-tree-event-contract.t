use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Backend::VerilogFamily::DeclarationCapture;
use FSM::SourceBitwiseTreePolicySupport;
my $json=JSON::PP->new->canonical;
my $available=FSM::SourceBitwiseTreePolicySupport->can('copy_origin');
sub tree {
    my ($names)=@_;my $t=['signal',$names->[0]];
    $t=['&',$t,['signal',$names->[$_]]] for 1..$#$names;
    return $t;
}
sub origin {
    my ($names)=@_;$names//=[qw(A B C)];
    return {kind=>'source_bitwise_tree',operator=>'&',source_names=>[@$names],expression_tree=>tree($names)};
}
sub policy {
    my ($names,$width)=@_;my $o=origin($names);
    return {%$o,kind=>'source_bitwise_tree_operand_max',selected_width=>$width//8};
}
sub event {
    my ($names,$width)=@_;
    return {expression=>'A & B & C',source_tree_origin=>origin($names),source_tree_width_allocation=>policy($names,$width)};
}
sub capture {
    my ($widths,$result,$event,%options)=@_;
    my $c=FSM::Backend::VerilogFamily::DeclarationCapture->new;$c->begin_module('tree_event');
    $c->record_intermediate_declaration({name=>'R',width=>$result,signed=>0,%{$options{result}//{}}});
    for my $name (sort keys %$widths) {
        $c->record_declaration('ports',{name=>$name,width=>$widths->{$name},signed=>0,%{$options{$name}//{}}});
    }
    my $ok=eval {$c->record_intermediate_assignment('R',$event);$c->complete;1};
    return ($ok,$c,$@);
}
sub refuses {
    my ($event,%options)=@_;
    my ($ok,$c,$error)=capture({A=>8,B=>4,C=>2},8,$event,%options);
    ok(!$ok,'invalid source tree event refuses');
    like($error,qr/tree|allocation|origin|family/i,'diagnostic names the selected data contract');
    ok(!eval {$c->snapshot;1},'invalid event exposes no partial snapshot');
}

subtest 'closed selected tree joins all ordered declarations and exact independent maxima' => sub {
    for my $case (
        [{A=>8,B=>4,C=>2},8,[qw(A B C)],'008'],
        [{A=>1,B=>8,C=>4},8,[qw(C A B)],8],
        [{A=>8,B=>4,C=>2},8,[qw(A B A)],8],
        [{A=>1,B=>1,C=>1},1,[qw(A B C)],1],
        [{A=>'18446744073709551616',B=>'18446744073709551617',C=>2},'18446744073709551617',[qw(A B C)],'18446744073709551617'],
    ) {
        my ($widths,$result,$names,$selected)=@$case;my $e=event($names,$selected);my $before=$json->encode($e);
        my ($ok,$c,$error)=capture($widths,$result,$e);
        ok($ok,'closed tree policy completes with exact declared maximum') or diag $error;
        next unless $ok;
        is($json->encode($e),$before,'caller record and scalar JSON kinds preserve');
        is($json->encode($c->snapshot->{target_intermediates}{R}),$before,'complete selected tree event detaches unchanged');
        $e->{source_tree_origin}{expression_tree}[1][1][1]='FOREIGN';
        my $copy=$c->snapshot;$copy->{target_intermediates}{R}{source_tree_width_allocation}{source_names}[0]='OTHER';
        is($json->encode($c->snapshot->{target_intermediates}{R}),$before,'caller and snapshot nested mutations cannot change collector');
    }
};

subtest 'syntactic origin without policy preserves independent contextual widths and mixed nodes' => sub {
    plan skip_all=>'source tree schema absent' unless $available;
    for my $width (1,8,32) {
        my $o=origin();$o->{operator}='|';$o->{expression_tree}[0]='|';$o->{expression_tree}[1][0]='^';
        my $e={expression=>'(A ^ B) | C',source_tree_origin=>$o};
        my ($ok,$c,$error)=capture({A=>8,B=>4,C=>2},$width,$e,A=>{signed=>1});
        ok($ok,'plain syntactic tree does not assert result max or unsigned source proof') or diag $error;
        is($json->encode($c->snapshot->{target_intermediates}{R}),$json->encode($e),'origin-only event keeps existing contextual constraints') if $ok;
    }
    my $mixed=origin();$mixed->{operator}='|';$mixed->{expression_tree}[0]='|';$mixed->{expression_tree}[1][0]='^';
    my $e={expression=>'(A ^ B) | C',source_tree_origin=>$mixed,
        source_tree_width_allocation=>{%$mixed,kind=>'source_bitwise_tree_operand_max',selected_width=>'8'}};
    my ($ok,$c,$error)=capture({A=>8,B=>4,C=>2},8,$e);
    ok($ok,'mixed original bitwise tree also qualifies exact max policy') or diag $error;
    is($json->encode($c->snapshot->{target_intermediates}{R}),$json->encode($e),'complete mixed policy and scalar kinds preserve') if $ok;
};

subtest 'malformed conflicting and differently associated tree records invalidate atomically' => sub {
    plan skip_all=>'source tree schema absent' unless $available;
    my $cycle=['&'];push @$cycle,$cycle,['signal','C'];
    for my $bad (undef,{}, {%{origin()},extra=>1},{%{origin()},kind=>'binary_bitwise'},
        {%{origin()},source_names=>[qw(B A C)]},{%{origin()},expression_tree=>$cycle},origin([qw(A B R)])) {
        refuses({expression=>'A & B & C',source_tree_origin=>$bad});
    }
    my $other=policy();$other->{expression_tree}=['&',['signal','A'],['&',['signal','B'],['signal','C']]];
    for my $bad (undef,{}, {%{policy()},extra=>1},{%{policy()},selected_width=>0},policy(undef,32),$other) {
        refuses({expression=>'A & B & C',source_tree_origin=>origin(),source_tree_width_allocation=>$bad});
    }
    refuses({expression=>'A & B & C',source_tree_width_allocation=>policy()});
    for my $other (
        {bitwise_origin=>{kind=>'binary_bitwise',operator=>'&',source_names=>[qw(A B)]}},
        {arithmetic_origin=>{kind=>'binary_arithmetic',operator=>'+',source_names=>[qw(A B)]}},
        {width_allocation=>{kind=>'binary_operand_max',operator=>'&',source_names=>[qw(A B)],selected_width=>8}},
    ) {refuses({%{event()},%$other})}
};

subtest 'every declared leaf and plain result leaf profile are required only with policy' => sub {
    plan skip_all=>'source tree schema absent' unless $available;
    for my $fields ({signed=>1},{declared_type_name=>'word_t'},{declared_type_spec=>{kind=>'bits',width=>8}},{state_model=>'enum'}) {
        refuses(event(),C=>$fields);
        refuses(event(),result=>$fields);
    }
    for my $e (event(),{expression=>'A & B & C',source_tree_origin=>origin()}) {
        my ($ok,$c)=capture({A=>8,B=>4},8,$e);
        ok(!$ok,'third original leaf needs an actual declaration even without policy');
        ok(!eval {$c->snapshot;1},'missing final leaf invalidates completion');
    }
};

subtest 'origin shares existing shape bounds and rejects binary or over-bound data before encoding' => sub {
    plan skip_all=>'source tree schema absent' unless $available;
    my $valid=origin([map {'N'.$_} 0..64]);
    ok(eval {FSM::SourceBitwiseTreePolicySupport->copy_origin($valid);1},'existing64-level origin boundary qualifies');
    for my $o (origin([qw(A B)]),origin([map {'N'.$_} 0..65])) {
        ok(!eval {FSM::SourceBitwiseTreePolicySupport->copy_origin($o);1},'binary-only or over-bound origin refuses');
    }
};

subtest 'new transaction resets optional fields and failed transaction can be reused' => sub {
    plan skip_all=>'source tree schema absent' unless $available;
    my ($ok,$c)=capture({A=>8,B=>4,C=>2},8,event());ok($ok,'initial selected tree completes');
    $c->begin_module('empty');$c->complete;
    ok(!exists($c->snapshot->{target_intermediates}),'empty reuse retains old empty snapshot shape');
    $c->begin_module('invalid');
    eval {$c->record_intermediate_assignment('R',event())};
    ok(!eval {$c->snapshot;1},'missing active declaration invalidates reuse');
    $c->begin_module('fresh');$c->complete;
    is($c->snapshot->{target_namespace}{module_name},'fresh','fresh successful transaction recovers');
};

done_testing();
