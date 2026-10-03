use strict;
use warnings;
use lib 'perl', 't/lib';
my $path='t/1947-isf-formal-reusable-products.t';
open my $fh,'-|','git','show','48b2380d79e44de815587c093a88ede6a244d34d:'.$path or die $!;
my $before=do {local $/;<$fh>};close $fh or die $!;
open $fh,'<:raw',$path or die $!;my $current=do {local $/;<$fh>};close $fh or die $!;
sub project_body {
 my ($text)=@_;my $start=index($text,'sub project {');my $end=index($text,'sub strict_child {',$start);
 die 'exact project helper missing' unless $start>=0 && $end>$start;
 return substr($text,$start,$end-$start);
}
my $actual=project_body($current);my $prior=project_body($before);
my $at=index($current,$actual);substr($current,$at,length($actual))=$prior;
# Compile the actual full test with only its exact prior project restored.
eval $current;die $@ if $@;
