#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Find qw(find);
use File::Spec;
use FindBin;
use JSON::PP ();

my $ROOT = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $BUNDLE_RELATIVE =
    'vial/qualification/regression_promotion_gate/evidence-v1';
my $MANIFEST_RELATIVE = 'transport-manifest.json';
my $SCHEMA = 'fsmgen.vial_regression_promotion_gate_evidence_transport.v1';
my $BUNDLE_IDENTITY =
    'regression-promotion-gate-evidence-transport/'
    . '3b4c486e8e3f853f626d85d2abc713846d0594230d922913c8655be3f682bbc6';
my $CORPUS_IDENTITY =
    'regression-promotion-corpus/'
    . 'ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505';
my $CORPUS_PUBLICATION_IDENTITY =
    'regression-promotion-corpus-publication/'
    . '865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e';
my $CORPUS_FILE_SET_SHA256 =
    'dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f';
my $QUALIFICATION_IDENTITY =
    'regression-promotion-qualification/'
    . 'd8fb18132ebb52d85f30f40edc46f8e81a47bba90eb61f9bf02ae0821da60c97';
my $QUALIFICATION_PUBLICATION_IDENTITY =
    'regression-promotion-budget-qualification-publication/'
    . '1c2a3832b2b4163e1a6a8124feff2b452f8522c2929098447f3903115ad2945f';
my $QUALIFICATION_REPORT_IDENTITY =
    'regression-promotion-budget-qualification-report/'
    . '0da2324912a8ffcaa0c167e75a5ecac87911eb3bc44f6d8c2b128d07e869622c';
my $QUALIFICATION_FILE_SET_SHA256 =
    '28ba972c3f8cbcc00d1d32c9db0d4015de57f0df49d11d7076262cd050069095';
my $PAYLOAD_MAX_BYTES = 8_388_608;
my $MANIFEST_MAX_BYTES = 32_768;
my $RESULT_MAX_BYTES = 32_768;
my $PAYLOAD_TOTAL_BYTES = 7_012_284;
my $CORPUS_TOTAL_BYTES = 6_220_126;
my $QUALIFICATION_TOTAL_BYTES = 792_158;
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

my @MANIFEST_KEYS = qw(
    bundle_identity entries explicit_nonclaims limits schema schema_version
    source_seals summary
);
my @ENTRY_KEYS = qw(
    bytes classification destination_relative_path ordinal sha256
    source_relative_path
);
my @NONCLAIMS = qw(
    evidence_recalibration evidence_reinterpretation gate_execution
    provider_execution simulator_execution performance_enforcement
    support_promotion architecture_scale_capacity
);
my %EXPECTED_SUMMARY = (
    corpus_file_count => 13,
    file_count => 15,
    qualification_file_count => 2,
    total_bytes => $PAYLOAD_TOTAL_BYTES,
);
my %EXPECTED_CORPUS_SUMMARY = (
    controller_invocations => 44,
    profile_count => 11,
    raw_measurement_records => 33,
    sample_exclusions => 0,
    validation_records => 11,
);
my %EXPECTED_QUALIFICATION_SUMMARY = (
    %EXPECTED_CORPUS_SUMMARY,
    qualified_profiles => 11,
);
my $EXPECTED_SOURCE_SEALS = {
    corpus => {
        corpus_identity => $CORPUS_IDENTITY,
        file_count => 13,
        file_set_sha256 => $CORPUS_FILE_SET_SHA256,
        publication_identity => $CORPUS_PUBLICATION_IDENTITY,
        total_bytes => $CORPUS_TOTAL_BYTES,
    },
    qualification => {
        file_count => 2,
        file_set_sha256 => $QUALIFICATION_FILE_SET_SHA256,
        publication_identity => $QUALIFICATION_PUBLICATION_IDENTITY,
        qualification_identity => $QUALIFICATION_IDENTITY,
        total_bytes => $QUALIFICATION_TOTAL_BYTES,
    },
};

@ARGV == 0 or die
    "usage: scripts/verify_vial_regression_promotion_evidence_transport.pl\n";

my $result = _verify();
my $encoded = _canonical($result) . "\n";
die "evidence transport verification result exceeds its bounded ceiling\n"
    if bytes::length($encoded) > $RESULT_MAX_BYTES;
print $encoded;

sub _verify {
    my @root_stat = lstat($ROOT);
    die "cannot stat repository root\n"
        unless @root_stat && -d _ && !-l _;
    my $root_device = $root_stat[0];
    my $bundle = _root_path($BUNDLE_RELATIVE);
    _safe_directory_chain($bundle, $root_device);

    my $manifest_path = File::Spec->catfile($bundle, $MANIFEST_RELATIVE);
    my $manifest_bytes = _read_stable(
        $manifest_path,
        $root_device,
        $MANIFEST_MAX_BYTES,
        undef,
        'transport manifest',
    );
    my $manifest = _decode_canonical(
        $manifest_bytes,
        'transport manifest',
    );
    _validate_manifest($manifest);
    _validate_bundle_census($bundle, $root_device, $manifest->{entries});

    my (@files, %documents, %bytes_by_class, %entry_by_class);
    my ($total_bytes, $corpus_files, $qualification_files) = (0, 0, 0);
    for my $entry (@{$manifest->{entries}}) {
        my $path = File::Spec->catfile(
            $bundle,
            split m{/}, $entry->{source_relative_path},
        );
        my $bytes = _read_stable(
            $path,
            $root_device,
            $entry->{bytes},
            $entry->{bytes},
            'evidence payload',
        );
        my $document = _decode_canonical($bytes, 'evidence payload');
        die "evidence payload SHA-256 changed\n"
            unless sha256_hex($bytes) eq $entry->{sha256};
        $documents{$entry->{source_relative_path}} = $document;
        $bytes_by_class{$entry->{classification}} = $bytes
            unless $entry->{classification} eq 'profile_measurement_report';
        $entry_by_class{$entry->{classification}} = $entry
            unless $entry->{classification} eq 'profile_measurement_report';
        $total_bytes += bytes::length($bytes);
        if ($entry->{classification} =~ /\A(?:corpus_|profile_)/) {
            ++$corpus_files;
        }
        else {
            ++$qualification_files;
        }
        push @files, {
            bytes => bytes::length($bytes),
            classification => $entry->{classification},
            destination_relative_path => $entry->{destination_relative_path},
            ordinal => $entry->{ordinal},
            sha256 => sha256_hex($bytes),
            source_relative_path => $entry->{source_relative_path},
        };
    }
    die "evidence payload byte census changed\n"
        unless $total_bytes == $PAYLOAD_TOTAL_BYTES;
    die "evidence payload file census changed\n"
        unless @files == 15 && $corpus_files == 13
            && $qualification_files == 2;

    _validate_source_seals(
        $manifest,
        \%documents,
        \%bytes_by_class,
        \%entry_by_class,
    );

    my $verification = {
        schema =>
            'fsmgen.vial_regression_promotion_gate_evidence_transport_verification.v1',
        schema_version => 1,
        verification_identity => undef,
        bundle_relative_path => $BUNDLE_RELATIVE,
        bundle_identity => $manifest->{bundle_identity},
        manifest => {
            bytes => bytes::length($manifest_bytes),
            sha256 => sha256_hex($manifest_bytes),
        },
        source_seals => _clone($manifest->{source_seals}),
        summary => {
            manifest_file_count => 1,
            payload_file_count => scalar(@files),
            payload_total_bytes => $total_bytes,
            corpus_file_count => $corpus_files,
            qualification_file_count => $qualification_files,
        },
        files => \@files,
        explicit_nonclaims => [qw(
            production_implementation_reuse source_mutation
            generated_coordinate_mutation materialization gate_execution
            provider_execution simulator_execution performance_enforcement
        )],
    };
    $verification->{verification_identity} =
        'regression-promotion-gate-evidence-transport-verification/'
        . sha256_hex(_canonical($verification));
    return $verification;
}

sub _validate_manifest {
    my ($manifest) = @_;
    _exact_keys($manifest, \@MANIFEST_KEYS, 'transport manifest');
    die "transport manifest schema changed\n"
        unless ($manifest->{schema} // '') eq $SCHEMA
            && _integer_equals($manifest->{schema_version}, 1);
    die "transport manifest limits changed\n"
        unless _same(
            $manifest->{limits},
            {
                manifest_max_bytes => $MANIFEST_MAX_BYTES,
                payload_max_bytes => $PAYLOAD_MAX_BYTES,
            },
        );
    die "transport manifest summary changed\n"
        unless _same($manifest->{summary}, \%EXPECTED_SUMMARY);
    die "transport manifest source seals changed\n"
        unless _same($manifest->{source_seals}, $EXPECTED_SOURCE_SEALS);
    die "transport manifest nonclaims changed\n"
        unless _same($manifest->{explicit_nonclaims}, \@NONCLAIMS);

    my $entries = $manifest->{entries};
    die "transport manifest entry count changed\n"
        unless ref($entries) eq 'ARRAY' && @{$entries} == 15;
    my (%sources, %destinations);
    my $total_bytes = 0;
    for my $index (0 .. $#{$entries}) {
        my $entry = $entries->[$index];
        _exact_keys($entry, \@ENTRY_KEYS, 'transport manifest entry');
        my $source = $entry->{source_relative_path};
        my $destination = $entry->{destination_relative_path};
        _safe_relative($source, 'transport source');
        _safe_relative($destination, 'transport destination');
        die "transport source root changed\n"
            unless $source =~ m{\Apayload/(?:regression-promotion-corpus-v1|regression-promotion-budget-qualification-v1)/};
        (my $tail = $source) =~ s{\Apayload/}{};
        die "transport source/destination mapping changed\n"
            unless $destination eq
                ".artifacts/qualification/vial-scale/v2/$tail";
        die "transport manifest contains duplicate paths\n"
            if $sources{$source}++ || $destinations{$destination}++;
        die "transport manifest byte count is invalid\n"
            unless _positive_integer($entry->{bytes})
                && $entry->{bytes} <= $PAYLOAD_MAX_BYTES;
        die "transport manifest digest is invalid\n"
            unless ($entry->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
        _validate_entry_order($entry, $index);
        $total_bytes += $entry->{bytes};
    }
    die "transport manifest aggregate byte count changed\n"
        unless $total_bytes == $PAYLOAD_TOTAL_BYTES
            && $total_bytes <= $PAYLOAD_MAX_BYTES;

    my $identity = $manifest->{bundle_identity};
    my $derived = 'regression-promotion-gate-evidence-transport/'
        . sha256_hex(_canonical({
            entries => $entries,
            schema => $manifest->{schema},
        }));
    die "transport manifest content identity changed\n"
        unless ($identity // '') eq $derived;
    die "transport manifest selected identity changed\n"
        unless $identity eq $BUNDLE_IDENTITY;
}

sub _validate_entry_order {
    my ($entry, $index) = @_;
    my ($expected_class, $expected_ordinal, $pattern);
    if ($index == 0) {
        ($expected_class, $expected_ordinal, $pattern) = (
            'corpus_manifest', undef,
            qr{\Apayload/regression-promotion-corpus-v1/complete/corpus-manifest[.]json\z},
        );
    }
    elsif ($index == 1) {
        ($expected_class, $expected_ordinal, $pattern) = (
            'corpus_report', undef,
            qr{\Apayload/regression-promotion-corpus-v1/complete/regression-promotion-corpus[.]json\z},
        );
    }
    elsif ($index >= 2 && $index <= 12) {
        $expected_ordinal = $index - 1;
        $expected_class = 'profile_measurement_report';
        my $ordinal = sprintf '%02d', $expected_ordinal;
        $pattern = qr{\Apayload/regression-promotion-corpus-v1/profiles/$ordinal-[0-9a-f]{64}/measurement-report[.]json\z};
    }
    elsif ($index == 13) {
        ($expected_class, $expected_ordinal, $pattern) = (
            'qualification_manifest', undef,
            qr{\Apayload/regression-promotion-budget-qualification-v1/current/qualification-manifest[.]json\z},
        );
    }
    else {
        ($expected_class, $expected_ordinal, $pattern) = (
            'qualification_report', undef,
            qr{\Apayload/regression-promotion-budget-qualification-v1/current/regression-promotion-budget-qualification[.]json\z},
        );
    }
    die "transport manifest entry order changed\n"
        unless ($entry->{classification} // '') eq $expected_class
            && ((!defined($expected_ordinal) && !defined($entry->{ordinal}))
                || (defined($expected_ordinal)
                    && _integer_equals($entry->{ordinal}, $expected_ordinal)))
            && ($entry->{source_relative_path} // '') =~ $pattern;
}

sub _validate_bundle_census {
    my ($bundle, $root_device, $entries) = @_;
    my %expected_files = ($MANIFEST_RELATIVE => 1);
    my %expected_directories = ('' => 1);
    for my $entry (@{$entries}) {
        my $relative = $entry->{source_relative_path};
        $expected_files{$relative} = 1;
        my $parent = dirname($relative);
        while ($parent ne '.' && $parent ne '') {
            $expected_directories{$parent} = 1;
            my $next = dirname($parent);
            last if $next eq $parent;
            $parent = $next;
        }
    }

    my (%actual_files, %actual_directories);
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            my @stat = lstat($path);
            die "cannot stat evidence transport path\n" unless @stat;
            die "evidence transport contains a symlink\n" if -l _;
            die "evidence transport path changed device\n"
                unless $stat[0] == $root_device;
            my $relative = File::Spec->abs2rel($path, $bundle);
            $relative = '' if $relative eq '.';
            $relative =~ s{\\}{/}g;
            if (-d _) {
                $actual_directories{$relative} = 1;
                return;
            }
            die "evidence transport contains a non-regular node\n"
                unless -f _;
            die "evidence transport contains an aliased file\n"
                unless $stat[3] == 1;
            $actual_files{$relative} = 1;
        },
    }, $bundle);
    die "evidence transport file census changed\n"
        unless _same([sort keys %actual_files], [sort keys %expected_files]);
    die "evidence transport directory census changed\n"
        unless _same(
            [sort keys %actual_directories],
            [sort keys %expected_directories],
        );
}

sub _validate_source_seals {
    my ($transport, $documents, $bytes_by_class, $entry_by_class) = @_;
    my $corpus_manifest = $documents->{
        $entry_by_class->{corpus_manifest}{source_relative_path}
    };
    my $corpus_report = $documents->{
        $entry_by_class->{corpus_report}{source_relative_path}
    };
    my $qualification_manifest = $documents->{
        $entry_by_class->{qualification_manifest}{source_relative_path}
    };
    my $qualification_report = $documents->{
        $entry_by_class->{qualification_report}{source_relative_path}
    };

    die "corpus manifest seal changed\n"
        unless ($corpus_manifest->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_corpus_manifest.v1'
            && _integer_equals($corpus_manifest->{schema_version}, 1)
            && ($corpus_manifest->{corpus_identity} // '') eq $CORPUS_IDENTITY
            && ($corpus_manifest->{publication_identity} // '') eq
                $CORPUS_PUBLICATION_IDENTITY
            && ($corpus_manifest->{outcome} // '') eq 'accepted'
            && _same($corpus_manifest->{summary}, \%EXPECTED_CORPUS_SUMMARY);
    die "corpus report seal changed\n"
        unless ($corpus_report->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1'
            && _integer_equals($corpus_report->{schema_version}, 1)
            && ($corpus_report->{corpus_identity} // '') eq $CORPUS_IDENTITY
            && _same($corpus_report->{summary}, \%EXPECTED_CORPUS_SUMMARY);
    _require_content_identity(
        $corpus_report,
        'corpus_identity',
        $CORPUS_IDENTITY,
        'regression-promotion-corpus/',
        'corpus',
    );
    _require_content_identity(
        $corpus_manifest,
        'publication_identity',
        $CORPUS_PUBLICATION_IDENTITY,
        'regression-promotion-corpus-publication/',
        'corpus publication',
    );
    die "corpus manifest report binding changed\n"
        unless _same(
            $corpus_manifest->{report_artifact},
            {
                bytes => $entry_by_class->{corpus_report}{bytes},
                relative_path =>
                    $entry_by_class->{corpus_report}{destination_relative_path},
                sha256 => $entry_by_class->{corpus_report}{sha256},
            },
        );
    die "corpus complete file-set identity changed\n"
        unless sha256_hex(join "\0",
            bytes::length($bytes_by_class->{corpus_report}),
            $bytes_by_class->{corpus_report},
            bytes::length($bytes_by_class->{corpus_manifest}),
            $bytes_by_class->{corpus_manifest},
        ) eq $CORPUS_FILE_SET_SHA256;

    my $profiles = $corpus_report->{profiles};
    die "corpus profile seal changed\n"
        unless ref($profiles) eq 'ARRAY' && @{$profiles} == 11;
    my @profile_entries = grep {
        $_->{classification} eq 'profile_measurement_report'
    } @{$transport->{entries}};
    for my $index (0 .. 10) {
        my $profile = $profiles->[$index];
        my $entry = $profile_entries[$index];
        my $document = $documents->{$entry->{source_relative_path}};
        die "profile evidence seal changed\n"
            unless _integer_equals($profile->{ordinal}, $index + 1)
                && _integer_equals($entry->{ordinal}, $index + 1)
                && _integer_equals($document->{profile}{ordinal}, $index + 1)
                && ($document->{schema} // '') eq
                    'fsmgen.vial_architecture_scale_regression_promotion_profile_publication.v1'
                && _integer_equals($document->{schema_version}, 1)
                && ($document->{profile}{selection_key} // '') eq
                    ($profile->{selection_key} // '')
                && ($document->{report}{report_identity} // '') eq
                    ($profile->{report_identity} // '')
                && _same(
                    $profile->{artifact},
                    {
                        atomic => JSON::PP::true,
                        bytes => $entry->{bytes},
                        ordinal => $entry->{ordinal},
                        relative_path => $entry->{destination_relative_path},
                        same_volume => JSON::PP::true,
                        selection_key => $profile->{selection_key},
                        sha256 => $entry->{sha256},
                    },
                );
    }

    my $source_evidence = {
        capture_revision => '155aa22ea3099642eb6b7f5de81ea03633e72bcb',
        corpus_identity => $CORPUS_IDENTITY,
        dirty_state => JSON::PP::false,
        file_set_sha256 => $CORPUS_FILE_SET_SHA256,
        plan_identity =>
            'regression-promotion-capture-plan/'
            . 'fbf697407b0ba326a11a10cbb2d31744f8d28944a0d4d402294cd960dea09737',
        policy_identity =>
            'regression-promotion-policy/'
            . '19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece',
        publication_id => 'regression-promotion-corpus-v1',
        publication_identity => $CORPUS_PUBLICATION_IDENTITY,
        publication_schema =>
            'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1',
    };
    die "qualification manifest seal changed\n"
        unless ($qualification_manifest->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_manifest.v1'
            && _integer_equals($qualification_manifest->{schema_version}, 1)
            && ($qualification_manifest->{publication_identity} // '') eq
                $QUALIFICATION_PUBLICATION_IDENTITY
            && ($qualification_manifest->{qualification_identity} // '') eq
                $QUALIFICATION_IDENTITY
            && ($qualification_manifest->{outcome} // '') eq
                'accepted_published_qualification'
            && _same(
                $qualification_manifest->{source_evidence},
                $source_evidence,
            )
            && _same(
                $qualification_manifest->{summary},
                \%EXPECTED_QUALIFICATION_SUMMARY,
            );
    die "qualification report seal changed\n"
        unless ($qualification_report->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_budget_qualification_publication_report.v1'
            && _integer_equals($qualification_report->{schema_version}, 1)
            && ($qualification_report->{publication_report_identity} // '') eq
                $QUALIFICATION_REPORT_IDENTITY
            && ($qualification_report->{outcome} // '') eq
                'accepted_published_qualification'
            && ($qualification_report->{qualification}{qualification_identity}
                // '') eq $QUALIFICATION_IDENTITY
            && _same(
                $qualification_report->{qualification}{source_evidence},
                $source_evidence,
            )
            && _same(
                $qualification_report->{qualification}{summary},
                \%EXPECTED_QUALIFICATION_SUMMARY,
            );
    _require_content_identity(
        $qualification_report->{qualification},
        'qualification_identity',
        $QUALIFICATION_IDENTITY,
        'regression-promotion-qualification/',
        'qualification',
    );
    _require_content_identity(
        $qualification_report,
        'publication_report_identity',
        $QUALIFICATION_REPORT_IDENTITY,
        'regression-promotion-budget-qualification-report/',
        'qualification report',
    );
    _require_content_identity(
        $qualification_manifest,
        'publication_identity',
        $QUALIFICATION_PUBLICATION_IDENTITY,
        'regression-promotion-budget-qualification-publication/',
        'qualification publication',
    );
    die "qualification manifest report binding changed\n"
        unless _same(
            $qualification_manifest->{report_artifact},
            {
                bytes => $entry_by_class->{qualification_report}{bytes},
                relative_path =>
                    $entry_by_class->{qualification_report}
                        {destination_relative_path},
                sha256 => $entry_by_class->{qualification_report}{sha256},
            },
        );
    die "qualification file-set identity changed\n"
        unless sha256_hex(join "\0",
            bytes::length($bytes_by_class->{qualification_report}),
            $bytes_by_class->{qualification_report},
            bytes::length($bytes_by_class->{qualification_manifest}),
            $bytes_by_class->{qualification_manifest},
        ) eq $QUALIFICATION_FILE_SET_SHA256;

    my $bindings = $qualification_manifest->{profile_bindings};
    my $qualified = $qualification_report->{qualification}{profiles};
    die "qualification profile binding seal changed\n"
        unless ref($bindings) eq 'ARRAY' && @{$bindings} == 11
            && ref($qualified) eq 'ARRAY' && @{$qualified} == 11;
    for my $index (0 .. 10) {
        my $profile = $profiles->[$index];
        for my $binding ($bindings->[$index], $qualified->[$index]) {
            die "qualification profile source binding changed\n"
                unless _integer_equals($binding->{ordinal}, $index + 1)
                    && ($binding->{selection_key} // '') eq
                        ($profile->{selection_key} // '')
                    && ($binding->{source_report_identity} // '') eq
                        ($profile->{report_identity} // '');
        }
    }
}

sub _require_content_identity {
    my ($value, $field, $expected, $prefix, $label) = @_;
    my $projection = _clone($value);
    my $identity = $projection->{$field};
    $projection->{$field} = undef;
    die "$label content identity changed\n"
        unless ($identity // '') eq $expected
            && $identity eq $prefix . sha256_hex(_canonical($projection));
}

sub _read_stable {
    my ($path, $device, $ceiling, $expected, $label) = @_;
    my @before = _safe_file($path, $device, $label);
    die "$label byte count changed\n"
        if defined($expected) && $before[7] != $expected;
    die "$label exceeds its bounded ceiling\n" if $before[7] > $ceiling;
    open my $fh, '<:raw', $path or die "cannot read $label\n";
    my @opened = stat($fh);
    die "$label changed while opening\n"
        unless @opened && _same_stat(\@before, \@opened);
    my $bytes = '';
    while (bytes::length($bytes) <= $ceiling) {
        my $read = read(
            $fh,
            my $chunk,
            $ceiling + 1 - bytes::length($bytes),
        );
        die "cannot read $label\n" unless defined($read);
        last if $read == 0;
        $bytes .= $chunk;
    }
    my @after_read = stat($fh);
    close $fh or die "cannot close $label\n";
    my @after_path = _safe_file($path, $device, $label);
    die "$label changed while reading\n"
        unless @after_read
            && _same_stat(\@before, \@after_read)
            && _same_stat(\@before, \@after_path);
    die "$label byte count changed\n"
        if defined($expected) && bytes::length($bytes) != $expected;
    die "$label exceeds its bounded ceiling\n"
        if bytes::length($bytes) > $ceiling;
    return $bytes;
}

sub _safe_file {
    my ($path, $device, $label) = @_;
    my @stat = lstat($path);
    die "$label is missing\n" unless @stat;
    die "$label is a symlink\n" if -l _;
    die "$label is not a regular file\n" unless -f _;
    die "$label changed device\n" unless $stat[0] == $device;
    die "$label is aliased\n" unless $stat[3] == 1;
    return @stat;
}

sub _safe_directory_chain {
    my ($target, $device) = @_;
    my $current = $ROOT;
    my $relative = File::Spec->abs2rel($target, $ROOT);
    die "evidence bundle escaped the repository root\n"
        if $relative eq '..' || $relative =~ m{\A[.][.][/]};
    for my $part (File::Spec->splitdir($relative)) {
        $current = File::Spec->catdir($current, $part);
        my @stat = lstat($current);
        die "evidence bundle directory is missing\n" unless @stat;
        die "evidence bundle directory is a symlink\n" if -l _;
        die "evidence bundle path is not a directory\n" unless -d _;
        die "evidence bundle directory changed device\n"
            unless $stat[0] == $device;
    }
}

sub _safe_relative {
    my ($relative, $label) = @_;
    die "$label path is unsafe\n"
        if !defined($relative) || ref($relative) || $relative eq ''
            || $relative =~ m{\A/}
            || $relative =~ m{\\}
            || $relative =~ m{(?:\A|/)[.][.]?(?:/|\z)}
            || $relative =~ m{//}
            || $relative !~ m{\A[-A-Za-z0-9_./]+\z};
}

sub _root_path {
    my ($relative) = @_;
    _safe_relative($relative, 'repository-relative');
    return File::Spec->catfile($ROOT, split m{/}, $relative);
}

sub _decode_canonical {
    my ($bytes, $label) = @_;
    my $value = eval { $JSON->decode($bytes) };
    die "$label JSON is invalid\n"
        if $@ || ref($value) ne 'HASH';
    die "$label is not canonical newline JSON\n"
        unless $bytes eq _canonical($value) . "\n";
    return $value;
}

sub _exact_keys {
    my ($value, $keys, $label) = @_;
    die "$label must be a JSON object\n" unless ref($value) eq 'HASH';
    die "$label keys changed\n"
        unless _same([sort keys %{$value}], [sort @{$keys}]);
}

sub _same_stat {
    my ($left, $right) = @_;
    for my $index (0, 1, 2, 3, 4, 7, 9, 10) {
        return 0 unless $left->[$index] == $right->[$index];
    }
    return 1;
}

sub _integer_equals {
    my ($value, $expected) = @_;
    return defined($value) && !ref($value)
        && _canonical($value) eq "$expected";
}

sub _positive_integer {
    my ($value) = @_;
    return defined($value) && !ref($value)
        && _canonical($value) =~ /\A[1-9][0-9]*\z/;
}

sub _clone {
    my ($value) = @_;
    return $JSON->decode(_canonical($value));
}

sub _same {
    my ($left, $right) = @_;
    return _canonical($left) eq _canonical($right);
}

sub _canonical {
    my ($value) = @_;
    return $JSON->encode($value);
}
