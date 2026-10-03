use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use Test::More;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
my $base='docs/audits/caller-formal-binding-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw','t/1933-isf-caller-formal-binding-scope.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub source {');my $end=index($test,'for my $actor_kind', $start);
die 'helper slice missing' unless $start>=0 && $end>$start;
my $helpers=substr($test,$start,$end-$start);
our $lowerer=FSM::Scheduler::ISF::LoweringIR->new;
our $observed;
{
 no warnings 'redefine';
 *main::like=sub ($$;$) {
  my ($error,$pattern,$label)=@_;my ($first)=split /\n/,$error;
  $observed={error=>$error,matched=>$error=~$pattern?1:0,primary_matched=>$first=~$pattern?1:0};
  return Test::More::like($error,$pattern,$label);
 };
}
eval $helpers;die $@ if $@;
my @cases;
for my $actor_kind (qw(input output storage)) {
 for my $formal_kind (qw(input output)) {
  for my $actual ('value','(+ value observed)') {
   push @cases,{id=>join('/',qw(shadow input),$actor_kind,$formal_kind,$actual),args=>{actor_kind=>$actor_kind,formal=>"(ports ($formal_kind value (width 4)))",body=>"(do worker (bind (input payload $actual)))"},mutation=>{path=>['transactions',1,'ports','inputs',0,'width'],value=>8},pattern=>q{width (?:8 does not match actor signal 'value' width 4|4 does not match transaction port width 8)}};
  }
  push @cases,{id=>join('/',qw(shadow output),$actor_kind,$formal_kind),args=>{actor_kind=>$actor_kind,formal=>"(ports ($formal_kind value (width 4)))",callee=>'(ports (output result (width 4)))',body=>'(do worker (bind (output result value)))'},mutation=>{path=>['transactions',1,'ports','outputs',0,'width'],value=>8},pattern=>q{width 8 does not match actor signal 'value' width 4}};
 }
}
push @cases,
 {id=>'actor input write',args=>{actor_kind=>'input',formal=>'',callee=>'(ports (output result (width 8)))',body=>'(do worker (bind (output result value)))'},pattern=>q{targets actor input 'value'.*read-only}},
 {id=>'actor output read',args=>{actor_kind=>'output',formal=>'',callee=>'(ports (input payload (width 8)))'},pattern=>q{reads actor output 'value'.*readback}},
 {id=>'callee formal is not caller variable',args=>{actor_kind=>'none',formal=>'',callee=>'(ports (input value (width 4)))',body=>'(do worker (bind (input value value)))'},pattern=>q{unknown actor signal 'value'}},
 {id=>'rule scope',args=>{actor_kind=>'output'},rule=>1,pattern=>q{Rule 'dispatch'.*reads actor output 'value'}};
for my $spec (
 ['wrong direction','(do worker (bind (output payload value)))',q{uses role 'output'.*declares 'input'}],
 ['unknown callee port','(do worker (bind (input missing value)))',q{unknown transaction port 'missing'}],
 ['missing binding','(do worker)',q{requires '\(bind}],
 ['duplicate binding','(do worker (bind (input payload value) (input payload value)))',q{duplicate binding}],
 ['wrong timing','(do worker (bind (input payload value (timing live))))',q{requested timing 'live'.*activation_region}],
 ['live repeat','(repeat 1 (do worker (bind (input missing nonexistent))))',q{unknown transaction port 'missing'}],
) {push @cases,{id=>$spec->[0],args=>{actor_kind=>'storage',body=>$spec->[1]},pattern=>$spec->[2]}}
sub assign {
 my ($value,$path,$replacement)=@_;my $last=$path->[-1];
 for my $part (@$path[0..$#$path-1]) {$value=ref($value) eq 'ARRAY'?$value->[$part]:$value->{$part}}
 if (ref($value) eq 'ARRAY') {$value->[$last]=$replacement} else {$value->{$last}=$replacement}
}
sub first_bind {
 my ($node,$path)=@_;return unless ref($node);
 if (ref($node) eq 'ARRAY') {
  return [@$path,1,0] if @$node && !ref($node->[0]) && $node->[0] eq 'bind';
  for my $i (0..$#$node) {my $found=first_bind($node->[$i],[@$path,$i]);return $found if $found}
 } elsif (ref($node) eq 'HASH') {
  for my $key (sort keys %$node) {my $found=first_bind($node->{$key},[@$path,$key]);return $found if $found}
 }
 return;
}
my @rows;
for my $case (@cases) {
 my $source=source(%{$case->{args}});my $actor=parse($source);
 assign($actor,$case->{mutation}{path},$case->{mutation}{value}) if $case->{mutation};
 if ($case->{rule}) {$actor->{transactions}[0]{clauses}=[];$actor->{rules}=[{name=>'dispatch',actions=>[['trigger','worker',['bind',['input','payload','value']]]]}]}
 my $pattern=eval 'qr/'.$case->{pattern}.'/';die $@ if $@;
 for my $band (qw(current_fixture wrong_native_shape)) {
  my $input=dclone($actor);my $control;
  if ($band eq 'wrong_native_shape') {
   my $path=first_bind($input,[]);
   $control=$path?{path=>$path,value=>'bogus'}:{path=>['transactions',1,'ports','inputs',0,'_isf_formal_identity'],value=>{}};
   assign($input,$control->{path},$control->{value});
  }
  my $before=$json->encode($input);$observed=undef;
  rejects($input,$pattern,"$case->{id} / $band");
  die 'missing actual consumer capture' unless $observed;
  is($observed->{matched},$observed->{primary_matched},"$case->{id} / $band whole trace cannot qualify a different primary category");
  is($json->encode($input),$before,"$case->{id} / $band whole caller stays unchanged");
  push @rows,{id=>$case->{id},band=>$band,spec=>$case,source=>$source,actor=>$input,control=>$control,%$observed};
 }
}
open my $out,'>:raw',"$base/causes.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n";close $out or die $!;
done_testing;
