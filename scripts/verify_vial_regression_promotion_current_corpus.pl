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
my $ACTIVE_RELATIVE =
    '.artifacts/qualification/vial-scale/v2/'
    . 'regression-promotion-corpus-v1';
my @STAGING_RELATIVES = (
    '.artifacts/tmp/vial-scale/'
        . 'regression-promotion-profile-publication/v1',
    '.artifacts/tmp/vial-scale/'
        . 'regression-promotion-corpus-publication/v1',
);
my $REPORT_RELATIVE = 'complete/regression-promotion-corpus.json';
my $MANIFEST_RELATIVE = 'complete/corpus-manifest.json';
my $CAPTURE_REVISION =
    '155aa22ea3099642eb6b7f5de81ea03633e72bcb';
my $CORPUS_IDENTITY =
    'regression-promotion-corpus/'
    . 'ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505';
my $PUBLICATION_IDENTITY =
    'regression-promotion-corpus-publication/'
    . '865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e';
my $PLAN_IDENTITY =
    'regression-promotion-capture-plan/'
    . 'fbf697407b0ba326a11a10cbb2d31744f8d28944a0d4d402294cd960dea09737';
my $POLICY_IDENTITY =
    'regression-promotion-policy/'
    . '19cf41056da86d95c266597e7db76eff3810ee29511a005e1051053009a65ece';
my $REPORT_SHA256 =
    'd6139d0f122ced6148846909b3dcf54fd2aed65df1b86f98425d265c060f84a1';
my $MANIFEST_SHA256 =
    '3de607e3d3504f7fe49ca092b32b5be7c4f2452ceb9af14559d83aef92990273';
my $FILE_SET_SHA256 =
    'dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f';
my $INVENTORY_SHA256 =
    '94c11e5c81843f412cb8d1af23b7699dbb15b1af19077c1903cab91d8eddbb57';
my $REPORT_BYTES = 23_288;
my $MANIFEST_BYTES = 1_280;
my $TOTAL_BYTES = 6_220_126;
my $MAX_RESULT_BYTES = 65_536;
my @NONCLAIMS = qw(
    producer_execution
    provider_execution
    simulator_execution
    measurement_controller_execution
    profile_capture_or_resume
    performance_budget_promotion
    support_promotion
    architecture_scale_capacity
    historical_artifact_reuse
);
my @CORPUS_KEYS = qw(
    schema schema_version corpus_identity plan_identity policy_identity
    publication_id publication_schema common_identity summary profiles
    explicit_nonclaims
);
my @MANIFEST_KEYS = qw(
    schema schema_version publication_identity corpus_identity plan_identity
    policy_identity publication_id report_artifact summary outcome
    explicit_nonclaims
);
my @CORPUS_PROFILE_KEYS = qw(
    ordinal selection_key report_identity common_identity provider_status
    applicability_status artifact
);
my @ARTIFACT_KEYS = qw(
    ordinal selection_key relative_path sha256 bytes same_volume atomic
);
my @PUBLICATION_KEYS = qw(
    schema schema_version publication_identity plan_identity policy_identity
    publication_id publication_schema profile report
);
my @PROFILE_KEYS = qw(
    ordinal worker_ordinal selection_key coordinates producer_authority
    producer_authority_identity adapter_class adapter_method adapter_arguments
    report_coordinate_authority provider_requirement applicability_requirement
    controller_invocations validation_records raw_measurement_records
    repository_root_binding publication_relative_path
);
my @SUMMARY_KEYS = qw(
    profile_count validation_records raw_measurement_records
    controller_invocations sample_exclusions
);
my @PROVIDER_KEYS = qw(
    kind external_verification_tool logical_name provider_identity
    tool_profile_identity
);
my @APPLICABILITY_KEYS = qw(
    required predicate controller_applicable measurement_applicable
    validation_records raw_measurement_records sample_exclusions outcome
);
my @COORDINATE_KEYS = qw(
    family level primary_axis backend_profile
);
my @REPORT_PREFIX = (
    undef,
    'semantic-bridge-measurement/',
    'semantic-bridge-measurement/',
    'execution-checking-measurement/',
    'execution-checking-measurement/',
    'backend-emission-measurement/',
    'backend-emission-measurement/',
    'backend-emission-measurement/',
    'portable-runtime-measurement/',
    'portable-vhdl-runtime-measurement/',
    'osvvm-runtime-measurement/',
    'balanced-portable-measurement/',
);
my @REPORT_SCHEMA = (
    undef,
    'fsmgen.vial_architecture_scale_semantic_bridge_measurement_set.v1',
    'fsmgen.vial_architecture_scale_semantic_bridge_measurement_set.v1',
    'fsmgen.vial_architecture_scale_execution_checking_measurement_set.v1',
    'fsmgen.vial_architecture_scale_execution_checking_measurement_set.v1',
    'fsmgen.vial_architecture_scale_backend_emission_measurement_set.v1',
    'fsmgen.vial_architecture_scale_backend_emission_measurement_set.v1',
    'fsmgen.vial_architecture_scale_backend_emission_measurement_set.v1',
    'fsmgen.vial_architecture_scale_portable_runtime_measurement_set.v1',
    'fsmgen.vial_architecture_scale_portable_vhdl_runtime_measurement_set.v1',
    'fsmgen.vial_architecture_scale_osvvm_runtime_measurement_set.v1',
    'fsmgen.vial_architecture_scale_balanced_portable_measurement_set.v1',
);
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

@ARGV == 0
    or die "usage: scripts/verify_vial_regression_promotion_current_corpus.pl\n";

my @root_stat = lstat($ROOT);
die "cannot stat repository root\n" unless @root_stat && -d _ && !-l _;
my ($root_device, $root_owner) = @root_stat[0, 4];
my $active = _root_path($ACTIVE_RELATIVE);
_safe_node($active, $root_device, $root_owner, 'directory');

my (%files, %directories);
find({
    no_chdir => 1,
    wanted => sub {
        my $path = $File::Find::name;
        die "current corpus contains a symlink\n" if -l $path;
        my $relative = File::Spec->abs2rel($path, $active);
        $relative = '' if $relative eq '.';
        $relative =~ s{\\}{/}g;
        if (-d _) {
            _safe_node($path, $root_device, $root_owner, 'directory');
            $directories{$relative} = 1;
            return;
        }
        die "current corpus contains a non-regular node\n" unless -f _;
        my @stat = _safe_node(
            $path, $root_device, $root_owner, 'single-link-file',
        );
        $files{$relative} = {path => $path, stat_bytes => $stat[7]};
    },
}, $active);

my $report_entry = $files{$REPORT_RELATIVE};
my $manifest_entry = $files{$MANIFEST_RELATIVE};
die "current corpus complete artifacts are missing\n"
    unless ref($report_entry) eq 'HASH' && ref($manifest_entry) eq 'HASH';
die "current corpus report stat size changed\n"
    unless $report_entry->{stat_bytes} == $REPORT_BYTES;
die "current corpus manifest stat size changed\n"
    unless $manifest_entry->{stat_bytes} == $MANIFEST_BYTES;

my $report_bytes = _read_exact($report_entry->{path}, $REPORT_BYTES);
my $manifest_bytes = _read_exact($manifest_entry->{path}, $MANIFEST_BYTES);
die "current corpus report hash changed\n"
    unless sha256_hex($report_bytes) eq $REPORT_SHA256;
die "current corpus manifest hash changed\n"
    unless sha256_hex($manifest_bytes) eq $MANIFEST_SHA256;
my $report = _decode_canonical($report_bytes, 'current corpus report');
my $manifest = _decode_canonical($manifest_bytes, 'current corpus manifest');

_exact_keys($report, \@CORPUS_KEYS, 'current corpus report');
_exact_keys($manifest, \@MANIFEST_KEYS, 'current corpus manifest');
die "current corpus report schema changed\n"
    unless ($report->{schema} // '') eq
            'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1'
        && _integer_equals($report->{schema_version}, 1)
        && ($report->{publication_id} // '') eq
            'regression-promotion-corpus-v1'
        && ($report->{publication_schema} // '') eq
            'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1';
die "current corpus manifest schema changed\n"
    unless ($manifest->{schema} // '') eq
            'fsmgen.vial_architecture_scale_regression_promotion_corpus_manifest.v1'
        && _integer_equals($manifest->{schema_version}, 1)
        && ($manifest->{publication_id} // '') eq
            'regression-promotion-corpus-v1'
        && ($manifest->{outcome} // '') eq 'accepted';
die "current corpus plan or policy identity changed\n"
    unless ($report->{plan_identity} // '') eq $PLAN_IDENTITY
        && ($manifest->{plan_identity} // '') eq $PLAN_IDENTITY
        && ($report->{policy_identity} // '') eq $POLICY_IDENTITY
        && ($manifest->{policy_identity} // '') eq $POLICY_IDENTITY;
die "current corpus explicit nonclaims changed\n"
    unless _same($report->{explicit_nonclaims}, \@NONCLAIMS)
        && _same($manifest->{explicit_nonclaims}, \@NONCLAIMS);

my $report_identity = $report->{corpus_identity};
my $report_projection = _clone($report);
$report_projection->{corpus_identity} = undef;
die "current corpus identity changed\n"
    unless ($report_identity // '') eq $CORPUS_IDENTITY
        && $report_identity eq 'regression-promotion-corpus/'
            . sha256_hex(_canonical($report_projection));
my $publication_identity = $manifest->{publication_identity};
my $manifest_projection = _clone($manifest);
$manifest_projection->{publication_identity} = undef;
die "current corpus publication identity changed\n"
    unless ($publication_identity // '') eq $PUBLICATION_IDENTITY
        && $publication_identity eq 'regression-promotion-corpus-publication/'
            . sha256_hex(_canonical($manifest_projection));
die "current corpus manifest binding changed\n"
    unless ($manifest->{corpus_identity} // '') eq $report_identity
        && _same($manifest->{summary}, $report->{summary})
        && ref($manifest->{report_artifact}) eq 'HASH'
        && _same(
            [sort keys %{$manifest->{report_artifact}}],
            [sort qw(bytes relative_path sha256)],
        )
        && _integer_equals(
            $manifest->{report_artifact}{bytes}, $REPORT_BYTES,
        )
        && ($manifest->{report_artifact}{relative_path} // '') eq
            "$ACTIVE_RELATIVE/$REPORT_RELATIVE"
        && ($manifest->{report_artifact}{sha256} // '') eq $REPORT_SHA256;
die "current corpus complete file-set identity changed\n"
    unless sha256_hex(join "\0",
        bytes::length($report_bytes), $report_bytes,
        bytes::length($manifest_bytes), $manifest_bytes,
    ) eq $FILE_SET_SHA256;

_exact_keys($report->{summary}, \@SUMMARY_KEYS, 'current corpus summary');
_require_summary($report->{summary});
my $profiles = $report->{profiles};
die "current corpus profile list changed\n"
    unless ref($profiles) eq 'ARRAY' && @{$profiles} == 11;
my $global_common = $report->{common_identity};
die "current corpus common identity changed\n"
    unless ref($global_common) eq 'HASH'
        && ($global_common->{git_revision} // '') eq $CAPTURE_REVISION
        && _false($global_common->{dirty_state})
        && ref($global_common->{host_profile}) eq 'HASH'
        && ref($global_common->{resource_guard}) eq 'HASH'
        && _true($global_common->{resource_guard}{active})
        && ($global_common->{resource_guard}{enforcement} // '') eq
            'repository_ram_guard';

my %expected_files = map { $_ => 1 }
    ($REPORT_RELATIVE, $MANIFEST_RELATIVE);
my %expected_directories = map { $_ => 1 } ('', 'complete', 'profiles');
my (@inventory, @provider_census);
push @inventory, {
    relative_path => $MANIFEST_RELATIVE,
    bytes => $MANIFEST_BYTES,
    sha256 => $MANIFEST_SHA256,
}, {
    relative_path => $REPORT_RELATIVE,
    bytes => $REPORT_BYTES,
    sha256 => $REPORT_SHA256,
};
my ($validations, $measurements, $controllers, $exclusions) = (0, 0, 0, 0);
my %selection_keys;

for my $index (0 .. $#{$profiles}) {
    my $ordinal = $index + 1;
    my $corpus_profile = $profiles->[$index];
    _exact_keys(
        $corpus_profile, \@CORPUS_PROFILE_KEYS,
        "current corpus profile $ordinal",
    );
    die "current corpus profile order changed\n"
        unless _integer_equals($corpus_profile->{ordinal}, $ordinal);
    my $selection_key = $corpus_profile->{selection_key};
    die "current corpus selection key changed\n"
        unless defined($selection_key) && !ref($selection_key)
            && length($selection_key) && !$selection_keys{$selection_key}++;

    my $artifact = $corpus_profile->{artifact};
    _exact_keys(
        $artifact, \@ARTIFACT_KEYS,
        "current corpus profile $ordinal artifact",
    );
    my $token = sha256_hex($selection_key);
    my $relative = sprintf(
        'profiles/%02d-%s/measurement-report.json', $ordinal, $token,
    );
    my $root_relative = "$ACTIVE_RELATIVE/$relative";
    die "current corpus profile artifact coordinate changed\n"
        unless _integer_equals($artifact->{ordinal}, $ordinal)
            && ($artifact->{selection_key} // '') eq $selection_key
            && ($artifact->{relative_path} // '') eq $root_relative
            && _true($artifact->{same_volume})
            && _true($artifact->{atomic})
            && _positive_integer($artifact->{bytes})
            && ($artifact->{sha256} // '') =~ /\A[0-9a-f]{64}\z/;
    my $file_entry = $files{$relative};
    die "current corpus profile file is missing\n"
        unless ref($file_entry) eq 'HASH';
    die "current corpus profile stat size changed\n"
        unless $file_entry->{stat_bytes} == $artifact->{bytes};
    my $bytes = _read_exact($file_entry->{path}, $artifact->{bytes});
    die "current corpus profile file hash changed\n"
        unless sha256_hex($bytes) eq $artifact->{sha256};
    my $publication = _decode_canonical(
        $bytes, "current corpus profile $ordinal publication",
    );
    _exact_keys(
        $publication, \@PUBLICATION_KEYS,
        "current corpus profile $ordinal publication",
    );
    die "current corpus profile publication schema changed\n"
        unless ($publication->{schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_profile_publication.v1'
            && _integer_equals($publication->{schema_version}, 1)
            && ($publication->{plan_identity} // '') eq $PLAN_IDENTITY
            && ($publication->{policy_identity} // '') eq $POLICY_IDENTITY
            && ($publication->{publication_id} // '') eq
                'regression-promotion-corpus-v1'
            && ($publication->{publication_schema} // '') eq
                'fsmgen.vial_architecture_scale_regression_promotion_corpus.v1';
    my $profile_publication_identity = $publication->{publication_identity};
    my $publication_projection = _clone($publication);
    $publication_projection->{publication_identity} = undef;
    die "current corpus profile publication identity changed\n"
        unless defined($profile_publication_identity)
            && !ref($profile_publication_identity)
            && $profile_publication_identity eq
                'regression-promotion-profile-publication/'
                . sha256_hex(_canonical($publication_projection));

    my $profile = $publication->{profile};
    _exact_keys(
        $profile, \@PROFILE_KEYS,
        "current corpus profile $ordinal dispatch",
    );
    die "current corpus profile dispatch binding changed\n"
        unless _integer_equals($profile->{ordinal}, $ordinal)
            && _integer_equals($profile->{worker_ordinal}, $ordinal)
            && ($profile->{selection_key} // '') eq $selection_key
            && ($profile->{publication_relative_path} // '') eq $root_relative
            && ($profile->{repository_root_binding} // '') eq
                'validated_capture_repository_root'
            && _integer_equals($profile->{controller_invocations}, 4)
            && _integer_equals($profile->{validation_records}, 1)
            && _integer_equals($profile->{raw_measurement_records}, 3);

    my $measurement_report = $publication->{report};
    die "current corpus profile report changed type\n"
        unless ref($measurement_report) eq 'HASH';
    die "current corpus profile report schema changed\n"
        unless ($measurement_report->{schema} // '') eq $REPORT_SCHEMA[$ordinal]
            && _integer_equals($measurement_report->{schema_version}, 1)
            && ($measurement_report->{mode} // '') eq 'gate_measurement'
            && ($measurement_report->{outcome} // '') eq 'accepted';
    my $measurement_report_projection = _clone($measurement_report);
    my $measurement_report_identity =
        delete $measurement_report_projection->{report_identity};
    die "current corpus profile report identity changed\n"
        unless defined($measurement_report_identity)
            && !ref($measurement_report_identity)
            && $measurement_report_identity eq
                $REPORT_PREFIX[$ordinal]
                . sha256_hex(_canonical($measurement_report_projection))
            && $measurement_report_identity eq
                ($corpus_profile->{report_identity} // '');
    _require_report_coordinates(
        $measurement_report, $profile->{report_coordinate_authority},
        $ordinal,
    );

    my @records = (
        $measurement_report->{validation_record},
        @{ $measurement_report->{measurement_records} // [] },
    );
    die "current corpus profile controller record count changed\n"
        unless ref($measurement_report->{measurement_records}) eq 'ARRAY'
            && @{$measurement_report->{measurement_records}} == 3
            && @records == 4;
    die "current corpus profile diagnostics or exclusions changed\n"
        unless ref($measurement_report->{diagnostics}) eq 'ARRAY'
            && !@{$measurement_report->{diagnostics}}
            && ref($measurement_report->{sample_exclusions}) eq 'ARRAY'
            && !@{$measurement_report->{sample_exclusions}};
    _require_report_cleanup($measurement_report->{cleanup}, scalar @records);

    my $common;
    for my $record_index (0 .. $#records) {
        my $record = $records[$record_index];
        my $expected_class = $record_index
            ? 'gate_measurement' : 'validation';
        die "current corpus profile controller record changed\n"
            unless ref($record) eq 'HASH'
                && ($record->{schema} // '') eq
                    'fsmgen.vial_architecture_scale_measurement.v1'
                && _integer_equals($record->{schema_version}, 1)
                && ($record->{run_class} // '') eq $expected_class
                && _integer_equals($record->{run_ordinal}, $record_index)
                && ($record->{outcome} // '') eq 'accepted'
                && !defined($record->{diagnostic})
                && ($record->{git_revision} // '') eq $CAPTURE_REVISION
                && _false($record->{dirty_state});
        die "current corpus profile correctness oracle closure changed\n"
            unless ref($record->{correctness_oracles}) eq 'ARRAY'
                && @{$record->{correctness_oracles}}
                && !grep {
                    ref($_) ne 'HASH' || !_true($_->{ok})
                } @{$record->{correctness_oracles}};
        _require_record_cleanup($record->{cleanup});
        die "current corpus profile record nonclaims changed\n"
            unless ref($record->{explicit_nonclaims}) eq 'ARRAY'
                && @{$record->{explicit_nonclaims}}
                && grep { $_ eq 'architecture_scale_capacity' }
                    @{$record->{explicit_nonclaims}};
        my $record_common = {
            git_revision => $record->{git_revision},
            dirty_state => _clone($record->{dirty_state}),
            host_profile => _clone($record->{host_profile}),
            tool_profile => _clone($record->{tool_profile}),
            resource_guard => _clone($record->{resource_guard}),
        };
        $common //= $record_common;
        die "current corpus profile mixed common identities\n"
            unless _same($common, $record_common);
    }
    die "current corpus profile common identity changed\n"
        unless _same($common, $corpus_profile->{common_identity});
    my $projected_global = _clone($common);
    delete $projected_global->{tool_profile};
    die "current corpus global common identity changed\n"
        unless _same($projected_global, $global_common);

    _require_provider(
        $profile->{provider_requirement}, $measurement_report, $common,
        $ordinal,
    );
    die "current corpus profile provider projection changed\n"
        unless _same(
            $profile->{provider_requirement},
            $corpus_profile->{provider_status},
        );
    _require_applicability(
        $profile->{applicability_requirement}, $measurement_report,
        $corpus_profile->{applicability_status},
    );

    $validations++;
    $measurements += 3;
    $controllers += 4;
    $exclusions += scalar @{$measurement_report->{sample_exclusions}};
    $expected_files{$relative} = 1;
    $expected_directories{dirname($relative)} = 1;
    push @inventory, {
        relative_path => $relative,
        bytes => 0 + $artifact->{bytes},
        sha256 => $artifact->{sha256},
    };
    push @provider_census, {
        ordinal => $ordinal,
        kind => $profile->{provider_requirement}{kind},
        logical_name => $profile->{provider_requirement}{logical_name},
        provider_identity => $profile->{provider_requirement}{provider_identity},
        tool_profile_identity =>
            $profile->{provider_requirement}{tool_profile_identity},
    };
}

die "current corpus aggregate record census changed\n"
    unless $validations == 11 && $measurements == 33
        && $controllers == 44 && $exclusions == 0;
die "current corpus namespace file census changed\n"
    unless _same([sort keys %files], [sort keys %expected_files]);
die "current corpus namespace directory census changed\n"
    unless _same([sort keys %directories], [sort keys %expected_directories]);

@inventory = sort {
    $a->{relative_path} cmp $b->{relative_path}
} @inventory;
die "current corpus file count changed\n" unless @inventory == 13;
my $total_bytes = 0;
$total_bytes += $_->{bytes} for @inventory;
die "current corpus total byte census changed\n"
    unless $total_bytes == $TOTAL_BYTES;
my $inventory_sha256 = sha256_hex(_canonical(\@inventory));
die "current corpus inventory identity changed\n"
    unless $inventory_sha256 eq $INVENTORY_SHA256;

for my $staging_relative (@STAGING_RELATIVES) {
    my $staging = _root_path($staging_relative);
    next unless -e $staging || -l $staging;
    _safe_node($staging, $root_device, $root_owner, 'directory');
    opendir my $staging_fh, $staging
        or die "cannot inspect current corpus staging\n";
    my @residue = grep { $_ ne '.' && $_ ne '..' } readdir $staging_fh;
    closedir $staging_fh
        or die "cannot close current corpus staging\n";
    die "current corpus staging residue remains\n" if @residue;
}

my $result = {
    schema =>
        'fsmgen.vial_architecture_scale_regression_promotion_current_corpus_verification.v1',
    schema_version => 1,
    active_relative_path => $ACTIVE_RELATIVE,
    corpus_identity => $report_identity,
    publication_identity => $publication_identity,
    plan_identity => $PLAN_IDENTITY,
    policy_identity => $POLICY_IDENTITY,
    capture_revision => $CAPTURE_REVISION,
    file_set_sha256 => $FILE_SET_SHA256,
    inventory_sha256 => $inventory_sha256,
    summary => {
        profile_count => scalar(@{$profiles}),
        file_count => scalar(@inventory),
        total_bytes => $total_bytes,
        report_bytes => bytes::length($report_bytes),
        manifest_bytes => bytes::length($manifest_bytes),
        validation_records => $validations,
        raw_measurement_records => $measurements,
        controller_invocations => $controllers,
        sample_exclusions => $exclusions,
    },
    common_identity => _clone($global_common),
    providers => \@provider_census,
    files => \@inventory,
    explicit_nonclaims => [@NONCLAIMS],
};
my $encoded = _canonical($result) . "\n";
die "current corpus verification result exceeds its bounded ceiling\n"
    if bytes::length($encoded) > $MAX_RESULT_BYTES;
print $encoded;

sub _require_summary {
    my ($summary) = @_;
    die "current corpus summary changed\n"
        unless _integer_equals($summary->{profile_count}, 11)
            && _integer_equals($summary->{validation_records}, 11)
            && _integer_equals($summary->{raw_measurement_records}, 33)
            && _integer_equals($summary->{controller_invocations}, 44)
            && _integer_equals($summary->{sample_exclusions}, 0);
}

sub _require_report_coordinates {
    my ($report, $authority, $ordinal) = @_;
    die "current corpus profile report-coordinate authority changed\n"
        unless ref($authority) eq 'HASH'
            && ($authority->{authority_identity} // '') =~
                /\Areport-coordinate-authority\/[0-9a-f]{64}\z/;
    my $coordinates = {
        family => $authority->{family},
        level => $authority->{level},
        primary_axis => $authority->{primary_axis},
        backend_profile => $authority->{backend_profile},
    };
    _exact_keys(
        $coordinates, \@COORDINATE_KEYS,
        "current corpus profile $ordinal report coordinates",
    );
    my $observed = {
        family => $report->{family},
        level => $report->{level},
        primary_axis => $report->{primary_axis},
        backend_profile => $report->{backend_profile},
    };
    die "current corpus profile report coordinates changed\n"
        unless _same($observed, $coordinates);
}

sub _require_report_cleanup {
    my ($cleanup, $records) = @_;
    die "current corpus profile report cleanup changed\n"
        unless ref($cleanup) eq 'HASH'
            && _same(
                [sort keys %{$cleanup}],
                [sort qw(ephemeral_removed records_total residue)],
            )
            && _true($cleanup->{ephemeral_removed})
            && _integer_equals($cleanup->{records_total}, $records)
            && ref($cleanup->{residue}) eq 'ARRAY'
            && !@{$cleanup->{residue}};
}

sub _require_record_cleanup {
    my ($cleanup) = @_;
    die "current corpus profile record cleanup changed\n"
        unless ref($cleanup) eq 'HASH'
            && _true($cleanup->{ephemeral_removed})
            && ref($cleanup->{residue}) eq 'ARRAY'
            && !@{$cleanup->{residue}}
            && defined($cleanup->{staging_identity})
            && !ref($cleanup->{staging_identity})
            && $cleanup->{staging_identity} =~
                m{\A[.]artifacts/tmp/vial-scale/[0-9a-f]{64}/(?:validation/00|gate_measurement/0[1-3])\z};
}

sub _require_provider {
    my ($required, $report, $common, $ordinal) = @_;
    _exact_keys(
        $required, \@PROVIDER_KEYS,
        "current corpus profile $ordinal provider",
    );
    my $kind = $required->{kind} // '';
    if ($kind eq 'exact_tool_profile') {
        my $tool = $report->{tool_profile};
        die "current corpus exact provider changed\n"
            unless ref($tool) eq 'HASH'
                && _true($required->{external_verification_tool})
                && _true($tool->{external_verification_tool})
                && ($tool->{logical_name} // '') eq
                    ($required->{logical_name} // '')
                && ($tool->{provider_identity} // '') eq
                    ($required->{provider_identity} // '')
                && 'tool-profile/' . sha256_hex(_canonical($tool)) eq
                    ($required->{tool_profile_identity} // '')
                && _same($tool, $common->{tool_profile});
        return;
    }
    if ($kind eq 'repository_materialization') {
        my $authority = $report->{profile_authority};
        my $verification = $report->{provider_verification};
        die "current corpus repository provider changed\n"
            unless _false($required->{external_verification_tool})
                && _false(
                    $common->{tool_profile}{external_verification_tool},
                )
                && ref($authority) eq 'HASH'
                && ref($authority->{structural_authority}) eq 'HASH'
                && ($authority->{structural_authority}
                    {provider_materialization} // '') eq
                    ($required->{provider_identity} // '')
                && ref($verification) eq 'HASH'
                && _true($verification->{applicable})
                && _true($verification->{included_in_emit})
                && _true($verification->{read_only})
                && _false($verification->{external_verification_tool})
                && ($verification->{classification} // '') eq
                    'sealed_osvvm_2026_05_provider_materialization';
        return;
    }
    if ($kind eq 'not_applicable') {
        die "current corpus inapplicable provider changed\n"
            unless _false($required->{external_verification_tool})
                && !defined($required->{logical_name})
                && !defined($required->{provider_identity})
                && !defined($required->{tool_profile_identity})
                && _false(
                    $common->{tool_profile}{external_verification_tool},
                );
        return unless exists $report->{provider_verification};
        my $verification = $report->{provider_verification};
        die "current corpus inapplicable provider status changed\n"
            unless ref($verification) eq 'HASH'
                && _false($verification->{applicable})
                && _false($verification->{included_in_emit})
                && _false($verification->{read_only})
                && _false($verification->{external_verification_tool})
                && ($verification->{classification} // '') eq
                    'not_applicable';
        return;
    }
    die "current corpus provider kind changed\n";
}

sub _require_applicability {
    my ($required, $report, $projected) = @_;
    die "current corpus applicability requirement changed\n"
        unless ref($required) eq 'HASH'
            && _true($required->{required})
            && defined($required->{predicate})
            && !ref($required->{predicate})
            && length($required->{predicate});
    my $measurement = $report->{measurement_applicability};
    die "current corpus measurement applicability changed\n"
        unless ref($measurement) eq 'HASH'
            && _true($measurement->{applicable})
            && !defined($measurement->{reason});
    my $controller = $report->{controller_applicability};
    die "current corpus controller applicability changed\n"
        if defined($controller)
            && (ref($controller) ne 'HASH'
                || !_true($controller->{applicable})
                || defined($controller->{reason}));
    my $expected = {
        required => JSON::PP::true,
        predicate => $required->{predicate},
        controller_applicable => JSON::PP::true,
        measurement_applicable => JSON::PP::true,
        validation_records => 1,
        raw_measurement_records => 3,
        sample_exclusions => 0,
        outcome => 'accepted',
    };
    _exact_keys(
        $projected, \@APPLICABILITY_KEYS,
        'current corpus projected applicability',
    );
    die "current corpus applicability projection changed\n"
        unless _same($projected, $expected);
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

sub _read_exact {
    my ($path, $expected) = @_;
    open my $fh, '<:raw', $path or die "cannot read current corpus file\n";
    my $bytes = '';
    while (bytes::length($bytes) <= $expected) {
        my $read = read($fh, my $chunk, $expected + 1 - bytes::length($bytes));
        die "cannot read current corpus file\n" unless defined($read);
        last if $read == 0;
        $bytes .= $chunk;
    }
    close $fh or die "cannot close current corpus file\n";
    die "current corpus file byte count changed\n"
        unless bytes::length($bytes) == $expected;
    return $bytes;
}

sub _root_path {
    my ($relative) = @_;
    die "repository-relative path is unsafe\n"
        if !defined($relative) || ref($relative)
            || $relative =~ m{(?:\A|/)[.][.](?:/|\z)};
    return File::Spec->catfile($ROOT, split m{/}, $relative);
}

sub _safe_node {
    my ($path, $device, $owner, $shape) = @_;
    my @stat = lstat($path);
    die "current corpus path is missing\n" unless @stat;
    die "current corpus path is a symlink\n" if -l _;
    die "current corpus path changed device or owner\n"
        unless $stat[0] == $device && $stat[4] == $owner;
    die "current corpus directory shape changed\n"
        if $shape eq 'directory' && !-d _;
    die "current corpus file shape changed\n"
        if $shape eq 'single-link-file' && (!-f _ || $stat[3] != 1);
    return @stat;
}

sub _exact_keys {
    my ($value, $keys, $label) = @_;
    die "$label must be a JSON object\n" unless ref($value) eq 'HASH';
    die "$label keys changed\n"
        unless _same([sort keys %{$value}], [sort @{$keys}]);
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

sub _true {
    my ($value) = @_;
    return defined($value) && ref($value) eq 'JSON::PP::Boolean'
        && _canonical($value) eq 'true';
}

sub _false {
    my ($value) = @_;
    return defined($value) && ref($value) eq 'JSON::PP::Boolean'
        && _canonical($value) eq 'false';
}

sub _same {
    my ($left, $right) = @_;
    return _canonical($left) eq _canonical($right);
}

sub _canonical {
    my ($value) = @_;
    return $JSON->encode($value);
}

sub _clone {
    my ($value) = @_;
    return $JSON->decode(_canonical($value));
}
