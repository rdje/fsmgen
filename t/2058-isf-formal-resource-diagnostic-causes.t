use strict;
use warnings;
use lib 'perl','t/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use FSM::Scheduler::ISF;
use FSM::Test::DiagnosticCause;

my $base='docs/audits/formal-resource-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
sub read_json {
    open my $fh,'<:raw',$_[0] or die $!;
    my $value=$json->decode(do {local $/;<$fh>});close $fh or die $!;
    return $value;
}
my $helper=read_json("$base/causes.json");
my $direct=read_json("$base/direct-causes.json");
my %reasons=(
    'raw formal alias'=>"ISF resource arbitration 'isf_resource_round_robin_pointer_collision' on resource 'shared_bus': generated round_robin pointer 'isf_rr_shared_bus_turn' collides with an existing actor symbol",
    'fixed'=>"ISF resource arbitration 'isf_resource_round_robin_pointer_collision' on resource 'shared_bus': generated round_robin pointer 'isf_rr_shared_bus_turn' collides with an existing actor symbol",
    'unknown_user'=>"ISF resource arbitration 'isf_resource_unknown_user' on resource 'shared_bus': user 'missing' is not a lowered rule",
    'overlap'=>"ISF resource arbitration 'isf_resource_round_robin_user_overlap' on resource 'other': rule user 'user0' is already bound to round_robin resource 'shared_bus'",
    'malformed name'=>"ISF resource arbitration 'isf_resource_round_robin_name_shape' on resource 'shared-bus': round_robin resource names must be HDL identifiers because FSMGen generates pointer storage from the resource name",
    'unsupported kind'=>"ISF resource arbitration 'isf_resource_unsupported_kind' on resource 'shared_bus': resource kind 'backlog_kind' is not enforced yet",
);
open my $fh,'<:raw','t/1944-isf-formal-resource-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub rejected {');my $end=index($test,"subtest '",$start);
die 'current rejection helper missing' unless $start>=0 && $end>$start;
my $rejected=substr($test,$start,$end-$start);
$start=index($test,'my $bad_name_ok = eval');$end=index($test,'rejected($bad_name,',$start);
die 'current direct assertion missing' unless $start>=0 && $end>$start;
my $direct_consumer=substr($test,$start,$end-$start);
{
    package ResourceCauseSubject;
    our ($lowerer,$bad_name,$error,@assertions);
    $lowerer=FSM::Scheduler::ISF->new->{ir};
    # Deliberate negative calls observe assertion bits. The default T1944
    # independently executes the real Test::More consumers.
    sub ok {push @assertions,$_[0]?1:0;return $_[0]}
    sub diag {}
    sub diagnostic_cause_matches {
        $error=$_[0];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
# Compile before failing API calls; an active consumer-string eval would echo
# wanted text into the stack and contaminate prior-consumer comparisons.
eval 'package ResourceCauseSubject;our ($lowerer,$bad_name);'
    .$rejected.'sub direct_consumer {'.$direct_consumer."\n}";die $@ if $@;
my @captures;
for my $consumer (qw(helper direct)) {
    my $rows=$consumer eq 'helper'?$helper->{rows}:$direct->{rows};
    for my $row (@$rows) {
        my $id=$consumer eq 'helper'?$row->{id}:'malformed name';
        my $expected=$reasons{$id};die 'unowned fixture' unless defined $expected;
        my $actor=dclone($row->{actor_before});my $before=$json->encode($actor);
        @ResourceCauseSubject::assertions=();$ResourceCauseSubject::error=undef;
        if ($consumer eq 'helper') {
            ResourceCauseSubject::rejected($actor,$expected,"$id / $row->{band}");
        } else {
            $ResourceCauseSubject::bad_name=$actor;
            ResourceCauseSubject::direct_consumer();
        }
        is_deeply(\@ResourceCauseSubject::assertions,[1,$row->{band} eq 'current_fixture'?1:0],
            "$consumer / $id / $row->{band} qualifies only its complete cause");
        my $code=$consumer eq 'helper'?$row->{code}:'isf_resource_round_robin_name_shape';
        my $primary=$row->{band} eq 'current_fixture'?$expected
            :"Transaction 'main': unsupported '(".($row->{band} eq 'primary_body_echo'?$code:'unsupported_clause')." ...)' clause in transaction body";
        is((split /\n/,$ResourceCauseSubject::error)[0],$primary,
            "$consumer / $id / $row->{band} actual primary cause");
        is($json->encode($actor),$before,"$consumer / $id / $row->{band} complete actor stays unchanged");
        push @captures,{consumer=>$consumer,id=>$id,band=>$row->{band},source=>$row->{source},
            actor=>$actor,expected_cause=>$expected,error=>$ResourceCauseSubject::error,
            assertions=>[@ResourceCauseSubject::assertions]};
    }
}
if (defined $ENV{FSMGEN_RESOURCE_CAUSE_CAPTURE}) {
    open my $out,'>:raw',$ENV{FSMGEN_RESOURCE_CAUSE_CAPTURE} or die $!;
    print {$out} $json->encode({rows=>\@captures}),"\n" or die $!;close $out or die $!;
}
done_testing;
