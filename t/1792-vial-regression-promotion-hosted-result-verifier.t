use v5.20;
use strict;
use warnings;

use lib 'perl';
use Digest::SHA qw(sha256_hex);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $json = JSON::PP->new->canonical(1)->utf8(1);
my $source = 'scripts/verify_vial_regression_promotion_hosted_result.pl';
ok(-x $source, 'tracked hosted-result verifier is executable');

my $fixture = tempdir(CLEANUP => 1);
my $script_dir = File::Spec->catdir($fixture, 'scripts');
my $result_dir = File::Spec->catdir(
    $fixture, qw(.artifacts qualification vial-scale v2
        regression-promotion-gate-v1 current),
);
make_path(File::Spec->catdir($fixture, '.git'), $script_dir, $result_dir);
my $script = File::Spec->catfile(
    $script_dir, 'verify_vial_regression_promotion_hosted_result.pl',
);
copy($source, $script) or die "cannot copy verifier: $!";
chmod 0755, $script or die "cannot make verifier executable: $!";
my $result_path = File::Spec->catfile(
    $result_dir, 'regression-promotion-gate-result.json',
);

my $qualification =
    'regression-promotion-qualification/'
    . 'd8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97';
my $publication =
    'regression-promotion-budget-qualification-publication/'
    . '1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f';
my $file_set =
    '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095';
my $contract = 'regression-promotion-gate-contract/' . ('a' x 64);
my $revision = 'b' x 40;

sub clone_value {
    return $json->decode($json->encode($_[0]));
}

sub fixture_result {
    my @profiles;
    for my $ordinal (1 .. 11) {
        my $informational = $ordinal <= 7 || $ordinal == 11;
        my $profile = {
            schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1',
            schema_version => 1,
            profile_result_identity => undef,
            contract_identity => $contract,
            qualification_identity => $qualification,
            qualification_publication_identity => $publication,
            qualification_file_set_sha256 => $file_set,
            ordinal => $ordinal,
            selection_key => "fixture-profile-$ordinal",
            execution_revision => $revision,
            report => {},
            observation => {
                validation_records => $informational ? 1 : 0,
                raw_measurement_records => $informational ? 3 : 0,
                controller_invocations => $informational ? 4 : 0,
                sample_exclusions => 0,
            },
            observed_environment => $informational ? {} : undef,
            provider => {
                availability => $informational ? 'available' : 'unavailable',
            },
            performance => {
                classification =>
                    $informational ? 'informational' : 'unavailable',
                reason => $informational
                    ? 'environment_identity_mismatch'
                    : 'exact_provider_unavailable',
                exact_environment => JSON::PP::false,
            },
            outcome => $informational
                ? 'accepted_informational' : 'unavailable',
            diagnostics => [],
            cleanup => {},
            explicit_nonclaims => [],
        };
        $profile->{profile_result_identity} =
            'regression-promotion-gate-profile-result/'
            . sha256_hex($json->encode($profile));
        push @profiles, $profile;
    }
    my $result = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1',
        schema_version => 1,
        gate_result_identity => undef,
        contract_identity => $contract,
        qualification_identity => $qualification,
        qualification_publication_identity => $publication,
        qualification_file_set_sha256 => $file_set,
        execution_revision => $revision,
        coordinator_revision => 'regression_promotion_gate_coordinator_v1',
        summary => {
            profile_count => 11,
            required_validation_records => 11,
            required_raw_measurement_records => 33,
            required_controller_invocations => 44,
            observed_validation_records => 8,
            observed_raw_measurement_records => 24,
            observed_controller_invocations => 32,
            sample_exclusions => 0,
            passed_profiles => 0,
            failed_profiles => 0,
            informational_profiles => 8,
            unavailable_profiles => 3,
            complete_observation => JSON::PP::false,
        },
        profiles => \@profiles,
        classification => 'unavailable',
        outcome => 'unavailable',
        diagnostics => [],
        cleanup => {},
        explicit_nonclaims => [],
    };
    rehash_result($result);
    return $result;
}

sub rehash_profile {
    my ($profile) = @_;
    $profile->{profile_result_identity} = undef;
    $profile->{profile_result_identity} =
        'regression-promotion-gate-profile-result/'
        . sha256_hex($json->encode($profile));
}

sub rehash_result {
    my ($result) = @_;
    $result->{gate_result_identity} = undef;
    $result->{gate_result_identity} = 'regression-promotion-gate-result/'
        . sha256_hex($json->encode($result));
}

sub write_result {
    my ($result, $noncanonical) = @_;
    open my $fh, '>', $result_path or die "cannot write result: $!";
    my $bytes = $json->encode($result) . "\n";
    $bytes = "  $bytes" if $noncanonical;
    print {$fh} $bytes or die "cannot populate result: $!";
    close $fh or die "cannot close result: $!";
}

sub run_verifier {
    my (@args) = @_;
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;
    return capture_verifier($^X, $script, @args);
}

subtest 'exact hosted outcome is independently accepted' => sub {
    my $result = fixture_result();
    write_result($result);
    my $run = run_verifier();
    ok($run->{success}, 'exact fixture succeeds');
    is($run->{stderr}, '', 'success keeps stderr empty');
    my $decoded = $json->decode($run->{stdout});
    is(
        $decoded->{outcome},
        'accepted_hosted_gate_observation',
        'verification result has the exact acceptance outcome',
    );
    is_deeply(
        $decoded->{informational_ordinals},
        [1 .. 7, 11],
        'all eight executable routes remain informational on the hosted host',
    );
    is_deeply(
        $decoded->{unavailable_ordinals},
        [8 .. 10],
        'all three absent runtime providers remain unavailable',
    );
    is_deeply(
        $decoded->{observed_topology},
        {
            validation_records => 8,
            raw_measurement_records => 24,
            controller_invocations => 32,
        },
        'honest observed topology is explicit',
    );
};

subtest 'qualification, topology, and classifications fail closed' => sub {
    my @cases = (
        ['qualification identity', sub {
            $_[0]{qualification_identity} =
                'regression-promotion-qualification/' . ('f' x 64);
        }, qr/qualification identity changed/],
        ['observed topology', sub {
            $_[0]{summary}{observed_controller_invocations} = 33;
        }, qr/observed_controller_invocations changed/],
        ['informational host', sub {
            $_[0]{profiles}[0]{performance}{exact_environment} =
                JSON::PP::true;
            rehash_profile($_[0]{profiles}[0]);
        }, qr/profile 1 classification changed/],
        ['unavailable-not-pass', sub {
            $_[0]{profiles}[7]{performance}{classification} = 'pass';
            rehash_profile($_[0]{profiles}[7]);
        }, qr/profile 8 classification changed/],
    );
    for my $case (@cases) {
        my $result = fixture_result();
        $case->[1]->($result);
        rehash_result($result);
        write_result($result);
        my $run = run_verifier();
        ok(!$run->{success}, "$case->[0] drift rejects");
        is($run->{stdout}, '', "$case->[0] drift emits no partial result");
        like($run->{stderr}, $case->[2], "$case->[0] diagnostic is exact");
    }
};

subtest 'canonical identity and closed invocation fail before acceptance' => sub {
    my $result = fixture_result();
    $result->{profiles}[0]{selection_key} = 'mutated-without-rehash';
    rehash_result($result);
    write_result($result);
    my $identity = run_verifier();
    ok(!$identity->{success}, 'profile content-identity mutation rejects');
    like($identity->{stderr}, qr/profile 1 content identity changed/,
        'profile identity diagnostic is exact');

    $result = fixture_result();
    write_result($result, 1);
    my $canonical = run_verifier();
    ok(!$canonical->{success}, 'noncanonical result bytes reject');
    like($canonical->{stderr}, qr/not canonical JSON/,
        'canonical-byte diagnostic is exact');

    write_result(fixture_result());
    my $arguments = run_verifier('--result', 'caller.json');
    ok(!$arguments->{success}, 'caller-supplied result path rejects');
    is($arguments->{status}, 1, 'closed invocation has deterministic status');
    like($arguments->{stderr}, qr/caller arguments are forbidden/,
        'closed-invocation diagnostic is exact');
};

subtest 'guard and publication-staging boundaries fail closed' => sub {
    write_result(fixture_result());
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    delete $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    delete $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    delete $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    my $unguarded = capture_verifier($^X, $script);
    my ($stdout, $stderr) = @{$unguarded}{qw(stdout stderr)};
    ok($unguarded->{status} != 0, 'unguarded invocation rejects');
    is($stdout, '', 'unguarded invocation emits no result');
    like($stderr, qr/active repository RAM guard is required/,
        'guard diagnostic is exact');

    my $stage = File::Spec->catdir(
        $fixture, qw(.artifacts tmp vial-scale
            regression-promotion-gate-publication v1),
    );
    make_path($stage);
    my $staged = run_verifier();
    ok(!$staged->{success}, 'publication-stage residue rejects');
    like($staged->{stderr}, qr/staging residue is present/,
        'staging-residue diagnostic is exact');
};

done_testing;

sub capture_verifier {
    my (@command) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, @command);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    my $status = $? >> 8;
    return {
        success => $status == 0 ? 1 : 0,
        status => $status,
        stdout => $out,
        stderr => $err,
    };
}
