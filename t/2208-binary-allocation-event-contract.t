use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use FSM::Backend::VerilogFamily::DeclarationCapture;
my $json=JSON::PP->new->canonical;
sub row {{name=>$_[0],width=>$_[1],signed=>0}}
sub origin {{kind=>'binary_bitwise',operator=>'&',source_names=>[@{$_[0]//['A','B']}]}}
sub policy {{kind=>'binary_operand_max',operator=>'&',source_names=>[@{$_[0]//['A','B']}],selected_width=>$_[1]//8}}
sub capture {
    my ($aw,$bw,$rw,$event,%options)=@_;
    my $c=FSM::Backend::VerilogFamily::DeclarationCapture->new;$c->begin_module('event');
    $c->record_intermediate_declaration(row('R',$rw));
    $c->record_declaration('ports',{%{row('A',$aw)},%{$options{a}//{}}});
    $c->record_declaration('ports',row('B',$bw)) unless $options{missing_b};
    my $ok=eval {$c->record_intermediate_assignment('R',$event);$c->complete;1};my $error=$@;
    return ($ok,$c,$error);
}
subtest 'closed allocation policy joins exact ordered origin and independent actual declarations' => sub {
    for my $case ([8,4,8,['A','B'],8],[1,8,8,['B','A'],8],[8,1,8,['A','A'],8],[1,1,1,['A','B'],'001'],['18446744073709551617','18446744073709551616','18446744073709551617',['A','B'],'18446744073709551617']) {
        my($aw,$bw,$rw,$names,$selected)=@$case;my $event={expression=>join(' & ',@$names),bitwise_origin=>origin($names),width_allocation=>policy($names,$selected)};
        my $before=$json->encode($event);my($ok,$c,$error)=capture($aw,$bw,$rw,$event);
        ok($ok,'closed intrinsic policy completes with exact actual widths') or diag $error;
        next unless $ok;
        is($json->encode($event),$before,'input field kinds preserve');
        is_deeply($c->snapshot->{target_intermediates}{R},$event,'optional field and selected JSON kind detach unchanged');
        $event->{width_allocation}{source_names}[0]='WRONG';
        my $snapshot=$c->snapshot;$snapshot->{target_intermediates}{R}{width_allocation}{source_names}[0]='OTHER';
        is($c->snapshot->{target_intermediates}{R}{width_allocation}{source_names}[0],$names->[0],'both input/output nested policy detach');
    }
};
subtest 'no policy keeps contextual result widths independent' => sub {
    for my $rw (1,8,32) {
        my $event={expression=>'A & B',bitwise_origin=>origin};my($ok,$c,$error)=capture(8,8,$rw,$event);
        ok($ok,'legacy narrow/equal/wide result remains accepted') or diag $error;
        is_deeply($c->snapshot->{target_intermediates}{R},$event,'legacy event shape unchanged');
    }
};
subtest 'malformed conflicting or width-inconsistent policies invalidate atomically' => sub {
    for my $bad (
        undef,{}, {%{policy()},extra=>1}, {%{policy()},kind=>'other'}, {%{policy()},operator=>'|'},
        policy(['B','A']),policy(['A']),policy(['A','R']),policy(['A','FOREIGN']),
        {%{policy()},selected_width=>0},{%{policy()},selected_width=>[]},policy(['A','B'],32),
    ) {
        my($ok,$c,$error)=capture(8,4,8,{expression=>'A & B',bitwise_origin=>origin,width_allocation=>$bad});
        ok(!$ok,'invalid optional policy refuses');like($error,qr/allocation/i,'error identifies allocation contract');
        ok(!eval {$c->snapshot;1},'invalid transaction exposes no partial snapshot');
    }
    for my $event (
        {expression=>'A & B',width_allocation=>policy},
        {expression=>'&A',reduction_origin=>{kind=>'scalar_reduction',operator=>'&',source_name=>'A'},width_allocation=>policy},
    ) {
        my($ok,$c)=capture(8,4,1,$event);ok(!$ok,'policy requires coherent binary origin');ok(!eval {$c->snapshot;1},'origin conflict invalidates');
    }
    for my $widths ([8,16,8],[8,4,1],[8,4,32],['18446744073709551616','18446744073709551617','18446744073709551616']) {
        my($ok,$c)=capture(@$widths,{expression=>'A & B',bitwise_origin=>origin,width_allocation=>policy(['A','B'],$widths->[2])});
        ok(!$ok,'actual selected result must equal exact operand maximum');ok(!eval {$c->snapshot;1},'actual width mismatch invalidates');
    }
};
subtest 'actual declaration membership and plain unsigned profiles are required only with policy' => sub {
    for my $options (
        {missing_b=>1},{a=>{signed=>1}},{a=>{declared_type_name=>'word_t'}},{a=>{declared_type_spec=>{kind=>'bits',width=>8}}},{a=>{state_model=>'enum'}},
    ) {
        my($ok,$c)=capture(8,4,8,{expression=>'A & B',bitwise_origin=>origin,width_allocation=>policy},%$options);
        ok(!$ok,'missing or typed actual operand refuses policy');ok(!eval {$c->snapshot;1},'unsupported actual membership/profile invalidates');
    }
    my($ok,$c,$error)=capture(8,4,8,{expression=>'A & B',bitwise_origin=>origin},a=>{signed=>1});
    ok($ok,'legacy syntactic origin retains existing signed numeric declarations') or diag $error;
};
subtest 'new transaction clears prior optional fields' => sub {
    my($ok,$c)=capture(8,4,8,{expression=>'A & B',bitwise_origin=>origin,width_allocation=>policy});
    ok($ok,'policy transaction succeeds');return unless $ok;
    $c->begin_module('empty');$c->complete;
    ok(!exists($c->snapshot->{target_intermediates}),'reuse retains original empty snapshot shape');
};
done_testing();
