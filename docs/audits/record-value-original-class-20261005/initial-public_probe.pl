use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use Scalar::Util qw(blessed refaddr);

{
    package ClassProbeException;
    use overload '""' => sub { "class probe object\n" }, fallback => 1;
    sub TO_JSON { "class probe object\n" }
}

my $json = JSON::PP->new->canonical;
my @rows;
sub observe {
    my ($name, $operation) = @_;
    my $ok = eval { $operation->(); 1 };
    my $error = $@;
    my $ref = ref($error);
    my $blessed = blessed($error);
    my ($encoded, $encoding_error);
    my $published = eval { $encoded = $json->encode({error => $error}); 1 };
    $encoding_error = $@;
    push @rows, {name => $name, accepted => $ok ? 1 : 0,
        reference_kind => $ref, blessed_class => $blessed,
        body => "$error", published => $published ? 1 : 0,
        encoded => $encoded, encoding_error => $encoding_error};
}

observe('literal-confess', sub { confess "class probe literal\n" });
observe('literal-die', sub { die "class probe literal\n" });
observe('literal-rethrow', sub {
    eval { confess "class probe literal\n" };
    my $error = $@;
    die $error;
});
observe('object-die', sub { die bless {}, 'ClassProbeException' });
observe('object-confess', sub { confess bless {}, 'ClassProbeException' });
observe('object-rethrow', sub {
    eval { die bless {}, 'ClassProbeException' };
    my $error = $@;
    die $error;
});
observe('object-interpolation', sub {
    my $error = bless {}, 'ClassProbeException';
    confess "class probe outer: $error";
});
observe('unblessed-reference', sub { die {reason => 'class probe reference'} });

my %flags;
for my $getter (qw(get_allow_blessed get_convert_blessed get_allow_tags get_allow_bignum)) {
    my $raw = $json->$getter();
    $flags{$getter} = {raw => $raw, effective => $raw ? 1 : 0};
}
print $json->encode({perl => "$^V", carp => Carp->VERSION,
    json_pp => JSON::PP->VERSION, scalar_util => Scalar::Util->VERSION,
    flags => \%flags, cases => \@rows}), "\n";
