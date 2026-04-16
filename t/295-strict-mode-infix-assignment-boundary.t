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
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

my $tempdir = tempdir(CLEANUP => 1);
my $libdir = File::Spec->catdir($tempdir, 'strict_infix_lib');
mkdir $libdir or die "Cannot create $libdir: $!";

my $infix_path = File::Spec->catfile($tempdir, 'strict_infix_direct.fsm');
my $infix_out_path = File::Spec->catfile($tempdir, 'strict_infix_direct.sv');
my $deconstruct_path = File::Spec->catfile($tempdir, 'strict_infix_deconstruct.fsm');
my $pair_path = File::Spec->catfile($tempdir, 'strict_pair_direct.fsm');
my $pair_out_path = File::Spec->catfile($tempdir, 'strict_pair_direct.sv');
my $child_top_path = File::Spec->catfile($tempdir, 'strict_infix_child_top.fsm');
my $child_out_path = File::Spec->catfile($tempdir, 'strict_infix_child_top.sv');
my $child_path = File::Spec->catfile($libdir, 'child_infix_dt.fsm');

write_file(
    $infix_path,
    <<'FSM'
(?fsm:strict_infix_direct
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
    (IN 8)
    (Q 8)
  )
  (idle
    (OUT = IN)
    (Q <- IN)
  )
)
FSM
);

write_file(
    $pair_path,
    <<'FSM'
(?fsm:strict_pair_direct
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
    (IN 8)
    (Q 8)
  )
  (idle
    (= (OUT IN))
    (<- (Q IN))
  )
)
FSM
);

write_file(
    $deconstruct_path,
    <<'FSM'
(?fsm:strict_infix_deconstruct
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (HI 4)
    (LO 4)
    (DATA 8)
  )
  (idle
    ((concat HI LO) = DATA)
  )
)
FSM
);

write_file(
    $child_top_path,
    <<'FSM'
(?top:strict_infix_child_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router child_infix_dt)
)
FSM
);

write_file(
    $child_path,
    <<'FSM'
(?dt:child_infix_dt
  (+size
    (data_in 8)
    (result_data 8)
  )
  (-route
    (result_data> = data_in)
  )
)
FSM
);

subtest 'default mode keeps infix assignment compatibility' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($infix_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_infix_direct\b/s,
        'default-mode pipeline still compiles infix assignment compatibility syntax',
    );
};

subtest 'strict mode accepts canonical assignment pairs' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($pair_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_pair_direct\b/s,
        'strict-mode pipeline compiles canonical assignment pair syntax',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $pair_out_path, $pair_path],
    );

    ok($success, 'CLI strict mode accepts canonical assignment pair syntax');
    ok(-e $pair_out_path, 'CLI strict mode emits HDL for canonical assignment pair syntax');
};

subtest 'shared frontend strict boundary rejects infix assignments' => sub {
    my $raw_ast = Lispish::multi($infix_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $infix_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects infix assignment '\(OUT = IN\)' in source '\Q$infix_path\E'.*Use the canonical pair form '\(= \(OUT IN\)\)'.*infix assignment compatibility/s,
        'shared frontend keeps an actionable infix-assignment migration hint',
    );
};

subtest 'shared frontend strict boundary also rejects infix LHS deconstruct assignments' => sub {
    my $raw_ast = Lispish::multi($deconstruct_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $deconstruct_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects infix assignment '\(\(concat HI LO\) = DATA\)' in source '\Q$deconstruct_path\E'.*Use the canonical pair form '\(= \(\(concat HI LO\) DATA\)\)'/s,
        'shared frontend gives the canonical pair hint for LHS deconstruct assignments too',
    );
};

subtest 'strict pipeline and CLI reject infix assignments before HDL emission' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($infix_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$infix_path\E'.*Strict mode rejects infix assignment '\(OUT = IN\)'.*Use the canonical pair form '\(= \(OUT IN\)\)'/s,
        'strict pipeline keeps source-file context around the infix-assignment boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $infix_out_path, $infix_path],
    );

    ok(!$success, 'CLI strict mode rejects infix assignments');
    ok(!-e $infix_out_path, 'CLI strict mode does not emit HDL for infix assignments');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$infix_path\E'.*Strict mode rejects infix assignment '\(OUT = IN\)'.*Use the canonical pair form '\(= \(OUT IN\)\)'/s,
        'CLI strict mode surfaces the same infix-assignment boundary',
    );
};

subtest 'strict mode also rejects external generated children that use infix assignments' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($child_top_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?dtc' 'child_infix_dt'.*Strict mode rejects infix assignment '\(result_data> = data_in\)'.*Use the canonical pair form '\(= \(result_data> data_in\)\)'/s,
        'strict pipeline keeps full child-source context around the infix-assignment boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '--path', $libdir, '-o', $child_out_path, $child_top_path],
    );

    ok(!$success, 'CLI strict mode rejects generated children that use infix assignments');
    ok(!-e $child_out_path, 'CLI strict mode does not emit HDL for generated children that use infix assignments');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?dtc' 'child_infix_dt'.*Strict mode rejects infix assignment '\(result_data> = data_in\)'.*Use the canonical pair form '\(= \(result_data> data_in\)\)'/s,
        'CLI strict mode surfaces the same child-source infix-assignment boundary',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
