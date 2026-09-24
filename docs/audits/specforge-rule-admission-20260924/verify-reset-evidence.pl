#!/usr/bin/env perl
use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use File::Path qw(make_path);
use JSON::PP;
use Digest::SHA qw(sha256_hex);
use FSM::Test::ProjectDataLocality;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);

my ($directory) = @ARGV;
die "Usage: $0 .artifacts/FRESH-DIRECTORY\n"
    unless @ARGV == 1 && $directory =~ m{\A[.]artifacts/[A-Za-z0-9_-]+\z} && !-e $directory;
die "Qualified Verilator runtime is required\n" unless darwin_verilator_runtime_qualified();
die "Artifact root must be an in-repository directory on the repository volume\n"
    unless abs_path('.artifacts') eq abs_path('.').'/.artifacts'
        && (stat('.artifacts'))[0] == (stat('.'))[0];
my $json = JSON::PP->new->canonical->utf8->pretty;
my $evidence = $json->decode(read_file('docs/audits/specforge-rule-admission-20260924/isf-reset-polarity.json'));
make_path($directory);
my @receipts;
for my $label (qw(before after)) {
    for my $fixture (qw(ordinary event)) {
        my $dir = "$directory/$label-$fixture";
        make_path($dir);
        my @names = $fixture eq 'event' ? ('event') : qw(sync_high sync_low async_high async_low);
        my @hdl;
        for my $name (@names) {
            my $artifact = $evidence->{hdl}{$label}{$name};
            die "HDL identity mismatch: $label/$name\n" unless sha256_hex($artifact->{text}) eq $artifact->{sha256};
            my $path = "$dir/$name.sv";
            write_file($path, $artifact->{text});
            push @hdl, $path;
        }
        my $oracle_name = $fixture eq 'event' ? 'isf_reset_event_tb.sv' : 'explicit_reset_behavior_tb.sv';
        my $oracle = $evidence->{oracles}{$oracle_name};
        die "Oracle identity mismatch: $oracle_name\n" unless sha256_hex($oracle->{text}) eq $oracle->{sha256};
        my $tb = "$dir/$oracle_name";
        write_file($tb, $oracle->{text});
        my $top = $fixture eq 'event' ? 'reset_event_tb' : 'reset_tb';
        my $object_dir = abs_path($dir).'/obj';
        my @command = ('verilator', '--binary', '--timing', '--assert', '-Wno-fatal', '-j', '1',
            '--top-module', $top, '--Mdir', $object_dir, @hdl, $tb);
        my $compile = run_verilator_compile(\@command);
        my $runtime = $compile->{ok} ? run_generated_binary(["$object_dir/V$top"]) : undef;
        my $accepted = $compile->{ok} && defined($runtime) && ($label eq 'before'
            ? !$runtime->{ok} && ($runtime->{stdout}.$runtime->{stderr}) =~ /(?:all reset modes expected|event count expected)/
            : $runtime->{ok} && $runtime->{stdout} =~ /(?:RESET_BEHAVIOR_PASS|ISF_RESET_EVENT_PASS)/);
        push @receipts, {label => $label, fixture => $fixture, expected_outcome_observed => $accepted ? 1 : 0,
            compile => $compile, runtime => $runtime};
        my $encoded = $json->encode(\@receipts);
        my $root = abs_path('.'); $encoded =~ s{\Q$root/\E}{}g;
        write_file("$directory/receipts.json", $encoded);
        die "Unexpected reset oracle result: $label/$fixture\n" unless $accepted;
        print "$label/$fixture: expected " . ($label eq 'before' ? 'behavioral rejection' : 'behavioral success') . " observed\n";
    }
}
sub read_file {
    open my $fh, '<:raw', $_[0] or die $!;
    my $text = do {local $/; <$fh>}; close $fh or die $!; return $text;
}
sub write_file {
    open my $fh, '>:raw', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!;
}
