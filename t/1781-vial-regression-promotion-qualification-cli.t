#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use bytes ();
use Cwd ();
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $repo_root = Cwd::realpath(File::Spec->catdir($FindBin::Bin, '..'));
my $runner = repo_path(
    $repo_root,
    'scripts/run_vial_regression_promotion_budget_qualification.pl',
);
my $fixture_root = repo_path(
    $repo_root, '.artifacts/tmp',
    "vial-regression-promotion-qualification-cli-$$",
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $maximum_output_bytes = 1_048_576;
my $maximum_error_bytes = 4_096;

die "qualification CLI fixture root already exists\n"
    if -e($fixture_root) || -l($fixture_root);
make_path($fixture_root, {mode => 0700});

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root)
            && !-l($fixture_root);
}

subtest 'tracked CLI exposes one closed explicit operation surface' => sub {
    ok(-f($runner) && !-l($runner), 'tracked qualification runner exists');
    ok(-x($runner), 'tracked qualification runner is executable');

    for my $control (
        ['no operation'],
        ['multiple operations', '--publish', '--validate'],
        ['positional argument', '--publish', 'foreign'],
        ['unknown option', '--foreign'],
        ['abbreviated option', '--pub'],
        ['case-variant option', '--PUBLISH'],
        ['help plus operation', '--help', '--validate'],
    ) {
        my ($name, @arguments) = @$control;
        my $run = run_cli($runner, @arguments);
        is($run->{status}, 2, "$name exits with usage status");
        is($run->{stdout}, '', "$name emits no JSON result");
        like($run->{stderr}, qr/Usage:/, "$name reports the closed usage");
        cmp_ok(bytes::length($run->{stderr}), '<=', $maximum_error_bytes,
            "$name diagnostic stays bounded");
    }

    my $help = run_cli($runner, '--help');
    is($help->{status}, 0, 'standalone help succeeds');
    is($help->{stdout}, '', 'help does not impersonate a JSON result');
    like($help->{stderr}, qr/Exactly one operation is required/,
        'help explains explicit operation selection');
    like($help->{stderr}, qr/does not activate performance enforcement/,
        'help keeps publication separate from the gate');
};

subtest 'fresh public paths derive the repository from the script' => sub {
    my ($fixture, $fixture_runner, $log) = cli_fixture('both-modes');
    local $ENV{FSMGEN_TEST_QUALIFICATION_CLI_LOG} = $log;

    for my $mode (qw(publish validate)) {
        my $run = run_cli($fixture_runner, "--$mode");
        is($run->{status}, 0, "--$mode succeeds through the public store")
            or diag($run->{stderr});
        is($run->{stderr}, '', "--$mode emits no diagnostic");
        my $result = decode_canonical_output(
            $run->{stdout}, "$mode output",
        );
        is($result->{operation}, $mode,
            "--$mode selects only the matching store method");
        is_deeply([sort keys %$result], [qw(operation root_source)],
            "--$mode emits only the store result");
        is($result->{root_source}, 'script_location',
            "--$mode exposes no caller repository path");
    }

    my @calls = map { $json->decode($_) }
        grep { length } split /\n/, read_raw($log);
    is_deeply([map { $_->{method} } @calls], [qw(publish load)],
        'fresh processes invoke each exact public store method once');
    my $canonical_fixture = Cwd::realpath($fixture);
    ok(!scalar(grep {
        $_->{repository_root} ne $canonical_fixture
    } @calls), 'both operations derive the fixture root from the script');
};

subtest 'canonical stdout admits the exact cap and rejects cap plus one' => sub {
    my (undef, $fixture_runner) = cli_fixture('output-boundary');

    {
        local $ENV{FSMGEN_TEST_QUALIFICATION_CLI_OUTPUT_BYTES} =
            $maximum_output_bytes;
        my $run = run_cli($fixture_runner, '--publish');
        is($run->{status}, 0, 'exact-cap canonical output succeeds')
            or diag($run->{stderr});
        is(bytes::length($run->{stdout}), $maximum_output_bytes,
            'exact-cap stdout retains every byte including newline');
        decode_canonical_output($run->{stdout}, 'exact-cap output');
    }

    {
        local $ENV{FSMGEN_TEST_QUALIFICATION_CLI_OUTPUT_BYTES} =
            $maximum_output_bytes + 1;
        my $run = run_cli($fixture_runner, '--publish');
        is($run->{status}, 1, 'cap-plus-one output has stable failure status');
        is($run->{stdout}, '', 'cap-plus-one emits no partial JSON');
        like($run->{stderr}, qr/exceeds the bounded CLI output envelope/,
            'cap-plus-one retains the exact failure reason');
        cmp_ok(bytes::length($run->{stderr}), '<=', $maximum_error_bytes,
            'output-bound failure diagnostic stays bounded');
    }
};

subtest 'malformed state and hostile diagnostics fail closed and bounded' => sub {
    my ($fixture, $fixture_runner) = cli_fixture('failures');

    {
        local $ENV{FSMGEN_TEST_QUALIFICATION_CLI_MALFORMED} = 1;
        my $run = run_cli($fixture_runner, '--validate');
        is($run->{status}, 1, 'malformed store state has stable failure status');
        is($run->{stdout}, '', 'malformed store state emits no JSON');
        like($run->{stderr}, qr/store result is invalid/,
            'malformed store state fails at the CLI boundary');
    }

    {
        local $ENV{FSMGEN_TEST_QUALIFICATION_CLI_FAILURE} =
            "$fixture\n" . ("hostile\t" x 2_000);
        my $run = run_cli($fixture_runner, '--publish');
        is($run->{status}, 1, 'store exception has stable failure status');
        is($run->{stdout}, '', 'store exception emits no false JSON success');
        like($run->{stderr}, qr/<repository-root>/,
            'repository path is sanitized from the diagnostic');
        unlike($run->{stderr}, qr/\Q$fixture\E/,
            'machine-local fixture path does not escape');
        unlike($run->{stderr}, qr/[\t\r]/,
            'control characters do not escape');
        like($run->{stderr}, qr/\n\z/,
            'failure diagnostic is exactly newline terminated');
        cmp_ok(bytes::length($run->{stderr}), '<=', $maximum_error_bytes,
            'hostile failure is byte bounded');
    }
};

subtest 'fixture cleanup is exact' => sub {
    remove_tree($fixture_root);
    ok(!-e($fixture_root) && !-l($fixture_root),
        'runner copies, doubles, logs, and large outputs leave no residue');
};

done_testing;

sub cli_fixture($name) {
    my $root = repo_path($fixture_root, $name);
    my $copy = repo_path(
        $root,
        'scripts/run_vial_regression_promotion_budget_qualification.pl',
    );
    my $module = repo_path(
        $root,
        'perl/FSM/VIAL/ArchitectureScaleRegressionPromotionQualificationStore.pm',
    );
    my $log = repo_path($root, '.artifacts/tmp/store-calls.jsonl');
    write_raw($copy, read_raw($runner));
    write_raw($module, <<'PERL');
package FSM::VIAL::ArchitectureScaleRegressionPromotionQualificationStore;

use v5.20;
use strict;
use warnings;
use bytes ();
use JSON::PP ();

my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub artifact_keys {
    return ['padding']
        if defined($ENV{FSMGEN_TEST_QUALIFICATION_CLI_OUTPUT_BYTES});
    return [qw(operation root_source)];
}

sub load_result_keys { return [qw(operation root_source)] }

sub publish { return _result('publish', $_[1]) }
sub load { return _result('load', $_[1]) }

sub _result {
    my ($method, $request) = @_;
    die "$ENV{FSMGEN_TEST_QUALIFICATION_CLI_FAILURE}\n"
        if defined($ENV{FSMGEN_TEST_QUALIFICATION_CLI_FAILURE});
    return [] if $ENV{FSMGEN_TEST_QUALIFICATION_CLI_MALFORMED};
    if (defined(my $target =
            $ENV{FSMGEN_TEST_QUALIFICATION_CLI_OUTPUT_BYTES})) {
        my $overhead = bytes::length('{"padding":""}' . "\n");
        die "fixture target is invalid\n" if $target < $overhead;
        return {padding => 'x' x ($target - $overhead)};
    }
    if (defined(my $log = $ENV{FSMGEN_TEST_QUALIFICATION_CLI_LOG})) {
        my $directory = $log;
        $directory =~ s{/[^/]+\z}{};
        require File::Path;
        File::Path::make_path($directory, {mode => 0700})
            unless -d $directory;
        open my $fh, '>>:raw', $log or die "cannot open fixture log: $!\n";
        print {$fh} $JSON->encode({
            method => $method,
            repository_root => $request->{repository_root},
        }), "\n" or die "cannot write fixture log: $!\n";
        close $fh or die "cannot close fixture log: $!\n";
    }
    return {
        operation => $method eq 'load' ? 'validate' : 'publish',
        root_source => 'script_location',
    };
}

1;
PERL
    return ($root, $copy, $log);
}

sub run_cli($path, @arguments) {
    my $error = gensym;
    my $pid = open3(my $input, my $output, $error,
        $^X, $path, @arguments);
    close $input;
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output;
    close $error;
    waitpid($pid, 0);
    return {
        status => $? == -1 ? -1 : $? >> 8,
        signal => $? & 127,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub decode_canonical_output($bytes, $label) {
    like($bytes, qr/\n\z/, "$label is newline terminated");
    my $value = eval { $json->decode($bytes) };
    is($@, '', "$label is valid JSON");
    is($bytes, $json->encode($value) . "\n", "$label is canonical JSON");
    return $value;
}

sub repo_path($root, @parts) {
    return File::Spec->catfile(
        $root, map { split m{/} } @parts,
    );
}

sub write_raw($path, $content) {
    make_path(dirname($path), {mode => 0700}) unless -d dirname($path);
    open my $fh, '>:raw', $path or die "cannot write '$path': $!\n";
    print {$fh} $content or die "cannot populate '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
}

sub read_raw($path) {
    open my $fh, '<:raw', $path or die "cannot read '$path': $!\n";
    local $/;
    my $content = <$fh> // '';
    close $fh or die "cannot close '$path': $!\n";
    return $content;
}
