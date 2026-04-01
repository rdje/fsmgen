#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $test_lib = File::Spec->catdir($FindBin::Bin, 'lib');
my $fsm_path = File::Spec->catfile($tempdir, 'extension_loader_context_smoke.fsm');
my $bad_config_path = File::Spec->catfile($tempdir, 'bad_extensions.fsmext');
my $bad_config_out_path = File::Spec->catfile($tempdir, 'bad_extension_config.sv');
my $bad_new_out_path = File::Spec->catfile($tempdir, 'bad_new_extension.sv');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:extension_loader_context_smoke
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (OUT 1)
  )
  (idle
    (OUT <= 1)
  )
)
FSM
);

write_file(
    $bad_config_path,
    <<'CFG'
module FSM::TestExtension::Marker
bad syntax here
CFG
);

subtest 'pipeline constructor keeps extension config file context' => sub {
    my $error = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            quiet => 1,
            extension_config_files => [$bad_config_path],
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Extension config file:\s+'\Q$bad_config_path\E'.*Invalid extension config line at '\Q$bad_config_path\E' line 2/s,
        'pipeline constructor keeps the extension config file label around malformed config input',
    );
};

subtest 'pipeline constructor keeps extension module context for constructor failures' => sub {
    my $error = eval {
        FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            quiet => 1,
            extension_modules => ['FSM::TestExtension::BadNew'],
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Extension module:\s+'FSM::TestExtension::BadNew'.*failed to instantiate via new\(\): BadNew test extension forced constructor failure/s,
        'pipeline constructor keeps the extension module label around new() failures',
    );
};

subtest 'CLI keeps extension config file context and cleans constructor failures' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            $^X,
            '-I', $test_lib,
            './bin/fsmgen',
            '--extension-config', $bad_config_path,
            '--quiet',
            '-o', $bad_config_out_path,
            $fsm_path,
        ],
    );

    ok(!$success, 'CLI fails when extension config loading fails during pipeline construction');
    ok(!-e $bad_config_out_path, 'CLI does not emit output for malformed extension config input');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Extension config file:\s+'\Q$bad_config_path\E'.*Invalid extension config line at '\Q$bad_config_path\E' line 2/s,
        'CLI keeps the extension config file label around malformed config input',
    );
    unlike(
        $combined_output,
        qr/\bat \Q\.\/bin\/fsmgen\E line \d+/,
        'CLI constructor failure output stays cleaned instead of dumping the script line',
    );
};

subtest 'CLI keeps extension module context and cleans constructor failures' => sub {
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            $^X,
            '-I', $test_lib,
            './bin/fsmgen',
            '--extension-module', 'FSM::TestExtension::BadNew',
            '--quiet',
            '-o', $bad_new_out_path,
            $fsm_path,
        ],
    );

    ok(!$success, 'CLI fails when extension module construction fails');
    ok(!-e $bad_new_out_path, 'CLI does not emit output for constructor-failing extension modules');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Extension module:\s+'FSM::TestExtension::BadNew'.*failed to instantiate via new\(\): BadNew test extension forced constructor failure/s,
        'CLI keeps the extension module label around constructor failures',
    );
    unlike(
        $combined_output,
        qr/\bat \Q\.\/bin\/fsmgen\E line \d+/,
        'CLI constructor failure output stays cleaned instead of dumping the script line',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
