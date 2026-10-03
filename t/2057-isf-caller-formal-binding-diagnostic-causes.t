use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Test::DiagnosticCause;

my $base='docs/audits/caller-formal-binding-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw',"$base/causes.json" or die $!;
my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my $context="Transaction 'caller': do target 'worker'";
my %reasons=(
    'actor input write'=>"$context output binding for port 'result' targets actor input 'value', but actor inputs are read-only",
    'actor output read'=>"$context input binding for port 'payload' reads actor output 'value', but actor output readback is not public",
    'callee formal is not caller variable'=>"$context binding for port 'value' references unknown actor signal 'value'",
    'rule scope'=>"Rule 'dispatch': trigger target 'worker' input binding for port 'payload' reads actor output 'value', but actor output readback is not public",
    'wrong direction'=>"$context binding for port 'payload' uses role 'output' but the transaction declares 'input'",
    'unknown callee port'=>"$context binds unknown transaction port 'missing' on 'worker'",
    'missing binding'=>"$context requires '(bind ...)' because transaction 'worker' declares ports",
    'duplicate binding'=>"Transaction 'caller': activation has duplicate binding for transaction port 'payload'",
    'wrong timing'=>"$context input binding for port 'payload' requested timing 'live', but this activation currently uses 'activation_region'; behavior-changing timing conversion is not supported yet",
    'live repeat'=>"Transaction 'caller': repeat-body do target 'worker' binds unknown transaction port 'missing' on 'worker'",
);
sub expected_cause {
    my ($id)=@_;
    return "$context binding for port 'result' width 8 does not match actor signal 'value' width 4"
        if $id =~ m{\Ashadow/output/};
    if ($id =~ m{\Ashadow/input/}) {
        return "$context input binding expression for port 'payload' width 4 does not match transaction port width 8"
            if $id =~ /\Q(+ value observed)\E\z/;
        return "$context binding for port 'payload' width 8 does not match actor signal 'value' width 4";
    }
    die "unknown declared case $id" unless exists $reasons{$id};
    return $reasons{$id};
}
sub assign {
    my ($value,$path,$replacement)=@_;
    for my $part (@$path[0..$#$path-1]) {
        $value=ref($value) eq 'ARRAY'?$value->[$part]:$value->{$part};
    }
    my $last=$path->[-1];
    if (ref($value) eq 'ARRAY') {$value->[$last]=dclone_value($replacement)}
    else {$value->{$last}=dclone_value($replacement)}
}
sub dclone_value {return ref($_[0])?dclone($_[0]):$_[0]}
open $fh,'<:raw','t/1933-isf-caller-formal-binding-scope.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub source {');my $end=index($test,'for my $actor_kind',$start);
die 'current helper block missing' unless $start>=0 && $end>$start;
my $helpers=substr($test,$start,$end-$start);
{
    package CallerBindingSubject;
    our (@assertions,$error);
    our $lowerer=FSM::Scheduler::ISF::LoweringIR->new;
    # Observe deliberate negative helper assertions without emitting failing TAP.
    # The default T1933 separately runs the actual Test::More consumers.
    sub ok {push @assertions,$_[0]?1:0;return $_[0]}
    sub diag {}
    sub diagnostic_cause_matches {
        $error=$_[0];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
eval 'package CallerBindingSubject;our $lowerer;'.$helpers;die $@ if $@;
my @captures;
for my $row (grep {$_->{band} eq 'current_fixture'} @$rows) {
    my $id=$row->{id};my $expected=expected_cause($id);
    my $actor=FSM::Adapter::ISF->new->parse_source($row->{source},'binding_scope.isf');
    my $spec=$row->{spec};
    assign($actor,$spec->{mutation}{path},$spec->{mutation}{value}) if $spec->{mutation};
    if ($spec->{rule}) {
        $actor->{transactions}[0]{clauses}=[];
        $actor->{rules}=[{name=>'dispatch',actions=>[['trigger','worker',['bind',['input','payload','value']]]]}];
    }
    for my $band (qw(positive wrong_native_shape label_echo)) {
        my $input=dclone($actor);
        if ($band ne 'positive') {
            my $path=$spec->{rule}?['rules',0,'actions',0,2,1,0]
                :$id eq 'missing binding'?['transactions',1,'ports','inputs',0,'_isf_formal_identity']
                :$id eq 'live repeat'?['transactions',0,'clauses',1,2,2,1,0]
                :['transactions',0,'clauses',1,2,1,0];
            assign($input,$path,$id eq 'missing binding'?{}:'bogus');
        }
        my $before=$json->encode($input);
        @CallerBindingSubject::assertions=();$CallerBindingSubject::error=undef;
        my $label="$id / $band".($band eq 'label_echo'?" / $expected":'');
        CallerBindingSubject::rejects($input,$expected,$label);
        is_deeply(\@CallerBindingSubject::assertions,[1,$band eq 'positive'?1:0],
            "$id / $band qualifies only its complete cause");
        my $primary=$band eq 'positive'?$expected
            :$id eq 'missing binding'?"Transaction 'worker': malformed or stale formal identity projection"
            :$spec->{rule}?"Transaction 'dispatch': activation bind role must be input or output"
            :"Transaction 'caller': activation bind role must be input or output";
        is((split /\n/,$CallerBindingSubject::error)[0],$primary,"$id / $band actual primary cause");
        is($json->encode($input),$before,"$id / $band whole actor stays unchanged");
        push @captures,{id=>$id,band=>$band,source=>$row->{source},actor=>$input,
            expected_cause=>$expected,label=>$label,error=>$CallerBindingSubject::error,
            assertions=>[@CallerBindingSubject::assertions]};
    }
}
if (defined $ENV{FSMGEN_CALLER_BINDING_CAUSE_CAPTURE}) {
    open my $out,'>:raw',$ENV{FSMGEN_CALLER_BINDING_CAUSE_CAPTURE} or die $!;
    print {$out} $json->encode({rows=>\@captures}),"\n" or die $!;
    close $out or die $!;
}
done_testing;
