#!/usr/bin/env perl

use strict;
use warnings;

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
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $capture =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture';
my $measurement = 'FSM::VIAL::ArchitectureScaleMeasurement';
my $plan_class =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionCapturePlan';
my $store =
    'FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore';
my $repo_root = Cwd::realpath(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_base = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-regression-promotion-profile-resume-$$",
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fixture_sequence = 0;

die "profile-resume fixture root already exists\n"
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

subtest 'current environment and public resume APIs are closed' => sub {
    my $repo = fresh_repository('closed-api');
    my $environment = $measurement->current_environment_identity({
        repository_root => $repo,
    });
    is_deeply([sort keys %$environment],
        [qw(host_profile resource_guard tool_profile)],
        'metadata-only environment identity has one closed shape');
    ok($environment->{resource_guard}{active},
        'environment identity retains the active repository guard');
    like(dies(sub {
        FSM::VIAL::ArchitectureScaleMeasurement::current_environment_identity(
            'borrowed', {},
        );
    }), qr/requires the exact class invocant/,
        'environment identity rejects a borrowed invocant');
    like(dies(sub {
        $measurement->current_environment_identity({
            repository_root => $repo, report => {},
        });
    }), qr/unknown key 'report'/,
        'environment callers cannot inject evidence');

    for my $key (qw(report entry callback adapter_method private_method)) {
        like(dies(sub {
            $capture->resume({
                repository_root => $repo, ordinal => 1, $key => 'injected',
            });
        }), qr/contains unknown key '\Q$key\E'/,
            "resume rejects caller $key injection");
    }
    like(dies(sub {
        $capture->resume({repository_root => $repo, ordinal => '1'});
    }), qr/profile capture ordinal is invalid/,
        'a JSON string cannot impersonate a resume ordinal');
    like(dies(sub {
        resume_with_validator($repo, 1);
    }), qr/(?:publication root is not a real directory|destination component)/,
        'an absent publication rejects without producer fallback');
};

subtest 'resume loads exact bytes in a fresh child without producer execution' => sub {
    my $repo = fresh_repository('resume-success');
    my $report = synthetic_report($repo, 1);
    my $artifact = $store->publish({
        repository_root => $repo, ordinal => 1, report => $report,
    });
    my $before = read_raw(repo_path(
        $repo, $artifact->{artifact_relative_path},
    ));
    my $pid_log = repo_path($repo, '.artifacts/tmp/resume-validator-pids');
    make_path(dirname($pid_log), {mode => 0700});
    my $result = resume_with_validator($repo, 1, pid_log => $pid_log);
    is($result->{artifact}{status}, 'loaded',
        'resume returns a loaded rather than republished artifact');
    is($result->{report_identity}, $report->{report_identity},
        'resume retains the exact stored report identity');
    is(read_raw(repo_path($repo, $artifact->{artifact_relative_path})),
        $before, 'resume leaves publication bytes unchanged');
    my @validator_pid = grep { length } split /\n/, read_raw($pid_log);
    is(scalar(@validator_pid), 2,
        'child and parent each rerun the public report validator once');
    ok(grep({ $_ != $$ } @validator_pid),
        'one validator execution occurs in a fresh child');
    ok(grep({ $_ == $$ } @validator_pid),
        'the parent independently revalidates after child completion');
};

subtest 'external and repository providers resume only at exact identity' => sub {
    for my $ordinal (7, 8) {
        my $repo = fresh_repository("provider-$ordinal");
        my $report = synthetic_report($repo, $ordinal);
        $store->publish({
            repository_root => $repo,
            ordinal => $ordinal,
            report => $report,
        });
        my $result = resume_with_validator($repo, $ordinal);
        is($result->{provider_status}{kind},
            plan_entry($ordinal)->{provider_requirement}{kind},
            "route $ordinal retains its exact provider kind");
        is($result->{artifact}{status}, 'loaded',
            "route $ordinal resumes without republishing");
    }
};

subtest 'stale revision, host, guard, tool, and mixed records reject' => sub {
    my @controls = (
        ['revision', qr/Git revision changed/, sub {
            $_->{git_revision} = 'f' x 40 for all_records($_[0]);
        }],
        ['host', qr/host identity is stale/, sub {
            $_->{host_profile}{cpu_model} = 'foreign-cpu'
                for all_records($_[0]);
        }],
        ['guard', qr/guard identity is stale/, sub {
            $_->{resource_guard}{host_max_percent} = 87
                for all_records($_[0]);
        }],
        ['tool', qr/tool identity is stale/, sub {
            $_->{tool_profile}{build} = 'foreign-build'
                for all_records($_[0]);
        }],
        ['mixed', qr/mixed host\/tool\/guard\/common identities/, sub {
            $_[0]{measurement_records}[2]{host_profile}{cpu_model} =
                'mixed-cpu';
        }],
        ['report-coordinate', qr/report coordinate 'primary_axis' changed/,
            sub { $_[0]{primary_axis} = 'foreign_axis' }],
    );
    for my $control (@controls) {
        my ($name, $expected, $mutate) = @$control;
        my $repo = fresh_repository("stale-$name");
        my $report = synthetic_report($repo, 1);
        $mutate->($report);
        $store->publish({
            repository_root => $repo, ordinal => 1, report => $report,
        });
        like(dies(sub { resume_with_validator($repo, 1) }), $expected,
            "$name resume identity rejects");
    }

    my $external_repo = fresh_repository('stale-external-provider');
    my $external = synthetic_report($external_repo, 8);
    $external->{tool_profile}{provider_identity} = 'foreign-provider';
    $_->{tool_profile}{provider_identity} = 'foreign-provider'
        for all_records($external);
    $store->publish({
        repository_root => $external_repo, ordinal => 8, report => $external,
    });
    like(dies(sub { resume_with_validator($external_repo, 8) }),
        qr/exact provider identity changed/,
        'rehashed foreign external provider rejects');

    my $material_repo = fresh_repository('stale-material-provider');
    my $material = synthetic_report($material_repo, 7);
    $_->{tool_profile}{external_verification_tool} = JSON::PP::true
        for all_records($material);
    $store->publish({
        repository_root => $material_repo, ordinal => 7, report => $material,
    });
    like(dies(sub { resume_with_validator($material_repo, 7) }),
        qr/repository provider became external/,
        'rehashed external structural provider rejects');
};

subtest 'staging, topology, and revision-one substitutions reject' => sub {
    my $stage_repo = published_repository('staging-residue', 1);
    my $entry = plan_entry(1);
    my $token = sprintf('%02d-%s', 1,
        sha256_hex($entry->{selection_key}));
    my $stage = repo_path(
        $stage_repo,
        ".artifacts/tmp/vial-scale/regression-promotion-profile-publication/v1/$token-residue",
    );
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile($stage, 'measurement-report.json'), "{}\n");
    like(dies(sub { resume_with_validator($stage_repo, 1) }),
        qr/retained staging residue/,
        'same-profile staging residue blocks resume before byte use');

    my $extra_repo = published_repository('extra-target-entry', 1);
    my $artifact = artifact_absolute($extra_repo, 1);
    write_raw(File::Spec->catfile(dirname($artifact), 'extra.json'), "{}\n");
    like(dies(sub { resume_with_validator($extra_repo, 1) }),
        qr/publication census changed/,
        'an extra target entry blocks resume');

    for my $control (
        ['plan', sub { $_[0]{plan_identity} = 'capture-plan/' . ('0' x 64) },
            qr/plan binding changed/],
        ['dispatch', sub { $_[0]{profile}{selection_key} .= '|foreign' },
            qr/dispatch binding changed/],
    ) {
        my ($name, $mutate, $expected) = @$control;
        my $repo = published_repository("stale-$name-publication", 1);
        rewrite_publication($repo, 1, $mutate);
        like(dies(sub { resume_with_validator($repo, 1) }), $expected,
            "rehashed stale $name publication rejects");
    }

    my $historical_repo = published_repository('historical-substitution', 1);
    my $target = artifact_absolute($historical_repo, 1);
    my $historical = repo_path(
        $historical_repo,
        '.artifacts/qualification/vial-scale/v1/measurement-report.json',
    );
    make_path(dirname($historical), {mode => 0700});
    write_raw($historical, read_raw($target));
    unlink($target) or die "cannot replace current publication: $!\n";
    symlink(File::Spec->abs2rel($historical, dirname($target)), $target)
        or die "cannot create historical substitution: $!\n";
    like(dies(sub { resume_with_validator($historical_repo, 1) }),
        qr/publication artifact is invalid/,
        'a revision-one symlink cannot satisfy current resume');
};

subtest 'post-worker mutation and producer-side repository mutation reject' => sub {
    my $artifact_repo = published_repository('post-worker-mutation', 1);
    my $worker = $capture->can('_run_profile_worker');
    my $post_error;
    {
        no warnings 'redefine';
        local *FSM::VIAL::ArchitectureScaleRegressionPromotionProfileCapture::_run_profile_worker =
            sub {
                my $result = $worker->(@_);
                append_raw(repo_path(
                    $artifact_repo,
                    $result->{artifact}{artifact_relative_path},
                ), "\n");
                return $result;
            };
        $post_error = dies(sub {
            resume_with_validator($artifact_repo, 1);
        });
    }
    like($post_error, qr/publication JSON is not canonical/,
        'mutation after child validation rejects in the parent reload');

    my $repo_mutation = published_repository('repository-mutation', 1);
    like(dies(sub {
        resume_with_validator($repo_mutation, 1, validator => sub {
            my ($request) = @_;
            write_raw(
                File::Spec->catfile($repo_mutation, 'anchor.txt'),
                "mutated\n",
            );
            return clone($request->{report});
        });
    }), qr/requires a clean Git revision/,
        'validator-side tracked mutation rejects before resume admission');
};

subtest 'resume worker exception and signal remain bounded failures' => sub {
    my $exception_repo = published_repository('worker-exception', 1);
    like(dies(sub {
        resume_with_validator($exception_repo, 1, validator => sub {
            die "synthetic resume validator exception\n";
        });
    }), qr/profile capture worker failed: synthetic resume validator exception/,
        'resume validator exceptions cross the bounded worker envelope');

    my $signal_repo = published_repository('worker-signal', 1);
    like(dies(sub {
        resume_with_validator($signal_repo, 1, validator => sub {
            kill 'TERM', $$;
            sleep 1;
            die "signal did not terminate resume worker\n";
        });
    }), qr/profile capture worker terminated by signal 15/,
        'signalled resume workers reject');
};

subtest 'repository-local resume fixtures clean exactly' => sub {
    remove_tree($fixture_base);
    ok(!-e($fixture_base) && !-l($fixture_base),
        'all publications, mutations, logs, and Git fixtures are removed');
};

done_testing;

sub resume_with_validator {
    my ($repo, $ordinal, %options) = @_;
    my $entry = plan_entry($ordinal);
    my $adapter = $entry->{adapter_class};
    my $method = $entry->{adapter_method};
    my $producer_calls = 0;
    my $result;
    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"${adapter}::${method}"} = sub {
            $producer_calls++;
            die "resume invoked the measurement producer\n";
        };
        local *{"${adapter}::validate_report"} = sub {
            my ($invocant, $request) = @_;
            die "resume validator class changed\n"
                unless $invocant eq $adapter;
            die "resume validator request changed\n"
                unless ref($request) eq 'HASH'
                    && canonical([sort keys %$request]) eq
                        canonical([qw(report repository_root)])
                    && $request->{repository_root} eq $repo;
            append_raw($options{pid_log}, "$$\n")
                if defined $options{pid_log};
            return $options{validator}
                ? $options{validator}->($request)
                : clone($request->{report});
        };
        $result = $capture->resume({
            repository_root => $repo, ordinal => $ordinal,
        });
    }
    die "resume executed the measurement producer\n" if $producer_calls;
    return $result;
}

sub published_repository {
    my ($name, $ordinal) = @_;
    my $repo = fresh_repository($name);
    $store->publish({
        repository_root => $repo,
        ordinal => $ordinal,
        report => synthetic_report($repo, $ordinal),
    });
    return $repo;
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
        schema => 'fsmgen.vial_architecture_scale_synthetic_resume.v1',
        schema_version => 1,
        report_identity => 'synthetic-resume/' . sha256_hex(
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

sub all_records {
    my ($report) = @_;
    return ($report->{validation_record}, @{$report->{measurement_records}});
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

sub artifact_absolute {
    my ($repo, $ordinal) = @_;
    return repo_path(
        $repo, plan_entry($ordinal)->{publication_relative_path},
    );
}

sub rewrite_publication {
    my ($repo, $ordinal, $mutate) = @_;
    my $loaded = $store->load({
        repository_root => $repo, ordinal => $ordinal,
    });
    my $publication = $loaded->{publication};
    $mutate->($publication);
    $publication->{publication_identity} = undef;
    $publication->{publication_identity} =
        'regression-promotion-profile-publication/'
        . sha256_hex(canonical($publication));
    write_raw(artifact_absolute($repo, $ordinal),
        canonical($publication) . "\n");
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

sub append_raw {
    my ($path, $content) = @_;
    open my $fh, '>>:raw', $path or die "cannot append '$path': $!\n";
    print {$fh} $content or die "cannot append data to '$path': $!\n";
    close $fh or die "cannot close '$path': $!\n";
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read '$path': $!\n";
    local $/;
    my $content = <$fh>;
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
