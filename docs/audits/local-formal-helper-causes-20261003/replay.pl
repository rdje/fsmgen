use strict;
use warnings;
use JSON::PP;
my $base='docs/audits/local-formal-helper-causes-20261003';
my $json=JSON::PP->new->canonical;
sub read_json {open my $fh,'<:raw',$_[0] or die $!;my $raw=do {local $/;<$fh>};close $fh or die $!;return $json->decode($raw)}
my $bound=read_json("$base/bindings.json");my $data=read_json("$base/causes.json");
eval 'package ReplayCurrentHelper;'.$bound->{helper};die $@ if $@;
delete $ENV{FSMGEN_FORMAL_DIAGNOSTIC_FULL_STACK};
my @rows;
for my $row (@{$data->{rows}}) {
    my $pattern=eval 'qr/'.$row->{pattern}.'/';die $@ if $@;
    push @rows,{id=>$row->{id},band=>$row->{band},matched=>ReplayCurrentHelper::diagnostic_matches($row->{error},$pattern)?1:0,full_trace_matched=>$row->{error}=~$pattern?1:0};
}
print $json->encode(\@rows),"\n";
