#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Fcntl qw(O_CREAT O_EXCL O_NOFOLLOW O_WRONLY);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use POSIX qw(_exit strftime);
use Test::More;
use Time::HiRes qw(sleep time);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::Runner;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::Backend::VerilatorLifecycle;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

plan skip_all =>
    'set FSMGEN_VIAL_MACOS_PREMAIN_QUALIFICATION=1 for host qualification'
    unless $ENV{FSMGEN_VIAL_MACOS_PREMAIN_QUALIFICATION};
plan skip_all => 'macOS pre-main qualification is Darwin-specific'
    unless $^O eq 'darwin';

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $json = JSON::PP->new->canonical(1);
my $condition =
    $ENV{FSMGEN_VIAL_MACOS_PREMAIN_CONDITION} // '';
die "FSMGEN_VIAL_MACOS_PREMAIN_CONDITION must be concurrent_link or quiet_no_compiler\n"
    unless $condition eq 'concurrent_link'
        || $condition eq 'quiet_no_compiler';
my $output_rel = $ENV{FSMGEN_VIAL_MACOS_PREMAIN_OUTPUT} // '';
die "FSMGEN_VIAL_MACOS_PREMAIN_OUTPUT must name one new repository-local qualification JSON\n"
    unless $output_rel =~ m{\A[.]artifacts/qualification/vial-macos-premain/[A-Za-z0-9_.-]+[.]json\z};
my $output_abs = repo_path($output_rel);
die "qualification output already exists or is a symlink\n"
    if -e $output_abs || -l $output_abs;

my $control_rel = ".artifacts/tmp/vial-macos-premain-qualification-$$";
my $control_abs = repo_path($control_rel);
my $sample_rel = $output_rel;
$sample_rel =~ s/[.]json\z/.sample.txt/;
my $sample_abs = repo_path($sample_rel);
my $sample_summary_rel = "$control_rel/sample-summary.json";
my $sample_summary_abs = repo_path($sample_summary_rel);
my $stage_abs;
my $record_published = 0;

END {
    remove_tree($control_abs)
        if defined($control_abs) && -d $control_abs && !-l $control_abs;
    remove_tree($stage_abs)
        if defined($stage_abs) && -d $stage_abs && !-l $stage_abs;
    unlink($sample_abs)
        if !$record_published && defined($sample_abs)
            && -f $sample_abs && !-l $sample_abs;
}

my $version = supervised(['/opt/homebrew/bin/verilator', '--version'], 10, 65_536);
plan skip_all => 'exact qualified Verilator 5.046 build is not installed'
    unless $version->{ok}
        && $version->{output}
            eq "Verilator 5.046 2026-02-28 rev vUNKNOWN-built20260228\n";

die "qualification control root already exists or is a symlink\n"
    if -e $control_abs || -l $control_abs;
validate_output_ancestry();
make_path($control_abs);
my $host_before = host_snapshot();
if ($condition eq 'concurrent_link') {
    ok(
        $host_before->{concurrency}{compiler_process_count} > 0,
        'concurrent-link condition has at least one unrelated compiler process',
    );
    BAIL_OUT('concurrent-link condition changed before qualification began')
        unless $host_before->{concurrency}{compiler_process_count} > 0;
}
else {
    is(
        $host_before->{concurrency}{compiler_process_count}, 0,
        'quiet-host condition has no unrelated compiler process',
    );
    BAIL_OUT('quiet-host condition changed before qualification began')
        unless $host_before->{concurrency}{compiler_process_count} == 0;
}

my ($execution_ir, $emission) = canonical_route();
my $stage_rel = ".artifacts/tmp/vial/$emission->{operation_id}";
$stage_abs = repo_path($stage_rel);
my $request = {
    repo_root => $repo_root,
    execution_ir => $execution_ir,
    emission => clone($emission),
    storage_context => {
        schema => 'fsmgen.vial_verilator_lifecycle_storage.v1',
        schema_version => 1,
        mode => 'public_runner',
        staging_identity => $stage_rel,
        containment => 'lifecycle_process_group',
    },
};

my $current = FSM::VIAL::Backend::Runner::_lifecycle_begin_for_test(
    $request,
);
ok($current->{ok}, 'qualification lifecycle admits exactly once');
for my $target (qw(prepared tool_verified compiled)) {
    last unless $current->{ok};
    $current = lifecycle_advance($request, $current->{handle});
    ok($current->{ok}, "qualification lifecycle reaches $target");
    is($current->{status}, $target, "$target state is exact")
        if $current->{ok};
}
BAIL_OUT('qualification could not produce the exact compiled executable')
    unless $current->{ok} && $current->{status} eq 'compiled';

my $compile_command = compile_command($emission);
my $binary_rel = $compile_command->{expected_outputs}[0];
my $binary_abs = repo_path($binary_rel);
my $binary_before = binary_metadata($binary_rel);
is(
    $binary_before->{sha256},
    $current->{stage_evidence}[-1]{evidence}{executable_sha256},
    'metadata census names the sealed executable bytes',
);
is($binary_before->{mode}, '0755', 'sealed executable mode is exact');

my $copy_rel = "$control_rel/generated-byte-identical-control";
my $copy_abs = repo_path($copy_rel);
copy($binary_abs, $copy_abs)
    or BAIL_OUT("cannot create byte-identical qualification control: $!");
chmod 0755, $copy_abs
    or BAIL_OUT("cannot seal byte-identical qualification control mode: $!");
my $copy_before = binary_metadata($copy_rel);
is(
    $copy_before->{sha256}, $binary_before->{sha256},
    'counterfactual control is byte-identical before either execution',
);

my $runtime_before_primary = runtime_snapshot();
my $primary_started_at_utc = utc_now();
my $sampler_pid = start_sampler($binary_rel);
my $primary = lifecycle_advance($request, $current->{handle});
my $primary_finished_at_utc = utc_now();
my $runtime_after_primary = runtime_snapshot();
my $sampler = finish_sampler($sampler_pid);
my $primary_capture = compact_capture(
    $primary->{stage_evidence}[-1]{evidence}{capture},
);
my $primary_ok = $primary->{ok} && $primary->{status} eq 'ran';
my $final_cleanup_removed = JSON::PP::false;
ok($primary_ok, 'primary generated executable reaches the ran state');
if ($primary_ok) {
    $current = $primary;
    for my $target (qw(trace_validated result_produced assembled)) {
        $current = lifecycle_advance($request, $current->{handle});
        ok($current->{ok}, "qualification lifecycle reaches $target");
        last unless $current->{ok};
    }
    my $finished = $current->{ok}
        ? FSM::VIAL::Backend::Runner::_lifecycle_finish_for_test({
            %{$request}, handle => clone($current->{handle}),
        })
        : $current;
    ok($finished->{ok}, 'successful primary lifecycle finishes exactly');
    $final_cleanup_removed = $finished->{cleanup}{removed}
        ? JSON::PP::true : JSON::PP::false;
    ok(
        $finished->{cleanup}{removed}
            && !-e $stage_abs && !-l $stage_abs,
        'successful primary lifecycle leaves zero staging residue',
    );
}
else {
    $final_cleanup_removed = $primary->{cleanup}{removed}
        ? JSON::PP::true : JSON::PP::false;
    ok(
        $primary->{cleanup}{removed}
            && !-e $stage_abs && !-l $stage_abs,
        'failed primary lifecycle remains a failure and cleans exactly',
    );
}

my $copy_run = supervised([$copy_rel], 30, 67_108_864);
ok($copy_run->{ok}, 'byte-identical different-path control executes once');
my $minimal_rel = "$control_rel/minimal-control.cc";
my $minimal_abs = repo_path($minimal_rel);
write_exclusive(
    $minimal_abs,
    qq{#include <cstdio>\nint main() { return std::fputs("minimal-control-ready\\n", stdout) < 0; }\n},
    0644,
);
my $minimal_binary_rel = "$control_rel/minimal-control";
my $minimal_compile = supervised(
    ['/usr/bin/clang++', '-std=c++17', '-o', $minimal_binary_rel, $minimal_rel],
    30, 1_048_576,
);
ok($minimal_compile->{ok}, 'same-volume minimal C++ control compiles freshly');
my $minimal_before = $minimal_compile->{ok}
    ? binary_metadata($minimal_binary_rel) : undef;
my $minimal_run = $minimal_compile->{ok}
    ? supervised([$minimal_binary_rel], 30, 1_048_576)
    : {ok => JSON::PP::false, output => ''};
ok($minimal_run->{ok}, 'fresh minimal C++ control executes once');
is(
    $minimal_run->{output}, "minimal-control-ready\n",
    'fresh minimal C++ control reaches main and first output',
) if $minimal_run->{ok};
my $system_true = supervised(['/usr/bin/true'], 10, 65_536);
ok($system_true->{ok}, 'platform-signed no-output supervisor control executes');

my $host_after = host_snapshot();
my $record = {
    schema => 'fsmgen.vial_macos_premain_qualification.v1',
    schema_version => 1,
    work_unit =>
        'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.5.3.1',
    recorded_at_utc => utc_now(),
    condition => $condition,
    host_before => $host_before,
    host_after => $host_after,
    lifecycle => {
        operation_id => $emission->{operation_id},
        started_at_utc => $primary_started_at_utc,
        finished_at_utc => $primary_finished_at_utc,
        environment_before => $runtime_before_primary,
        environment_after => $runtime_after_primary,
        primary_ok => $primary_ok ? JSON::PP::true : JSON::PP::false,
        capture => $primary_capture,
        runtime_output_sha256 => $primary_ok
            ? $primary->{stage_evidence}[-1]{evidence}{runtime_output_sha256}
            : undef,
        diagnostic => $primary_ok ? undef : clone($primary->{diagnostics}),
        cleanup_removed => $final_cleanup_removed,
        sample => $sampler,
    },
    generated_binary => $binary_before,
    byte_identical_control => {
        metadata => $copy_before,
        capture => compact_capture($copy_run),
    },
    minimal_cpp_control => {
        metadata => $minimal_before,
        compile => compact_capture($minimal_compile),
        run => compact_capture($minimal_run),
    },
    platform_control => {
        executable => '/usr/bin/true',
        capture => compact_capture($system_true),
    },
    boundaries => {
        retry_count => 0,
        run_deadline_seconds => 30,
        signing_changed => JSON::PP::false,
        security_changed => JSON::PP::false,
        unrelated_process_changed => JSON::PP::false,
        failed_result_promoted => JSON::PP::false,
    },
};
is_deeply(
    [sort keys %{$record}],
    [sort qw(
        schema schema_version work_unit recorded_at_utc condition host_before
        host_after lifecycle generated_binary byte_identical_control
        minimal_cpp_control platform_control boundaries
    )],
    'qualification record has one closed top-level schema',
);
is_deeply(
    [sort keys %{$record->{lifecycle}}],
    [sort qw(
        operation_id started_at_utc finished_at_utc environment_before
        environment_after primary_ok capture runtime_output_sha256 diagnostic
        cleanup_removed sample
    )],
    'qualification lifecycle evidence has one closed key set',
);
is_deeply(
    [sort keys %{$record->{boundaries}}],
    [sort qw(
        retry_count run_deadline_seconds signing_changed security_changed
        unrelated_process_changed failed_result_promoted
    )],
    'qualification non-workaround boundary is closed',
);
my $canonical_record = $json->encode($record);
is_deeply(
    $json->decode($canonical_record), $record,
    'qualification record is wholly canonical-JSON-safe',
);
unlike(
    $canonical_record,
    qr{(?:/Volumes/|/Users/|[.]\./)},
    'qualification record leaks no absolute host or parent-relative path',
);
make_path(dirname($output_abs));
my $record_text = $json->pretty->encode($record);
write_exclusive($output_abs, $record_text, 0644);
$record_published = 1;
diag(
    "qualification-record: $output_rel sha256="
        . sha256_hex($record_text)
        . ' bytes=' . bytes::length($record_text),
);
diag("qualification-sample: $sample_rel") if -f $sample_abs;

done_testing();

sub lifecycle_advance {
    my ($base, $handle) = @_;
    return FSM::VIAL::Backend::Runner::_lifecycle_advance_for_test({
        %{$base}, handle => clone($handle),
    });
}

sub canonical_route {
    my $vial_path = 'vial/ahb_subordinate_base_output_arbitration.vial';
    my $hial_path = 'ppif/ahb_lite_subordinate.ppif';
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path($vial_path)),
        source_name => $vial_path,
        source_catalog => {},
    });
    my $built = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => source_envelope(
            $hial_path, slurp_raw(repo_path($hial_path)), 'ppif',
        ),
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    BAIL_OUT('canonical qualification plan failed') unless $built->{ok};
    my $emission = FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => ".artifacts/test/vial-macos-premain-contract-$$",
        backend_profile => 'sv_portable_verilator',
    });
    BAIL_OUT('canonical qualification emission failed') unless $emission->{ok};
    return ($built->{execution_ir}, $emission);
}

sub compile_command {
    my ($emission) = @_;
    my ($artifact) = grep {
        $_->{relpath}
            eq 'backends/sv_portable_verilator/commands/compile-command.json'
    } @{$emission->{artifacts}};
    BAIL_OUT('portable emission omitted its compile command')
        unless defined $artifact;
    return $json->decode($artifact->{content});
}

sub source_envelope {
    my ($relative, $text, $kind) = @_;
    return {
        source_id => $relative,
        source_kind_hint => $kind,
        text => $text,
        encoding => 'utf-8',
        origin => 'repository',
        display_name => $relative,
        canonical_id => undef,
        relative_path => $relative,
        metadata => {},
    };
}

sub host_snapshot {
    my $sw_vers = checked_text(['/usr/bin/sw_vers']);
    my $uname = checked_text(['/usr/bin/uname', '-a']);
    my $sysctl = checked_text([
        '/usr/sbin/sysctl', '-n',
        'machdep.cpu.brand_string', 'hw.model', 'hw.machine', 'hw.ncpu',
        'hw.memsize', 'kern.osversion',
    ]);
    my @sysctl = split /\n/, $sysctl;
    my $runtime = runtime_snapshot();
    my $spctl = supervised(['/usr/sbin/spctl', '--status'], 10, 65_536);
    return {
        product => normalized_lines($sw_vers),
        kernel => trim($uname),
        cpu => {
            brand => $sysctl[0], model => $sysctl[1],
            machine => $sysctl[2], logical_cpus => 0 + $sysctl[3],
            memory_bytes => 0 + $sysctl[4], os_build => $sysctl[5],
        },
        tools => {
            verilator => trim($version->{output}),
            clang => trim(checked_text(['/usr/bin/clang++', '--version'])),
        },
        policy => {
            assessment_status_code => $spctl->{exit_code},
            assessment_status => trim($spctl->{output}),
            syspolicyd_cpu_percent_snapshot =>
                $runtime->{syspolicyd_cpu_percent_snapshot},
        },
        concurrency => $runtime->{concurrency},
    };
}

sub runtime_snapshot {
    my $ps = supervised([
        '/bin/ps', '-axo', 'pid=,ppid=,pgid=,%cpu=,state=,command=',
    ], 10, 8_388_608);
    BAIL_OUT('cannot collect the required read-only process census')
        unless $ps->{ok};
    my %kind = (cargo => 0, clang => 0, linker => 0, rustc => 0);
    my $syspolicyd_cpu;
    for my $line (split /\n/, $ps->{output}) {
        next unless $line =~ /^\s*\d+\s+\d+\s+\d+\s+([0-9.]+)\s+\S+\s+(.+)$/;
        my ($cpu, $command) = ($1, $2);
        $syspolicyd_cpu = 0 + $cpu
            if $command eq '/usr/libexec/syspolicyd';
        $kind{rustc}++ if $command =~ m{/(?:rustc)(?:\s|\z)};
        $kind{cargo}++ if $command =~ m{/(?:cargo)(?:\s|\z)};
        $kind{clang}++ if $command =~ m{/(?:clang|clang\+\+)(?:\s|\z)};
        $kind{linker}++ if $command =~ m{/(?:ld|ld64)(?:\s|\z)};
    }
    my $compiler_count = 0;
    $compiler_count += $_ for values %kind;
    return {
        recorded_at_utc => utc_now(),
        syspolicyd_cpu_percent_snapshot => $syspolicyd_cpu,
        concurrency => {
            compiler_process_count => $compiler_count,
            compiler_processes_by_kind => \%kind,
        },
    };
}

sub binary_metadata {
    my ($relative) = @_;
    my $absolute = repo_path($relative);
    BAIL_OUT("qualification binary is absent: $relative")
        unless -f $absolute && !-l $absolute;
    my @stat = lstat($absolute);
    my $xattr = supervised(['/usr/bin/xattr', $relative], 10, 65_536);
    my @xattr_name = $xattr->{ok}
        ? grep { length } split /\n/, $xattr->{output} : ();
    my @xattrs;
    for my $name (sort @xattr_name) {
        my $value = supervised(
            ['/usr/bin/xattr', '-px', $name, $relative], 10, 65_536,
        );
        push @xattrs, {
            name => $name,
            readable => $value->{ok} ? JSON::PP::true : JSON::PP::false,
            value_hex => $value->{ok}
                ? do { my $hex = $value->{output}; $hex =~ s/\s+//g; lc $hex }
                : undef,
        };
    }
    my $display = supervised(
        ['/usr/bin/codesign', '-d', '--verbose=4', $relative],
        10, 262_144,
    );
    my $verify = supervised(
        ['/usr/bin/codesign', '--verify', '--verbose=4', $relative],
        10, 262_144,
    );
    my $otool = supervised(['/usr/bin/otool', '-l', $relative], 10, 2_097_152);
    my $file = supervised(['/usr/bin/file', '-b', $relative], 10, 65_536);
    return {
        relative_path => $relative,
        sha256 => sha256_hex(slurp_raw($absolute)),
        bytes => 0 + $stat[7],
        mode => sprintf('%04o', $stat[2] & 07777),
        device => 0 + $stat[0],
        inode => 0 + $stat[1],
        file_identity => $file->{ok} ? trim($file->{output}) : undef,
        extended_attributes => \@xattrs,
        codesign_display => {
            status => $display->{exit_code},
            lines => normalized_lines(sanitize_host($display->{output})),
        },
        codesign_verify => {
            status => $verify->{exit_code},
            output => trim(sanitize_host($verify->{output})),
        },
        mach_o_load_commands => {
            status => $otool->{exit_code},
            sha256 => sha256_hex(sanitize_host($otool->{output})),
            selected_lines => [grep {
                /\A\s*(?:cmd LC_|uuid |platform |minos |sdk |name |dataoff |datasize )/
            } split /\n/, sanitize_host($otool->{output})],
        },
    };
}

sub start_sampler {
    my ($target_rel) = @_;
    my $pid = fork();
    BAIL_OUT("cannot fork read-only stack sampler: $!") unless defined $pid;
    return $pid if $pid;

    my $summary = {status => 'process_not_observed'};
    my $deadline = time() + 2;
    my $target_pid;
    while (time() < $deadline) {
        my $ps = supervised(['/bin/ps', '-axo', 'pid=,command='], 2, 2_097_152);
        if ($ps->{ok}) {
            for my $line (split /\n/, $ps->{output}) {
                next unless $line =~ /^\s*(\d+)\s+(.+)$/;
                my ($candidate, $command) = ($1, $2);
                if ($command eq $target_rel
                        || index($command, "$target_rel ") == 0
                        || $command eq repo_path($target_rel)
                        || index($command, repo_path($target_rel) . ' ') == 0) {
                    $target_pid = $candidate;
                    last;
                }
            }
        }
        last if defined $target_pid;
        sleep 0.02;
    }
    if (defined $target_pid) {
        $summary = {status => 'exited_before_sample', observed_pid => 0 + $target_pid};
        sleep 2;
        if (kill 0, $target_pid) {
            my $sample = supervised(
                [
                    '/usr/bin/sample', "$target_pid", '1', '1',
                    '-file', $sample_abs,
                ],
                10, 8_388_608,
            );
            if (-e $sample_abs || -l $sample_abs) {
                die "qualification sample is not a regular nonsymlink file\n"
                    unless -f $sample_abs && !-l $sample_abs;
                my @sample_stat = lstat($sample_abs);
                my @repo_stat = lstat($repo_root);
                die "qualification sample changed filesystem volume\n"
                    unless @sample_stat && @repo_stat
                        && $sample_stat[0] == $repo_stat[0];
                my $raw_sample = slurp_raw($sample_abs);
                my $dyld_count = () = $raw_sample =~ /_dyld_start/g;
                my $image_count = () = $raw_sample =~ /^Binary Images:/mg;
                $summary = {
                    status => $sample->{ok} && bytes::length($raw_sample)
                        ? 'sample_captured'
                        : $sample->{ok}
                            ? 'sample_produced_no_output'
                            : 'sample_command_failed',
                    observed_pid => 0 + $target_pid,
                    sample_exit_code => $sample->{exit_code},
                    sample_sha256 => sha256_hex($raw_sample),
                    sample_bytes => bytes::length($raw_sample),
                    dyld_start_occurrences => $dyld_count,
                    binary_image_headers => $image_count,
                    raw_sample_relative_path => $sample_rel,
                };
            }
            else {
                $summary = {
                    status => $sample->{ok}
                        ? 'sample_produced_no_output'
                        : 'sample_command_failed',
                    observed_pid => 0 + $target_pid,
                    sample_exit_code => $sample->{exit_code},
                };
            }
        }
    }
    write_exclusive(
        $sample_summary_abs, $json->encode($summary) . "\n", 0644,
    );
    _exit(0);
}

sub finish_sampler {
    my ($pid) = @_;
    waitpid($pid, 0);
    BAIL_OUT('read-only stack sampler did not exit cleanly') unless $? == 0;
    BAIL_OUT('read-only stack sampler omitted its summary')
        unless -f $sample_summary_abs && !-l $sample_summary_abs;
    return $json->decode(slurp_raw($sample_summary_abs));
}

sub supervised {
    my ($argv, $timeout, $limit) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle::_capture_process(
        {
            repo_root => $repo_root,
            storage_context => {containment => 'lifecycle_process_group'},
        },
        $argv, $timeout, $limit,
    );
}

sub checked_text {
    my ($argv) = @_;
    my $capture = supervised($argv, 10, 1_048_576);
    BAIL_OUT("required metadata command failed: $argv->[0]")
        unless $capture->{ok};
    return $capture->{output};
}

sub compact_capture {
    my ($capture) = @_;
    return undef unless defined $capture;
    my %copy = %{$capture};
    if (exists $copy{output}) {
        my $output = delete $copy{output};
        $copy{output_sha256} = sha256_hex($output // '');
        $copy{output_bytes} = bytes::length($output // '')
            unless exists $copy{output_bytes};
    }
    return clone(\%copy);
}

sub write_exclusive {
    my ($path, $content, $mode) = @_;
    make_path(dirname($path));
    sysopen(my $fh, $path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, $mode)
        or die "cannot create qualification file '$path': $!";
    print {$fh} $content
        or die "cannot write qualification file '$path': $!";
    close $fh or die "cannot close qualification file '$path': $!";
}

sub validate_output_ancestry {
    my $repo_device = (lstat($repo_root))[0];
    my $relative = '';
    for my $component (qw(.artifacts qualification vial-macos-premain)) {
        $relative = length($relative) ? "$relative/$component" : $component;
        my $path = repo_path($relative);
        make_path($path) unless -e $path || -l $path;
        die "qualification output ancestor is not an owned directory: $relative\n"
            unless -d $path && !-l $path;
        my @stat = lstat($path);
        die "qualification output ancestor changed filesystem volume: $relative\n"
            unless @stat && $stat[0] == $repo_device;
    }
    die "qualification sample sidecar already exists or is a symlink\n"
        if -e $sample_abs || -l $sample_abs;
}

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "cannot close '$path': $!";
    return $content;
}

sub clone {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub trim {
    my ($value) = @_;
    $value //= '';
    $value =~ s/\A\s+|\s+\z//g;
    return $value;
}

sub normalized_lines {
    my ($value) = @_;
    return [grep { length } map { trim($_) } split /\n/, $value // ''];
}

sub sanitize_host {
    my ($value) = @_;
    $value //= '';
    $value =~ s{\Q$repo_root\E}{<repo>}g;
    return $value;
}

sub utc_now {
    return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
}

package FSM::VIAL::Backend::Runner;

sub _lifecycle_begin_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->begin_session($raw);
}

sub _lifecycle_advance_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->advance_session($raw);
}

sub _lifecycle_finish_for_test {
    my ($raw) = @_;
    return FSM::VIAL::Backend::VerilatorLifecycle->finish_session($raw);
}

package main;
