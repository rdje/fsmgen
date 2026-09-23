#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use POSIX ();
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $fixture = File::Spec->catdir(
    $root, '.artifacts', 'tmp',
    "vial-regression-promotion-budget-qualification-mutations-$$",
);
my $qualification_relative = join '/', qw(
    .artifacts qualification vial-scale v2
    regression-promotion-budget-qualification-v1 current
);
my $corpus_relative = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-corpus-v1
);
my $verifier_relative =
    'scripts/verify_vial_regression_promotion_budget_qualification.pl';
my $source_verifier_relative =
    'scripts/verify_vial_regression_promotion_current_corpus.pl';
my $historical_relative = join '/', qw(
    .artifacts qualification vial-scale history
    610ed7869642ee57f9df608204cfbad3a0b187e4
    regression-promotion-report-coordinate-failure-ordinal-5-v1
    profiles
    01-cba98f10c2a7bf1d5f35f2aa79daf240c642fffb2bc5fa15a96a7a4273fbf300
    measurement-report.json
);
my $qualification_stage_relative = join '/', qw(
    .artifacts tmp vial-scale
    regression-promotion-budget-qualification-publication v1
);
my $source_stage_relative = join '/', qw(
    .artifacts tmp vial-scale regression-promotion-corpus-publication v1
);
my $json = JSON::PP->new->canonical(1)->utf8(1);

my $real_qualification = repo_path($root, $qualification_relative);
my $real_corpus = repo_path($root, $corpus_relative);
my $ignored_inputs_present = -d $real_qualification && !-l $real_qualification
    && -d $real_corpus && !-l $real_corpus;
my $real_qualification_before = $ignored_inputs_present
    ? tree_census($real_qualification, 1) : undef;
my $real_corpus_before = $ignored_inputs_present
    ? tree_census($real_corpus, 1) : undef;
my $real_qualification_content = $ignored_inputs_present
    ? tree_census($real_qualification, 0) : undef;
my $real_corpus_content = $ignored_inputs_present
    ? tree_census($real_corpus, 0) : undef;

if ($ignored_inputs_present) {
    die "budget-qualification mutation fixture root already exists\n"
        if -e($fixture) || -l($fixture);
    make_path($fixture, {mode => 0700});
}

END {
    remove_tree($fixture)
        if $ignored_inputs_present
            && defined($fixture) && -d($fixture) && !-l($fixture);
}

if ($ignored_inputs_present) {
    copy_file(
        repo_path($root, $verifier_relative),
        repo_path($fixture, $verifier_relative),
    );
    copy_file(
        repo_path($root, $source_verifier_relative),
        repo_path($fixture, $source_verifier_relative),
    );
    copy_tree(
        $real_qualification,
        repo_path($fixture, $qualification_relative),
    );
    copy_tree($real_corpus, repo_path($fixture, $corpus_relative));
}

my $verifier = repo_path($fixture, $verifier_relative);
my $qualification = repo_path($fixture, $qualification_relative);
my $corpus = repo_path($fixture, $corpus_relative);
my $report = repo_path(
    $qualification, 'regression-promotion-budget-qualification.json',
);
my $manifest = repo_path($qualification, 'qualification-manifest.json');
my $source_profile = $ignored_inputs_present ? first_matching_file(
    $corpus, qr{/profiles/01-[^/]+/measurement-report[.]json\z},
) : undef;
my $historical = repo_path($root, $historical_relative);
my $report_mode = $ignored_inputs_present
    ? ((lstat($report))[2] & 07777) : undef;
my $manifest_mode = $ignored_inputs_present
    ? ((lstat($manifest))[2] & 07777) : undef;
my $source_profile_mode = $ignored_inputs_present
    ? ((lstat($source_profile))[2] & 07777) : undef;
my $fixture_baseline = $ignored_inputs_present
    ? tree_census($fixture, 0) : undef;
my $verified;

SKIP: {
skip 'ignored budget qualification inputs are absent on a fresh checkout', 10
    unless $ignored_inputs_present;

subtest 'copied exact qualification and source corpus are authentic' => sub {
    my @root_stat = lstat($root);
    my @fixture_stat = lstat($fixture);
    my @qualification_stat = lstat($qualification);
    my @corpus_stat = lstat($corpus);
    is($fixture_stat[0], $root_stat[0],
        'fixture resides on the repository device');
    is($qualification_stat[0], $root_stat[0],
        'copied qualification resides on the repository device');
    is($corpus_stat[0], $root_stat[0],
        'copied source corpus resides on the repository device');
    is($fixture_stat[4], $root_stat[4],
        'fixture retains the repository owner');
    is_deeply(
        tree_census($qualification, 0), $real_qualification_content,
        'qualification copy matches every real path/mode/link/owner/device/byte/hash',
    );
    is_deeply(
        tree_census($corpus, 0), $real_corpus_content,
        'source copy matches every real path/mode/link/owner/device/byte/hash',
    );
    $verified = assert_accepts('copied exact publication baseline');
};

subtest 'content, schema, type, formula, budget, order, and count reject' => sub {
    exercise_json_mutation('report content', $report, sub {
        $_[0]{outcome} = 'rejected';
    });
    exercise_json_mutation('report schema', $report, sub {
        $_[0]{schema} .= '.changed';
    });
    exercise_json_mutation('numeric type', $report, sub {
        $_[0]{qualification}{schema_version} = JSON::PP::true;
    });
    exercise_json_mutation('formula', $report, sub {
        $_[0]{qualification}{formula}{wall_time_ns}{floor}++;
    });
    exercise_json_mutation('qualified budget', $report, sub {
        $_[0]{qualification}{profiles}[0]{qualified_budget}
            {wall_time_ns}++;
    });
    exercise_json_mutation('profile order', $report, sub {
        @{$_[0]{qualification}{profiles}}[0, 1] =
            @{$_[0]{qualification}{profiles}}[1, 0];
    });
    exercise_json_mutation('profile count', $report, sub {
        pop @{$_[0]{qualification}{profiles}};
    });

    my $manifest_bytes = read_raw($manifest);
    exercise_mutation(
        'noncanonical manifest',
        sub { write_raw($manifest, $manifest_bytes . ' ') },
        sub { restore_raw($manifest, $manifest_bytes, $manifest_mode) },
    );
};

subtest 'environment, provider, applicability, and provenance reject' => sub {
    exercise_json_mutation('host profile', $report, sub {
        $_[0]{qualification}{profiles}[0]{environment_identity}
            {host_profile}{cpu_model} .= '-changed';
    });
    exercise_json_mutation('tool profile', $report, sub {
        $_[0]{qualification}{profiles}[0]{environment_identity}
            {tool_profile}{reported_version} .= '-changed';
    });
    exercise_json_mutation('resource guard', $report, sub {
        $_[0]{qualification}{profiles}[0]{environment_identity}
            {resource_guard}{host_max_percent}--;
    });
    exercise_json_mutation('provider status', $report, sub {
        $_[0]{qualification}{profiles}[8]{provider_status}
            {provider_identity} .= '-changed';
    });
    exercise_json_mutation('applicability contract', $report, sub {
        $_[0]{qualification}{performance_applicability}
            {environment_mismatch} = 'accepted';
    });
    exercise_json_mutation('publisher revision', $report, sub {
        $_[0]{publisher_revision} = '0' x 40;
    });
    exercise_json_mutation('source evidence', $report, sub {
        $_[0]{qualification}{source_evidence}{corpus_identity} =
            'regression-promotion-corpus/' . ('0' x 64);
    });
    exercise_json_mutation('stale evidence revision', $report, sub {
        $_[0]{qualification}{profiles}[0]{evidence_revision} = '0' x 40;
    });
};

subtest 'namespace, alias, collision, staging, and residue reject' => sub {
    my $extra = File::Spec->catfile($qualification, 'foreign.json');
    exercise_mutation(
        'extra namespace path',
        sub { write_raw($extra, "{}\n") },
        sub { unlink($extra) or die "cannot remove extra-path control\n" },
    );

    my $report_bytes = read_raw($report);
    exercise_mutation(
        'missing namespace path',
        sub { unlink($report) or die "cannot remove copied report\n" },
        sub { restore_raw($report, $report_bytes, $report_mode) },
    );
    exercise_mutation(
        'report symlink',
        sub {
            unlink($report) or die "cannot remove report for symlink\n";
            symlink($manifest, $report)
                or die "cannot create report symlink control: $!\n";
        },
        sub {
            unlink($report) or die "cannot remove report symlink\n";
            restore_raw($report, $report_bytes, $report_mode);
        },
    );
    exercise_mutation(
        'report hard link',
        sub {
            unlink($report) or die "cannot remove report for hard link\n";
            link($manifest, $report)
                or die "cannot create report hard-link control: $!\n";
        },
        sub {
            unlink($report) or die "cannot remove report hard link\n";
            restore_raw($report, $report_bytes, $report_mode);
        },
    );
    exercise_mutation(
        'report special-file node',
        sub {
            unlink($report) or die "cannot remove report for FIFO\n";
            POSIX::mkfifo($report, 0600)
                or die "cannot create report FIFO control: $!\n";
        },
        sub {
            unlink($report) or die "cannot remove report FIFO\n";
            restore_raw($report, $report_bytes, $report_mode);
        },
    );
    exercise_mutation(
        'report coordinate collision',
        sub {
            unlink($report) or die "cannot remove report for collision\n";
            make_path($report, {mode => 0700});
        },
        sub {
            remove_tree($report);
            restore_raw($report, $report_bytes, $report_mode);
        },
    );

    my $qualification_stage =
        repo_path($fixture, $qualification_stage_relative);
    exercise_mutation(
        'qualification staging residue',
        sub {
            make_path($qualification_stage, {mode => 0700});
            write_raw(File::Spec->catfile($qualification_stage, 'residue'),
                "residue\n");
        },
        sub { remove_tree(repo_path($fixture, '.artifacts/tmp')) },
    );

    my $source_stage = repo_path($fixture, $source_stage_relative);
    exercise_mutation(
        'source publication residue',
        sub {
            make_path($source_stage, {mode => 0700});
            write_raw(File::Spec->catfile($source_stage, 'residue'),
                "residue\n");
        },
        sub { remove_tree(repo_path($fixture, '.artifacts/tmp')) },
    );

    my $source_bytes = read_raw($source_profile);
    my $historical_bytes = read_raw($historical);
    exercise_mutation(
        'historical source substitution',
        sub { write_raw($source_profile, $historical_bytes) },
        sub {
            restore_raw(
                $source_profile, $source_bytes, $source_profile_mode,
            );
        },
    );
};

subtest 'authenticated applicability has explicit three-way behavior' => sub {
    my $published = $json->decode(read_raw($report));
    my $policy = $published->{qualification}{performance_applicability};
    my $profile = $published->{qualification}{profiles}[0];
    is(
        $verified->{performance_applicability_identity},
        $policy->{applicability_identity},
        'policy comes from the independently authenticated qualification',
    );
    is_deeply(
        $policy->{exact_environment_fields},
        [qw(host_profile tool_profile resource_guard provider_status)],
        'all four environment dimensions are exact',
    );
    is_deeply(
        $policy->{exact_deterministic_fields},
        [qw(selection_key workload_identity correctness_projection_identity)],
        'all three deterministic dimensions are exact',
    );
    is($policy->{evidence_revision_role},
        'immutable_qualification_provenance_only',
        'the capture revision is provenance rather than an applicability axis');

    my $reference = applicability_reference($profile);
    my $exact = clone_value($reference);
    $exact->{evidence_revision} = 'f' x 40;
    is(
        applicability_outcome($policy, $reference, $exact),
        'performance_enforcement_eligible_after_correctness',
        'a later revision with exact deterministic and environment identity is eligible',
    );

    for my $field (@{$policy->{exact_environment_fields}}) {
        my $changed = clone_value($reference);
        mutate_value($changed->{exact_environment}{$field});
        is(
            applicability_outcome($policy, $reference, $changed),
            'correctness_required_performance_informational',
            "$field drift leaves correctness required and performance informational",
        );
    }
    for my $field (@{$policy->{exact_deterministic_fields}}) {
        my $changed = clone_value($reference);
        mutate_value($changed->{exact_deterministic}{$field});
        is(
            applicability_outcome($policy, $reference, $changed),
            'correctness_rejects_before_performance',
            "$field drift rejects before performance",
        );
    }

    my $unavailable = clone_value($reference);
    $unavailable->{exact_environment}{provider_status}{kind} = 'unavailable';
    is(
        applicability_outcome($policy, $reference, $unavailable),
        'unavailable_not_pass',
        'an unavailable exact provider cannot be reported as a pass',
    );
};

subtest 'recalibration requires separately owned immutable replacement' => sub {
    my $published = $json->decode(read_raw($report));
    my $contract = $published->{publication_contract};
    is($contract->{enforcement_state}, 'not_activated',
        'publication alone does not activate enforcement');
    is($contract->{replacement_policy}{version},
        'immutable_new_version_only', 'replacement requires a new version');
    ok(!$contract->{replacement_policy}{overwrite},
        'replacement cannot overwrite the current version');
    is($contract->{recalibration}{authority},
        'separately_owned_task_tree_leaf',
        'recalibration requires separate task-tree ownership');
    is($contract->{recalibration}{evidence},
        'old_and_new_current_corpus_qualifications',
        'recalibration requires old and new qualification evidence');

    is(recalibration_outcome($contract, {
        overwrite => JSON::PP::true,
        separately_owned => JSON::PP::true,
        old_identity => 'old',
        new_identity => 'new',
    }), 'rejected_overwrite', 'an in-place overwrite rejects');
    is(recalibration_outcome($contract, {
        overwrite => JSON::PP::false,
        separately_owned => JSON::PP::false,
        old_identity => 'old',
        new_identity => 'new',
    }), 'rejected_unowned', 'an unowned replacement rejects');
    is(recalibration_outcome($contract, {
        overwrite => JSON::PP::false,
        separately_owned => JSON::PP::true,
        old_identity => 'same',
        new_identity => 'same',
    }), 'rejected_missing_old_new_evidence',
        'a replacement without distinct old/new identities rejects');
    is(recalibration_outcome($contract, {
        overwrite => JSON::PP::false,
        separately_owned => JSON::PP::true,
        old_identity => 'old',
        new_identity => 'new',
    }), 'eligible_immutable_new_version',
        'separate ownership plus distinct old/new evidence is eligible');
};

$verified = assert_accepts('all controls restored final baseline');
    is_deeply(
        tree_census($real_qualification, 1), $real_qualification_before,
        'all copied controls leave the real qualification byte/file-identical',
    );
    is_deeply(
        tree_census($real_corpus, 1), $real_corpus_before,
        'all copied controls leave the real source corpus byte/file-identical',
    );
    remove_tree($fixture);
    ok(!-e($fixture) && !-l($fixture),
        'repository-local mutation fixture is removed deterministically');
}

done_testing;



sub exercise_json_mutation {
    my ($label, $path, $mutator) = @_;
    my $original = read_raw($path);
    my $value = $json->decode($original);
    $mutator->($value);
    my $mutated = $json->encode($value) . "\n";
    die "$label did not change copied bytes\n" if $mutated eq $original;
    exercise_mutation(
        $label,
        sub { write_raw($path, $mutated) },
        sub { write_raw($path, $original) },
    );
}

sub exercise_mutation {
    my ($label, $mutate, $restore) = @_;
    $mutate->();
    my $rejected = run_verifier();
    isnt($rejected->{status}, 0, "$label rejects");
    is($rejected->{signal}, 0, "$label exits without a signal");
    is($rejected->{stdout}, '', "$label emits no partial result");
    isnt($rejected->{stderr}, '', "$label emits a diagnostic");
    cmp_ok(bytes::length($rejected->{stderr}), '<=', 65_536,
        "$label diagnostic stays inside the test ceiling");
    $restore->();
    is_deeply(
        tree_census($fixture, 0), $fixture_baseline,
        "$label restores the exact copied fixture census",
    );
}

sub assert_accepts {
    my ($label) = @_;
    my $result = run_verifier();
    is($result->{status}, 0, "$label accepts") or diag($result->{stderr});
    is($result->{signal}, 0, "$label exits without a signal");
    is($result->{stderr}, '', "$label is diagnostic-free");
    isnt($result->{stdout}, '', "$label emits its complete result");
    cmp_ok(bytes::length($result->{stdout}), '<=', 262_144,
        "$label result is bounded");
    my $decoded = eval { $json->decode($result->{stdout}) };
    is($@, '', "$label result is JSON");
    is($result->{stdout}, $json->encode($decoded) . "\n",
        "$label result is canonical newline JSON");
    return $decoded;
}

sub applicability_reference {
    my ($profile) = @_;
    return {
        evidence_revision => $profile->{evidence_revision},
        exact_environment => clone_value($profile->{environment_identity}),
        exact_deterministic => {
            selection_key => $profile->{selection_key},
            workload_identity => $profile->{workload_identity},
            correctness_projection_identity =>
                $profile->{correctness_projection_identity},
        },
    };
}

sub applicability_outcome {
    my ($policy, $reference, $candidate) = @_;
    for my $field (@{$policy->{exact_deterministic_fields}}) {
        return $policy->{deterministic_mismatch}
            unless same_value(
                $reference->{exact_deterministic}{$field},
                $candidate->{exact_deterministic}{$field},
            );
    }
    for my $field (@{$policy->{exact_environment_fields}}) {
        next if same_value(
            $reference->{exact_environment}{$field},
            $candidate->{exact_environment}{$field},
        );
        return $policy->{unavailable_exact_provider}
            if $field eq 'provider_status'
                && ($candidate->{exact_environment}{$field}{kind} // '') eq
                    'unavailable';
        return $policy->{environment_mismatch};
    }
    return $policy->{matching_later_revision};
}

sub recalibration_outcome {
    my ($contract, $candidate) = @_;
    return 'rejected_overwrite'
        if $candidate->{overwrite}
            || $contract->{replacement_policy}{overwrite};
    return 'rejected_unowned' unless $candidate->{separately_owned};
    return 'rejected_missing_old_new_evidence'
        unless defined($candidate->{old_identity})
            && defined($candidate->{new_identity})
            && $candidate->{old_identity} ne $candidate->{new_identity};
    return 'eligible_immutable_new_version';
}

sub mutate_value {
    my ($value) = @_;
    if (ref($value) eq 'HASH') {
        my ($key) = sort keys %$value;
        die "cannot mutate empty object\n" unless defined($key);
        mutate_value($value->{$key});
        return;
    }
    if (ref($value) eq 'ARRAY') {
        die "cannot mutate empty array\n" unless @$value;
        mutate_value($value->[0]);
        return;
    }
    $_[0] = defined($value) ? "$value-changed" : 'changed';
}

sub run_verifier {
    my $error = gensym;
    my $pid = open3(my $input, my $output, $error, $^X, $verifier);
    close $input or die "cannot close verifier input\n";
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output or die "cannot close verifier output\n";
    close $error or die "cannot close verifier diagnostics\n";
    waitpid($pid, 0) == $pid or die "cannot wait for verifier\n";
    return {
        status => $? == -1 ? -1 : $? >> 8,
        signal => $? & 127,
        stdout => $stdout,
        stderr => $stderr,
    };
}

sub tree_census {
    my ($base, $include_inode) = @_;
    die "ignored budget qualification input is absent\n" unless -d $base;
    my @entries;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat mutation-census path\n" unless @stat;
            my $relative = File::Spec->abs2rel($path, $base);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            my $entry = {
                relative_path => $relative,
                device => $stat[0],
                mode => $stat[2],
                links => $stat[3],
                owner => $stat[4],
                bytes => $stat[7],
                type => -l _ ? 'symlink'
                    : -d _ ? 'directory'
                    : -f _ ? 'file' : 'other',
            };
            $entry->{inode} = $stat[1] if $include_inode;
            $entry->{sha256} = sha256_hex(read_raw($path)) if -f _;
            push @entries, $entry;
        },
    }, $base);
    return [sort {
        $a->{relative_path} cmp $b->{relative_path}
    } @entries];
}

sub copy_tree {
    my ($source, $destination) = @_;
    die "mutation fixture source tree is unavailable\n"
        unless -d($source) && !-l($source);
    my @directory_modes;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            die "mutation fixture source contains a symlink\n" if -l($path);
            my $relative = File::Spec->abs2rel($path, $source);
            my $target = $relative eq '.'
                ? $destination
                : File::Spec->catfile($destination, $relative);
            my @stat = lstat($path);
            die "cannot stat mutation fixture source path\n" unless @stat;
            my $permissions = $stat[2] & 07777;
            if (-d _) {
                make_path($target, {mode => 0700});
                push @directory_modes, [$target, $permissions];
                return;
            }
            die "mutation fixture source contains a non-file\n" unless -f _;
            copy_file($path, $target);
            chmod($permissions, $target) == 1
                or die "cannot preserve mutation fixture file mode\n";
        },
    }, $source);
    for my $entry (sort {
        length($b->[0]) <=> length($a->[0])
    } @directory_modes) {
        chmod($entry->[1], $entry->[0]) == 1
            or die "cannot preserve mutation fixture directory mode\n";
    }
}

sub copy_file {
    my ($source, $destination) = @_;
    make_path(dirname($destination), {mode => 0700});
    copy($source, $destination)
        or die "cannot copy mutation fixture file\n";
}

sub first_matching_file {
    my ($base, $pattern) = @_;
    my @matches;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my $normalized = $path;
            $normalized =~ s{\\}{/}g;
            push @matches, $path if -f _ && $normalized =~ $pattern;
        },
    }, $base);
    die "mutation fixture expected exactly one matching file\n"
        unless @matches == 1;
    return $matches[0];
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or die "cannot read mutation fixture path\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or die "cannot close mutation fixture path\n";
    return $bytes;
}

sub write_raw {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path
        or die "cannot write mutation fixture path\n";
    print {$fh} $bytes or die "cannot write mutation fixture bytes\n";
    close $fh or die "cannot close mutation fixture path\n";
}

sub restore_raw {
    my ($path, $bytes, $mode) = @_;
    write_raw($path, $bytes);
    chmod($mode, $path) == 1
        or die "cannot restore mutation fixture file mode\n";
}

sub clone_value {
    my ($value) = @_;
    return $json->decode($json->encode($value));
}

sub same_value {
    my ($left, $right) = @_;
    return $json->encode($left) eq $json->encode($right);
}

sub repo_path {
    my ($base, @parts) = @_;
    return File::Spec->catfile($base, map { split m{/} } @parts);
}
