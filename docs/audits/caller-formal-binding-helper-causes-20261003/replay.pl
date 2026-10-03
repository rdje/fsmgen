use strict;
use warnings;
use JSON::PP;
my $base='docs/audits/caller-formal-binding-helper-causes-20261003';
open my $fh,'<:raw',"$base/causes.json" or die $!;
my $json=JSON::PP->new->canonical;
my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my @out;
for my $r (@$rows) {
 my $pattern=eval 'qr/'.$r->{spec}{pattern}.'/';die $@ if $@;
 my ($first)=split /\n/,$r->{error};
 push @out,{id=>$r->{id},band=>$r->{band},matched=>$r->{error}=~$pattern?1:0,primary_matched=>$first=~$pattern?1:0};
}
print $json->encode(\@out),"\n";
