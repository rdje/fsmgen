use strict;
use warnings;
use JSON::PP;
my $base='docs/audits/formal-resource-helper-causes-20261003';my $json=JSON::PP->new->canonical;my %out;
for my $name (qw(helper direct)) {
 open my $fh,'<:raw',"$base/".($name eq 'helper'?'causes.json':'direct-causes.json') or die $!;
 my $rows=$json->decode(do {local $/;<$fh>})->{rows};close $fh or die $!;
 $out{$name}=[map {my $code=$name eq 'helper'?$_->{code}:'isf_resource_round_robin_name_shape';my $pattern=qr/\Q$code\E/;my ($first)=split /\n/,$_->{error};{matched=>$_->{error}=~$pattern?1:0,primary_matched=>$first=~$pattern?1:0}} @$rows];
}
print $json->encode(\%out),"\n";
