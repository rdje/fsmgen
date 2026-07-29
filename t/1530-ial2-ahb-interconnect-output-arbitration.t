#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $temp_root = File::Spec->catdir($repo_root, '.artifacts', 'tmp');
make_path($temp_root);

subtest 'one-window interconnect output modes are exclusive with assertions enabled' => sub {
    run_case(
        label => 'one-window',
        source => 'ppif/ahb_interconnect.ppif',
        harness => 't/data/ahb_interconnect_output_arbitration_one_window_tb.svt',
        top => 'ahb_interconnect_output_arbitration_one_window_tb',
        pass => qr/PASS one-window mapped_zero mapped_nonzero wait success error replacement unmapped/,
        ial0_checks => [
            [
                qr/\(<\(! \(& \(! \(== HTRANS 2'b00\)\) \(< HADDR 4\)\)\)\s+\(= \(HSEL_REGS> 0\)\)\s+\(= \(HADDR_REGS> 0\)\)/s,
                'complementary not-hit mode owns the one-window select/address defaults',
            ],
            [
                qr/\(<\(& \(! ahb_data_owner_0_q\) \(! \(& \(! \(== HTRANS 2'b00\)\) \(! \(< HADDR 4\)\)\)\)\)\s+\(= \(HREADY> 1\)\)\s+\(= \(HRESP> 2'b00\)\)\s+\(= \(HRDATA> 0\)\)/s,
                'ordinary response mode excludes both retained ownership and first-cycle unmapped response',
            ],
        ],
        hdl_checks => [
            [qr/selector multi-value conflict: HSEL_REGS/, 'generated one-window fabric keeps select arbitration assertions'],
            [qr/selector multi-value conflict: HREADY/, 'generated one-window fabric keeps response arbitration assertions'],
        ],
    );
};

subtest 'two-window interconnect output modes are exclusive with assertions enabled' => sub {
    run_case(
        label => 'two-window',
        source => 'ppif/ahb_interconnect_two_subordinate.ppif',
        harness => 't/data/ahb_interconnect_output_arbitration_two_window_tb.svt',
        top => 'ahb_interconnect_output_arbitration_two_window_tb',
        pass => qr/PASS two-window status control local wait success error replacement unmapped/,
        ial0_checks => [
            [
                qr/\(<\(! \(& \(! \(== HTRANS 2'b00\)\) \(< HADDR 4\)\)\)\s+\(= \(HSEL_STATUS> 0\)\)\s+\(= \(HADDR_STATUS> 0\)\)/s,
                'complementary status not-hit mode owns status select/address defaults',
            ],
            [
                qr/\(<\(! \(& \(! \(== HTRANS 2'b00\)\) \(& \(>= HADDR 4\) \(< HADDR 8\)\)\)\)\s+\(= \(HSEL_CONTROL> 0\)\)\s+\(= \(HADDR_CONTROL> 0\)\)/s,
                'complementary control not-hit mode owns control select/address defaults',
            ],
            [
                qr/\(<\(& \(! \(| ahb_data_owner_0_q ahb_data_owner_1_q\)\) \(! \(& \(! \(== HTRANS 2'b00\)\) \(! \(| \(& \(< HADDR 4\)\) \(& \(>= HADDR 4\) \(< HADDR 8\)\)\)\)\)\)\)\s+\(= \(HREADY> 1\)\)/s,
                'ordinary response mode excludes every retained owner and the first-cycle unmapped mode',
            ],
        ],
        hdl_checks => [
            [qr/selector multi-value conflict: HSEL_STATUS/, 'generated two-window fabric keeps status select arbitration assertions'],
            [qr/selector multi-value conflict: HSEL_CONTROL/, 'generated two-window fabric keeps control select arbitration assertions'],
            [qr/selector multi-value conflict: HREADY/, 'generated two-window fabric keeps response arbitration assertions'],
        ],
    );
};

done_testing();

sub run_case {
    my (%case) = @_;
    my $work = tempdir("t1530-$case{label}-XXXXXX", DIR => $temp_root, CLEANUP => 1);
    my $outdir = File::Spec->catdir($work, 'out');
    my $objdir = File::Spec->catdir($work, 'obj');
    my $hdl = File::Spec->catfile($work, 'ahb_tb.sv');
    my $source = repo_file($case{source});
    my $harness = repo_file($case{harness});

    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => [
            repo_file('bin/fsmgen'), '--quiet', '--strict', '--outdir', $outdir,
            '--output', $hdl, $source,
        ],
    );
    ok($generate_ok, "$case{label} public source emits strict HDL and review artifacts")
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;
    is(join('', @{$generate_stderr || []}), '', "$case{label} strict generation keeps stderr clean");

    my $ial0 = slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm'));
    for my $check (@{$case{ial0_checks}}) {
        like($ial0, $check->[0], $check->[1]);
    }

    my $emitted = slurp($hdl);
    like($emitted, qr/\bmodule\s+ahb_interconnect\b/, "$case{label} HDL contains the generated fabric module");
    for my $check (@{$case{hdl_checks}}) {
        like($emitted, $check->[0], $check->[1]);
    }

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '-Wno-fatal', '-Wno-PINMISSING',
            '-j', '1', '--top-module', $case{top}, '--Mdir', $objdir, $hdl, $harness,
        ],
    );
    ok($compile_ok, "$case{label} assertion-enabled direct fabric harness builds")
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;
    unlike(
        join('', @{$compile_stdout || []}, @{$compile_stderr || []}),
        qr/UNOPTFLAT/,
        "$case{label} fabric build remains free of combinational-loop warnings",
    );

    my $binary = File::Spec->catfile($objdir, 'V' . $case{top});
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, "$case{label} assertion-enabled direct fabric runtime succeeds")
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    return unless $run_ok;
    is(join('', @{$run_stderr || []}), '', "$case{label} runtime keeps stderr clean");
    like(join('', @{$run_stdout || []}), $case{pass}, "$case{label} runtime covers the selected output modes");
}

sub repo_file {
    return File::Spec->catfile($repo_root, split('/', $_[0]));
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
