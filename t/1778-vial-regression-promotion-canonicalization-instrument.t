#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(realpath);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $relative =
    'scripts/measure_vial_regression_promotion_canonicalization.pl';
my $script = File::Spec->catfile($root, split m{/}, $relative);
my $json = JSON::PP->new->canonical(1)->utf8(1);

subtest 'tracked runner keeps closed local read-only measurement boundaries' => sub {
    my $source = read_raw($script);
    like($source, qr/use FindBin;/,
        'runner derives the repository root from its tracked location');
    like($source, qr{/usr/bin/sample}, 'runner invokes the macOS sampler');
    like($source, qr/'-file'/,
        'sampler writes through its direct file option');
    unlike($source, qr{(?:^|[^A-Za-z])/(?:private/)?tmp(?:/|[^A-Za-z])},
        'runner contains no off-volume temporary path');
    like(
        $source,
        qr/run_independent_verifier\(\).*run_independent_verifier\(\)/s,
        'runner independently authenticates the publication before and after',
    );
    like(
        $source,
        qr/ArchitectureScaleBalancedPortableMeasurement\s*\n\s*->validate_report/,
        'balanced phase crosses the public adapter validation boundary',
    );
    like(
        $source,
        qr/ArchitectureScaleRegressionPromotionCorpusStore\s*\n\s*->load/,
        'corpus phase crosses the public store load boundary',
    );
    unlike(
        $source,
        qr/sub install_bindings\s*\{.*?\binstall_bindings\(/s,
        'wrapper installation does not recurse through the module set',
    );
};

subtest 'synthetic underlay proves exact values and byte attribution' => sub {
    my $run = invoke('--self-test');
    is($run->{exit}, 0, 'self-test succeeds') or diag($run->{stderr});
    is($run->{stderr}, '', 'self-test is diagnostic-free');
    cmp_ok(length($run->{stdout}), '<=', 262_144,
        'self-test output obeys the result ceiling');
    my $decoded = eval { $json->decode($run->{stdout}) };
    is($@, '', 'self-test output is JSON');
    is(
        $run->{stdout}, $json->encode($decoded) . "\n",
        'self-test output is canonical newline JSON',
    );
    is(
        $decoded->{schema},
        'fsmgen.vial_regression_promotion_canonicalization_instrumentation_self_test.v1',
        'self-test exposes its non-production evidence scope',
    );
    ok($decoded->{exact_values_preserved},
        'instrumented clone, canonical encoding, and digest preserve values');
    ok($decoded->{prototypes_preserved},
        'instrumentation preserves and restores imported-call prototypes');
    is(scalar(@{$decoded->{modules}}), 1,
        'only the synthetic module records activity');
    my $operations = $decoded->{modules}[0]{operations};
    is($operations->{clone}{calls}, 1, 'one clone boundary is counted');
    is($operations->{clone}{top_level_calls}, 1,
        'one top-level clone boundary is counted');
    is($operations->{clone}{recursive_node_calls}, 0,
        'synthetic JSON clone has no recursive manual-clone nodes');
    is($operations->{clone}{json_encode_calls}, 1,
        'clone attribution sees its existing encoder call');
    is($operations->{clone}{encoded_bytes}, $decoded->{canonical_bytes},
        'clone attribution reports exact encoded bytes without a probe encode');
    is($operations->{canonical_encode}{calls}, 1,
        'one canonical boundary is counted');
    is($operations->{canonical_encode}{encoded_bytes},
        $decoded->{canonical_bytes},
        'canonical attribution reports exact returned encoder bytes');
    is($operations->{sha256_hex}{calls}, 1,
        'one SHA-256 boundary is counted');
};

subtest 'invocation is closed and real phases require guarded destinations' => sub {
    my $help = invoke('--help');
    is($help->{exit}, 0, 'help succeeds');
    like($help->{stdout}, qr/^Usage:/, 'help publishes the closed command');
    is($help->{stderr}, '', 'help is diagnostic-free');

    my $foreign_absolute = File::Spec->catfile(
        File::Spec->rootdir, 'foreign', 'x.sample.txt',
    );

    for my $arguments (
        [],
        ['--phase', 'foreign', '--sample-relative',
            '.artifacts/diagnostics/vial-scale/x.sample.txt'],
        ['--phase', 'corpus-load', '--sample-relative', $foreign_absolute],
        ['--phase', 'corpus-load', '--sample-relative',
            '.artifacts/diagnostics/vial-scale/x.sample.txt'],
    ) {
        my $run = invoke(@{$arguments});
        isnt($run->{exit}, 0, 'invalid or unguarded invocation rejects');
        is($run->{stdout}, '', 'rejection emits no measurement result');
        cmp_ok(length($run->{stderr}), '<=', 8_192,
            'rejection diagnostic stays bounded');
    }
};

done_testing();

sub invoke {
    my (@arguments) = @_;
    my ($input, $output);
    my $error = gensym;
    my $pid = open3($input, $output, $error, $^X, $script, @arguments);
    close $input or die "cannot close runner input\n";
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output or die "cannot close runner output\n";
    close $error or die "cannot close runner diagnostic pipe\n";
    waitpid($pid, 0) == $pid or die "cannot wait for runner\n";
    return {exit => $? >> 8, stdout => $stdout, stderr => $stderr};
}

sub read_raw {
    my ($path) = @_;
    open my $handle, '<:raw', $path or die "cannot open $path\n";
    local $/;
    my $bytes = <$handle> // '';
    close $handle or die "cannot close $path\n";
    return $bytes;
}
