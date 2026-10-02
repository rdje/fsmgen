package FSM::Test::ConditionalOriginAuthority;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use JSON::PP;
use FSM::Test::ConditionalOriginParser;

my $json = JSON::PP->new->canonical;

# The caller supplies its authoritative source independently of the submitted
# actor/ledger. Reconstruct both complete products through the real parser.
# This private local-source proof refuses imports and does not adopt production
# metadata. An embedded digest is never a source authority.
sub from_source {
    my ($class, $source, $label) = @_;
    confess "conditional origin independent source authority required\n"
        unless defined($source) && !ref($source) && length($source)
            && defined($label) && !ref($label) && length($label);
    my $parser = FSM::Test::ConditionalOriginAuthority::LocalParser->new;
    my $actor = $parser->parse_source($source, $label);
    return bless {
        actor_json => $json->encode($actor),
        ledger_json => $json->encode($parser->ledger),
    }, $class;
}

sub validate {
    my ($self, $actor, $ledger) = @_;
    confess "conditional origin independent source authority required\n"
        unless defined($self->{actor_json}) && defined($self->{ledger_json});
    confess "conditional origin actor differs from authoritative source\n"
        unless $json->encode($actor) eq $self->{actor_json};
    confess "conditional origin ledger differs from authoritative source\n"
        unless $json->encode($ledger) eq $self->{ledger_json};
    return 1;
}

sub actor { return $json->decode($_[0]{actor_json}) }
sub ledger { return $json->decode($_[0]{ledger_json}) }

package FSM::Test::ConditionalOriginAuthority::LocalParser;
use parent 'FSM::Test::ConditionalOriginParser';
use Carp qw(confess);

sub _parse_imports {
    confess "conditional origin imported source authority is not qualified\n";
}

1;
