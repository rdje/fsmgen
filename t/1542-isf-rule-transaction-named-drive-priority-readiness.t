#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Pipeline::HDLGenerator;
use FSM::ProjectDataLocality qw(configure_project_temp_environment create_project_tempdir);
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::LoweringIR;

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
configure_project_temp_environment(purpose => 'tests');
my $workspace = create_project_tempdir(purpose => 'tests');

subtest 'direct transaction assignment priority remains mechanically exclusive' => sub {
    my $path = data_path('isf_rule_transaction_direct_priority_control.isf');
    my $source = slurp($path);
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $path);
    my $schedule = decode_json(FSM::Scheduler::ISF->new()->report($actor));

    is_deeply(
        $schedule->{priority_resolutions},
        [{
            target => 'out',
            winner => 'force_out',
            winner_kind => 'rule',
            loser => 'main',
            loser_kind => 'transaction',
        }],
        'schedule reports direct rule-over-transaction suppression',
    );
    is_deeply($schedule->{compile_issues}, [], 'direct priority control has no compile issue');

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $transaction_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'main',
        owner_kind => 'transaction',
    );
    is_deeply(
        $transaction_out->{priority_suppressed_by},
        ['force_out'],
        'direct transaction assignment records its higher-priority suppressor',
    );
    is_deeply(
        $transaction_out->{activation}{assignment_guard},
        { expr => '(! override_req)' },
        'direct transaction assignment is guarded by the inverse rule condition',
    );

    my $hdl = generate_hdl('direct_priority_control', $source, $path);
    like(
        $hdl,
        qr/assign main_update_1_out_0_en = main_update_1_en & not_override_req;/,
        'direct generated selector enable includes the priority guard',
    );
    run_runtime(
        module => 'direct_priority_control',
        hdl => $hdl,
        testbench => data_path('isf_rule_transaction_direct_priority_control_tb.svt'),
        top => 'direct_priority_control_tb',
        expect_success => 1,
        expected_output => qr/PASS direct rule\/transaction priority out=1/,
    );
};

subtest 'transaction-invoked named drive retains separate provenance and conflicts at runtime' => sub {
    my $path = data_path('isf_rule_transaction_named_drive_priority_probe.isf');
    my $source = slurp($path);
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', $path);
    ok($check->{success}, 'strict public check currently accepts the named-drive overlap');
    is($check->{diagnostic_summary}{diagnostic_count}, 0, 'strict public check exposes no diagnostic for the overlap');

    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $path);
    my $schedule = decode_json(FSM::Scheduler::ISF->new()->report($actor));
    is_deeply($schedule->{priority_resolutions}, [], 'named-drive overlap records no priority resolution');
    is(scalar(@{$schedule->{compile_issues}}), 1, 'named-drive overlap records one compile issue');
    is($schedule->{compile_issues}[0]{code}, 'isf_unproven_rule_drive_overlap', 'compile issue uses the rule/drive code');
    is($schedule->{compile_issues}[0]{severity}, 'warning', 'compile issue remains warning-only');
    is($schedule->{compile_issues}[0]{proof_status}, 'not_doable', 'compile issue remains unproved');
    is_deeply(
        [map { [$_->{owner}, $_->{owner_kind}, $_->{source_kind}, $_->{rhs}] }
            @{$schedule->{compile_issues}[0]{sources}}],
        [
            ['force_out', 'rule', 'rule_action', '1'],
            ['drive_zero', 'drive', 'drive_body', '0'],
        ],
        'public schedule loses the invoking transaction at the drive-body boundary',
    );

    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my $drive_start = find_provenance(
        $ir,
        target => 'drive_zero_start',
        owner => 'main',
        source_kind => 'drive_call_start',
    );
    is($drive_start->{owner_kind}, 'transaction', 'drive-call request retains transaction provenance');
    my $drive_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'drive_zero',
        source_kind => 'drive_body',
    );
    is($drive_out->{owner_kind}, 'drive', 'drive body changes provenance owner kind to drive');
    is_deeply($drive_out->{priority_suppressed_by}, [], 'drive output records no transaction-level suppressor');
    is_deeply(
        $drive_out->{activation}{assignment_guard},
        { port => 'drive_zero_start' },
        'drive output sees only the aggregate drive request',
    );

    my $hdl = generate_hdl('named_drive_priority_probe', $source, $path);
    like(
        $hdl,
        qr/assign drive_zero_out_0_en = drive_zero_en & \(\|drive_zero_start\);/,
        'named-drive selector enable has no rule-priority guard',
    );
    like(
        $hdl,
        qr/assert \(\$onehot0\(\{out_0_en, out_1_en\}\)\) else \$error\("selector multi-value conflict: out"\);/,
        'generated multi-value selector assertion remains authoritative',
    );

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', $path);
    my ($out_family) = grep { $_->{signal_name} eq 'out' }
        @{$semantic->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families}};
    is_deeply($out_family->{driver_blocks}, ['-drive_zero', '-force_out'], 'semantic output family exposes both drive blocks');
    is_deeply($out_family->{rhs_values}, ['0', '1'], 'semantic output family exposes both values');

    run_runtime(
        module => 'named_drive_priority_probe',
        hdl => $hdl,
        testbench => data_path('isf_rule_transaction_named_drive_priority_probe_tb.svt'),
        top => 'named_drive_priority_probe_tb',
        expect_success => 0,
        expected_output => qr/selector multi-value conflict: out/,
    );
};

subtest 'shared named-drive activation requires caller-aware handling' => sub {
    my $source = <<'ISF';
(actor named_drive_multi_caller_boundary
  (clock clk)
  (reset reset)
  (interface
    (input main_start)
    (input auxiliary_start)
    (input override_req)
    (output main_done)
    (output auxiliary_done)
    (output out))
  (priority force_out over main)
  (drive drive_zero
    (out 0))
  (transaction main
    (on main_start)
    (drive drive_zero)
    (complete main_done))
  (transaction auxiliary
    (on auxiliary_start)
    (drive drive_zero)
    (complete auxiliary_done))
  (rule force_out override_req
    (out 1)))
ISF
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, 'named-drive-multi-caller-boundary.isf');
    my $ir = FSM::Scheduler::ISF::LoweringIR->new()->build_module($actor);
    my @callers = sort map { $_->{owner} } grep {
        $_->{target} eq 'drive_zero_start' && $_->{source_kind} eq 'drive_call_start'
    } @{$ir->{assignment_provenance}};
    is_deeply(\@callers, ['auxiliary', 'main'], 'call sites retain two distinct transaction owners');

    my $drive_out = find_provenance(
        $ir,
        target => 'out',
        owner => 'drive_zero',
        source_kind => 'drive_body',
    );
    is_deeply(
        $drive_out->{activation}{assignment_guard},
        { port => 'drive_zero_start' },
        'shared drive body sees only the aggregate request after caller fan-in',
    );
    note('whole-drive masking would suppress the unrelated auxiliary caller; the contract must preserve caller identity or fail closed');
};

done_testing();

sub generate_hdl {
    my ($module, $source, $source_path) = @_;
    my $actor = FSM::Adapter::ISF->new()->parse_source($source, $source_path);
    my $fsm = FSM::Scheduler::ISF->new()->lower($actor)->{files}{"$module.fsm"};
    my $fsm_path = File::Spec->catfile($workspace, "$module.fsm");
    write_file($fsm_path, $fsm);
    return FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    )->generate_hdl_from_file($fsm_path)->{hdl_code};
}

sub run_runtime {
    my (%args) = @_;
    my $hdl_path = File::Spec->catfile($workspace, "$args{module}.sv");
    write_file($hdl_path, $args{hdl});
    my $objdir = File::Spec->catdir($workspace, "obj-$args{module}");
    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '-j', '1', '--sv', '--top-module', $args{top}, '--Mdir', $objdir,
            $hdl_path, $args{testbench},
        ],
    );
    my $compile_output = join('', @{$compile_stdout || []}, @{$compile_stderr || []});
    ok($compile_ok, "$args{module} assertion-enabled Verilator build succeeds")
        or diag($compile_output);
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, "V$args{top}");
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    my $run_output = join('', @{$run_stdout || []}, @{$run_stderr || []});
    is($run_ok ? 1 : 0, $args{expect_success} ? 1 : 0, "$args{module} runtime has the expected success state")
        or diag($run_output);
    like($run_output, $args{expected_output}, "$args{module} runtime exposes the expected outcome");
}

sub run_json_command {
    my @command = @_;
    my ($ok, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $stderr_text = join('', @{$stderr || []});
    ok($ok, "@command succeeds") or diag($stderr_text);
    is($stderr_text, '', "@command keeps stderr clean");
    my $json = join('', @{$stdout || []});
    return decode_json($json);
}

sub find_provenance {
    my ($ir, %want) = @_;
    RECORD:
    for my $record (@{$ir->{assignment_provenance} || []}) {
        for my $key (sort keys %want) {
            next RECORD unless defined($record->{$key}) && $record->{$key} eq $want{$key};
        }
        return $record;
    }
    return {};
}

sub data_path {
    my ($name) = @_;
    return File::Spec->catfile($FindBin::Bin, 'data', $name);
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $content or die "write $path: $!";
    close $fh or die "close $path: $!";
}
