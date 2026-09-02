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
use POSIX qw(_exit);
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture';
my $plan_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $repo_root = Cwd::realpath(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-regression-promotion-profile-capture-$$",
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fixture_sequence = 0;

die "profile-capture fixture root already exists\n"
    if -e $fixture_base || -l $fixture_base;
make_path($fixture_base, {mode => 0700});

local $ENV{FSMGEN_RAM_GUARD_ACTIVE} = 1;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT} = 88;
local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB} = 4096;

END {
    remove_tree($fixture_base)
        if defined($fixture_base) && -d($fixture_base) && !-l($fixture_base);
}

subtest 'public capture inherits the active repository guard' => sub {
    local $ENV{FSMGEN_RAM_GUARD_ACTIVE};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT};
    local $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB};
    like(dies(sub {
        $class->capture({repository_root => $repo_root, ordinal => 1});
    }), qr/requires the active repository RAM guard/,
        'capture rejects before deriving or executing a producer');
};

my $sealed_plan = $plan_class->derive({repository_root => $repo_root});
{
    no warnings 'redefine';
    *FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan::derive =
        sub { return clone($sealed_plan) };
}

subtest 'public API is ordinal-only, closed, and metadata-bounded' => sub {
    is_deeply([sort @{$class->result_keys}], [sort qw(
        schema schema_version plan_identity policy_identity ordinal
        selection_key report_identity common_identity provider_status
        applicability_status artifact
    )], 'capture result has one closed metadata schema');
    is_deeply($class->capture_limits, {
        capture_revision => 'regression_promotion_profile_capture_v1',
        maximum_ipc_bytes => 65_536,
        maximum_error_bytes => 4_096,
        validation_records => 1,
        raw_measurement_records => 3,
        controller_invocations => 4,
    }, 'worker IPC and accepted record counts are explicit');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::capture(
            'borrowed', {},
        );
    }), qr/requires the exact class invocant/,
        'borrowed invocants reject');

    my $repo = fresh_repository('closed-request');
    for my $key (qw(
        entry report callback adapter_class adapter_method private_method
        publication_relative_path
    )) {
        like(dies(sub {
            $class->capture({
                repository_root => $repo, ordinal => 1, $key => 'injected',
            });
        }), qr/contains unknown key '\Q$key\E'/,
            "caller $key injection rejects");
    }
    like(dies(sub {
        $class->capture({repository_root => $repo, ordinal => '1'});
    }), qr/profile capture ordinal is invalid/,
        'a JSON string cannot masquerade as ordinal one');
    like(dies(sub {
        $class->capture({repository_root => $repo, ordinal => 12});
    }), qr/profile capture ordinal is unknown/,
        'an ordinal outside the current plan rejects');
};

subtest 'one sealed public adapter executes in a child and publishes v2' => sub {
    my $repo = fresh_repository('semantic-success');
    my $parent_pid = $$;
    my $result = capture_with_report($repo, 1, sub {
        return synthetic_report($repo, 1);
    });
    isnt($result->{common_identity}{host_profile}{worker_pid}, $parent_pid,
        'the public adapter ran in a distinct child process');
    is($result->{ordinal}, 1, 'result retains the selected ordinal');
    is($result->{artifact}{status}, 'published',
        'the child published through the v2 store');
    like($result->{artifact}{artifact_relative_path},
        qr{\A[.]artifacts/qualification/vial-scale/v2/},
        'only the plan-derived v2 coordinate is returned');
    ok($result->{artifact}{same_volume} && $result->{artifact}{atomic},
        'metadata retains same-volume atomic publication evidence');
    is($result->{applicability_status}{raw_measurement_records}, 3,
        'three raw records were admitted');
    is($result->{applicability_status}{sample_exclusions}, 0,
        'zero exclusions were admitted');
    my $loaded = $store->load({repository_root => $repo, ordinal => 1});
    is($loaded->{publication}{report}{validation_record}{run_class},
        'validation', 'the stored report starts with validation');
    is_deeply(
        [map { $_->{run_ordinal} }
            @{$loaded->{publication}{report}{measurement_records}}],
        [1, 2, 3], 'the stored raw records retain exact order');
    ok(!same_profile_staging_paths($repo, 1),
        'successful dispatch leaves no profile staging residue');
};

subtest 'exact external and repository providers bind to the report' => sub {
    my $external_repo = fresh_repository('external-provider');
    my $external = capture_with_report($external_repo, 8, sub {
        return synthetic_report($external_repo, 8);
    });
    is($external->{provider_status}{kind}, 'exact_tool_profile',
        'runtime capture returns the exact external provider status');
    is($external->{provider_status}{provider_identity},
        'qualified_verilator_5_046',
        'runtime capture retains the qualified provider identity');

    my $material_repo = fresh_repository('material-provider');
    my $material = capture_with_report($material_repo, 7, sub {
        return synthetic_report($material_repo, 7);
    });
    is($material->{provider_status}{kind}, 'repository_materialization',
        'emission capture distinguishes repository provider materialization');
    is($material->{provider_status}{provider_identity},
        'external_exact_osvvm_2026_05',
        'repository materialization retains its exact sealed identity');
};

subtest 'every current route crosses the same one-entry child boundary' => sub {
    for my $ordinal (2 .. 6, 9 .. 11) {
        my $repo = fresh_repository("route-$ordinal");
        my $result = capture_with_report($repo, $ordinal, sub {
            return synthetic_report($repo, $ordinal);
        });
        is($result->{ordinal}, $ordinal,
            "route $ordinal retains its exact dispatch ordinal");
        is($result->{selection_key}, plan_entry($ordinal)->{selection_key},
            "route $ordinal retains its exact selection key");
        is($result->{artifact}{status}, 'published',
            "route $ordinal publishes once through the v2 store");
    }
};

subtest 'producer report coordinates are exact and independent of selection' => sub {
    my $backend = plan_entry(5);
    ok(!defined($backend->{coordinates}{primary_axis}),
        'the backend policy selection axis remains deliberately nullable');
    is($backend->{report_coordinate_authority}{primary_axis},
        'artifact_graph',
        'the backend producer report axis remains independently explicit');

    for my $control (
        ['family-change', 5, sub { $_[0]{family} = 'foreign_family' },
            qr/report coordinate 'family' changed/],
        ['level-change', 5, sub { $_[0]{level} = 'foreign_level' },
            qr/report coordinate 'level' changed/],
        ['axis-change', 5, sub { $_[0]{primary_axis} = 'foreign_axis' },
            qr/report coordinate 'primary_axis' changed/],
        ['backend-change', 5,
            sub { $_[0]{backend_profile} = 'foreign_backend' },
            qr/report coordinate 'backend_profile' changed/],
        ['family-omission', 5, sub { delete $_[0]{family} },
            qr/report coordinate 'family' changed/],
        ['level-omission', 5, sub { delete $_[0]{level} },
            qr/report coordinate 'level' changed/],
        ['axis-omission', 5, sub { delete $_[0]{primary_axis} },
            qr/report coordinate 'primary_axis' changed/],
        ['backend-omission', 5, sub { delete $_[0]{backend_profile} },
            qr/report coordinate 'backend_profile' changed/],
        ['backend-appearance', 1,
            sub { $_[0]{backend_profile} = 'foreign_backend' },
            qr/report coordinate 'backend_profile' appeared/],
    ) {
        my ($name, $ordinal, $mutation, $expected) = @{$control};
        my $repo = fresh_repository("report-coordinate-$name");
        like(dies(sub {
            capture_with_report($repo, $ordinal, sub {
                my $report = synthetic_report($repo, $ordinal);
                $mutation->($report);
                return $report;
            });
        }), $expected, "$name rejects");
        ok(!-e(expected_profile_directory($repo, $ordinal)),
            "$name never publishes");
    }
};

subtest 'failed, mixed, reordered, excluded, and residual reports reject' => sub {
    my @controls = (
        ['coordinate', sub { $_[0]{family} = 'foreign_family' },
            qr/report coordinate 'family' changed/],
        ['validation', sub { $_[0]{validation_record}{outcome} = 'rejected' },
            qr/record 0 did not accept/],
        ['incomplete', sub { pop @{$_[0]{measurement_records}} },
            qr/measurement records are invalid/],
        ['reordered', sub {
            @{$_[0]{measurement_records}}[0, 1] =
                @{$_[0]{measurement_records}}[1, 0];
        }, qr/record order changed/],
        ['failed-raw', sub {
            $_[0]{measurement_records}[1]{outcome} = 'stage_failure';
        }, qr/record 2 did not accept/],
        ['excluded', sub {
            push @{$_[0]{sample_exclusions}}, {reason => 'fixture'};
        }, qr/sample exclusions are invalid/],
        ['diagnostic', sub {
            push @{$_[0]{diagnostics}}, {code => 'fixture'};
        }, qr/diagnostics are invalid/],
        ['boolean-type', sub {
            $_[0]{measurement_applicability}{applicable} = 1;
        }, qr/profile capture measurement applicable is not a JSON boolean/],
        ['residue', sub {
            push @{$_[0]{cleanup}{residue}}, 'fixture';
        }, qr/cleanup is invalid/],
        ['mixed-common', sub {
            $_[0]{measurement_records}[2]{host_profile}{worker_pid}++;
        }, qr/mixed host\/tool\/guard\/common identities/],
        ['dirty-record', sub {
            $_[0]{validation_record}{dirty_state} = JSON::PP::true;
            $_->{dirty_state} = JSON::PP::true
                for @{$_[0]{measurement_records}};
        }, qr/report is dirty/],
    );
    for my $control (@controls) {
        my ($name, $mutation, $expected) = @$control;
        my $repo = fresh_repository("reject-$name");
        my $error = dies(sub {
            capture_with_report($repo, 1, sub {
                my $report = synthetic_report($repo, 1);
                $mutation->($report);
                return $report;
            });
        });
        like($error, $expected, "$name report rejects");
        ok(!-e(expected_profile_directory($repo, 1)),
            "$name report never publishes");
    }
};

subtest 'provider substitution and repository mutation reject before publish' => sub {
    my $provider_repo = fresh_repository('provider-substitution');
    like(dies(sub {
        capture_with_report($provider_repo, 8, sub {
            my $report = synthetic_report($provider_repo, 8);
            $report->{tool_profile}{provider_identity} = 'foreign_provider';
            $_->{tool_profile}{provider_identity} = 'foreign_provider'
                for ($report->{validation_record},
                    @{$report->{measurement_records}});
            return $report;
        });
    }), qr/exact provider identity changed/,
        'an internally consistent foreign external provider rejects');
    ok(!-e(expected_profile_directory($provider_repo, 8)),
        'foreign provider report never publishes');

    my $material_repo = fresh_repository('material-provider-substitution');
    like(dies(sub {
        capture_with_report($material_repo, 7, sub {
            my $report = synthetic_report($material_repo, 7);
            $_->{tool_profile}{external_verification_tool} = JSON::PP::true
                for ($report->{validation_record},
                    @{$report->{measurement_records}});
            return $report;
        });
    }), qr/repository provider became external/,
        'an internally consistent external structural tool profile rejects');
    ok(!-e(expected_profile_directory($material_repo, 7)),
        'external structural tool profile never publishes');

    my $mutation_repo = fresh_repository('repository-mutation');
    like(dies(sub {
        capture_with_report($mutation_repo, 1, sub {
            write_raw(File::Spec->catfile($mutation_repo, 'anchor.txt'),
                "mutated\n");
            return synthetic_report($mutation_repo, 1);
        });
    }), qr/requires a clean Git revision/,
        'a producer-side tracked mutation rejects before publication');
    ok(!-e(expected_profile_directory($mutation_repo, 1)),
        'repository mutation never publishes');

    my $dirty_repo = fresh_repository('dirty-before-fork');
    write_raw(File::Spec->catfile($dirty_repo, 'untracked.txt'), "dirty\n");
    like(dies(sub {
        capture_with_report($dirty_repo, 1, sub {
            die "producer must not execute in a dirty repository\n";
        });
    }), qr/requires a clean Git revision/,
        'dirty repository state rejects before worker execution');
};

subtest 'worker failures and hostile envelopes fail closed' => sub {
    my $exception_repo = fresh_repository('worker-exception');
    like(dies(sub {
        capture_with_report($exception_repo, 1, sub {
            die "synthetic producer exception\n";
        });
    }), qr/profile capture worker failed: synthetic producer exception/,
        'producer exceptions cross only the bounded failure envelope');

    my $signal_repo = fresh_repository('worker-signal');
    like(dies(sub {
        capture_with_report($signal_repo, 1, sub {
            kill 'TERM', $$;
            sleep 1;
            die "signal did not terminate worker\n";
        });
    }), qr/profile capture worker terminated by signal 15/,
        'signalled workers reject');

    my $exit_repo = fresh_repository('worker-exit');
    my $exit_error;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::_capture_in_child =
            sub { _exit(23) };
        $exit_error = dies(sub {
            $class->capture({repository_root => $exit_repo, ordinal => 1});
        });
    }
    like($exit_error, qr/returned no result with exit status 23/,
        'unframed worker exits reject');

    my $decode = $class->can('_decode_worker_envelope');
    my (undef, $malformed) = $decode->('{not-json}');
    is($malformed, 'result is not valid JSON',
        'malformed worker JSON rejects');
    my $valid = {
        schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_profile_worker.v1',
        schema_version => 1,
        ok => JSON::PP::true,
        payload => {},
        error => undef,
    };
    my $pretty = JSON::PP->new->utf8(1)->pretty(1)->encode($valid);
    my (undef, $noncanonical) = $decode->($pretty);
    is($noncanonical, 'result is not canonical JSON',
        'noncanonical worker JSON rejects');
    my (undef, $oversized) = $decode->('x' x 65_537);
    is($oversized, 'result exceeded the bounded envelope',
        'cap-plus-one worker bytes reject before decode');
    my $bounded = $class->can('_bounded_error')->("x" x 8_192);
    is(bytes::length($bounded), 4_096,
        'worker diagnostics remain inside the error ceiling');
};

subtest 'repository-local fixtures and publications clean exactly' => sub {
    remove_tree($fixture_base);
    ok(!-e($fixture_base) && !-l($fixture_base),
        'all child publications, Git fixtures, and mutations are removed');
};

done_testing;

sub capture_with_report {
    my ($repo, $ordinal, $producer) = @_;
    my $entry = plan_entry($ordinal);
    my $adapter = $entry->{adapter_class};
    my $method = $entry->{adapter_method};
    my $result;
    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"${adapter}::${method}"} = sub {
            my ($invocant, $request) = @_;
            die "adapter class invocant changed\n" unless $invocant eq $adapter;
            my %expected = (
                %{$entry->{adapter_arguments}}, repository_root => $repo,
            );
            die "sealed adapter arguments changed\n"
                unless canonical($request) eq canonical(\%expected);
            return $producer->($request);
        };
        local *{"${adapter}::validate_report"} = sub {
            my ($invocant, $request) = @_;
            die "validator class invocant changed\n" unless $invocant eq $adapter;
            die "validator request changed\n"
                unless ref($request) eq 'HASH'
                    && canonical([sort keys %$request]) eq
                        canonical([qw(report repository_root)])
                    && $request->{repository_root} eq $repo;
            return clone($request->{report});
        };
        $result = $class->capture({
            repository_root => $repo, ordinal => $ordinal,
        });
    }
    return $result;
}

sub synthetic_report {
    my ($repo, $ordinal) = @_;
    my $entry = plan_entry($ordinal);
    my $revision = git_output($repo, qw(rev-parse HEAD));
    $revision =~ s/\s+\z//;
    my $tool = $entry->{provider_requirement}{kind} eq 'exact_tool_profile'
        ? $entry->{adapter_class}->tool_profile
        : {
            logical_name => 'fsmgen',
            provider_identity => 'repository_owned',
            external_verification_tool => JSON::PP::false,
        };
    my $common = {
        git_revision => $revision,
        dirty_state => JSON::PP::false,
        host_profile => {system => 'fixture', worker_pid => $$},
        tool_profile => clone($tool),
        resource_guard => {
            active => JSON::PP::true,
            host_max_percent => 88,
            single_descendant_max_mib => 4096,
        },
    };
    my $report = {
        schema => 'fsmgen.vial_architecture_scale_synthetic_capture.v1',
        schema_version => 1,
        report_identity => 'synthetic-capture/' . sha256_hex(
            join('/', $ordinal, $revision, $$),
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

sub expected_profile_directory {
    my ($repo, $ordinal) = @_;
    return dirname(repo_path(
        $repo, plan_entry($ordinal)->{publication_relative_path},
    ));
}

sub same_profile_staging_paths {
    my ($repo, $ordinal) = @_;
    my $entry = plan_entry($ordinal);
    my $token = sprintf('%02d-%s', $ordinal,
        sha256_hex($entry->{selection_key}));
    my $base = repo_path($repo,
        '.artifacts/tmp/vial-scale/regression-promotion-profile-publication/v1');
    return () unless -d $base;
    opendir my $dh, $base or die "cannot inspect capture staging: $!\n";
    my @paths = grep { /^\Q$token\E-/ } readdir $dh;
    closedir $dh or die "cannot close capture staging: $!\n";
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
    open my $fh, '>:raw', $path or die "cannot write '$path': $!\n";
    print {$fh} $content or die "cannot populate '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
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
