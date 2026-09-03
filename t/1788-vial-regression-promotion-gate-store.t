use v5.20;
use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use POSIX ();
use Test::More;

use lib 'perl';
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator;
use FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore;

my $STORE =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore';
my $CONTRACT =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract';
my $COORDINATOR =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator';
my $REVISION = '1' x 40;
my $TARGET_RELATIVE = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-gate-v1
    current regression-promotion-gate-result.json
);
my $STAGING_RELATIVE = join '/', qw(
    .artifacts tmp vial-scale regression-promotion-gate-publication v1
);
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

sub clone_value {
    return $JSON->decode($JSON->encode($_[0]));
}

sub canonical_bytes {
    return $JSON->encode($_[0]) . "\n";
}

sub write_bytes {
    my ($path, $bytes) = @_;
    make_path(dirname($path), {mode => 0700});
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print {$fh} $bytes or die "cannot populate $path: $!";
    close $fh or die "cannot close $path: $!";
    chmod 0600, $path or die "cannot chmod $path: $!";
}

sub read_bytes {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or die "cannot close $path: $!";
    return $bytes;
}

sub dies_like {
    my ($code, $pattern, $name) = @_;
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    ok(!$ok, $name) or diag('call unexpectedly succeeded');
    like($error, $pattern, "$name reports the closed rejection")
        unless $ok;
}

sub fixture_contract {
    return {
        contract_identity =>
            'regression-promotion-gate-contract/' . ('a' x 64),
        qualification_evidence => {
            qualification_identity =>
                'regression-promotion-qualification/' . ('b' x 64),
            publication_identity =>
                'regression-promotion-budget-qualification-publication/'
                    . ('c' x 64),
            qualification_file_set_sha256 => 'd' x 64,
        },
        result_contract => {
            schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1',
            profile_schema =>
                'fsmgen.vial_architecture_scale_regression_promotion_gate_profile_result.v1',
            identity_prefix => 'regression-promotion-gate-result/',
            publication_relative_path => $TARGET_RELATIVE,
            staging_relative_path => $STAGING_RELATIVE,
            publication_mode => 'atomic_replaceable_latest_observation',
            maximum_profile_report_bytes => 1_048_576,
            maximum_profile_ipc_bytes => 1_048_576,
            maximum_result_bytes => 1_048_576,
            maximum_error_bytes => 4_096,
            maximum_recovery_entries => 1,
            same_volume => JSON::PP::true,
            atomic => JSON::PP::true,
            interrupted_run_preserves_previous_result => JSON::PP::true,
            result_is_qualification_evidence => JSON::PP::false,
            qualification_overwrite => JSON::PP::false,
            cleanup => 'owned_staging_absent_after_result_reload',
        },
    };
}

sub fixture_result {
    my ($contract, $marker) = @_;
    return {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_gate_result.v1',
        gate_result_identity =>
            'regression-promotion-gate-result/'
                . sha256_hex("fixture-result-$marker"),
        contract_identity => $contract->{contract_identity},
        qualification_identity =>
            $contract->{qualification_evidence}{qualification_identity},
        qualification_publication_identity =>
            $contract->{qualification_evidence}{publication_identity},
        qualification_file_set_sha256 =>
            $contract->{qualification_evidence}
                {qualification_file_set_sha256},
        execution_revision => $REVISION,
        fixture_marker => $marker,
    };
}

sub with_fixture {
    my ($root, $state, $code) = @_;
    my $counts = {
        derive => 0,
        run => 0,
        admit => 0,
        clean => 0,
        unchanged_clean => 0,
    };
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = '1';
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = '80';
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = '4096';
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore::_require_clean_revision =
        sub {
            ++$counts->{clean};
            return $REVISION;
        };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore::_require_unchanged_clean_revision =
        sub {
            my (undef, $expected) = @_;
            ++$counts->{unchanged_clean};
            die "fixture revision mismatch\n" unless $expected eq $REVISION;
            return 1;
        };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateContract::derive =
        sub {
            my ($class, $request) = @_;
            ++$counts->{derive};
            die "fixture contract invocant changed\n"
                unless $class eq $CONTRACT;
            die "fixture contract root changed\n"
                unless ref($request) eq 'HASH'
                    && $request->{repository_root} eq $root;
            return clone_value($state->{contract});
        };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator::run =
        sub {
            my ($class, $request) = @_;
            ++$counts->{run};
            die "fixture coordinator invocant changed\n"
                unless $class eq $COORDINATOR;
            die "fixture coordinator root changed\n"
                unless ref($request) eq 'HASH'
                    && $request->{repository_root} eq $root;
            return clone_value($state->{producer_result});
        };
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateCoordinator::_admit_for_store =
        sub {
            my ($class, $request) = @_;
            ++$counts->{admit};
            die "fixture admission invocant changed\n"
                unless $class eq $COORDINATOR;
            die "fixture admission request changed\n"
                unless ref($request) eq 'HASH'
                    && ref($request->{result}) eq 'HASH'
                    && ref($request->{contract}) eq 'HASH'
                    && defined($request->{execution_revision});
            return clone_value($request->{result});
        };
    return $code->($counts);
}

my $limits = $STORE->publication_limits;
is_deeply(
    $limits,
    {
        publication_revision => 'regression_promotion_gate_store_v1',
        publication_relative_path => $TARGET_RELATIVE,
        staging_relative_path => $STAGING_RELATIVE,
        maximum_result_bytes => 1_048_576,
        maximum_error_bytes => 4_096,
        maximum_recovery_entries => 1,
    },
    'publication limits freeze the fixed coordinate and bounded recovery',
);
is_deeply(
    $STORE->artifact_keys,
    [qw(
        schema schema_version status publication_relative_path sha256 bytes
        same_volume atomic replaced_previous
    )],
    'artifact schema is closed',
);
is_deeply(
    $STORE->load_result_keys,
    [qw(result artifact)],
    'load schema is closed',
);

{
    package Local::BorrowedGateStore;
    our @ISA = ('FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore');
}
dies_like(
    sub { Local::BorrowedGateStore->publication_limits },
    qr/exact class invocant/,
    'a borrowed publication API is rejected',
);
{
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    dies_like(
        sub { $STORE->load({repository_root => '.'}) },
        qr/requires the active repository RAM guard/,
        'load is guard-gated before repository access',
    );
}
dies_like(
    sub {
        $COORDINATOR->_admit_for_store({
            result => {}, contract => {}, execution_revision => $REVISION,
        });
    },
    qr/caller-sealed/,
    'aggregate admission cannot be invoked outside the store',
);

my $root = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($root, '.git'));
my $contract = fixture_contract();
my $state = {
    contract => $contract,
    producer_result => fixture_result($contract, 'first'),
};
my $target = File::Spec->catfile($root, split m{/}, $TARGET_RELATIVE);
my $stage_base =
    File::Spec->catdir($root, split m{/}, $STAGING_RELATIVE);

with_fixture($root, $state, sub {
    my ($counts) = @_;
    dies_like(
        sub {
            $STORE->publish({
                repository_root => $root,
                result => $state->{producer_result},
            });
        },
        qr/unknown key 'result'/,
        'publish rejects a caller-selected result',
    );
    dies_like(
        sub {
            $STORE->load({
                repository_root => $root,
                publication_relative_path => $TARGET_RELATIVE,
            });
        },
        qr/unknown key 'publication_relative_path'/,
        'load rejects a caller-selected coordinate',
    );

    my $artifact = $STORE->publish({repository_root => $root});
    is($artifact->{status}, 'published', 'first result is published');
    ok(!$artifact->{replaced_previous}, 'first publication replaces nothing');
    is(
        $artifact->{publication_relative_path},
        $TARGET_RELATIVE,
        'publication uses the fixed result coordinate',
    );
    is(
        read_bytes($target),
        canonical_bytes($state->{producer_result}),
        'published bytes are exact canonical newline-terminated JSON',
    );
    is((stat($target))[2] & 07777, 0600, 'published result is private');
    is((stat($target))[0], (stat($root))[0], 'published result stays on volume');
    is((stat($target))[3], 1, 'published result has one link');
    ok(!-e $stage_base && !-l $stage_base,
        'first publication removes all staging');
    is($counts->{derive}, 1, 'first publication derives one independent contract');
    is($counts->{run}, 1, 'first publication executes one coordinator');
    cmp_ok($counts->{admit}, '>=', 2,
        'first publication admits generated and reloaded result bytes');

    my $runs_before_load = $counts->{run};
    my $load = $STORE->load({repository_root => $root});
    is_deeply(
        $load->{result}, $state->{producer_result},
        'load returns the exact admitted aggregate',
    );
    is($load->{artifact}{status}, 'loaded', 'load reports loaded status');
    is($counts->{run}, $runs_before_load, 'load is producer-free');
    ok(!-e $stage_base && !-l $stage_base,
        'load leaves no staging residue');

    my $unchanged = $STORE->publish({repository_root => $root});
    is($unchanged->{status}, 'unchanged', 'identical result is unchanged');
    ok(!$unchanged->{replaced_previous},
        'unchanged result reports no replacement');

    $state->{producer_result} = fixture_result($contract, 'second');
    my $replacement = $STORE->publish({repository_root => $root});
    is($replacement->{status}, 'replaced', 'new result replaces the latest');
    ok($replacement->{replaced_previous},
        'replacement reports the prior valid observation');
    is(
        read_bytes($target), canonical_bytes($state->{producer_result}),
        'replacement exposes only the complete new result',
    );
    ok(!-e $stage_base && !-l $stage_base,
        'replacement removes all staging');

    my $preserved = read_bytes($target);
    $state->{producer_result} = fixture_result($contract, 'interrupted');
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore::_atomic_replace =
        sub { die "injected interruption before rename\n" };
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/injected interruption before rename/,
        'interruption before replacement is rejected',
    );
    is(read_bytes($target), $preserved,
        'interruption preserves the previous valid result exactly');
    ok(!-e $stage_base && !-l $stage_base,
        'interrupted publication cleans its owned stage');
});

with_fixture($root, $state, sub {
    my ($counts) = @_;
    my $recovery = fixture_result($contract, 'recovery');
    my $bytes = canonical_bytes($recovery);
    my $stage = File::Spec->catfile(
        $stage_base, 'gate-result-' . sha256_hex($bytes) . '.json',
    );
    write_bytes($stage, $bytes);
    my $artifact = $STORE->publish({repository_root => $root});
    is($artifact->{status}, 'recovered', 'one valid stage is recovered');
    ok($artifact->{replaced_previous},
        'recovery reports replacement of the prior observation');
    is(read_bytes($target), $bytes, 'recovery installs exact staged bytes');
    is($counts->{run}, 0, 'recovery does not execute the coordinator');
    ok(!-e $stage_base && !-l $stage_base,
        'recovery prunes all staging');

    my $malformed = "{not-json}\n";
    $stage = File::Spec->catfile(
        $stage_base, 'gate-result-' . sha256_hex($malformed) . '.json',
    );
    write_bytes($stage, $malformed);
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/JSON is invalid/,
        'malformed recovery bytes are rejected',
    );
    ok(!-e $stage_base && !-l $stage_base,
        'malformed owned recovery stage is removed');

    my $mismatch = canonical_bytes(fixture_result($contract, 'digest'));
    $stage = File::Spec->catfile(
        $stage_base, 'gate-result-' . ('f' x 64) . '.json',
    );
    write_bytes($stage, $mismatch);
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/recovery identity changed/,
        'stage filename and content identity mismatch is rejected',
    );
    ok(!-e $stage_base && !-l $stage_base,
        'identity-mismatched recovery stage is removed');

    my @ambiguous;
    for my $marker (qw(ambiguous-a ambiguous-b)) {
        my $candidate = canonical_bytes(fixture_result($contract, $marker));
        my $path = File::Spec->catfile(
            $stage_base,
            'gate-result-' . sha256_hex($candidate) . '.json',
        );
        write_bytes($path, $candidate);
        push @ambiguous, $path;
    }
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/recovery state is ambiguous/,
        'multiple recovery candidates are rejected',
    );
    ok(!grep({ -e $_ || -l $_ } @ambiguous),
        'ambiguous owned recovery entries are removed');
    ok(!-e $stage_base && !-l $stage_base,
        'ambiguous recovery leaves no staging residue');

    my $invalid_name = File::Spec->catfile($stage_base, 'caller-stage.json');
    write_bytes($invalid_name, $bytes);
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/staging entry is invalid/,
        'non-identity-scoped staging entry is rejected',
    );
    ok(!-e $invalid_name && !-l $invalid_name,
        'invalid owned staging entry is removed');
    ok(!-e $stage_base && !-l $stage_base,
        'invalid staging census leaves no residue');
});

with_fixture($root, $state, sub {
    my $valid = fixture_result($contract, 'recovery-object');
    my $bytes = canonical_bytes($valid);
    my $name = 'gate-result-' . sha256_hex($bytes) . '.json';
    my $stage = File::Spec->catfile($stage_base, $name);
    my $backing = File::Spec->catfile($root, 'stage-backing.json');

    write_bytes($backing, $bytes);
    make_path($stage_base, {mode => 0700});
    symlink($backing, $stage) or die "cannot create stage symlink: $!";
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/artifact is invalid/,
        'symlink recovery stage is rejected',
    );
    ok(!-e $stage && !-l $stage, 'rejected stage symlink is removed safely');

    make_path($stage_base, {mode => 0700});
    link($backing, $stage) or die "cannot create stage hardlink: $!";
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/hard-linked/,
        'hard-linked recovery stage is rejected',
    );
    ok(!-e $stage && !-l $stage, 'rejected stage hardlink is removed safely');

    make_path($stage_base, {mode => 0700});
    POSIX::mkfifo($stage, 0600) == 0 or die "cannot create stage FIFO: $!";
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/artifact is invalid/,
        'special-file recovery stage is rejected without opening it',
    );
    ok(!-e $stage && !-l $stage, 'rejected stage FIFO is removed safely');
    unlink $backing or die "cannot remove stage backing: $!";
});

with_fixture($root, $state, sub {
    my $valid = fixture_result($contract, 'target-valid');
    my $valid_bytes = canonical_bytes($valid);
    write_bytes($target, $valid_bytes);

    my $pretty = JSON::PP->new->pretty(1)->canonical(1)->encode($valid);
    write_bytes($target, $pretty);
    dies_like(
        sub { $STORE->load({repository_root => $root}) },
        qr/not canonical|not newline-terminated/,
        'noncanonical target bytes are rejected',
    );

    write_bytes($target, 'x' x 1_048_577);
    dies_like(
        sub { $STORE->load({repository_root => $root}) },
        qr/exceeds its bounded ceiling/,
        'oversized target bytes are rejected before decode',
    );

    my $backing = File::Spec->catfile($root, 'target-backing.json');
    write_bytes($backing, $valid_bytes);
    unlink $target or die "cannot remove oversized target: $!";
    symlink($backing, $target) or die "cannot create target symlink: $!";
    dies_like(
        sub { $STORE->load({repository_root => $root}) },
        qr/artifact is invalid/,
        'symlink target is rejected',
    );

    unlink $target or die "cannot remove target symlink: $!";
    link($backing, $target) or die "cannot create target hardlink: $!";
    dies_like(
        sub { $STORE->load({repository_root => $root}) },
        qr/hard-linked/,
        'hard-linked target is rejected',
    );

    unlink $target or die "cannot remove target hardlink: $!";
    unlink $backing or die "cannot remove target backing: $!";
    POSIX::mkfifo($target, 0600) == 0 or die "cannot create target FIFO: $!";
    dies_like(
        sub { $STORE->load({repository_root => $root}) },
        qr/artifact is invalid/,
        'special-file target is rejected without opening it',
    );
    unlink $target or die "cannot remove target FIFO: $!";

    write_bytes($target, $valid_bytes);
    my $wrong_device = (stat($root))[0] + 1;
    dies_like(
        sub {
            FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore::_read_exact_file(
                $target, $wrong_device, 1_048_576,
            );
        },
        qr/crossed repository volume/,
        'cross-device file identity is rejected',
    );
});

with_fixture($root, $state, sub {
    my $baseline = fixture_result($contract, 'mutation-baseline');
    write_bytes($target, canonical_bytes($baseline));
    $state->{producer_result} = fixture_result($contract, 'mutation-new');
    my $mutation = fixture_result($contract, 'mutation-race');
    my $original = $STORE->can('_require_target_unchanged');
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionGateStore::_require_target_unchanged =
        sub {
            my ($path, @rest) = @_;
            unlink $path or die "cannot remove target for mutation: $!";
            write_bytes($path, canonical_bytes($mutation));
            return $original->($path, @rest);
        };
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/target changed before replacement/,
        'post-validation target mutation is rejected before atomic replacement',
    );
    is(
        read_bytes($target), canonical_bytes($mutation),
        'mutation rejection does not overwrite the concurrently changed target',
    );
    ok(!-e $stage_base && !-l $stage_base,
        'mutation rejection cleans the owned stage');
});

with_fixture($root, $state, sub {
    write_bytes(
        $target,
        canonical_bytes(fixture_result($contract, 'binding-baseline')),
    );
    my $mixed = fixture_result($contract, 'mixed-evidence');
    $mixed->{qualification_file_set_sha256} = 'e' x 64;
    $state->{producer_result} = $mixed;
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/evidence binding changed/,
        'mixed qualification evidence is rejected before staging',
    );
    ok(!-e $stage_base && !-l $stage_base,
        'mixed evidence rejection creates no stage');

    my $stale = fixture_result($contract, 'stale-revision');
    $stale->{execution_revision} = '2' x 40;
    $state->{producer_result} = $stale;
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/evidence binding changed/,
        'stale execution revision is rejected before staging',
    );

    my $oversized = fixture_result($contract, 'oversized-new');
    $oversized->{padding} = 'x' x 1_048_576;
    $state->{producer_result} = $oversized;
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/exceeds its bounded ceiling/,
        'oversized newly coordinated result is rejected before staging',
    );

    my $aliased_contract = fixture_contract();
    $aliased_contract->{result_contract}{publication_relative_path} =
        '.artifacts/qualification/vial-scale/v2/'
        . 'regression-promotion-budget-qualification-v1/current';
    $state->{contract} = $aliased_contract;
    $state->{producer_result} = fixture_result($aliased_contract, 'alias');
    dies_like(
        sub { $STORE->publish({repository_root => $root}) },
        qr/publication contract changed/,
        'qualification/result coordinate aliasing is rejected',
    );
    ok(!-e $stage_base && !-l $stage_base,
        'contract rejection creates no stage');
});

done_testing;
