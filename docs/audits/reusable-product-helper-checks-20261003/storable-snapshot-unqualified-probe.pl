use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use Test::More;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $base='docs/audits/reusable-product-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
our $l=FSM::Scheduler::ISF->new->{ir};
our ($a,@observations);
open my $fh,'<:raw','t/1947-isf-formal-reusable-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub refused {');my $end=index($test,"subtest '",$start);
die 'exact helper missing' unless $start>=0 && $end>$start;
my $helper=substr($test,$start,$end-$start);
$start=index($test,'eval {$l->build_module($a)};');$end=index($test,'my $physical = project($q);',$start);
die 'exact direct consumer missing' unless $start>=0 && $end>$start;
my $direct=substr($test,$start,$end-$start);
{
 no warnings 'redefine';
 *main::like=sub ($$;$) {
  my ($error,$pattern,$label)=@_;my ($primary)=split /\n/,$error;
  push @observations,{error=>$error,pattern=>"$pattern",matched=>$error=~$pattern?1:0,primary_matched=>defined($primary)&&$primary=~$pattern?1:0};
  return Test::More::like($error,$pattern,$label);
 };
}
# Compile exact consumer bodies before calls; active string-eval sources would
# contaminate diagnostic stacks with expectations.
eval $helper.'sub direct_consumer {'.$direct."\n}";die $@ if $@;
my ($mixed)=$test=~/my \$mixed = <<'ISF';\n(.*?)\nISF/s;die 'literal mixed source missing' unless defined $mixed;
$mixed.="\n";
my $adapter=FSM::Adapter::ISF->new;
my $mixed_actor=$adapter->parse_source($mixed,'reusable_products.isf');
my $atl=$adapter->parse_file('isf/atl_resolved_child_pipeline.isf');
open $fh,'<:raw','isf/atl_resolved_child_pipeline.isf' or die $!;my $atl_source=do {local $/;<$fh>};close $fh or die $!;
my @specs=(
 ['missing library module','missing a generated module name','mixed',sub {delete $_[0]{library_uses}[0]{module}}],
 ['library versus generated module collision','conflicts with another generated child','mixed',sub {$_[0]{library_uses}[0]{module}='worker'}],
 ['missing library actor','does not carry a reusable actor shell','mixed',sub {delete $_[0]{library_uses}[0]{actor}}],
 ['missing resolved ATL module','missing a generated module name','atl',sub {my ($key)=keys %{$_[0]{_atl_actor_type_resolutions}};delete $_[0]{_atl_actor_type_resolutions}{$key}{module}}],
 ['unsupported ATL group composition','cannot combine generated child wiring with static group metadata','atl',sub {$_[0]{actor_network}{groups}=[{name=>'grouped'}]}],
);
my @rows;
for my $spec (@specs) {
 my ($id,$wanted,$kind,$mutate)=@$spec;
 my $fixture=dclone($kind eq 'mixed'?$mixed_actor:$atl);$mutate->($fixture);
 for my $band (qw(current_fixture earlier_target primary_target_echo)) {
  my $submitted=dclone($fixture);
  if ($band ne 'current_fixture') {
   my $tx=$submitted->{transactions}[-1];
   unshift @{$tx->{clauses}},['spawn',$band eq 'primary_target_echo'?$wanted:'missing_child','as','wrong_job'];
  }
  my $before=dclone($submitted);@observations=();
  my $pattern = $id eq 'library versus generated module collision'
   ? qr/conflicts with another generated child/
   : $id eq 'missing library actor'
   ? qr/does not carry a reusable actor shell/
   : $id eq 'unsupported ATL group composition'
   ? qr/cannot combine generated child wiring with static group metadata/
   : qr/missing a generated module name/;
  refused($submitted,$pattern,$id);
  is_deeply($submitted,$before,"$id/$band submitted actor unchanged");
  is(scalar(@observations),2,"$id/$band observes both APIs");
  for my $i (0,1) {
   my $o=$observations[$i];
   is($o->{matched},$band eq 'current_fixture'?1:0,"$id/$band desired cause safety in ".(qw(prepare_formal_source build_module))[$i]);
   push @rows,{id=>$id,wanted=>$wanted,kind=>$kind,source=>$kind eq 'mixed'?$mixed:$atl_source,band=>$band,method=>(qw(prepare_formal_source build_module))[$i],actor_before=>$before,actor_after=>dclone($submitted),%$o};
  }
 }
}
(my $width_source=$mixed)=~s/\(transaction worker/(storage (var payload (width 8))) (transaction worker/;
my $width_actor=$adapter->parse_source($width_source,'reusable_products.isf');
for my $band (qw(current_fixture earlier_target primary_target_echo)) {
 $a=dclone($width_actor);
 if ($band ne 'current_fixture') {unshift @{$a->{transactions}[-1]{clauses}},['spawn',$band eq 'primary_target_echo'?'width payload':'missing_child','as','wrong_job']}
 my $before=dclone($a);@observations=();direct_consumer();
 is_deeply($a,$before,"direct/$band actor unchanged");
 is(scalar(@observations),1,"direct/$band observes actual consumer");
 is($observations[0]{matched},$band eq 'current_fixture'?1:0,"direct/$band desired width cause safety");
 push @rows,{id=>'raw parent width conflict',wanted=>'width/payload regex',kind=>'mixed',source=>$width_source,band=>$band,method=>'build_module',actor_before=>$before,actor_after=>dclone($a),%{$observations[0]}};
}
open my $out,'>:raw',"$base/causes.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n" or die $!;close $out or die $!;
done_testing;
