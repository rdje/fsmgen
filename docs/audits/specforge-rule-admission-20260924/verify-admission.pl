#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use lib "$FindBin::Bin/../../../perl", "$FindBin::Bin/../../../t/lib";
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryCoverage qw(build_source_query_cohort select_source_query_cohort);
use FSM::Adapter::ISF;
use FSM::Adapter::IAL2::PPIF;

my $root = abs_path("$FindBin::Bin/../../..");
chdir $root or die "chdir repository: $!\n";
my $output = shift @ARGV;
my $collect_failures = @ARGV && $ARGV[0] eq '--collect-failures' ? shift(@ARGV) : undef;
die "usage: verify-admission.pl .artifacts/<existing-directory>/<new-report>.json [--collect-failures]\n"
    unless defined($output) && !@ARGV && $output =~ m{\A\.artifacts/(?:[A-Za-z0-9_-]+/)+[A-Za-z0-9_-]+\.json\z} && !-e $output;
my $json = JSON::PP->new->canonical->utf8->pretty;
my $cohort = [grep {$_->{file_kind} =~ /\A(?:isf|ppif|axi|apb|ahb)\z/} @{build_source_query_cohort()}];
my @sources = @{select_source_query_cohort({cohort => $cohort,
    exists($ENV{FSMGEN_ADMISSION_SOURCES}) ? (source_ids => $json->decode($ENV{FSMGEN_ADMISSION_SOURCES})) : ()})};
my @results;
my $isf = FSM::Adapter::ISF->new;
my $protocol = FSM::Adapter::IAL2::PPIF->new;
$| = 1;
for my $row (@sources) {
    my $source = $row->{source_id};
    open my $in, '<:raw', $source or die "read source: $!\n";
    my $bytes = do {local $/; <$in>}; close $in or die "close source: $!\n";
    my @actors;
    my $ok = eval {
        die "unhandled source search-path authority\n" if @{$row->{search_path_relpaths}};
        if ($row->{file_kind} eq 'isf') {
            my $actor = $isf->parse_file($source);
            push @actors, {name => $actor->{actor_name}, source_sha256 => sha256_hex($bytes)};
        } else {
            my $result = $protocol->parse_file($source);
            my $generated = $result->{generated_ial1};
            die "missing public generated ISF artifact set\n" unless ref($generated) eq 'HASH' && $generated->{format} eq 'isf';
            my @items = exists($generated->{items}) ? @{$generated->{items}} : ($generated);
            die "empty generated ISF artifact set\n" unless @items;
            for my $item (@items) {
                die "malformed public generated ISF artifact\n" unless defined($item->{text}) && defined($item->{name});
                # Admission here is the ordinary public protocol adapter path.
                # Generated-artifact replay is separately owned by .32.4: some
                # historical interconnect review artifacts bypass ISF lowering.
                push @actors, {artifact => $item->{name}, source_sha256 => sha256_hex($item->{text})};
            }
        }
        1;
    };
    my $error = $@;
    $error =~ s{\Q$root/\E}{}g;
    push @results, {source => $source, source_sha256 => sha256_hex($bytes),
        passed => $ok ? JSON::PP::true : JSON::PP::false, actors => \@actors,
        ($ok ? () : (error => $error))};
    open my $out, '>:raw', $output or die "write report: $!\n";
    print {$out} $json->encode({selected => scalar(@sources), consumed => scalar(@results), results => \@results});
    close $out or die "close report: $!\n";
    print(($ok ? 'PASS ' : 'FAIL '), "$source\n");
    die $error unless $ok || $collect_failures;
}
print 'Actor admission complete: ', scalar(@results), " supported sources.\n";
exit(grep({!$_->{passed}} @results) ? 1 : 0);
