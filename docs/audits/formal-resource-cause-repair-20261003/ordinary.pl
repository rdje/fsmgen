use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $base='docs/audits/formal-resource-cause-repair-20261003';
my $json=JSON::PP->new->canonical;
open my $fh,'<:raw','t/1944-isf-formal-resource-products.t' or die $!;
my $test=do {local $/;<$fh>};close $fh or die $!;
my $start=index($test,'sub parse {');my $end=index($test,'sub prior_names {',$start);
die 'literal source helpers missing' unless $start>=0 && $end>$start;
eval substr($test,$start,$end-$start);die $@ if $@;
my @rows;
for my $case ((map {[$_,3]} qw(rule_slot output_bundle transaction_start storage_port)),['rule_slot',1],['rule_slot',2],['rule_slot',5]) {
    my ($kind,$count)=@$case;my $source=source($kind,$count);my $actor=parse($source);
    my $before=$json->encode($actor);my $lowerer=FSM::Scheduler::ISF->new->{ir};
    my $prepared=$lowerer->prepare_formal_source($actor);my $module=$lowerer->build_module($actor);
    die 'ordinary source mutation' unless $before eq $json->encode($actor);
    die 'prepared actor drift' unless $before eq $json->encode($prepared->{actor});
    push @rows,{kind=>$kind,count=>$count,source=>$source,actor=>$actor,prepared=>$prepared,module=>$module};
}
open my $out,'>:raw',"$base/products.json" or die $!;print {$out} $json->encode({rows=>\@rows}),"\n";close $out or die $!;
print 'PASS seven ordinary whole resource actors/preparation/modules and source isolation.',"\n";
