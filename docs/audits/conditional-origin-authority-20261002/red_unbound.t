use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Test::ConditionalOriginParser;

my $json = JSON::PP->new->canonical;
my @paths = sort glob 'docs/audits/conditional-origin-parser-20261002/current-corrected/*.json';
die 'wrong complete predecessor membership' unless @paths == 54;
for my $path (@paths) {
    open my $file, '<:raw', $path or die $!;
    my $product = $json->decode(do {local $/; <$file>});
    my $producer = FSM::Test::ConditionalOriginParser->new;
    my $actor = $producer->parse_source($product->{source}, $product->{label});
    my $forged = $producer->ledger;
    $forged->{catalog}[0]{owner}{name} = 'forged_source_owner';
    $forged->{source_sha256} = '0' x 64;
    my $fresh = FSM::Test::ConditionalOriginParser->new;
    ok(!eval {$fresh->validate($actor, $forged); 1}, "fresh structural verifier must refuse forgery: $path");
    if (my $dir = $ENV{FSMGEN_ORIGIN_AUTHORITY_RED_CAPTURE}) {
        my ($name) = $path =~ m{/([^/]+)$};
        open my $out, '>:raw', "$dir/$name" or die $!;
        print {$out} $json->encode({source => $product->{source}, label => $product->{label},
            actor => $actor, trusted_ledger => $producer->ledger, forged_ledger => $forged,
            accepted => $fresh->validate($actor, $forged) ? JSON::PP::true : JSON::PP::false}) . "\n";
        close $out or die $!;
    }
}
done_testing;
