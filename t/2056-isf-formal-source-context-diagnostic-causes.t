use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use FSM::Test::DiagnosticCause;

my $base='docs/audits/formal-source-context-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
sub read_json {
    open my $fh,'<:raw',$_[0] or die $!;
    my $raw=do {local $/;<$fh>};
    close $fh or die $!;
    return $json->decode($raw);
}
my $old=read_json("$base/causes.json");
my $live=read_json("$base/corrected-live.json");
my %sources=map {$_->{id}=>$_->{input}} grep {$_->{band} eq 'current_fixture'} @{$old->{rows}};
my @cases=(
    ['static parameter boundary',$sources{'live binding'},"Transaction 'main': when-body nested repeat generated do bindings require static '(params ...)' overrides in the current nested generated blocking-do subset"],
    ['live binding',$live->{source},"Transaction 'main': repeat-body do target 'worker' binds unknown transaction port 'missing' on 'worker'"],
    ['malformed dead binding',$sources{'malformed dead binding'},"Transaction 'main': do target 'worker' bind entries must be '(input port expr [(timing snapshot|live)])' or '(output port signal)'"],
    ['unknown dead target',$sources{'unknown dead target'},"Transaction 'main': do target 'absent' is not a declared transaction"],
    ['local option',$sources{'local option'},"Transaction 'main': unsupported local option 'typo'"],
    ['wait operator',$sources{'wait operator'},"Transaction 'main': runtime dynamic wait count expression '(bogus count)' must use a supported expression operator shape in transaction body"],
    ['nested local',$sources{'nested local'},"Transaction 'main': unsupported '(local ...)' clause in repeat body"],
);
open my $fh,'<:raw','t/1936-isf-formal-source-context.t' or die $!;
my $source=do {local $/;<$fh>};close $fh or die $!;
my $start=index($source,'sub rejects {');my $end=index($source,"\n}\n",$start)+3;
die 'current helper missing' unless $start>=0 && $end>$start;
my $helper=substr($source,$start,$end-$start);
{
    package SourceContextSubject;
    our (@assertions,$error);
    our $lowerer=FSM::Scheduler::ISF::LoweringIR->new;
    sub prepare { $lowerer->prepare_formal_source(FSM::Adapter::ISF->new->parse_source($_[0],'source_context.isf')) }
    # Observe assertion bits so intentional negative helper calls do not emit
    # failing TAP. The actual current helper and real failing API remain intact.
    sub ok {push @assertions,$_[0]?1:0}
    sub diagnostic_cause_matches {
        $error=$_[0];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
eval 'package SourceContextSubject;'.$helper;die $@ if $@;
my @captures;
for my $case (@cases) {
    my ($id,$positive,$expected)=@$case;
    for my $band (qw(positive wrong_parser source_echo)) {
        my $input=$band eq 'positive'?$positive:$band eq 'source_echo'?'; '.$expected."\n(not_actor)":'(not_actor)';
        @SourceContextSubject::assertions=();
        $SourceContextSubject::error=undef;
        SourceContextSubject::rejects($input,$expected,"$id / $band");
        is_deeply(\@SourceContextSubject::assertions,[1,$band eq 'positive'?1:0],
            "$id / $band reports its actual complete cause");
        is((split /\n/,$SourceContextSubject::error)[0],
            $band eq 'positive'?$expected:"Error: no (actor ...) root found in 'source_context.isf'",
            "$id / $band actual primary cause");
        push @captures,{id=>$id,band=>$band,input=>$input,expected_cause=>$expected,
            error=>$SourceContextSubject::error,assertions=>[@SourceContextSubject::assertions]};
    }
}
if (defined $ENV{FSMGEN_SOURCE_CONTEXT_CAUSE_CAPTURE}) {
    open my $out,'>:raw',$ENV{FSMGEN_SOURCE_CONTEXT_CAUSE_CAPTURE} or die $!;
    print {$out} $json->encode({rows=>\@captures}),"\n" or die $!;
    close $out or die $!;
}
done_testing;
