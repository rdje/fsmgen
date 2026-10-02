use strict;
use warnings;
use JSON::PP;
my $j=JSON::PP->new->canonical;
my $input=$j->decode(do {local $/;<STDIN>});
# Exact bound assertion statements over actual saved scalar errors. The probe
# itself calls Test::More::like; this cold primitive independently replays each
# scalar/regex result without claiming arbitrary Test::More input semantics.
sub like {return $_[0]=~$_[1]?1:0}
my @results;
for my $r (@{$input->{products}}) {
    my $error=$r->{error};my $diagnostic=$error;
    my $statement=$input->{sites}{$r->{site}}{statement};
    my $matched=eval 'local $@=$error;'.$statement;die$@ if$@;
    push @results,$matched?1:0;
}
print $j->encode(\@results);
