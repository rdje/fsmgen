#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use FindBin;
use JSON::PP qw(encode_json decode_json);
use Test::More;
use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');
use FSM::ProjectDataLocality qw(create_project_tempdir repository_root);
use FSM::Test::ProjectDataLocality;

my $root = repository_root();
my $perl = abs_path($^X);
die 'test needs an absolute executable interpreter' unless defined($perl) && -f $perl && -x $perl;
my $workspace = create_project_tempdir(purpose => 'rust-parity-tests');
my $bin = File::Spec->catdir($workspace, 'bin');
my $invalid = File::Spec->catdir($workspace, 'invalid');
make_path($bin, File::Spec->catdir($invalid, 'cargo'));
my $config_path = File::Spec->catfile($workspace, 'config.json');
my $trace_path = File::Spec->catfile($workspace, 'trace.json');
my $cargo = File::Spec->catfile($bin, 'cargo');
my $rustc = File::Spec->catfile($bin, 'rustc');
my $program = <<'PROGRAM';
use strict;
use warnings;
use JSON::PP qw(decode_json);
open my $fh, '<', $config_path or die $!;
my $config = decode_json(do { local $/; <$fh> });
close $fh or die $!;
my $mode = $config->{mode};
$| = 1;
print STDOUT "program-out\n";
print STDERR "program-err\n";
exit 7 if $mode eq 'program_nonzero';
kill 'TERM', $$ if $mode eq 'program_signal';
if ($mode eq 'program_overflow') { print 'x' x 1_048_577; exit 0; }
if ($mode eq 'program_timeout') {
    $SIG{TERM} = 'IGNORE';
    my $child = fork();
    die $! unless defined $child;
    if (!$child) { sleep 60; exit 0; }
    print "descendant=$child\n";
    sleep 60;
}
PROGRAM
my $cargo_program = <<'CARGO';
use strict;
use warnings;
use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP qw(encode_json decode_json);
open my $fh, '<', $config_path or die $!;
my $config = decode_json(do { local $/; <$fh> });
close $fh or die $!;
my $mode = $config->{mode};
my ($target) = map { $ARGV[$_ + 1] } grep { $ARGV[$_] eq '--target-dir' } 0 .. $#ARGV;
die 'missing target directory' unless defined $target;
open my $trace, '>', $config->{trace} or die $!;
print {$trace} encode_json({argv => \@ARGV, cwd => getcwd(), environment => {
    map { $_ => $ENV{$_} } qw(CARGO_HOME CARGO_TARGET_DIR RUSTC TMPDIR TMP TEMP RUSTC_WRAPPER CARGO_BUILD_TARGET)
}});
close $trace or die $!;
print STDERR "build-err\n";
exit 0 if $mode eq 'missing';
if ($mode eq 'malformed') { print "not json\n"; exit 0; }
my $out = File::Spec->catdir($target, 'debug');
make_path($out);
my $exe = File::Spec->catfile($out, 'fsmgen-portable-api-check-smoke');
open my $binary, '>', $exe or die $!;
print {$binary} $mode eq 'exec_error' ? "#!/absent-rust-parity-interpreter\n" : $config->{program};
close $binary or die $!;
chmod($mode eq 'not_executable' ? 0644 : 0755, $exe) or die $!;
if ($mode eq 'symlink') {
    unlink $exe or die $!;
    symlink $config->{outside}, $exe or die $!;
}
$exe = $config->{outside} if $mode eq 'outside';
my $record = {
    reason => 'compiler-artifact', package_id => $config->{package_id},
    manifest_path => $config->{manifest},
    target => {name => 'fsmgen-portable-api-check-smoke', kind => ['bin'], src_path => $config->{source}},
    executable => $exe,
};
$record->{manifest_path} .= '.decoy' if $mode eq 'manifest_decoy';
$record->{package_id} .= '.decoy' if $mode eq 'package_decoy';
$record->{target}{src_path} .= '.decoy' if $mode eq 'source_decoy';
print encode_json($record), "\n";
print encode_json($record), "\n" if $mode eq 'duplicate';
exit 9 if $mode eq 'build_nonzero';
CARGO
my $prefix = "#!$perl\nmy \$config_path = pack('H*', '" . unpack('H*', $config_path) . "');\n";
write_file($cargo, $prefix . $cargo_program, 0755);
write_file($rustc, "#!$perl\nexit 0;\n", 0755);
my $outside = File::Spec->catfile($workspace, 'outside');
write_file($outside, $prefix . $program, 0755);
my $url = File::Spec->catdir($root, qw(rust fsmgen-portable-api));
$url =~ s{([^A-Za-z0-9/_.~-])}{sprintf '%%%02X', ord($1)}ge;
my %config = (
    trace => $trace_path, program => $prefix . $program, outside => $outside,
    manifest => File::Spec->catfile($root, qw(rust fsmgen-portable-api Cargo.toml)),
    source => File::Spec->catfile($root, qw(rust fsmgen-portable-api src bin check_smoke_projection.rs)),
    package_id => "path+file://$url#fsmgen_portable_api\@0.1.0",
);
{
    local $ENV{PATH} = join(':', $invalid, $bin, $ENV{PATH});
    require FSM::Test::RustParityRuntime;
    FSM::Test::RustParityRuntime->import('run_rust_parity');
}

subtest 'caller options cannot change command, path, or budgets' => sub {
    for my $options ([timeout_seconds => 999], [argv => [$outside]], [target_dir => $workspace], [env => {}]) {
        my $rejected = run_rust_parity(@$options);
        is($rejected->{status}, 'invocation_error', 'caller option fails closed');
        is($rejected->{failure_stage}, 'invocation', 'rejection precedes execution');
        ok(!$rejected->{stages}[0]{cleanup}{leader_started}, 'rejection starts no process');
    }
};

subtest 'fixed tools and local fresh artifacts survive later environment changes' => sub {
    local $ENV{PATH} = $invalid;
    local $ENV{RUSTC_WRAPPER} = $outside;
    local $ENV{CARGO_BUILD_TARGET} = 'caller-target';
    my %before = %ENV;
    my $result = invoke('success');
    is_deeply(\%ENV, \%before, 'caller environment is restored exactly');
    ok($result->{ok}, 'initial directory decoy and later PATH mutation cannot replace Cargo') or diag explain $result;
    is_deeply([sort keys %$result], [sort qw(schema schema_version ok status failure_stage stages)], 'aggregate has a closed shape');
    is($result->{schema}, 'fsmgen.test.rust_parity_result.v1', 'aggregate schema is exact');
    is_deeply([map { $_->{stage} } @{$result->{stages}}], [qw(cargo_build perl_oracle rust_execution)], 'separate stages retain execution order');
    my $trace = read_json($trace_path);
    my $target = $trace->{environment}{CARGO_TARGET_DIR};
    is_deeply($trace->{argv}, [
        'build', '--offline', '--locked', '--manifest-path', File::Spec->catfile($root, qw(rust Cargo.toml)),
        '--package', 'fsmgen_portable_api', '--bin', 'fsmgen-portable-api-check-smoke',
        '--message-format=json-render-diagnostics', '--target-dir', $target,
    ], 'build argv is sealed and shell-free');
    is($trace->{cwd}, $root, 'build cwd is the repository');
    is($trace->{environment}{CARGO_HOME}, File::Spec->catdir($root, qw(.artifacts cache cargo)), 'Cargo cache is local');
    is($trace->{environment}{RUSTC}, $rustc, 'rustc identity was selected before PATH mutation');
    ok(!defined $trace->{environment}{RUSTC_WRAPPER}, 'caller wrapper cannot acquire build authority');
    ok(!defined $trace->{environment}{CARGO_BUILD_TARGET}, 'caller target cannot redirect the artifact');
    for my $key (qw(TMPDIR TMP TEMP)) {
        is($trace->{environment}{$key}, File::Spec->catdir($root, qw(.artifacts tmp rust-parity)), "$key is local");
    }
    like(File::Spec->abs2rel($target, $root), qr{\A\.artifacts/build/rust-parity/fsmgen-[^/]+\z}, 'build has an exclusive local workspace');
    ok(!-e $target, 'successful call removes its build workspace');
    is($result->{stages}[-1]{stdout}, "program-out\n", 'program stdout stays separate');
    is($result->{stages}[-1]{stderr}, "program-err\n", 'program stderr stays separate');
    for my $stage (@{$result->{stages}}) {
        my $build = $stage->{stage} eq 'cargo_build';
        is($stage->{timeout_seconds}, $build ? 120 : 10, 'stage wall is fixed');
        is($stage->{capture_limit_bytes}, $build ? 8_388_608 : 1_048_576, 'stage capture is fixed');
        ok($stage->{cleanup}{leader_reaped} && $stage->{cleanup}{group_gone}, 'stage cleanup is proved');
    }
};

subtest 'bad build records cannot launch a stale or decoy artifact' => sub {
    for my $mode (qw(build_nonzero missing malformed duplicate manifest_decoy package_decoy source_decoy outside symlink not_executable)) {
        my $result = invoke($mode);
        ok(!$result->{ok}, "$mode fails closed");
        is($result->{failure_stage}, $mode eq 'build_nonzero' ? 'cargo_build' : 'artifact_admission', "$mode stops at the first failed stage");
        ok(!grep($_->{stage} eq 'perl_oracle' || $_->{stage} eq 'rust_execution', @{$result->{stages}}), "$mode never starts either check program");
        my $target = read_json($trace_path)->{environment}{CARGO_TARGET_DIR};
        ok(!-e $target, "$mode removes only its build workspace");
        ok(-f $outside, "$mode preserves the outside decoy");
    }
};

subtest 'runtime failure truth and hostile descendant cleanup survive the adapter' => sub {
    my %status = (program_nonzero => 'nonzero_exit', program_signal => 'signaled',
        program_overflow => 'output_limited', program_timeout => 'timed_out', exec_error => 'exec_error');
    for my $mode (sort keys %status) {
        my $result = invoke($mode);
        is($result->{status}, $status{$mode}, "$mode keeps engine failure status") or diag explain $result;
        is($result->{failure_stage}, 'rust_execution', "$mode is attributed to direct execution");
        my $stage = $result->{stages}[-1];
        ok($stage->{cleanup}{leader_reaped} && $stage->{cleanup}{group_gone}, "$mode proves cleanup");
        is($stage->{exit_code}, 7, 'nonzero exit is exact') if $mode eq 'program_nonzero';
        is($stage->{signal}, 15, 'signal is not folded into an exit code') if $mode eq 'program_signal';
        if ($mode eq 'program_timeout') {
            ok($stage->{cleanup}{term_sent} && $stage->{cleanup}{kill_sent}, 'TERM-resistant group requires KILL');
            my ($child) = $stage->{stdout} =~ /descendant=(\d+)/;
            ok(defined($child), 'fixture exposed its descendant identity');
            ok(!kill(0, $child), 'reported descendant is gone') if defined $child;
        }
        my $target = read_json($trace_path)->{environment}{CARGO_TARGET_DIR};
        ok(!-e $target, "$mode removes its private build directory");
    }
};

done_testing();

sub invoke {
    my ($mode) = @_;
    write_file($config_path, encode_json({%config, mode => $mode}));
    return run_rust_parity();
}

sub read_json {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $record = decode_json(do { local $/; <$fh> });
    close $fh or die $!;
    return $record;
}

sub write_file {
    my ($path, $content, $mode) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $content or die $!;
    close $fh or die $!;
    chmod $mode, $path or die $! if defined $mode;
}
