#!/usr/bin/env perl

use strict;
use warnings;

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
    $repo_root, 'scripts/run_vial_regression_promotion_corpus.pl',
);
my $fixture_root = repo_path(
    $repo_root, '.artifacts/tmp',
    "vial-regression-promotion-corpus-cli-$$",
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $maximum_output_bytes = 1_048_576;

die "CLI fixture root already exists\n"
    if -e($fixture_root) || -l($fixture_root);
make_path($fixture_root, {mode => 0700});

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root)
            && !-l($fixture_root);
}

subtest 'tracked CLI exposes one closed explicit operation surface' => sub {
    ok(-f($runner) && !-l($runner), 'tracked corpus runner exists');
    ok(-x($runner), 'tracked corpus runner is executable');

    my $limits_run = run_cli($runner, '--limits');
    is($limits_run->{status}, 0, '--limits succeeds without a RAM guard')
        or diag($limits_run->{stderr});
    is($limits_run->{stderr}, '', '--limits emits no diagnostic');
    my $limits = decode_canonical_output(
        $limits_run->{stdout}, 'limits output',
    );
    is_deeply([sort keys %$limits], [sort qw(
        schema schema_version maximum_output_bytes coordination
    )], 'limits output has one closed schema');
    is($limits->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_corpus_cli_limits.v1',
        'limits output is versioned');
    is($json->encode($limits->{schema_version}), '1',
        'limits schema version is a JSON number');
    is($limits->{maximum_output_bytes}, $maximum_output_bytes,
        'limits publish the exact stdout envelope');
    is($limits->{coordination}{profile_count}, 11,
        'limits retain the current coordinator cardinality');

    for my $control (
        ['no operation'],
        ['multiple operations', '--inventory', '--capture'],
        ['positional argument', '--limits', 'foreign'],
        ['unknown option', '--foreign'],
        ['abbreviated option', '--inv'],
        ['case-variant option', '--LIMITS'],
        ['help plus operation', '--help', '--capture'],
    ) {
        my ($name, @arguments) = @$control;
        my $run = run_cli($runner, @arguments);
        is($run->{status}, 2, "$name exits with usage status");
        is($run->{stdout}, '', "$name emits no JSON result");
        like($run->{stderr}, qr/Usage:/, "$name reports the closed usage");
    }

    my $help = run_cli($runner, '--help');
    is($help->{status}, 0, 'standalone help succeeds');
    is($help->{stdout}, '', 'help does not impersonate a JSON result');
    like($help->{stderr}, qr/Exactly one operation is required/,
        'help explains explicit operation selection');
    like($help->{stderr}, qr/--capture may execute real providers and tools/,
        'help makes the expensive capture boundary explicit');
};

subtest 'fresh public paths derive the repository from the script' => sub {
    my ($fixture, $fixture_runner, $log) = cli_fixture('all-modes');
    local $ENV{FSMGEN_TEST_CORPUS_CLI_LOG} = $log;

    for my $mode (qw(inventory capture validate)) {
        my $run = run_cli($fixture_runner, "--$mode");
        is($run->{status}, 0, "--$mode succeeds through the public method")
            or diag($run->{stderr});
        is($run->{stderr}, '', "--$mode emits no diagnostic");
        my $result = decode_canonical_output(
            $run->{stdout}, "$mode output",
        );
        is($result->{operation}, $mode,
            "--$mode selects only the matching coordinator method");
        is_deeply([sort keys %$result], [qw(operation root_source)],
            "--$mode emits only the coordinator result");
        is($result->{root_source}, 'script_location',
            "--$mode does not expose an injectable repository path");
    }

    my @calls = map { $json->decode($_) }
        grep { length } split /\n/, read_raw($log);
    is_deeply([map { $_->{method} } @calls],
        [qw(inventory capture validate)],
        'fresh processes invoke each exact public method once');
    my $canonical_fixture = Cwd::realpath($fixture);
    ok(!scalar(grep {
        $_->{repository_root} ne $canonical_fixture
    } @calls),
        'every public operation derives the fixture root from the script');
};

subtest 'canonical stdout admits the exact cap and rejects cap plus one' => sub {
    my (undef, $fixture_runner) = cli_fixture('output-boundary');

    {
        local $ENV{FSMGEN_TEST_CORPUS_CLI_OUTPUT_BYTES} =
            $maximum_output_bytes;
        my $run = run_cli($fixture_runner, '--capture');
        is($run->{status}, 0, 'exact-cap canonical output succeeds')
            or diag($run->{stderr});
        is(bytes::length($run->{stdout}), $maximum_output_bytes,
            'exact-cap stdout retains every byte including newline');
        decode_canonical_output($run->{stdout}, 'exact-cap output');
    }

    {
        local $ENV{FSMGEN_TEST_CORPUS_CLI_OUTPUT_BYTES} =
            $maximum_output_bytes + 1;
        my $run = run_cli($fixture_runner, '--capture');
        isnt($run->{status}, 0, 'cap-plus-one canonical output rejects');
        is($run->{stdout}, '', 'cap-plus-one emits no partial JSON');
        like($run->{stderr}, qr/exceeds the bounded CLI output envelope/,
            'cap-plus-one retains the exact failure reason');
    }
};

subtest 'coordinator failures propagate without false JSON success' => sub {
    my (undef, $fixture_runner) = cli_fixture('failure');
    local $ENV{FSMGEN_TEST_CORPUS_CLI_FAILURE} = 'synthetic coordinator failure';
    my $run = run_cli($fixture_runner, '--validate');
    isnt($run->{status}, 0, 'coordinator exception remains a CLI failure');
    is($run->{stdout}, '', 'coordinator exception emits no JSON result');
    like($run->{stderr}, qr/synthetic coordinator failure/,
        'coordinator diagnostic remains authoritative');
};

subtest 'fixture cleanup is exact' => sub {
    remove_tree($fixture_root);
    ok(!-e($fixture_root) && !-l($fixture_root),
        'runner copies, doubles, logs, and large outputs leave no residue');
};

done_testing;

sub cli_fixture {
    my ($name) = @_;
    my $root = repo_path($fixture_root, $name);
    my $copy = repo_path(
        $root, 'scripts/run_vial_regression_promotion_corpus.pl',
    );
    my $module = repo_path(
        $root,
        'perl/FSM/VIAL/ArchitectureScaleRegressionPromotionCorpusCoordinator.pm',
    );
    my $log = repo_path($root, '.artifacts/tmp/coordinator-calls.jsonl');
    write_raw($copy, read_raw($runner));
    write_raw($module, <<'PERL');
package FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator;

use strict;
use warnings;
use bytes ();
use JSON::PP ();

my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub coordination_limits {
    return {
        coordination_revision => 'fixture',
        maximum_profile_ipc_bytes => 65_536,
        maximum_error_bytes => 4_096,
        profile_count => 11,
        validation_records => 11,
        raw_measurement_records => 33,
        controller_invocations => 44,
    };
}

sub inventory { return _result('inventory', $_[1]) }
sub capture { return _result('capture', $_[1]) }
sub validate { return _result('validate', $_[1]) }

sub _result {
    my ($method, $request) = @_;
    die "$ENV{FSMGEN_TEST_CORPUS_CLI_FAILURE}\n"
        if defined($ENV{FSMGEN_TEST_CORPUS_CLI_FAILURE});
    if (defined(my $target = $ENV{FSMGEN_TEST_CORPUS_CLI_OUTPUT_BYTES})) {
        my $overhead = bytes::length('{"padding":""}' . "\n");
        die "fixture target is invalid\n" if $target < $overhead;
        return {padding => 'x' x ($target - $overhead)};
    }
    if (defined(my $log = $ENV{FSMGEN_TEST_CORPUS_CLI_LOG})) {
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
    return {operation => $method, root_source => 'script_location'};
}

1;
PERL
    return ($root, $copy, $log);
}

sub run_cli {
    my ($path, @arguments) = @_;
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

sub decode_canonical_output {
    my ($bytes, $label) = @_;
    like($bytes, qr/\n\z/, "$label is newline terminated");
    my $value = eval { $json->decode($bytes) };
    is($@, '', "$label is valid JSON");
    is($bytes, $json->encode($value) . "\n", "$label is canonical JSON");
    return $value;
}

sub repo_path {
    my ($root, @parts) = @_;
    return File::Spec->catfile(
        $root, map { split m{/} } @parts,
    );
}

sub write_raw {
    my ($path, $content) = @_;
    make_path(dirname($path), {mode => 0700}) unless -d dirname($path);
    open my $fh, '>:raw', $path or die "cannot write '$path': $!\n";
    print {$fh} $content or die "cannot populate '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!\n";
    local $/;
    my $content = <$fh> // '';
    close $fh or die "cannot close '$path': $!\n";
    return $content;
}
