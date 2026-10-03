use strict;
use warnings;
use JSON::PP;
my $base='docs/audits/formal-source-context-helper-causes-20261003';
open my $fh,'<:raw',"$base/causes.json" or die $!;my $raw=do {local $/;<$fh>};close $fh or die $!;
my $json=JSON::PP->new->canonical;my @rows;
for my $r (@{$json->decode($raw)->{rows}}) {
 my $pattern=eval 'qr/'.$r->{pattern}.'/';die $@ if $@;
 my ($primary)=split /\n/,$r->{error};
 push @rows,{id=>$r->{id},band=>$r->{band},matched=>$r->{error}=~$pattern?1:0,primary_matched=>$primary=~$pattern?1:0};
}
print $json->encode(\@rows),"\n";
