use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;

my $json = JSON::PP->new->canonical;
eval { confess "forward probe inner\n" };
my $inner = $@;
my @cases;
sub observe {
    my ($name, $operation) = @_;
    my $ok = eval { $operation->(); 1 };
    my $error = $@;
    push @cases, {name => $name, accepted => $ok ? 1 : 0,
        reference_kind => ref($error), error => $error};
}
observe('newline-string', sub { die "forward probe literal\n" });
observe('no-newline-string', sub { die 'forward probe literal' });
observe('explicit-rethrow', sub { die $inner });
observe('implicit-rethrow', sub { $@ = $inner; die });
observe('interpolated-outer', sub { confess "forward probe outer: $inner\n" });
observe('altering-die-hook', sub {
    local $SIG{__DIE__} = sub { die "forward probe hook changed\n" };
    die $inner;
});
print $json->encode({perl => "$^V", carp => $Carp::VERSION,
    json_pp => $JSON::PP::VERSION, inner => $inner, cases => \@cases}), "\n";
