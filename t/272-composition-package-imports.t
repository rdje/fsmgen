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
use FSM::Composition::Parser;
use FSM::Pipeline::HDLGenerator;

subtest 'composition parser records package imports and embedded package roots' => sub {
    my $parser = FSM::Composition::Parser->new;

    my $spec = $parser->parse_source(
        scalar Lispish::multi(\<<'FSM'),
(?top:package_parse_top
  (+import shared_local shared_external)
  (?ports:public_io
    status_out>
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_local.mode.BUSY/status_out/
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)
FSM
    );

    is_deeply(
        $spec->top->package_imports,
        ['shared_local', 'shared_external'],
        'parser preserves explicit package imports on the typed composition top',
    );
    ok(
        exists $spec->embedded_package_sources->{shared_local},
        'parser records embedded package roots alongside the typed composition top',
    );
    ok(
        !exists $spec->embedded_package_sources->{shared_external},
        'parser does not invent missing embedded package roots',
    );
};

subtest 'pipeline and CLI resolve embedded and external package imports for named literal actuals' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $composition_path = File::Spec->catfile($tempdir, 'package_import_top.fsm');
    my $package_path = File::Spec->catfile($libdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'package_import_top.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
    (NIBBLE 4'hA)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:package_import_top
  (+import shared_local shared_external)
  (?ports:public_io
    prefix<1
    shared_out>8
    shared_flag>
    packed_out>6
  )
  (?rtl:uart_tx)
  (?toplink:wiring
    /=shared_external.RESET_BYTE/shared_out/
    /=shared_local.mode.BUSY/shared_flag/
    /prefix,=shared_local.mode.IDLE,=shared_external.NIBBLE/packed_out/
    /=shared_external.RESET_BYTE/uart_tx.data_in/
    /=shared_local.mode.BUSY/uart_tx.enable/
  )
)

(?pkg:shared_local
  (+enums
    (mode
      (IDLE 0)
      (BUSY 1)
    )
  )
)

(?rtlif:uart_tx
  data_in<8:data
  enable<1:data
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $hdl = $result->{hdl_code};

    is_deeply(
        [sort @{$result->{composition_spec}->top->package_imports || []}],
        [qw(shared_external shared_local)],
        'pipeline result preserves imported package names on the composition spec',
    );
    ok(
        exists $result->{composition_spec}->embedded_package_sources->{shared_local},
        'pipeline result preserves embedded package roots on the composition spec',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('shared_external.RESET_BYTE'),
        "8'hA5",
        'resolved top symbols expose imported external package constants by namespace',
    );
    is(
        $result->{composition_spec}->top->top_symbols->resolve_actual_payload('shared_local.mode.BUSY'),
        '1',
        'resolved top symbols expose imported embedded package enum members by namespace',
    );
    like($hdl, qr/assign\s+shared_out\s*=\s*8'b10100101\s*;/, 'generated HDL emits external package constant top-output assignments');
    like($hdl, qr/assign\s+shared_flag\s*=\s*1'b1\s*;/, 'generated HDL emits embedded package enum-member top-output assignments');
    like($hdl, qr/assign\s+packed_out\s*=\s*\{prefix,\s*1'b0,\s*4'b1010\}\s*;/, 'generated HDL emits package-backed concat operands through the typed structural path');
    like($hdl, qr/\.data_in\(8'b10100101\)/, 'generated HDL binds imported package constants into child inputs');
    like($hdl, qr/\.enable\(1'b1\)/, 'generated HDL binds imported package enum members into child inputs');

    my @cmd = ('./bin/fsmgen', '--quiet', '--path', $libdir, '-o', $output_path, $composition_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok($success, 'CLI accepts imported package actuals on the bounded composition path');
    ok(-e $output_path, 'CLI emits HDL for composition sources that import semantic packages');
    ok(!defined($error_code) || $error_code == 0, 'CLI exits successfully for package-backed composition generation');
    unlike($combined_output, qr/package-source .* blocked|does not generate HDL directly/s, 'successful package-backed CLI generation does not report package-boundary failures');
};

subtest 'pipeline and CLI reject direct package roots as non-generating sources' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $package_path = File::Spec->catfile($tempdir, 'shared_external.fsm');
    my $output_path = File::Spec->catfile($tempdir, 'shared_external.sv');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_external
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($package_path);
        undef;
    };
    $pipeline_error = $@;

    like(
        $pipeline_error,
        qr/Package source '\?pkg:shared_external' does not generate HDL directly/s,
        'pipeline rejects direct package roots with a targeted package-boundary diagnostic',
    );

    my @cmd = ('./bin/fsmgen', '--quiet', '-o', $output_path, $package_path);
    my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) = run(command => \@cmd, verbose => 0);
    my $combined_output = join('', @{$stdout_buf || []}, @{$stderr_buf || []});

    ok(!$success, 'CLI rejects direct package roots');
    ok(!-e $output_path, 'CLI does not emit HDL for direct package roots');
    like(
        $combined_output,
        qr/Package source '\?pkg:shared_external' does not generate HDL directly/s,
        'CLI surfaces the targeted direct-package-root boundary',
    );
    isnt($error_code, 0, 'CLI exits non-zero for direct package roots');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
