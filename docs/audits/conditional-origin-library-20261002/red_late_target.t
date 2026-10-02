use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::SameSourceLibraryOriginParser;
{
    package FSM::Test::LateOriginTargetMutation;
    use parent 'FSM::Test::SameSourceLibraryOriginParser';
    sub _finalize_actor_crossings {
        my ($self, $actor, @args) = @_;
        my $result = $self->SUPER::_finalize_actor_crossings($actor, @args);
        $actor->{transactions}[0]{clauses}[0][1] = 'start';
        return $result;
    }
}
my $json = JSON::PP->new->canonical;
open my $file, '<:raw', '.artifacts/conditional-origin-library/current/first_select.json' or die $!;
my $source = $json->decode(do {local $/; <$file>});
ok(!eval {FSM::Test::LateOriginTargetMutation->new->parse_source($source->{source}, $source->{label}); 1},
    'canonical late target mutation must refuse stale source association');
done_testing;
