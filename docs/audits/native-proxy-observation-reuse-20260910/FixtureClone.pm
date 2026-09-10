package NativeProxyObservationFixtureClone;
use strict;
use warnings;
use JSON::PP ();

# Qualification data only: JSON cloning preserves the caller's JSON number /
# string distinction, while restoring each original character flag preserves
# the additional octet-vs-character contract used by binary source snapshots.
my $JSON = JSON::PP->new->canonical->ascii;
sub _restore_flags {
    my ($original, $copy) = @_;
    if (ref($original) eq 'HASH') {
        $copy->{$_} = _restore_flags($original->{$_}, $copy->{$_}) for keys %$original;
    } elsif (ref($original) eq 'ARRAY') {
        $copy->[$_] = _restore_flags($original->[$_], $copy->[$_]) for 0..$#$original;
    } elsif (!ref($original) && defined($original)) {
        if (utf8::is_utf8($original)) {
            utf8::upgrade($copy);
        } elsif (utf8::is_utf8($copy)) {
            utf8::downgrade($copy, 1) or die "fixture JSON clone changed octet values\n";
        }
    }
    return $copy;
}
sub clone {
    return _restore_flags($_[0], $JSON->decode($JSON->encode($_[0])));
}
1;
