#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $isf_file = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'spawn_parent.isf');

subtest 'generated-composition fixture lowers to scheduled parent, child, and top artifacts' => sub {
    my ($files, $report) = lower_spawn_fixture();

    is_deeply(
        sorted([keys %$files]),
        [qw(child_worker.fsm spawn_parent.fsm spawn_parent_top.fsm)],
        'lowering emits the expected generated-composition file set',
    );

    my $top_fsm = $files->{'spawn_parent_top.fsm'};
    my $parent_fsm = $files->{'spawn_parent.fsm'};
    my $child_fsm = $files->{'child_worker.fsm'};

    like($top_fsm, qr/\A\(\?top:spawn_parent_top\b/, 'generated top names the spawn_parent_top module');
    like($top_fsm, qr/\(\?fsmc:spawn_parent spawn_parent\)/, 'generated top instantiates the parent module');
    for my $instance (qw(w0 w1 w2)) {
        like($top_fsm, qr/\(\?fsmc:\Q$instance\E child_worker\)/, "generated top instantiates child $instance");
        like($top_fsm, qr/\(trigger \Q$instance\E\.trigger\)/, "generated top fans public trigger into child $instance");
        like(
            $top_fsm,
            qr/\(spawn_parent\.\Q$instance\E_start \Q$instance\E\.start\)/,
            "generated top wires parent start to child $instance",
        );
        like(
            $top_fsm,
            qr/\(\Q$instance\E\.done spawn_parent\.\Q$instance\E_done\)/,
            "generated top wires child $instance done back to parent",
        );
        like(
            $top_fsm,
            qr/\(\Q$instance\E\.rdata_start spawn_parent\.\Q$instance\E_rdata_start\)/,
            "generated top wires child $instance drive request back to parent",
        );
        like(
            $top_fsm,
            qr/\(\Q$instance\E\.rdata_val spawn_parent\.\Q$instance\E_rdata_val\)/,
            "generated top wires child $instance drive payload back to parent",
        );
    }

    like($parent_fsm, qr/\(parent_main_spawn_1\n\s+\(= \(w0_start> 1\)\)/, 'parent asserts w0 start in the first spawn state');
    like($parent_fsm, qr/\(parent_main_spawn_2\n\s+\(= \(w1_start> 1\)\)/, 'parent asserts w1 start in the second spawn state');
    like($parent_fsm, qr/\(parent_main_spawn_3\n\s+\(= \(w2_start> 1\)\)/, 'parent asserts w2 start in the third spawn state');
    like(
        $parent_fsm,
        qr/\(parent_main_await_all_4\n\s+\(-> parent_main_done_5 <\(& w0_done w1_done w2_done\)\)/,
        'parent awaits all child done handoffs',
    );
    like($parent_fsm, qr/\(<1 \(done> 1\)\)/, 'parent completion remains a one-cycle delayed pulse');
    for my $instance (qw(w0 w1 w2)) {
        like(
            $parent_fsm,
            qr/\(<- \(rdata> \Q$instance\E_rdata_val\) <\Q$instance\E_rdata_start\)/,
            "parent rdata drive block consumes child $instance payload handoff",
        );
    }

    like($child_fsm, qr/\(\?fsm:child_worker\b/, 'child scheduled artifact names child_worker');
    like($child_fsm, qr/\(rdata_start 1\)/, 'child declares the drive request handoff');
    like($child_fsm, qr/\(rdata_val 32\)/, 'child declares the drive payload handoff');
    like($child_fsm, qr/\(= \(rdata_start> 1\)\)/, 'child asserts the drive request output');
    like($child_fsm, qr/\(= \(rdata_val> val\)\)/, 'child exposes sampled payload through the drive payload output');
    unlike($child_fsm, qr/\n\s+\(rdata 32\)\n/, 'child does not expose the parent-owned rdata output directly');

    assert_report_shape($report);
};

subtest 'generated-composition fixture strict schedule JSON matches the in-process report' => sub {
    my (undef, $in_process_report) = lower_spawn_fixture();
    my ($success, $stdout, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--emit-schedule-json',
            $isf_file,
        ],
        'strict schedule JSON generation',
    );

    ok($success, 'strict schedule JSON generation succeeds for the generated-composition fixture');
    is($stderr, '', 'strict schedule JSON generation keeps stderr clean');
    is_deeply(
        decode_json($stdout),
        $in_process_report,
        'strict schedule JSON generation matches the in-process report',
    );
};

subtest 'generated-composition fixture strict outdir and scheduled HDL paths succeed' => sub {
    my ($files) = lower_spawn_fixture();
    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'lowered');
    my $direct_top_hdl = File::Spec->catfile($tempdir, 'spawn_parent_direct_top.sv');

    my ($outdir_success, undef, $outdir_stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--outdir',
            $outdir,
            '--output',
            $direct_top_hdl,
            $isf_file,
        ],
        'strict outdir generation',
    );

    ok($outdir_success, 'strict outdir generation succeeds for the generated-composition fixture');
    is($outdir_stderr, '', 'strict outdir generation keeps stderr clean');
    ok(-f $direct_top_hdl, 'strict outdir generation writes the requested top HDL');

    for my $basename (sort keys %$files) {
        my $path = File::Spec->catfile($outdir, $basename);
        ok(-f $path, "strict outdir generation writes $basename");
        is(slurp($path), $files->{$basename}, "strict outdir $basename matches in-process lowering");
    }

    my $top_hdl = generate_hdl_from_fsm(
        File::Spec->catfile($outdir, 'spawn_parent_top.fsm'),
        File::Spec->catfile($tempdir, 'spawn_parent_top.sv'),
        'generated top scheduled FSM',
    );
    like($top_hdl, qr/\bmodule\s+spawn_parent_top\b/, 'top HDL contains the generated top module');
    like(
        $top_hdl,
        qr/spawn_parent spawn_parent \([\s\S]*?\.w0_rdata_start\(comp_link_w0_rdata_start\)/,
        'top HDL wires the first child drive request into the parent instance',
    );
    like(
        $top_hdl,
        qr/child_worker w0 \([\s\S]*?\.rdata_start\(comp_link_w0_rdata_start\)/,
        'top HDL wires the first child drive request source',
    );
    like(
        $top_hdl,
        qr/child_worker w2 \([\s\S]*?\.rdata_val\(comp_link_w2_rdata_val\)/,
        'top HDL wires the last child drive payload source',
    );

    my $parent_hdl = generate_hdl_from_fsm(
        File::Spec->catfile($outdir, 'spawn_parent.fsm'),
        File::Spec->catfile($tempdir, 'spawn_parent_parent.sv'),
        'parent scheduled FSM',
    );
    like($parent_hdl, qr/\bmodule\s+spawn_parent\b/, 'parent HDL contains the parent module');
    like($parent_hdl, qr/\bPARENT_MAIN_AWAIT_ALL_4\b/, 'parent HDL contains the await-all state encoding');
    like($parent_hdl, qr/\bw0_start\b/, 'parent HDL exposes the first start handoff');
    like($parent_hdl, qr/\bw2_start\b/, 'parent HDL exposes the last start handoff');
    like($parent_hdl, qr/\brdata_next\s*=\s*w0_rdata_val\s*;/, 'parent HDL consumes the first child payload');
    like($parent_hdl, qr/\brdata_next\s*=\s*w2_rdata_val\s*;/, 'parent HDL consumes the last child payload');
    like($parent_hdl, qr/\bdone_pulse_delay_pipe\b/, 'parent HDL implements delayed completion pulse state');

    my $child_hdl = generate_hdl_from_fsm(
        File::Spec->catfile($outdir, 'child_worker.fsm'),
        File::Spec->catfile($tempdir, 'child_worker.sv'),
        'child scheduled FSM',
    );
    like($child_hdl, qr/\bmodule\s+child_worker\b/, 'child HDL contains the child module');
    like($child_hdl, qr/\bCHILD_WORKER_DRIVE_0\b/, 'child HDL contains the child drive state encoding');
    like($child_hdl, qr/\brdata_start\b/, 'child HDL exposes drive request output');
    like($child_hdl, qr/\brdata_val\b/, 'child HDL exposes drive payload output');
    like($child_hdl, qr/\brdata_val\s*=\s*val\s*;/, 'child HDL drives the sampled payload');
    like($child_hdl, qr/\bdone_pulse_delay_pipe\b/, 'child HDL implements delayed completion pulse state');
};

done_testing();

sub lower_spawn_fixture {
    my $actor = FSM::Adapter::ISF->new()->parse_file($isf_file);
    my $scheduler = FSM::Scheduler::ISF->new();
    my $result = $scheduler->lower($actor);
    my $report = decode_json($scheduler->report($actor));

    return ($result->{files}, $report);
}

sub assert_report_shape {
    my ($report) = @_;

    is($report->{source}, 'spawn_parent.isf', 'schedule report names the source fixture');
    is($report->{scheduled_fsm}, 'spawn_parent.fsm', 'schedule report names the parent scheduled FSM');
    is($report->{clock}, 'clk', 'schedule report records the clock');
    is($report->{watchdog}, '65536', 'schedule report records the watchdog literal');
    is_deeply(
        $report->{reset},
        { name => 'rst_n', kind => 'async', polarity => 'active_low' },
        'schedule report records async active-low reset metadata',
    );
    is($report->{inputs}, 10, 'schedule report input count includes generated handoff inputs');
    is($report->{outputs}, 5, 'schedule report output count includes generated start outputs');
    is($report->{port_count}, 15, 'schedule report port count includes generated handoffs');
    is($report->{state_count}, 6, 'schedule report parent state count');
    is_deeply($report->{compile_issues}, [], 'schedule report has no compile issues');

    is_deeply(
        $report->{transactions},
        [
            {
                name => 'parent_main',
                count => 6,
                states => [qw(
                  parent_main_idle_0
                  parent_main_spawn_1
                  parent_main_spawn_2
                  parent_main_spawn_3
                  parent_main_await_all_4
                  parent_main_done_5
                )],
            },
        ],
        'schedule report records the parent transaction state order',
    );
    is_deeply(
        $report->{dt_blocks},
        [{ name => 'rdata', kind => 'drive', assignments => 3 }],
        'schedule report records the parent rdata fan-in drive block',
    );

    my $composition = $report->{generated_composition};
    is($composition->{kind}, 'spawn_generated_top', 'generated composition kind is bounded');
    is($composition->{top_module}, 'spawn_parent_top', 'generated composition reports the top module');
    is($composition->{top_fsm}, 'spawn_parent_top.fsm', 'generated composition reports the top scheduled artifact');
    is_deeply(
        $composition->{parent},
        { module => 'spawn_parent', scheduled_fsm => 'spawn_parent.fsm' },
        'generated composition reports the parent artifact',
    );
    is_deeply(
        $composition->{children},
        [
            {
                transaction => 'child_worker',
                module => 'child_worker',
                scheduled_fsm => 'child_worker.fsm',
                parameters => [],
            },
        ],
        'generated composition reports the child artifact',
    );

    is_deeply(
        [map { $_->{instance} } @{$composition->{instances}}],
        [qw(w0 w1 w2)],
        'generated composition reports all spawned instances in source order',
    );
    for my $instance (@{$composition->{instances}}) {
        my $name = $instance->{instance};
        is($instance->{activation_kind}, 'spawn', "instance $name reports spawn activation kind");
        is($instance->{child}, 'child_worker', "instance $name reports the child module");
        is_deeply(
            $instance->{start},
            { parent_port => "${name}_start", child_port => 'start' },
            "instance $name reports start handoff",
        );
        is_deeply(
            $instance->{done},
            { child_port => 'done', parent_port => "${name}_done" },
            "instance $name reports done handoff",
        );
        is_deeply($instance->{parameter_bindings}, [], "instance $name has no parameter bindings");
        is_deeply(
            $instance->{drive_handoffs},
            [
                {
                    drive => 'rdata',
                    request => {
                        child_port => 'rdata_start',
                        parent_port => "${name}_rdata_start",
                    },
                    payloads => [
                        {
                            parameter => 'val',
                            child_port => 'rdata_val',
                            parent_port => "${name}_rdata_val",
                            width => '32',
                        },
                    ],
                },
            ],
            "instance $name reports rdata request and payload handoffs",
        );

        assert_storage($report, "${name}_done", 'counter', 'activation_done_handoff', 1);
        assert_storage($report, "${name}_rdata_start", 'counter', 'drive_request', 1);
        assert_storage($report, "${name}_rdata_val", 'counter', 'drive_payload', 32);
    }
    assert_storage($report, 'done', 'register', 'completion_pulse', 1);
}

sub assert_storage {
    my ($report, $name, $kind, $role, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "storage entry '$name' exists");
    return unless $entry;
    is($entry->{kind}, $kind, "storage entry '$name' kind");
    is($entry->{role}, $role, "storage entry '$name' role");
    is($entry->{width}, $width, "storage entry '$name' width");
}

sub generate_hdl_from_fsm {
    my ($fsm_file, $output_file, $label) = @_;
    my ($success, undef, $stderr) = run_cli(
        [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--output',
            $output_file,
            $fsm_file,
        ],
        "strict HDL generation for $label",
    );

    ok($success, "strict HDL generation succeeds for $label");
    is($stderr, '', "strict HDL generation keeps stderr clean for $label");
    ok(-f $output_file, "strict HDL generation writes output for $label");

    return slurp($output_file);
}

sub run_cli {
    my ($command, $label) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
      run(command => $command);

    diag("$label failed: $error_message") if !$success && defined $error_message;
    return (
        $success,
        join('', @{$stdout_buf || []}),
        join('', @{$stderr_buf || []}),
    );
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
