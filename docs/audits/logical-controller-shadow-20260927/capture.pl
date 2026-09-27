#!/usr/bin/env perl
use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use File::Path qw(make_path);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner qw(run_source_query normalize_repository_paths);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Run from the repository root. Capture whole reports and emitted files; no
# fields are dropped. The only normalization removes this repository's prefix.
my $phase = shift // 'current';
die "phase must be a simple name\n" unless $phase =~ /\A[a-z]+\z/;
my $directory = '.artifacts/logical-controller-model';
make_path($directory);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical->pretty;
my @out;
for my $source (sort glob 't/data/logical-controller-shadow/*.isf') {
    my $row = {
        source_id => $source, query_kinds => [qw(check semantic schedule)],
        search_path_relpaths => [], strict => 1, language_version => undef,
    };
    my %reports;
    for my $kind (@{$row->{query_kinds}}) {
        my $result = run_source_query({repository_root => $root, row => $row, query_kind => $kind});
        die "$source $kind transport failure: " . $json->encode($result)
            if $result->{native}{exit_code} || $result->{stdio}{exit_code}
                || $result->{native}{stderr} || $result->{stdio}{stderr};
        die "producer changed during query\n"
            unless $json->encode($result->{producer_sha256_before})
                eq $json->encode($result->{producer_sha256_after});
        die "source changed during query\n"
            unless $result->{source_sha256_before} eq $result->{source_sha256_after};
        my $native = normalize_repository_paths($result->{native}{report}, $root);
        die "$source $kind API mismatch\n"
            unless $json->encode($native)
                eq $json->encode($result->{adapter_result}{structuredContent}{report});
        die "$source $kind MCP mismatch\n"
            unless $json->encode($result->{adapter_result})
                eq $json->encode($result->{stdio}{response}{result});
        $reports{$kind} = $native;
    }
    my $actor = FSM::Adapter::ISF->new->parse_file($source);
    my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
    push @out, {source => $source, reports => \%reports, files => $files};
    print "$phase $source parity PASS\n";
}
open my $fh, '>', "$directory/$phase.json" or die $!;
print {$fh} $json->encode(\@out);
close $fh or die $!;
