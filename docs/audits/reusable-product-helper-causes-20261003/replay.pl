use strict;
use warnings;
use JSON::PP;
my $base='docs/audits/reusable-product-helper-causes-20261003';
open my $fh,'<:raw',"$base/causes.json" or die $!;
my $json=JSON::PP->new->canonical;
my $data=$json->decode(do {local $/;<$fh>});close $fh or die $!;
my @rows;
for my $r (@{$data->{rows}}) {
    my $p=$r->{id} eq 'raw parent width conflict'
        ? qr/(?:width|Width).*payload|payload.*(?:width|Width)/s
        : $r->{id} eq 'library versus generated module collision'
        ? qr/conflicts with another generated child/
        : $r->{id} eq 'missing library actor'
        ? qr/does not carry a reusable actor shell/
        : $r->{id} eq 'unsupported ATL group composition'
        ? qr/cannot combine generated child wiring with static group metadata/
        : qr/missing a generated module name/;
    my ($primary)=split /\n/,$r->{error};
    push @rows,{matched=>$r->{error}=~$p?1:0,
        primary_matched=>$primary=~$p?1:0,pattern=>"$p"};
}
print $json->encode(\@rows),"\n";
