use strict;
use warnings;
use Carp;
use JSON::PP;
open my $fh,'<:raw','docs/audits/prepared-reservation-helper-causes-20261003/causes.json' or die $!;
my $rows=JSON::PP->new->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
print "Carp public VERSION=$Carp::VERSION MaxArgLen=$Carp::MaxArgLen\n";
for my $row (@$rows) {
 next if $row->{direct} || $row->{band} ne 'earlier_reference' || $row->{assertions}[1];
 print "$row->{label}\npattern=$row->{pattern}\n$row->{error}";
}
