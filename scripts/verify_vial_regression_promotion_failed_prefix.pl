#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Find qw(find);
use File::Spec;
use FindBin;
use JSON::PP ();

my $ROOT = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $CAPTURE_REVISION =
    '610ed7869642ee57f9df608204cfbad3a0b187e4';
my $ARCHIVED_BY_REVISION =
    'f58a050fd95ad4ba90b2b3afc598227547dbb717';
my $ARCHIVE_NAME =
    'regression-promotion-report-coordinate-failure-ordinal-5-v1';
my $ARCHIVE_RELATIVE =
    '.artifacts/qualification/vial-scale/history/'
    . $CAPTURE_REVISION . '/' . $ARCHIVE_NAME;
my $ACTIVE_RELATIVE =
    '.artifacts/qualification/vial-scale/v2/'
    . 'regression-promotion-corpus-v1';
my $EXPECTED_ARCHIVE_IDENTITY =
    'regression-promotion-failed-prefix/'
    . 'f46939aab1731f2b2a136a0d06cf161d4ff6ec99b2336559227a668c8b86e5a4';
my $EXPECTED_MANIFEST_SHA256 =
    '06cb98730ad4168cda68fd7864939c499a86766b8a6c0d13216fcc04819d2223';
my $EXPECTED_PROFILES_SHA256 =
    '286a4948fec76e6f126de2fdaef7af09d0c6665e854ce9e57756042706860f6d';
my $EXPECTED_FILES_SHA256 =
    'ffb9197d464eea035ee8332f24e6cd869b4e9305f44b5001513cc225e5d91654';
my $EXPECTED_REPORT_BYTES = 600_036;
my $EXPECTED_MANIFEST_BYTES = 4_503;
my $EXPECTED_TOTAL_BYTES = 604_539;
my $JSON = JSON::PP->new->canonical(1)->utf8(1);

@ARGV == 0 or die "usage: scripts/verify_vial_regression_promotion_failed_prefix.pl\n";
my $archive = _root_path($ARCHIVE_RELATIVE);
my $active = _root_path($ACTIVE_RELATIVE);
die "active regression-promotion v2 namespace is not empty\n"
    if -e $active || -l $active;
die "failed-prefix archive is unavailable\n"
    unless -d $archive && !-l $archive;

my @root_stat = stat($ROOT);
die "cannot stat repository root\n" unless @root_stat;
my ($root_device, $owner) = @root_stat[0, 4];
_safe_path($archive, $root_device, $owner, 0);

my $parent = File::Spec->catdir(
    $ROOT, split m{/},
    '.artifacts/qualification/vial-scale/history/' . $CAPTURE_REVISION,
);
opendir my $parent_fh, $parent or die "cannot inspect archive parent\n";
my @staging = grep {
    /^\Q.$ARCHIVE_NAME\E[.]stage-/
} readdir $parent_fh;
closedir $parent_fh or die "cannot close archive parent\n";
die "failed-prefix archive staging residue remains\n" if @staging;

my @files;
find({
    no_chdir => 1,
    wanted => sub {
        my $path = $File::Find::name;
        die "failed-prefix archive contains a symlink\n" if -l $path;
        return unless -f _;
        _safe_path($path, $root_device, $owner, 1);
        my $bytes = _read_raw($path);
        my $relative = File::Spec->abs2rel($path, $archive);
        $relative =~ s{\\}{/}g;
        push @files, {
            relative_path => $relative,
            bytes => bytes::length($bytes),
            sha256 => sha256_hex($bytes),
        };
    },
}, $archive);
@files = sort { $a->{relative_path} cmp $b->{relative_path} } @files;
die "failed-prefix archive file count changed\n" unless @files == 5;
die "failed-prefix archive file identity changed\n"
    unless sha256_hex($JSON->encode(\@files)) eq $EXPECTED_FILES_SHA256;

my $manifest_path = File::Spec->catfile($archive, 'manifest.json');
my $manifest_bytes = _read_raw($manifest_path);
die "failed-prefix manifest byte count changed\n"
    unless bytes::length($manifest_bytes) == $EXPECTED_MANIFEST_BYTES;
die "failed-prefix manifest hash changed\n"
    unless sha256_hex($manifest_bytes) eq $EXPECTED_MANIFEST_SHA256;
my $manifest = eval { $JSON->decode($manifest_bytes) };
die "failed-prefix manifest JSON is invalid\n"
    if $@ || ref($manifest) ne 'HASH';
die "failed-prefix manifest is not canonical newline JSON\n"
    unless $manifest_bytes eq $JSON->encode($manifest) . "\n";
die "failed-prefix manifest schema changed\n"
    unless ($manifest->{schema} // '') eq
            'fsmgen.vial_architecture_scale_regression_promotion_failed_prefix_archive.v1'
        && _integer_equals($manifest->{schema_version}, 1);
die "failed-prefix revision binding changed\n"
    unless ($manifest->{capture_revision} // '') eq $CAPTURE_REVISION
        && ($manifest->{archived_by_revision} // '') eq
            $ARCHIVED_BY_REVISION
        && !defined($manifest->{superseding_revision});
my $archive_identity = $manifest->{archive_identity};
$manifest->{archive_identity} = undef;
die "failed-prefix archive identity changed\n"
    unless ($archive_identity // '') eq $EXPECTED_ARCHIVE_IDENTITY
        && $archive_identity eq 'regression-promotion-failed-prefix/'
            . sha256_hex($JSON->encode($manifest));
$manifest->{archive_identity} = $archive_identity;

my $failure = $manifest->{failure_observation};
die "failed-prefix failure observation changed\n"
    unless ref($failure) eq 'HASH'
        && _integer_equals($failure->{exit_code}, 70)
        && _integer_equals($failure->{failed_profile_ordinal}, 5)
        && ($failure->{diagnostic} // '') eq
            "profile capture report coordinate 'primary_axis' appeared"
        && ($failure->{report_coordinate} // '') eq 'primary_axis'
        && ($failure->{observed_report_value} // '') eq 'artifact_graph'
        && !defined($failure->{selected_coordinate_value})
        && $failure->{failed_profile_publication_absent}
        && $failure->{corpus_report_absent}
        && $failure->{corpus_manifest_absent}
        && $failure->{staging_residue_absent};

my $profiles = $manifest->{profiles};
die "failed-prefix profile inventory changed\n"
    unless ref($profiles) eq 'ARRAY' && @{$profiles} == 4
        && ($manifest->{profiles_canonical_json_sha256} // '') eq
            $EXPECTED_PROFILES_SHA256
        && sha256_hex($JSON->encode($profiles)) eq
            $EXPECTED_PROFILES_SHA256;
my $report_bytes = 0;
for my $index (0 .. $#{$profiles}) {
    my $entry = $profiles->[$index];
    die "failed-prefix profile order changed\n"
        unless ref($entry) eq 'HASH'
            && _integer_equals($entry->{ordinal}, $index + 1);
    my $path = File::Spec->catfile(
        $archive, split m{/}, $entry->{relative_path},
    );
    _safe_path($path, $root_device, $owner, 1);
    my $bytes = _read_raw($path);
    die "failed-prefix report content changed\n"
        unless bytes::length($bytes) == $entry->{bytes}
            && sha256_hex($bytes) eq $entry->{sha256};
    my $publication = eval { $JSON->decode($bytes) };
    die "failed-prefix report JSON is invalid\n"
        if $@ || ref($publication) ne 'HASH';
    die "failed-prefix report is not canonical newline JSON\n"
        unless $bytes eq $JSON->encode($publication) . "\n";
    die "failed-prefix publication identity changed\n"
        unless _integer_equals(
                $publication->{profile}{ordinal}, $entry->{ordinal},
            )
            && ($publication->{profile}{selection_key} // '') eq
                ($entry->{selection_key} // '')
            && $JSON->encode($publication->{profile}{coordinates}) eq
                $JSON->encode($entry->{coordinates})
            && ($publication->{report}{report_identity} // '') eq
                ($entry->{report_identity} // '')
            && ($publication->{publication_identity} // '') eq
                ($entry->{publication_identity} // '')
            && ($publication->{plan_identity} // '') eq
                ($manifest->{plan_identity} // '')
            && ($publication->{policy_identity} // '') eq
                ($manifest->{policy_identity} // '');
    my @records = (
        $publication->{report}{validation_record},
        @{$publication->{report}{measurement_records} // []},
    );
    die "failed-prefix controller record count changed\n"
        unless @records == 4;
    for my $record_index (0 .. $#records) {
        my $record = $records[$record_index];
        die "failed-prefix controller record changed\n"
            unless ref($record) eq 'HASH'
                && ($record->{git_revision} // '') eq $CAPTURE_REVISION
                && !$record->{dirty_state}
                && ($record->{outcome} // '') eq 'accepted'
                && ($record->{run_class} // '') eq
                    ($record_index ? 'gate_measurement' : 'validation')
                && _integer_equals($record->{run_ordinal}, $record_index);
    }
    $report_bytes += bytes::length($bytes);
}
die "failed-prefix report census changed\n"
    unless $report_bytes == $EXPECTED_REPORT_BYTES
        && _integer_equals($manifest->{report_bytes}, $report_bytes)
        && _integer_equals($manifest->{report_count}, 4)
        && _integer_equals($manifest->{profile_count}, 4);
my $total_bytes = 0;
$total_bytes += $_->{bytes} for @files;
die "failed-prefix total byte census changed\n"
    unless $total_bytes == $EXPECTED_TOTAL_BYTES;

print $JSON->encode({
    schema =>
        'fsmgen.vial_architecture_scale_regression_promotion_failed_prefix_verification.v1',
    schema_version => 1,
    archive_relative_path => $ARCHIVE_RELATIVE,
    archive_identity => $archive_identity,
    file_count => scalar(@files),
    total_bytes => $total_bytes,
    report_count => scalar(@{$profiles}),
    report_bytes => $report_bytes,
    manifest_bytes => bytes::length($manifest_bytes),
    manifest_sha256 => $EXPECTED_MANIFEST_SHA256,
    profiles_canonical_json_sha256 => $EXPECTED_PROFILES_SHA256,
    archive_files_canonical_json_sha256 => $EXPECTED_FILES_SHA256,
    active_namespace => 'absent',
    archive_staging_count => scalar(@staging),
}), "\n";

sub _root_path {
    my ($relative) = @_;
    die "repository-relative path is unsafe\n"
        if !defined($relative) || $relative =~ m{(?:\A|/)[.][.](?:/|\z)};
    return File::Spec->catfile($ROOT, split m{/}, $relative);
}

sub _safe_path {
    my ($path, $device, $expected_owner, $require_file) = @_;
    my @stat = lstat($path);
    die "archive path is missing\n" unless @stat;
    die "archive path is a symlink\n" if -l _;
    die "archive path changed device or owner\n"
        unless $stat[0] == $device && $stat[4] == $expected_owner;
    die "archive file shape changed\n"
        if $require_file && (!-f _ || $stat[3] != 1);
    return 1;
}

sub _read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read archive path\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close archive path\n";
    return $bytes;
}

sub _integer_equals {
    my ($value, $expected) = @_;
    return defined($value) && !ref($value)
        && $value =~ /\A(?:0|[1-9][0-9]*)\z/
        && 0 + $value == $expected;
}
