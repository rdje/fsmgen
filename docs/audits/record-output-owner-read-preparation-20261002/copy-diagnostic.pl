use strict;
use warnings;
use JSON::PP;
use Storable qw(dclone);
sub copy_value {
    my ($value) = @_;
    return {map {$_ => copy_value($value->{$_})} keys %$value} if ref($value) eq 'HASH';
    return [map {copy_value($_)} @$value] if ref($value) eq 'ARRAY';
    return $value;
}
my $value = "3";
my $positive = $value > 0;
my $data = {width => $value};
my $json = JSON::PP->new->canonical;
print $json->encode($data), "\n", $json->encode(copy_value($data)), "\n", $json->encode(dclone($data)), "\n";
