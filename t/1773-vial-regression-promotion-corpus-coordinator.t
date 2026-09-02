#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Cwd ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleMeasurement;
use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator;
use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator';
my $corpus_store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore';
my $measurement = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $plan_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $profile_store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $profile_capture =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture';
my $repo_root = Cwd::realpath(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-regression-promotion-corpus-coordinator-$$",
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fixture_sequence = 0;

die "coordinator fixture root already exists\n"
    if -e $fixture_base || -l $fixture_base;
make_path($fixture_base, {mode => 0700});

local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;

END {
    remove_tree($fixture_base)
        if defined($fixture_base) && -d($fixture_base) && !-l($fixture_base);
}

my $sealed_plan = $plan_class->derive({repository_root => $repo_root});
{
    no warnings 'redefine';
    *FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan::derive =
        sub { return clone($sealed_plan) };
}

subtest 'public APIs are closed, guarded, and metadata-bounded' => sub {
    is_deeply($class->coordination_limits, {
        coordination_revision =>
            'regression_promotion_corpus_coordinator_v2',
        maximum_profile_ipc_bytes => 65_536,
        maximum_error_bytes => 4_096,
        profile_count => 11,
        validation_records => 11,
        raw_measurement_records => 33,
        controller_invocations => 44,
    }, 'coordinator publishes its exact bounded worker and corpus census');
    is_deeply([sort @{$class->result_keys}], [sort qw(
        schema schema_version operation plan_identity policy_identity
        capture_revision execution_revision common_identity summary profiles
        corpus_identity publication_identity corpus_artifact
    )], 'coordination result has one closed metadata schema');
    is_deeply([sort @{$class->profile_outcome_keys}], [sort qw(
        ordinal selection_key operation report_identity provider_status
        applicability_status artifact
    )], 'profile outcome contains metadata rather than raw measurement data');
    is_deeply([sort @{$class->inventory_keys}], [sort qw(
        schema schema_version plan_identity policy_identity git_revision
        profile_count present_profiles missing_profiles profiles corpus
    )], 'inventory shape is explicit');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::capture(
            'borrowed', {},
        );
    }), qr/requires the exact class invocant/,
        'borrowed invocants reject');

    my $repo = fresh_repository('closed-api');
    for my $method (qw(inventory capture validate)) {
        for my $key (qw(
            worker callback result profiles ordinal operation plan report
            capture_revision execution_revision
        )) {
            like(dies(sub {
                $class->$method({
                    repository_root => $repo, $key => 'injected',
                });
            }), qr/contains unknown key '\Q$key\E'/,
                "$method rejects caller $key injection");
        }
    }
    {
        local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
        like(dies(sub {
            $class->inventory({repository_root => $repo});
        }), qr/requires the active repository RAM guard/,
            'inventory rejects before filesystem admission without the guard');
    }

    my $inventory = $class->inventory({repository_root => $repo});
    is($inventory->{present_profiles}, 0,
        'fresh inventory has no current profile publication');
    is($inventory->{missing_profiles}, 11,
        'fresh inventory names every missing profile');
    is($inventory->{corpus}{status}, 'missing',
        'fresh inventory has no complete seal');
    is_deeply([map { $_->{ordinal} } @{$inventory->{profiles}}],
        [1 .. 11], 'fresh inventory retains exact plan order');
};

my $complete_repo;
subtest 'eleven fresh profile workers publish one complete current corpus' => sub {
    my $repo = fresh_repository('complete-capture');
    $complete_repo = $repo;
    my $pid_log = repo_path($repo, '.artifacts/tmp/producer-pids');
    my $coordinator_pid_log = repo_path(
        $repo, '.artifacts/tmp/coordinator-profile-pids',
    );
    my $run_in_child = $class->can('_run_profile_operation_in_child');
    my $result;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::_run_profile_operation_in_child = sub {
            append_raw($coordinator_pid_log, "$$\n");
            goto &$run_in_child;
        };
        $result = with_synthetic_adapters(sub {
            return $class->capture({repository_root => $repo});
        }, producer_pid_log => $pid_log);
    }

    is($result->{operation}, 'capture',
        'capture returns the exact coordination operation');
    is($result->{schema},
        'fsmgen.vial_architecture_scale_regression_promotion_corpus_coordination.v2',
        'coordination result advances its revision-separated schema');
    is($json->encode($result->{schema_version}), '2',
        'coordination result schema version is a JSON number');
    is($result->{capture_revision}, $result->{execution_revision},
        'fresh capture binds evidence and execution to one clean revision');
    is($result->{summary}{captured_profiles}, 11,
        'all eleven missing profiles are captured');
    is($result->{summary}{resumed_profiles}, 0,
        'fresh capture resumes no profile');
    is($result->{summary}{validated_profiles}, 11,
        'every captured profile is independently validated');
    is($result->{summary}{validation_records}, 11,
        'complete result admits eleven validation records');
    is($result->{summary}{raw_measurement_records}, 33,
        'complete result admits 33 raw measurement records');
    is($result->{summary}{controller_invocations}, 44,
        'complete result admits 44 controller invocations');
    is($result->{summary}{sample_exclusions}, 0,
        'complete result admits zero exclusions');
    is($result->{corpus_artifact}{status}, 'published',
        'complete corpus is published only after all profiles pass');
    is_deeply([map { $_->{operation} } @{$result->{profiles}}],
        [('capture') x 11], 'profile outcomes preserve exact operation order');

    my @producer_pid = grep { length } split /\n/, read_raw($pid_log);
    is(scalar(@producer_pid), 11,
        'one producer call occurred per selected profile');
    ok(!grep({ $_ == $$ } @producer_pid),
        'every producer executed behind a fresh profile-worker boundary');
    my @coordinator_pid = grep { length }
        split /\n/, read_raw($coordinator_pid_log);
    is(scalar(@coordinator_pid), 11,
        'one whole ProfileCapture operation ran per coordinator child');
    is(scalar(keys %{ {map { $_ => 1 } @coordinator_pid} }), 11,
        'every whole ProfileCapture operation used a fresh process');
    ok(!grep({ $_ == $$ } @coordinator_pid),
        'long-lived coordinator performs no direct profile validation');
    my %coordinator_pid = map { $_ => 1 } @coordinator_pid;
    ok(!grep({ $coordinator_pid{$_} } @producer_pid),
        'producer grandchildren remain distinct from profile parents');

    my $inventory = $class->inventory({repository_root => $repo});
    is($inventory->{present_profiles}, 11,
        'post-capture inventory loads every profile');
    is($inventory->{missing_profiles}, 0,
        'post-capture inventory has no missing profile');
    is($inventory->{corpus}{status}, 'present',
        'post-capture inventory loads the complete seal');
    is($inventory->{corpus}{corpus_identity}, $result->{corpus_identity},
        'inventory binds the exact complete identity');
    ok(!owned_staging_paths($repo),
        'successful complete capture leaves no owned staging residue');
};

subtest 'existing profiles resume without producers and validate read-only' => sub {
    my $repo = $complete_repo;
    my $producer_log = repo_path(
        $repo, '.artifacts/tmp/resume-producer-pids',
    );
    my $before = complete_bytes($repo);
    my $recaptured = with_synthetic_adapters(sub {
        return $class->capture({repository_root => $repo});
    }, producer_pid_log => $producer_log, forbid_producer => 1);
    is($recaptured->{summary}{captured_profiles}, 0,
        'repeat capture does not recapture an existing profile');
    is($recaptured->{summary}{resumed_profiles}, 11,
        'repeat capture resumes every exact profile boundary');
    is($recaptured->{corpus_artifact}{status}, 'unchanged',
        'repeat capture retains byte-identical complete publication');
    ok(!-e($producer_log),
        'resume path did not invoke a measurement producer');
    is(complete_bytes($repo), $before,
        'repeat capture leaves complete bytes unchanged');

    my $validated = with_synthetic_adapters(sub {
        return $class->validate({repository_root => $repo});
    }, forbid_producer => 1);
    is($validated->{operation}, 'validate',
        'validate returns its exact read-only operation');
    is($validated->{summary}{captured_profiles}, 0,
        'validation never captures a missing profile');
    is($validated->{summary}{resumed_profiles}, 11,
        'validation re-admits all eleven profiles through resume workers');
    is($validated->{corpus_artifact}{status}, 'loaded',
        'validation loads rather than republishes the complete corpus');
    is(complete_bytes($repo), $before,
        'validation leaves complete bytes unchanged');
};

subtest 'complete validation separates sealed capture from clean execution' => sub {
    my $repo = $complete_repo;
    my $capture_revision = git_output($repo, qw(rev-parse HEAD));
    $capture_revision =~ s/\s+\z//;
    my $before = complete_bytes($repo);
    write_raw(repo_path($repo, 'anchor.txt'), "fixture\nnext revision\n");
    git_ok($repo, qw(add anchor.txt));
    git_ok($repo, qw(commit -q -m next-revision));
    my $execution_revision = git_output($repo, qw(rev-parse HEAD));
    $execution_revision =~ s/\s+\z//;
    isnt($execution_revision, $capture_revision,
        'fixture advances the clean execution revision after sealing');

    like(dies(sub {
        with_synthetic_adapters(sub {
            return $profile_capture->resume({
                repository_root => $repo, ordinal => 1,
            });
        }, forbid_producer => 1);
    }), qr/Git revision changed/,
        'public single-profile resume remains same-revision strict');
    like(dies(sub {
        $profile_capture->_corpus_validate_resume({
            repository_root => $repo,
            ordinal => 1,
            capture_revision => $capture_revision,
        });
    }), qr/private to the exact coordinator/,
        'foreign callers cannot invoke revision-separated resume');

    my $private_resume = $profile_capture->can('_corpus_validate_resume');
    my $capture_revision_log = repo_path(
        $repo, '.artifacts/tmp/private-resume-capture-revisions',
    );
    my $validated;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::_corpus_validate_resume = sub {
            append_raw(
                $capture_revision_log,
                "$_[1]{capture_revision}\n",
            );
            goto &$private_resume;
        };
        $validated = with_synthetic_adapters(sub {
            return $class->validate({repository_root => $repo});
        }, forbid_producer => 1);
    }
    is($validated->{capture_revision}, $capture_revision,
        'validation reports the immutable evidence revision');
    is($validated->{execution_revision}, $execution_revision,
        'validation separately reports the clean executing revision');
    is($validated->{common_identity}{git_revision}, $capture_revision,
        'validated common identity remains capture-revision evidence');
    my @seen_capture_revisions = grep { length }
        split /\n/, read_raw($capture_revision_log);
    is_deeply(
        \@seen_capture_revisions,
        [($capture_revision) x 11],
        'only the complete seal supplies all eleven private resume revisions',
    );
    is($validated->{summary}{captured_profiles}, 0,
        'revision-separated validation captures no profile');
    is($validated->{summary}{resumed_profiles}, 11,
        'revision-separated validation re-admits all eleven profiles');
    is(complete_bytes($repo), $before,
        'revision-separated validation leaves the complete seal byte exact');

    {
        my $load = $corpus_store->can('load');
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore::load = sub {
            my $loaded = $load->(@_);
            $loaded->{report}{common_identity}{git_revision} = 'f' x 40;
            return $loaded;
        };
        like(dies(sub {
            $class->validate({repository_root => $repo});
        }), qr/profile capture revision changed/,
            'forged complete-versus-profile capture revision rejects');
    }
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::_corpus_validate_resume = sub {
            $_[1]{capture_revision} = 'not-a-revision';
            goto &$private_resume;
        };
        like(dies(sub {
            $class->validate({repository_root => $repo});
        }), qr/capture revision is invalid/,
            'malformed internal capture revision rejects before byte admission');
    }
    {
        my $load = $corpus_store->can('load');
        my $mutated = 0;
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore::load = sub {
            my $loaded = $load->(@_);
            if (!$mutated++) {
                write_raw(
                    repo_path($repo, 'anchor.txt'),
                    "fixture\ncomplete-load mutation\n",
                );
            }
            return $loaded;
        };
        like(dies(sub {
            $class->validate({repository_root => $repo});
        }), qr/requires a clean Git revision/,
            'repository mutation during complete load rejects immediately');
    }
    write_raw(repo_path($repo, 'anchor.txt'), "fixture\nnext revision\n");
    is(git_output($repo, qw(status --porcelain)), '',
        'complete-load mutation control restores the clean fixture revision');
    {
        my $mutated = 0;
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::_corpus_validate_resume = sub {
            if (!$mutated++) {
                write_raw(
                    repo_path($repo, 'anchor.txt'),
                    "fixture\nexecution mutation\n",
                );
            }
            goto &$private_resume;
        };
        like(dies(sub {
            $class->validate({repository_root => $repo});
        }), qr/requires a clean Git revision/,
            'current execution-repository mutation still rejects');
    }
    is(complete_bytes($repo), $before,
        'all revision controls preserve complete publication bytes');
};

subtest 'capture resumes an exact prefix and captures only missing profiles' => sub {
    my $repo = fresh_repository('partial-resume');
    publish_profiles($repo, 1 .. 5);
    my $pid_log = repo_path($repo, '.artifacts/tmp/partial-producer-ordinals');
    my $result = with_synthetic_adapters(sub {
        return $class->capture({repository_root => $repo});
    }, producer_ordinal_log => $pid_log);
    is($result->{summary}{resumed_profiles}, 5,
        'present prefix profiles resume at exact boundaries');
    is($result->{summary}{captured_profiles}, 6,
        'only six missing suffix profiles are captured');
    is_deeply(
        [grep { length } split /\n/, read_raw($pid_log)],
        [6 .. 11], 'producer calls occur only for missing ordinals');
    is($result->{corpus_artifact}{status}, 'published',
        'mixed resume/capture closes one complete seal');
};

subtest 'profile order, common identity, provider, and bytes fail closed' => sub {
    my $order_repo = prepared_repository('wrong-order');
    like(dies(sub {
        with_synthetic_adapters(sub {
            with_profile_result_mutation(1, sub {
                $_[0]{ordinal} = 2;
            }, sub {
                $class->capture({repository_root => $order_repo});
            });
        }, forbid_producer => 1);
    }), qr/profile order changed/,
        'a duplicate/reordered worker result rejects before sealing');
    ok(!complete_exists($order_repo),
        'order rejection withholds the complete seal');

    my $common_repo = prepared_repository('mixed-common');
    like(dies(sub {
        with_synthetic_adapters(sub {
            with_profile_result_mutation(2, sub {
                $_[0]{common_identity}{host_profile}{system} = 'foreign';
            }, sub {
                $class->capture({repository_root => $common_repo});
            });
        }, forbid_producer => 1);
    }), qr/common identity changed/,
        'a mixed route host identity rejects before sealing');

    my $provider_repo = prepared_repository('foreign-provider');
    like(dies(sub {
        with_synthetic_adapters(sub {
            with_profile_result_mutation(1, sub {
                $_[0]{provider_status}{kind} = 'foreign';
            }, sub {
                $class->capture({repository_root => $provider_repo});
            });
        }, forbid_producer => 1);
    }), qr/profile provider changed/,
        'a route-specific provider mutation rejects');

    my $oversized_repo = prepared_repository('oversized-metadata');
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::resume =
            sub {
                return {padding => 'x' x 65_537};
            };
        like(dies(sub {
            $class->capture({repository_root => $oversized_repo});
        }), qr/metadata exceeded the bounded envelope/,
            'cap-plus-one worker metadata rejects before admission');
    }

    for my $control (
        ['schema-version-string', sub { $_[0]{schema_version} = '1' },
            qr/profile result schema is invalid/],
        ['ordinal-string', sub { $_[0]{ordinal} = '1' },
            qr/profile order changed/],
        ['validation-count-string', sub {
            $_[0]{applicability_status}{validation_records} = '1';
        }, qr/profile applicability changed/],
        ['artifact-bytes-string', sub {
            $_[0]{artifact}{artifact_bytes} =
                sprintf('%s', $_[0]{artifact}{artifact_bytes});
        }, qr/profile artifact identity is invalid/],
    ) {
        my ($name, $mutate, $diagnostic) = @$control;
        my $repo = prepared_repository("numeric-string-$name");
        like(dies(sub {
            with_synthetic_adapters(sub {
                with_profile_result_mutation(1, $mutate, sub {
                    $class->capture({repository_root => $repo});
                });
            }, forbid_producer => 1);
        }), $diagnostic,
            "$name cannot impersonate an admitted JSON number");
        ok(!complete_exists($repo),
            "$name rejection withholds the complete seal");
    }
};

subtest 'worker failures and post-worker mutations propagate fail closed' => sub {
    for my $control (
        ['exception', 'profile capture worker failed: synthetic exception'],
        ['exit', 'profile capture worker exited with status 75'],
        ['signal', 'profile capture worker terminated by signal 15'],
        ['malformed', 'profile capture worker result is not valid JSON'],
        ['noncanonical', 'profile capture worker result is not canonical JSON'],
    ) {
        my ($name, $message) = @$control;
        my $repo = fresh_repository("worker-$name");
        {
            no warnings 'redefine';
            local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::capture =
                sub { die "$message\n" };
            like(dies(sub {
                $class->capture({repository_root => $repo});
            }), qr/\Q$message\E/,
                "$name worker failure remains authoritative");
        }
        ok(!complete_exists($repo),
            "$name worker failure withholds the complete seal");
    }

    for my $control (
        ['outer-exception', sub { die "outer synthetic exception\n" },
            qr/corpus profile worker failed: outer synthetic exception/],
        ['outer-signal', sub { kill 'TERM', $$; return {} },
            qr/corpus profile worker terminated by signal 15/],
        ['outer-no-result', sub { POSIX::_exit(0) },
            qr/corpus profile worker returned no result/],
        ['outer-exit', sub { POSIX::_exit(75) },
            qr/corpus profile worker returned no result with exit status 75/],
        ['outer-oversize', sub {
            return {
                oversized => 'x' x
                    ($class->coordination_limits
                        ->{maximum_profile_ipc_bytes} + 1),
            };
        }, qr/corpus profile worker metadata exceeded the bounded envelope/],
    ) {
        my ($name, $worker, $diagnostic) = @$control;
        my $repo = fresh_repository($name);
        {
            no warnings 'redefine';
            local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::_run_profile_operation_in_child = $worker;
            like(dies(sub {
                $class->capture({repository_root => $repo});
            }), $diagnostic, "$name fails across the outer process boundary");
        }
        ok(!complete_exists($repo),
            "$name failure withholds the complete seal");
    }

    for my $control (
        ['outer-malformed', '{', qr/result is not valid JSON/],
        ['outer-noncanonical', '{} ', qr/result is not canonical JSON/],
    ) {
        my ($name, $wire_bytes, $diagnostic) = @$control;
        my $repo = fresh_repository($name);
        {
            no warnings 'redefine';
            local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::_run_profile_operation_in_child = sub {
                return {};
            };
            local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::_write_profile_worker_result = sub {
                return defined(syswrite($_[0], $wire_bytes)) ? 1 : 0;
            };
            like(dies(sub {
                $class->capture({repository_root => $repo});
            }), $diagnostic, "$name fails across the outer process boundary");
        }
        ok(!complete_exists($repo),
            "$name failure withholds the complete seal");
    }

    my $mutation_repo = prepared_repository('post-worker-mutation');
    like(dies(sub {
        with_synthetic_adapters(sub {
            my $original = $class->can('_run_profile_operation');
            no warnings 'redefine';
            local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::_run_profile_operation =
                sub {
                    my ($operation, $repo, $ordinal, $capture_revision) = @_;
                    my $result = $original->(
                        $operation, $repo, $ordinal, $capture_revision,
                    );
                    if ($ordinal == 1) {
                        append_raw(repo_path(
                            $repo, $result->{artifact}{artifact_relative_path},
                        ), "mutation\n");
                    }
                    return $result;
                };
            $class->capture({repository_root => $mutation_repo});
        }, forbid_producer => 1);
    }), qr/(?:publication JSON is invalid|not canonical JSON|artifact size changed|artifact SHA-256 changed)/,
        'post-worker profile-byte mutation rejects before sealing');
    ok(!complete_exists($mutation_repo),
        'post-worker mutation leaves no complete seal');

    my $dirty_repo = fresh_repository('repository-mutation');
    like(dies(sub {
        with_synthetic_adapters(sub {
            return $class->capture({repository_root => $dirty_repo});
        }, mutate_repository_ordinal => 1);
    }), qr/requires a clean Git revision/,
        'tracked repository mutation during the first worker rejects');
    ok(!complete_exists($dirty_repo),
        'repository mutation withholds the complete seal');
};

subtest 'missing validation, incomplete state, and cleanup fail closed' => sub {
    my $missing = fresh_repository('missing-validation');
    like(dies(sub {
        $class->validate({repository_root => $missing});
    }), qr/requires an existing complete publication/,
        'validate never falls back to capture');

    my $incomplete = fresh_repository('incomplete-profile');
    make_path(dirname(repo_path(
        $incomplete,
        plan_entry(1)->{publication_relative_path},
    )), {mode => 0700});
    like(dies(sub {
        $class->inventory({repository_root => $incomplete});
    }), qr/profile 1 publication is incomplete/,
        'an existing partial target is not classified as missing');

    remove_tree($fixture_base);
    ok(!-e($fixture_base) && !-l($fixture_base),
        'all Git fixtures, publications, mutations, and logs clean exactly');
};

done_testing;

sub with_synthetic_adapters {
    my ($code, %options) = @_;
    my $measure = sub {
        my ($adapter, $request, $method) = @_;
        my @matches = grep {
            $_->{adapter_class} eq $adapter
                && $_->{adapter_method} eq $method
                && canonical({
                    %{$_->{adapter_arguments}},
                    repository_root => $request->{repository_root},
                }) eq canonical($request)
        } @{$sealed_plan->{entries}};
        die "synthetic adapter request did not select one plan entry\n"
            unless @matches == 1;
        my $ordinal = $matches[0]{ordinal};
        die "resume invoked the measurement producer\n"
            if $options{forbid_producer};
        append_raw($options{producer_pid_log}, "$$\n")
            if defined $options{producer_pid_log};
        append_raw($options{producer_ordinal_log}, "$ordinal\n")
            if defined $options{producer_ordinal_log};
        if (($options{mutate_repository_ordinal} // 0) == $ordinal) {
            append_raw(
                File::Spec->catfile($request->{repository_root}, 'anchor.txt'),
                "dirty\n",
            );
        }
        return synthetic_report($request->{repository_root}, $ordinal);
    };
    my $validate = sub {
        my ($adapter, $request) = @_;
        die "synthetic validator request changed\n"
            unless ref($request) eq 'HASH'
                && canonical([sort keys %$request]) eq
                    canonical([qw(report repository_root)]);
        return clone($request->{report});
    };

    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::measure_profile =
        sub { $measure->($_[0], $_[1], 'measure_profile') };
    local *FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurement::validate_report =
        $validate;
    local *FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::measure_profile =
        sub { $measure->($_[0], $_[1], 'measure_profile') };
    local *FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurement::validate_report =
        $validate;
    local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::measure_profile =
        sub { $measure->($_[0], $_[1], 'measure_profile') };
    local *FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement::validate_report =
        $validate;
    local *FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::measure_profile =
        sub { $measure->($_[0], $_[1], 'measure_profile') };
    local *FSM::VIAL::ArchitectureScalePortableRuntimeMeasurement::validate_report =
        $validate;
    local *FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::measure_profile =
        sub { $measure->($_[0], $_[1], 'measure_profile') };
    local *FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurement::validate_report =
        $validate;
    local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::measure_profile =
        sub { $measure->($_[0], $_[1], 'measure_profile') };
    local *FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::validate_report =
        $validate;
    local *FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::measure_member =
        sub { $measure->($_[0], $_[1], 'measure_member') };
    local *FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement::validate_report =
        $validate;
    return $code->();
}

sub with_profile_result_mutation {
    my ($target_ordinal, $mutate, $code) = @_;
    my $original = $class->can('_run_profile_operation');
    no warnings 'redefine';
    local *FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusCoordinator::_run_profile_operation =
        sub {
            my ($operation, $repo, $ordinal, $capture_revision) = @_;
            my $result = $original->(
                $operation, $repo, $ordinal, $capture_revision,
            );
            $mutate->($result) if $ordinal == $target_ordinal;
            return $result;
        };
    return $code->();
}

sub synthetic_report {
    my ($repo, $ordinal) = @_;
    my $entry = plan_entry($ordinal);
    my $revision = git_output($repo, qw(rev-parse HEAD));
    $revision =~ s/\s+\z//;
    my $environment = $measurement->current_environment_identity({
        repository_root => $repo,
    });
    my $tool = $entry->{provider_requirement}{kind} eq 'exact_tool_profile'
        ? $entry->{adapter_class}->tool_profile
        : $environment->{tool_profile};
    my $common = {
        git_revision => $revision,
        dirty_state => JSON::PP::false,
        host_profile => clone($environment->{host_profile}),
        tool_profile => clone($tool),
        resource_guard => clone($environment->{resource_guard}),
    };
    my $report = {
        schema => 'fsmgen.vial_architecture_scale_synthetic_coordination.v1',
        schema_version => 1,
        report_identity => 'synthetic-coordination/' . sha256_hex(
            join('/', $ordinal, $revision, $repo),
        ),
        family => $entry->{report_coordinate_authority}{family},
        level => $entry->{report_coordinate_authority}{level},
        primary_axis =>
            $entry->{report_coordinate_authority}{primary_axis},
        mode => 'gate_measurement',
        controller_applicability => {
            applicable => JSON::PP::true, reason => undef,
        },
        measurement_applicability => {
            applicable => JSON::PP::true, reason => undef,
        },
        validation_record => synthetic_record($common, 'validation', 0),
        measurement_records => [map {
            synthetic_record($common, 'gate_measurement', $_)
        } 1 .. 3],
        sample_exclusions => [],
        outcome => 'accepted',
        diagnostics => [],
        cleanup => {
            records_total => 4,
            ephemeral_removed => JSON::PP::true,
            residue => [],
        },
    };
    $report->{backend_profile} =
        $entry->{report_coordinate_authority}{backend_profile}
        if defined $entry->{report_coordinate_authority}{backend_profile};
    if ($entry->{provider_requirement}{kind} eq 'exact_tool_profile') {
        $report->{tool_profile} = clone($tool);
    }
    elsif ($entry->{provider_requirement}{kind}
            eq 'repository_materialization') {
        $report->{profile_authority} = {
            structural_authority => {
                provider_materialization =>
                    $entry->{provider_requirement}{provider_identity},
            },
        };
        $report->{provider_verification} = {
            applicable => JSON::PP::true,
            included_in_emit => JSON::PP::true,
            read_only => JSON::PP::true,
            external_verification_tool => JSON::PP::false,
            classification =>
                'sealed_osvvm_2026_05_provider_materialization',
        };
    }
    elsif ($entry->{adapter_class} eq
            'FSM::VIAL::ArchitectureScaleBackendEmissionMeasurement') {
        $report->{provider_verification} = {
            applicable => JSON::PP::false,
            included_in_emit => JSON::PP::false,
            read_only => JSON::PP::false,
            external_verification_tool => JSON::PP::false,
            classification => 'not_applicable',
        };
    }
    return $report;
}

sub synthetic_record {
    my ($common, $run_class, $run_ordinal) = @_;
    return {
        %{clone($common)},
        run_class => $run_class,
        run_ordinal => $run_ordinal,
        outcome => 'accepted',
    };
}

sub publish_profiles {
    my ($repo, @ordinals) = @_;
    for my $ordinal (@ordinals) {
        $profile_store->publish({
            repository_root => $repo,
            ordinal => $ordinal,
            report => synthetic_report($repo, $ordinal),
        });
    }
}

sub prepared_repository {
    my ($name) = @_;
    my $repo = fresh_repository($name);
    publish_profiles($repo, 1 .. 11);
    return $repo;
}

sub fresh_repository {
    my ($name) = @_;
    my $repo = File::Spec->catdir(
        $fixture_base, sprintf('%02d-%s', ++$fixture_sequence, $name),
    );
    make_path($repo, {mode => 0700});
    write_raw(File::Spec->catfile($repo, '.gitignore'), ".artifacts/\n");
    write_raw(File::Spec->catfile($repo, 'anchor.txt'), "fixture\n");
    git_ok($repo, qw(init -q));
    git_ok($repo, qw(config user.name FSMGEN));
    git_ok($repo, qw(config user.email fsmgen@example.invalid));
    git_ok($repo, qw(add .gitignore anchor.txt));
    git_ok($repo, qw(commit -q -m fixture));
    return $repo;
}

sub plan_entry {
    my ($ordinal) = @_;
    my @matches = grep { $_->{ordinal} == $ordinal }
        @{$sealed_plan->{entries}};
    die "test plan ordinal $ordinal is unavailable\n" unless @matches == 1;
    return clone($matches[0]);
}

sub complete_relative {
    return join '/',
        $sealed_plan->{publication_base}, $sealed_plan->{publication_id},
        'complete';
}

sub complete_exists {
    my ($repo) = @_;
    my $path = repo_path($repo, complete_relative());
    return -e($path) || -l($path);
}

sub complete_bytes {
    my ($repo) = @_;
    my $root = repo_path($repo, complete_relative());
    return join "\0",
        read_raw(File::Spec->catfile(
            $root, 'regression-promotion-corpus.json',
        )),
        read_raw(File::Spec->catfile($root, 'corpus-manifest.json'));
}

sub owned_staging_paths {
    my ($repo) = @_;
    my $base = repo_path($repo, '.artifacts/tmp/vial-scale');
    return () unless -d $base;
    my @paths;
    require File::Find;
    File::Find::find({
        no_chdir => 1,
        wanted => sub {
            push @paths, $File::Find::name
                if $File::Find::name =~ /regression-promotion/
                    && $File::Find::name ne $base;
        },
    }, $base);
    return @paths;
}

sub git_ok {
    my ($repo, @args) = @_;
    system('git', '-C', $repo, @args) == 0
        or die "git @args failed in fixture\n";
}

sub git_output {
    my ($repo, @args) = @_;
    open my $fh, '-|', 'git', '-C', $repo, @args
        or die "cannot run git @args in fixture\n";
    local $/;
    my $output = <$fh> // '';
    close $fh or die "git @args failed in fixture\n";
    return $output;
}

sub repo_path {
    my ($root, $relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub write_raw {
    my ($path, $content) = @_;
    make_path(dirname($path), {mode => 0700}) unless -d dirname($path);
    open my $fh, '>:raw', $path or die "cannot write '$path': $!\n";
    print {$fh} $content or die "cannot populate '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
}

sub append_raw {
    my ($path, $content) = @_;
    make_path(dirname($path), {mode => 0700}) unless -d dirname($path);
    open my $fh, '>>:raw', $path or die "cannot append '$path': $!\n";
    print {$fh} $content or die "cannot append content to '$path': $!\n";
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

sub canonical {
    return $json->encode($_[0]);
}

sub clone {
    return $json->decode($json->encode($_[0]));
}

sub dies {
    my ($code) = @_;
    my $error;
    eval { $code->(); 1 } or $error = $@;
    return defined($error) ? $error : '';
}
