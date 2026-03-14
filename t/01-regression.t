#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename;
use File::Spec;
use File::Temp qw/ tempdir /;
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::SourceClassifier;

my $fsm_dir = 'fsm';
my @fsm_files = grep { is_active_fsm_source($_) } glob("$fsm_dir/*.fsm");

if (!@fsm_files) {
    plan skip_all => "No .fsm files found in $fsm_dir";
}

plan tests => scalar(@fsm_files);

my $tempdir = tempdir( CLEANUP => 1 );

for my $fsm_file (sort @fsm_files) {
    my $base = basename($fsm_file, '.fsm');
    my $out_file = File::Spec->catfile($tempdir, "$base.sv");
    
    # Run fsmgen on the file, outputting to temp dir
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
        run(command => ["./bin/fsmgen", "-o", $out_file, "--quiet", $fsm_file]);
        
    ok($success, "fsmgen compiled $fsm_file")
        or diag("Error: " . ($error_message || "unknown") . "\nStderr:\n" . join("", @{$stderr_buf || []}) . "\nStdout:\n" . join("", @{$stdout_buf || []}));
}

sub is_active_fsm_source {
    my ($fsm_file) = @_;
    my $raw_ast = Lispish::multi($fsm_file);
    return 0 unless $raw_ast;

    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    return ($source_info->{kind} || '') eq 'fsm';
}
