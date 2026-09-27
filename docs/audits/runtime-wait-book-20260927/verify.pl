#!/usr/bin/env perl
use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

# Run from the repository root. Output and temporary carriers stay local.
my $output = shift // '.artifacts/wait-book/result.json';
die "Output must be repository-relative\n"
    if @ARGV || File::Spec->file_name_is_absolute($output) || $output =~ m{(?:^|/)\.\.(?:/|$)};
make_path(dirname($output));
my $json = JSON::PP->new->canonical->pretty;
my $manifest = $json->decode(read_file('docs/audits/runtime-wait-book-20260927/fixtures.json'));
my $book = read_file($manifest->{chapter});
my $work = tempdir(CLEANUP => 1);
my (@results, @errors, %seen);
my $root = abs_path('.');
for my $case (@{$manifest->{cases}}) {
    my $actor = FSM::Adapter::ISF->new->parse_source($case->{source}, "$case->{id}.isf");
    my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
    my $record = {id => $case->{id}, source_sha256 => sha256_hex($case->{source}), carriers => [], fragments => []};
    for my $name (sort keys %$files) {
        next unless $name =~ /\.fsm\z/;
        my $path = "$work/$name";
        write_file($path, $files->{$name});
        my $check = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
        my $report = $json->decode($check->{stdout});
        $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($report, $root);
        push @{$record->{carriers}}, {name => $name, sha256 => sha256_hex($files->{$name}), exit_code => $check->{exit_code}, success => $report->{success}};
        if (my $refusal = $case->{expected_refusal}) {
            my $messages = join("\n", map {$_->{message} // ''} @{$report->{diagnostics} // []});
            push @errors, "$case->{id}/$name no longer matches tracked refusal $refusal->{owner}"
                unless $check->{exit_code} == 1 && !$report->{success}
                    && index($messages, $refusal->{diagnostic}) >= 0;
        } else {
            push @errors, "$case->{id}/$name strict replay failed: " . $json->encode($report)
                if $check->{exit_code} || !$report->{success};
        }
    }
    for my $fragment (@{$case->{fragments}}) {
        my $id = $fragment->{id};
        die "Duplicate fragment $id\n" if $seen{$id}++;
        my @matches = $book =~ /<!-- \Q$id\E -->\n```lisp\n(.*?)\n```/sg;
        die "Expected exactly one book fragment $id\n" unless @matches == 1;
        my @blocks;
        for my $state (@{$fragment->{states}}) {
            my @states;
            my $carrier = $files->{$case->{carrier}};
            die "Missing selected carrier $case->{carrier}\n" unless defined $carrier;
            push @states, $carrier =~ /(^  \(\Q$state\E\n.*?^  \))/msg;
            die "Expected exactly one generated state $state for $id\n" unless @states == 1;
            my $block = $states[0];
            $block =~ s/^  //mg;
            push @blocks, $block;
        }
        my $expected = join("\n\n", @blocks);
        my $matches = tokens($expected) eq tokens($matches[0]);
        push @errors, "$id differs from $case->{id}" unless $matches;
        push @{$record->{fragments}}, {id => $id, matches => $matches ? JSON::PP::true : JSON::PP::false,
            generated => $expected, documented => $matches[0]};
    }
    push @results, $record;
    print "$case->{id}: lowered and inspected\n";
}
my ($section) = $book =~ /(The first runtime scalar surface.*?)(?=^## `\(complete port\)`)/ms;
die "Missing runtime wait section\n" unless defined $section;
my @state_fragments = $section =~ /^```lisp\n(\((?:main|parent)_.*?)\n```/msg;
die "Unmapped generated wait fragment\n" unless @state_fragments == keys %seen;
write_file($output, $json->encode({baseline => $manifest->{baseline}, results => \@results, errors => \@errors}));
die join("\n", @errors) . "\n" if @errors;
print "wait-book: all mapped fragments match current carriers; declared carrier outcomes verified\n";

sub tokens {
    my ($text) = @_;
    # Only formatting whitespace is ignored; operators, ordering and grouping
    # must match. These generated state excerpts contain no quoted strings.
    return join(" ", $text =~ /([()]|[^()\s]+)/g);
}
sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    return do {local $/; <$fh>};
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print {$fh} $text or die "$path: $!";
    close $fh or die "$path: $!";
}
