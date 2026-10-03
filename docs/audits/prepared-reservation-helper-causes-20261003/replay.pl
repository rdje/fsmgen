use strict;
use warnings;
use JSON::PP;
open my $fh,'<:raw','docs/audits/prepared-reservation-helper-causes-20261003/causes.json' or die $!;
my $json=JSON::PP->new->canonical;my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
my @bits;
for my $row (@$rows) {
 my ($body)=$row->{pattern}=~/\A\(\?\^:(.*)\)\z/s;die 'pattern flags' unless defined $body;
 my $pattern=qr/$body/;die 'pattern spelling' unless "$pattern" eq $row->{pattern};
 push @bits,[$row->{error}=~$pattern?1:0,(split /\n/,$row->{error})[0]=~$pattern?1:0];
}
print $json->encode(\@bits),"\n";
