package FSM::Support::ISFResetProvenance;

use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';

our @EXPORT_OK = qw(snapshot_reset_provenance reset_provenance_contract);

sub reset_provenance_contract {
    return {
        entry_keys => [qw(domain origin)],
        origin_values => [qw(explicit legacy_default domain_absent)],
        shape => 'array in authored domain order; domain is null for a legacy actor or a declared domain name; null when declaration provenance is unknown',
        meaning => 'clause presence in ISF, not grounding in an upstream specification; explicit does not imply every timing/polarity operand was authored',
    };
}

# The parser owns the evidence. Never reconstruct origin from effective policy.
# Return only detached JSON-safe values, including for caller-constructed actors.
sub snapshot_reset_provenance {
    my ($value) = @_;
    return undef unless defined $value;
    confess "Invalid ISF reset provenance: expected a nonempty array\n"
        unless ref($value) eq 'ARRAY' && @$value;
    my %seen;
    my @result;
    for my $entry (@$value) {
        confess "Invalid ISF reset provenance: expected domain/origin entry\n"
            unless ref($entry) eq 'HASH' && keys(%$entry) == 2
                && exists $entry->{domain} && exists $entry->{origin};
        my ($domain, $origin) = @{$entry}{qw(domain origin)};
        confess "Invalid ISF reset provenance: invalid domain\n"
            if defined($domain) && (ref($domain) || !length($domain));
        confess "Invalid ISF reset provenance: invalid origin\n"
            unless defined($origin) && !ref($origin)
                && $origin =~ /\A(?:explicit|legacy_default|domain_absent)\z/;
        confess "Invalid ISF reset provenance: inconsistent domain scope\n"
            if (!defined($domain) && (@$value != 1 || $origin eq 'domain_absent'))
                || (defined($domain) && $origin eq 'legacy_default');
        my $key = defined($domain) ? "domain:$domain" : 'legacy';
        confess "Invalid ISF reset provenance: duplicate domain\n" if $seen{$key}++;
        push @result, {domain => $domain, origin => $origin};
    }
    return \@result;
}

1;
