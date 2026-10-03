use strict;
use warnings;
use lib 'perl';
use JSON::PP;
use Storable qw(dclone);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
my $json=JSON::PP->new->canonical;
my $adapter=FSM::Adapter::ISF->new;
my $id=$ARGV[0] // 'fifo_library_use';
die 'unowned source' unless $id eq 'fifo_library_use' || $id eq 'atl_resolved_child_pin_egress_vector_multi_pipeline';
my $actor=$adapter->parse_file("isf/$id.isf");
push @{$actor->{transactions}},$adapter->parse_source(
    '(actor scratch (transaction local_main (ports (input local_delay (width 4))) (wait local_delay)))',
    'reusable_products.isf')->{transactions}[0];
my $l=FSM::Scheduler::ISF->new->{ir};
my @steps=({stage=>'parsed',actor=>$json->decode($json->encode($actor))});
push @steps,{stage=>'storable_clone',actor=>$json->decode($json->encode($actor)),clone=>$json->decode($json->encode(dclone($actor)))};
my $p=$l->prepare_formal_source($actor);
push @steps,{stage=>'prepared',actor=>$json->decode($json->encode($actor)),
    prepared_actor=>$json->decode($json->encode($p->{actor}))};
my $m=$l->build_module($actor);
push @steps,{stage=>'built',actor=>$json->decode($json->encode($actor)),
    prepared_actor=>$json->decode($json->encode($p->{actor}))};
open my $out,'>:raw',"docs/audits/reusable-product-helper-causes-20261003/$id-input-steps.json" or die $!;
print {$out} $json->encode({steps=>\@steps}),"\n" or die $!;close $out or die $!;
print "Captured exact whole actor primitive kinds after each actual API.\n";
