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

my $tempdir = tempdir(CLEANUP => 1);

subtest 'symbol-definition identifier and scalar-token boundaries are rejected explicitly' => sub {
    my $constants_error = parse_failure(<<'FSM');
(?fsm:bad_constants_name_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (bad-name 1)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($constants_error, qr/Malformed '\+constants' entry for constant 'bad-name'/, 'bad +constants identifier gets a targeted diagnostic');

    my $define_error = parse_failure(<<'FSM');
(?fsm:bad_define_name_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+define
    (bad-name 1)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($define_error, qr/Malformed '\+define' entry for name 'bad-name'/, 'bad +define identifier gets a targeted diagnostic');

    my $params_error = parse_failure(<<'FSM');
(?fsm:bad_params_name_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (bad-name 8)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($params_error, qr/Malformed '\+params' entry for parameter 'bad-name'/, 'bad +params identifier gets a targeted diagnostic');

    my $enums_error = parse_failure(<<'FSM');
(?fsm:bad_enum_member_value_contract
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+enums
    (mode
      (IDLE (1 2))
    )
  )
  (-dt
    (OUT = 1)
  )
)
FSM
    like($enums_error, qr/Malformed '\+enums' member 'IDLE' for enum 'mode'/, 'non-scalar +enums member value gets a targeted diagnostic');
};

subtest 'pipeline and CLI do not emit HDL for malformed +constants identifier tokens' => sub {
    assert_pipeline_and_cli_reject(
        'bad_constants_name_cli.fsm',
        <<'FSM',
(?fsm:bad_constants_name_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+constants
    (bad-name 1)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
        qr/Malformed '\+constants' entry for constant 'bad-name'/,
        'malformed +constants identifier token',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed +define identifier tokens' => sub {
    assert_pipeline_and_cli_reject(
        'bad_define_name_cli.fsm',
        <<'FSM',
(?fsm:bad_define_name_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+define
    (bad-name 1)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
        qr/Malformed '\+define' entry for name 'bad-name'/,
        'malformed +define identifier token',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed +params identifier tokens' => sub {
    assert_pipeline_and_cli_reject(
        'bad_params_name_cli.fsm',
        <<'FSM',
(?fsm:bad_params_name_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+params
    (bad-name 8)
  )
  (-dt
    (OUT = 1)
  )
)
FSM
        qr/Malformed '\+params' entry for parameter 'bad-name'/,
        'malformed +params identifier token',
    );
};

subtest 'pipeline and CLI do not emit HDL for malformed +enums scalar tokens' => sub {
    assert_pipeline_and_cli_reject(
        'bad_enum_member_value_cli.fsm',
        <<'FSM',
(?fsm:bad_enum_member_value_cli
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+enums
    (mode
      (IDLE (1 2))
    )
  )
  (-dt
    (OUT = 1)
  )
)
FSM
        qr/Malformed '\+enums' member 'IDLE' for enum 'mode'/,
        'malformed +enums scalar token',
    );
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

sub assert_pipeline_and_cli_reject {
    my ($filename, $fsm_text, $error_re, $label) = @_;

    my $fsm_path = write_fsm($filename, $fsm_text);
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug => 0,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($fsm_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;
    ok($pipeline_error, "pipeline rejects $label");
    like($pipeline_error, $error_re, "pipeline surfaces the explicit boundary for $label");

    my $out_path = File::Spec->catfile($tempdir, $filename . '.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $out_path, '--quiet', $fsm_path],
    );

    ok(!$success, "CLI rejects $label");
    ok(!-e $out_path, "CLI does not emit output for $label");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );
    like($combined_output, $error_re, "CLI surfaces the explicit boundary for $label");
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
