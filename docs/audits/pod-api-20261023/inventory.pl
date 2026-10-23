#!/usr/bin/env perl
use v5.20;
use strict;
use warnings;
use File::Find qw(find);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use Pod::Simple::Checker;
use Pod::Simple::HTMLBatch;

# Read-only census. Run from the repository root; never load the FSM modules.
my @paths;
find({ no_chdir => 1, wanted => sub {
    die "Unsafe source $_\n" if -l $_;
    push @paths, $_ if -f $_ && /\.pm\z/;
}}, 'perl/FSM');
my @rows;
for my $path (sort @paths) {
    open my $fh, '<:raw', $path or die "$path: $!";
    local $/;
    my $source = <$fh>;
    my $checker = Pod::Simple::Checker->new;
    my $diagnostics = '';
    $checker->output_string(\$diagnostics);
    $checker->parse_string_document($source);
    push @rows, {
        path => $path, sha256 => sha256_hex($source), bytes => length($source),
        pod => $checker->content_seen ? JSON::PP::true : JSON::PP::false,
        errors => ($checker->any_errata_seen || $diagnostics =~ /\S/) ? JSON::PP::true : JSON::PP::false,
        diagnostics => $diagnostics,
    };
}
chomp(my $revision = `git rev-parse HEAD`);
die "Cannot resolve capture boundary\n" unless $revision =~ /\A[0-9a-f]{40}\z/;
print JSON::PP->new->ascii->canonical->pretty->encode({
    capture_revision => $revision,
    scope => 'regular .pm files recursively under perl/FSM; no module execution',
    perl => "$^V", checker => $Pod::Simple::Checker::VERSION,
    htmlbatch => $Pod::Simple::HTMLBatch::VERSION, sources => \@rows,
});
