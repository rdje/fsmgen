use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
my $base='docs/audits/formal-source-context-helper-causes-20261003';
open my $fh,'<:raw','t/1936-isf-formal-source-context.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my ($source)=$test=~/my \$base = <<'ISF';\n(.*?)^ISF$/ms;die 'fixture extraction' unless defined $source;
for my $pair (
 ['(repeat ZERO','(repeat 1'],
 ['(do worker (bind','(do worker (params (COUNT 1)) (bind'],
 ['(transaction worker (ports (input data (width 4)))','(transaction worker (ports (input data (width 4))) (params (COUNT 1))'],
) {
 my ($from,$to)=@$pair;
 my $n=$source=~s/\Q$from\E/$to/;die 'mutation cardinality' unless $n==1;
}
open my $input,'>:raw',"$base/corrected-source.isf" or die $!;print {$input} $source;close $input or die $!;
my $actor=FSM::Adapter::ISF->new->parse_source($source,'source_context.isf');
my $before=JSON::PP->new->canonical->encode($actor);
my $accepted=eval {FSM::Scheduler::ISF::LoweringIR->new->prepare_formal_source($actor);1};
my $error=$@;
my $row={source=>$source,actor=>$actor,accepted=>$accepted?1:0,error=>$error,unchanged=>JSON::PP->new->canonical->encode($actor) eq $before?1:0};
open my $out,'>:raw',"$base/corrected-live.json" or die $!;print {$out} JSON::PP->new->canonical->encode($row),"\n";close $out or die $!;
print $error;
