use strict;
use warnings;
use lib 'perl', 't/lib';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
use Test::More;
my $base='docs/audits/formal-source-context-cause-repair-20261003/prior';
my $json=JSON::PP->new->canonical;
open my $fh,'-|','git','show','4ed8478c149cf632238dd120570756c96c717dcb:t/1936-isf-formal-source-context.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my ($direct)=$test=~/my \$source = <<'ISF';\n(.*?)^ISF$/ms;
my ($zero)=$test=~/my \$base = <<'ISF';\n(.*?)^ISF$/ms;
die 'fixture extraction failed' unless defined $direct && defined $zero;
my $start=index($test,'sub rejects {');my $end=index($test,"\n}\n",$start)+3;
die 'helper extraction failed' unless $start>=0 && $end>$start;
my $helper=substr($test,$start,$end-$start);
our $lowerer=FSM::Scheduler::ISF::LoweringIR->new;
sub parse {FSM::Adapter::ISF->new->parse_source($_[0],'source_context.isf')}
sub prepare {$lowerer->prepare_formal_source(parse($_[0]))}
our $observed;
# Capture the raw error at the actual Test::More consumer boundary. Run the
# unchanged full rejects helper; only its imported assertion sink is observed.
# Test::More imports like, so replace that alias explicitly after import.
{
 no warnings 'redefine';
 *main::like=sub {my ($error,$pattern,$label)=@_;$observed={error=>$error,matched=>$error=~$pattern?1:0};return Test::More::like($error,$pattern,$label)};
}
eval $helper;die $@ if $@;
my @spec=(
 ['live binding',$zero,'(repeat ZERO','(repeat 1',q{unknown transaction port 'missing'}],
 ['malformed dead binding',$zero,'(input missing unknown)','(input missing)',q{bind.*(?:entries|input|requires)}],
 ['unknown dead target',$zero,'(do worker','(do absent',q{not a declared transaction}],
 ['local option',$direct,'(local scratch (width 4) (init 1))','(local scratch (width 4) (typo 1))',q{unsupported local option}],
 ['wait operator',$direct,'(wait count)','(wait (bogus count))',q{supported expression operator shape}],
 ['nested local',$direct,'(repeat count (set value count))','(repeat count (local nested (width 4)))',q{unsupported.*local}],
);
my %echo=('live binding'=>q{unknown transaction port 'missing'},'malformed dead binding'=>'bind input','unknown dead target'=>'not a declared transaction','local option'=>'unsupported local option','wait operator'=>'supported expression operator shape','nested local'=>'unsupported local');
my @rows;
for my $spec (@spec) {
 my ($id,$source,$from,$to,$pattern_text)=@$spec;
 my $count=($source=~s/\Q$from\E/$to/);die 'mutation cardinality' unless $count==1;
 my $pattern=eval 'qr/'.$pattern_text.'/';die $@ if $@;
 for my $band (qw(current_fixture wrong_parser wrong_parser_isolated source_echo_isolated)) {
    my $input=$band eq 'current_fixture'?$source:$band eq 'source_echo_isolated'?'; '.$echo{$id}."\n(not_actor)":'(not_actor)';
    $observed=undef;
    if ($band eq 'wrong_parser_isolated' || $band eq 'source_echo_isolated') {
      my $ok=eval {prepare($input);1};my $error=$@;
      $observed={error=>$error,matched=>$error=~$pattern?1:0};
      ok(!$ok,"$id / isolated actually refuses");
      is((split /\n/,$error)[0],"Error: no (actor ...) root found in 'source_context.isf'","$id / isolated actual primary cause");
    } else {
      rejects($input,$pattern,"$id / $band");
    }
    die 'missing capture' unless $observed;
    is($observed->{matched},$band eq 'current_fixture' && $id ne 'live binding'?1:0,"$id / $band has its declared primary cause");
    my ($first)=split /\n/,$observed->{error};
    push @rows,{id=>$id,band=>$band,input=>$input,pattern=>$pattern_text,primary_matched=>$first=~$pattern?1:0,%$observed};
 }
}
my %products;
for my $pair (['direct',$direct],['zero',$zero]) {
 my ($id,$source)=@$pair;
 my $actor=parse($source);my $before=$json->encode($actor);
 my $prepared=$lowerer->prepare_formal_source($actor);
 is($json->encode($actor),$before,"$id ordinary source remains unchanged");
 is($json->encode($prepared->{actor}),$before,"$id complete prepared actor equals source");
 $products{$id}={source=>$source,actor=>$actor,prepared=>$prepared};
}
open my $out,'>:raw',"$base/causes.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n";close $out or die $!;
open $out,'>:raw',"$base/products.json" or die $!;print {$out} $json->encode(\%products),"\n";close $out or die $!;
done_testing;
