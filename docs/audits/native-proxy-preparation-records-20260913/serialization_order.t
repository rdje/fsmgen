#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use JSON::PP ();
use Test::More;

open my $input, '<:raw', "$FindBin::Bin/vectors.json" or die "vectors: $!";
my $vectors = JSON::PP->new->decode(do { local $/; <$input> });
close $input or die "close vectors: $!";
my $record = $vectors->{original_v1};
my $expected = $vectors->{original_v1_raw};
my $shared = JSON::PP->new->canonical->ascii;
is($shared->encode($record), $expected, 'same original record initially has canonical bytes');
my $old_output = $shared->pretty->encode({raw => $shared->encode($record)});
my $nested = JSON::PP->new->decode($old_output)->{raw};
isnt($nested, $expected, 'chained pretty mutates the encoder before nested argument serialization');
is_deeply(JSON::PP->new->decode($nested), $record, 'original failure changes formatting, not record values');

my $canonical = JSON::PP->new->canonical->ascii;
my $presentation = JSON::PP->new->canonical->ascii->pretty;
my $fixed_output = $presentation->encode({raw => $canonical->encode($record)});
is(JSON::PP->new->decode($fixed_output)->{raw}, $expected, 'separate presentation encoder preserves exact nested bytes');
is($canonical->encode($record), $expected, 'canonical encoder remains unchanged after output formatting');
done_testing();
