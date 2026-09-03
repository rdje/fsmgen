use v5.20;
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

my $repository_root =
    Cwd::realpath(File::Spec->catdir($FindBin::Bin, '..'));
my $runner = repo_path(
    $repository_root,
    'scripts/run_vial_regression_promotion_gate.pl',
);
my $fixture_root = repo_path(
    $repository_root, '.artifacts/tmp',
    "vial-regression-promotion-gate-cli-$$",
);
my $MAX_OUTPUT_BYTES = 1_048_576;
my $MAX_ERROR_BYTES = 4_096;
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

die "gate CLI fixture root already exists\n"
    if -e($fixture_root) || -l($fixture_root);
make_path($fixture_root, {mode => 0700});

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root)
            && !-l($fixture_root);
}

subtest 'tracked CLI has one explicit non-bypassable operation surface' => sub {
    ok(-f($runner) && !-l($runner), 'tracked gate runner exists');
    ok(-x($runner), 'tracked gate runner is executable');

    for my $control (
        ['no operation'],
        ['multiple operations', '--run', '--validate-result'],
        ['repeated operation', '--run', '--run'],
        ['positional argument', '--run', 'foreign'],
        ['unknown option', '--foreign'],
        ['abbreviated option', '--val'],
        ['case-variant option', '--RUN'],
        ['help plus operation', '--help', '--run'],
        ['repeated help', '--help', '--help'],
    ) {
        my ($name, @arguments) = @$control;
        my $result = run_cli($runner, @arguments);
        is($result->{status}, 2, "$name exits with usage status");
        is($result->{stdout}, '', "$name emits no JSON result");
        like($result->{stderr}, qr/Usage:/,
            "$name reports the closed usage");
        cmp_ok(bytes::length($result->{stderr}), '<=', $MAX_ERROR_BYTES,
            "$name diagnostic stays bounded");
    }

    my $help = run_cli($runner, '--help');
    is($help->{status}, 0, 'standalone help succeeds');
    is($help->{stdout}, '', 'help does not impersonate a gate result');
    like($help->{stderr}, qr/There is no default expensive operation/,
        'help makes omission safety explicit');
    like($help->{stderr}, qr/may execute real providers, simulators/,
        'help identifies the expensive run boundary');
    like($help->{stderr}, qr/No flag can downgrade/,
        'help exposes the non-bypassable applicability contract');
    like($help->{stderr}, qr/never recalibrate/,
        'help keeps result observation separate from qualification');
};

subtest 'fresh processes use only the script-derived public store path' => sub {
    my ($fixture, $fixture_runner, $log) = cli_fixture('public-path');
    local $ENV{FSMGEN_TEST_GATE_CLI_LOG} = $log;

    my $run = run_cli($fixture_runner, '--run');
    is($run->{status}, 0, '--run succeeds through publish then reload')
        or diag($run->{stderr});
    is($run->{stderr}, '', '--run emits no diagnostic');
    my $run_result = decode_canonical_output($run->{stdout}, '--run output');
    is_deeply(
        $run_result,
        {operation => 'run', root_source => 'script_location'},
        '--run prints only the admitted gate result',
    );

    my $validate = run_cli($fixture_runner, '--validate-result');
    is($validate->{status}, 0,
        '--validate-result succeeds through producer-free load')
        or diag($validate->{stderr});
    is($validate->{stderr}, '', '--validate-result emits no diagnostic');
    my $validate_result = decode_canonical_output(
        $validate->{stdout}, '--validate-result output',
    );
    is_deeply(
        $validate_result,
        {operation => 'validate-result', root_source => 'script_location'},
        '--validate-result prints only the admitted stored result',
    );

    my @calls = map { $JSON->decode($_) }
        grep { length } split /\n/, read_raw($log);
    is_deeply(
        [map { $_->{method} } @calls],
        [qw(publish load load)],
        'run publishes and reloads while validation only loads',
    );
    my $canonical_fixture = Cwd::realpath($fixture);
    ok(!grep({ $_->{repository_root} ne $canonical_fixture } @calls),
        'every operation derives the fixture root from the script');
    ok(!grep({ exists($_->{result}) || exists($_->{path}) } @calls),
        'the CLI supplies no result or coordinate to the store');
};

subtest 'canonical stdout admits the exact cap and rejects cap plus one' => sub {
    my (undef, $fixture_runner) = cli_fixture('output-boundary');

    {
        local $ENV{FSMGEN_TEST_GATE_CLI_OUTPUT_BYTES} =
            $MAX_OUTPUT_BYTES;
        my $run = run_cli($fixture_runner, '--run');
        is($run->{status}, 0, 'exact-cap gate result succeeds')
            or diag($run->{stderr});
        is(bytes::length($run->{stdout}), $MAX_OUTPUT_BYTES,
            'exact-cap stdout retains every byte including newline');
        decode_canonical_output($run->{stdout}, 'exact-cap output');
    }

    {
        local $ENV{FSMGEN_TEST_GATE_CLI_OUTPUT_BYTES} =
            $MAX_OUTPUT_BYTES + 1;
        my $run = run_cli($fixture_runner, '--validate-result');
        is($run->{status}, 1,
            'cap-plus-one gate result has stable failure status');
        is($run->{stdout}, '', 'cap-plus-one emits no partial JSON');
        like($run->{stderr}, qr/exceeds the bounded CLI output envelope/,
            'cap-plus-one retains the exact failure reason');
        cmp_ok(bytes::length($run->{stderr}), '<=', $MAX_ERROR_BYTES,
            'output-bound failure diagnostic stays bounded');
    }
};

subtest 'malformed state, limit drift, and hostile errors fail bounded' => sub {
    my ($fixture, $fixture_runner) = cli_fixture('failures');

    for my $control (
        ['publish artifact', '--run', 'publish'],
        ['load envelope', '--validate-result', 'load'],
        ['loaded artifact', '--validate-result', 'loaded-artifact'],
        ['gate result', '--validate-result', 'result'],
        ['extra result field', '--validate-result', 'extra-result'],
    ) {
        my ($name, $operation, $malformed) = @$control;
        local $ENV{FSMGEN_TEST_GATE_CLI_MALFORMED} = $malformed;
        my $result = run_cli($fixture_runner, $operation);
        is($result->{status}, 1, "$name has stable failure status");
        is($result->{stdout}, '', "$name emits no false JSON success");
        like($result->{stderr}, qr/(?:store|artifact|gate result)/,
            "$name rejects at a closed result boundary");
        cmp_ok(bytes::length($result->{stderr}), '<=', $MAX_ERROR_BYTES,
            "$name diagnostic stays bounded");
    }

    {
        local $ENV{FSMGEN_TEST_GATE_CLI_LIMIT_DRIFT} = 1;
        my $result = run_cli($fixture_runner, '--validate-result');
        is($result->{status}, 1, 'store limit drift rejects');
        is($result->{stdout}, '', 'store limit drift emits no result');
        like($result->{stderr}, qr/store result ceiling changed/,
            'store limit drift has one exact reason');
    }

    {
        local $ENV{FSMGEN_TEST_GATE_CLI_FAILURE} =
            "$fixture\nhostile\t" . ('x' x 8_192);
        local $ENV{FSMGEN_TEST_GATE_CLI_FAIL_METHOD} = 'publish';
        my $result = run_cli($fixture_runner, '--run');
        is($result->{status}, 1, 'store exception has stable failure status');
        is($result->{stdout}, '', 'store exception emits no partial result');
        like($result->{stderr}, qr/<repository-root>/,
            'repository path is sanitized');
        unlike($result->{stderr}, qr/\Q$fixture\E/,
            'machine-local fixture path does not escape');
        unlike($result->{stderr}, qr/[\t\r]/,
            'control characters do not escape');
        like($result->{stderr}, qr/\n\z/,
            'failure diagnostic is exactly newline terminated');
        cmp_ok(bytes::length($result->{stderr}), '<=', $MAX_ERROR_BYTES,
            'hostile failure is byte bounded');
    }
};

subtest 'copied public-path fixtures leave no filesystem residue' => sub {
    remove_tree($fixture_root);
    ok(!-e($fixture_root) && !-l($fixture_root),
        'runner copies, doubles, logs, and large results are absent');
};

done_testing;

sub cli_fixture {
    my ($name) = @_;
    my $root = repo_path($fixture_root, $name);
    my $copy = repo_path(
        $root, 'scripts/run_vial_regression_promotion_gate.pl',
    );
    my $store = repo_path(
        $root,
        'perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateStore.pm',
    );
    my $coordinator = repo_path(
        $root,
        'perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateCoordinator.pm',
    );
    my $log = repo_path($root, '.artifacts/tmp/gate-store-calls.jsonl');
    write_raw($copy, read_raw($runner));
    chmod 0755, $copy or die "cannot make copied runner executable: $!\n";
    write_raw($store, <<'PERL');
package FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore;

use v5.20;
use strict;
use warnings;
use bytes ();
use JSON::PP ();

my $JSON = JSON::PP->new->canonical(1)->utf8(1);
my $PUBLISHED = 0;
my @ARTIFACT_KEYS = qw(
    schema schema_version status publication_relative_path sha256 bytes
    same_volume atomic replaced_previous
);

sub publication_limits {
    return {
        publication_revision => 'fixture',
        publication_relative_path => '.artifacts/fixture/result.json',
        staging_relative_path => '.artifacts/tmp/fixture',
        maximum_result_bytes =>
            $ENV{FSMGEN_TEST_GATE_CLI_LIMIT_DRIFT} ? 1 : 1_048_576,
        maximum_error_bytes => 4_096,
        maximum_recovery_entries => 1,
    };
}

sub artifact_keys { return [@ARTIFACT_KEYS] }
sub load_result_keys { return [qw(result artifact)] }

sub publish {
    my ($class, $request) = @_;
    _record('publish', $request);
    _fail('publish');
    return [] if ($ENV{FSMGEN_TEST_GATE_CLI_MALFORMED} // '') eq
        'publish';
    $PUBLISHED = 1;
    return _artifact('published');
}

sub load {
    my ($class, $request) = @_;
    _record('load', $request);
    _fail('load');
    return [] if ($ENV{FSMGEN_TEST_GATE_CLI_MALFORMED} // '') eq 'load';
    my $result = _result($PUBLISHED ? 'run' : 'validate-result');
    $result = [] if ($ENV{FSMGEN_TEST_GATE_CLI_MALFORMED} // '') eq
        'result';
    $result->{foreign} = 1
        if ref($result) eq 'HASH'
            && ($ENV{FSMGEN_TEST_GATE_CLI_MALFORMED} // '') eq
                'extra-result';
    my $artifact =
        ($ENV{FSMGEN_TEST_GATE_CLI_MALFORMED} // '') eq 'loaded-artifact'
            ? [] : _artifact('loaded');
    return {result => $result, artifact => $artifact};
}

sub _result {
    my ($operation) = @_;
    if (defined(my $target = $ENV{FSMGEN_TEST_GATE_CLI_OUTPUT_BYTES})) {
        my $overhead = bytes::length('{"padding":""}' . "\n");
        die "fixture output target is invalid\n" if $target < $overhead;
        return {padding => 'x' x ($target - $overhead)};
    }
    return {
        operation => $operation,
        root_source => 'script_location',
    };
}

sub _artifact {
    my ($status) = @_;
    return {
        schema => 'fixture-artifact',
        schema_version => 1,
        status => $status,
        publication_relative_path => '.artifacts/fixture/result.json',
        sha256 => 'a' x 64,
        bytes => 1,
        same_volume => JSON::PP::true,
        atomic => JSON::PP::true,
        replaced_previous => JSON::PP::false,
    };
}

sub _fail {
    my ($method) = @_;
    return unless ($ENV{FSMGEN_TEST_GATE_CLI_FAIL_METHOD} // '') eq $method;
    die "$ENV{FSMGEN_TEST_GATE_CLI_FAILURE}\n";
}

sub _record {
    my ($method, $request) = @_;
    my $log = $ENV{FSMGEN_TEST_GATE_CLI_LOG};
    return unless defined($log);
    my $directory = $log;
    $directory =~ s{/[^/]+\z}{};
    require File::Path;
    File::Path::make_path($directory, {mode => 0700})
        unless -d $directory;
    open my $fh, '>>:raw', $log or die "cannot open fixture log: $!\n";
    print {$fh} $JSON->encode({
        method => $method,
        %$request,
    }), "\n" or die "cannot write fixture log: $!\n";
    close $fh or die "cannot close fixture log: $!\n";
}

1;
PERL
    write_raw($coordinator, <<'PERL');
package FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;

use v5.20;
use strict;
use warnings;

sub result_keys {
    return ['padding']
        if defined($ENV{FSMGEN_TEST_GATE_CLI_OUTPUT_BYTES});
    return [qw(operation root_source)];
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
    my $value = eval { $JSON->decode($bytes) };
    is($@, '', "$label is valid JSON");
    is($bytes, $JSON->encode($value) . "\n", "$label is canonical JSON");
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
