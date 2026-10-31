package FSMGenBackendInputStaleControl;
use strict;
use warnings;
use JSON::PP;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Digest::SHA qw(sha256_hex);
use FSM::Test::AhbReference;
my $json = JSON::PP->new->canonical->utf8;
open my $stream, '<:raw', 't/data/vial-backend-foundation-historical-inputs.json.gz' or die "$!";
my $compressed = do {local $/; <$stream>};
close $stream or die "$!";
my $text;
gunzip(\$compressed => \$text) or die "$GunzipError";
my $old = $json->decode($text);
die 'historical control fixture changed' unless sha256_hex($json->encode($old))
    eq '0b826052e52df3d59d08fb49f4a4ff18a228b7ce8e7282af0e56b2121b9e8452';
{
    no warnings 'redefine';
    # Deliberately wrong: present the authenticated old DUT as current.
    # Every production route, current bridge and frozen historical oracle stays live.
    *FSM::Test::AhbReference::current_ahb_backend_inputs = sub {
        return $json->decode($json->encode($old));
    };
}
1;
