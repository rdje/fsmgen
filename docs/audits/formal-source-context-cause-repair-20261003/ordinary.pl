use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF::LoweringIR;
my $base='docs/audits/formal-source-context-cause-repair-20261003';
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw','docs/audits/formal-source-context-helper-causes-20261003/products.json' or die $!;
my $old=$json->decode(do {local $/;<$fh>});close $fh or die $!;
my %products;
for my $name (sort keys %$old) {
 my $source=$old->{$name}{source};my $actor=FSM::Adapter::ISF->new->parse_source($source,'source_context.isf');
 my $before=$json->encode($actor);
 my $prepared=FSM::Scheduler::ISF::LoweringIR->new->prepare_formal_source($actor);
 die 'source mutation' unless $json->encode($actor) eq $before;
 $products{$name}={source=>$source,actor=>$actor,prepared=>$prepared};
 die 'whole product drift' unless $json->encode($products{$name}) eq $json->encode($old->{$name});
}
open my $out,'>:raw',"$base/products.json" or die $!;print {$out} $json->encode(\%products),"\n";close $out or die $!;
print "PASS whole ordinary source/preparation products and kinds versus immutable diagnosis.\n";
