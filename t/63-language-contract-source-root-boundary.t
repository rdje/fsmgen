#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::HDLGenerator;
use FSM::SourceClassifier;

my $tempdir = tempdir(CLEANUP => 1);
my $source_path = File::Spec->catfile($tempdir, 'bare_root.fsm');
my $out_path = File::Spec->catfile($tempdir, 'bare_root.sv');

write_file(
    $source_path,
    <<'FSM'
(+system
  (clock clk)
  (sreset rstn)
)
(idle
  (OUT <= 1)
)
FSM
);

my $raw_ast = Lispish::multi($source_path);
my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
is($source_info->{kind}, 'unknown', 'bare top-level FSM content stays outside active source kinds');
ok(!defined($source_info->{header}), 'classifier leaves bare top-level FSM content without a supported source header');

subtest 'bare top-level FSM content is rejected explicitly at the source-root boundary' => sub {
    my $parser_error = parse_failure(<<'FSM');
(+system
  (clock clk)
  (sreset rstn)
)
(idle
  (OUT <= 1)
)
FSM
    like($parser_error, qr/Malformed top-level source root '\+system'/, 'bare top-level +system content gets a targeted source-root diagnostic');
    unlike($parser_error, qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/, 'generic FSM-shape error is no longer used for bare top-level content');

    my $state_root_error = parse_failure(<<'FSM');
(idle
  (OUT <= 1)
)
FSM
    like($state_root_error, qr/Malformed top-level source root 'idle'/, 'bare top-level state/DT content also gets the source-root diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for bare top-level FSM content' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );
    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($source_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, 'pipeline rejects bare top-level FSM content');
    like($pipeline_error, qr/Malformed top-level source root '\+system'/, 'pipeline surfaces the explicit source-root boundary');
    unlike($pipeline_error, qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/, 'pipeline no longer leaks the generic FSM-shape error');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $source_path],
    );

    ok(!$success, 'CLI rejects bare top-level FSM content');
    ok(!-e $out_path, 'CLI does not emit output for bare top-level FSM content');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, qr/Malformed top-level source root '\+system'/, 'CLI surfaces the explicit source-root boundary');
    unlike($combined_output, qr/Expected FSM structure containing '\?fsm:name' or '\+fsm'/, 'CLI no longer leaks the generic FSM-shape error');
};

done_testing();

sub parse_failure {
    my ($fsm_text) = @_;
    my $fsm_path = write_fsm('parse_failure_' . int(rand(1_000_000)) . '.fsm', $fsm_text);
    my $raw_ast = Lispish::multi($fsm_path);
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);

    my $error = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $error = $@ if !$error;
    ok($error, 'parse fails for generated fixture');
    return $error;
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
