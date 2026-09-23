#!/usr/bin/env perl

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix;
use FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix;

my $repo_root = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::Bin, '..'),
);
my $fixture_root = File::Spec->catdir(
    $repo_root, '.artifacts', 'tmp',
    "vial-legacy-matrix-publication-bounds-$$",
);
my $publication_base = join '/', qw(
    .artifacts qualification vial-scale v1
);
my $staging_base = join '/', qw(
    .artifacts tmp vial-scale matrix-publication
);
my $json = JSON::PP->new->canonical(1)->utf8(1);
my $sequence = 0;

my @publishers = (
    {
        name => 'semantic/bridge',
        class =>
            'FSM::VIAL::ArchitectureScaleSemanticBridgeMeasurementMatrix',
        revision => 'semantic_bridge_matrix_v1',
        maximum => 524_288,
        filename => 'measurement-set.json',
    },
    {
        name => 'execution/checking',
        class =>
            'FSM::VIAL::ArchitectureScaleExecutionCheckingMeasurementMatrix',
        revision => 'execution_checking_matrix_v1',
        maximum => 1_048_576,
        filename => 'measurement-publication.json',
    },
);

die "legacy publication fixture root already exists\n"
    if -e $fixture_root || -l $fixture_root;
make_path($fixture_root, {mode => 0700});

END {
    remove_tree($fixture_root)
        if defined($fixture_root) && -d($fixture_root)
            && !-l($fixture_root);
}

subtest 'immutable revision-1 census independently supports containment ceilings' => sub {
    plan skip_all => 'ignored revision-1 publication is absent on a fresh checkout'
        unless -d repo_path($repo_root, $publication_base);
    my $census = immutable_publication_census();
    is_deeply($census->{semantic_bridge}, {
        count => 111,
        total_bytes => 7_418_437,
        maximum_bytes => 253_882,
        maximum_path => join('/',
            $publication_base,
            'semantic-catalog-v1.actions.qualification-candidate-v1',
            'measurement-set.json',
        ),
        canonical_files => 111,
        exact_directories => 111,
        regular_files => 111,
        one_link_files => 111,
        same_volume_files => 111,
        admitted_files => 111,
    }, 'all semantic/bridge files retain the independently derived census');
    is_deeply($census->{execution_checking}, {
        count => 75,
        total_bytes => 7_312_415,
        maximum_bytes => 759_867,
        maximum_path => join('/',
            $publication_base,
            'checking-state-v1.coverpoints.qualification-candidate-v1',
            'measurement-publication.json',
        ),
        canonical_files => 75,
        exact_directories => 75,
        regular_files => 75,
        one_link_files => 75,
        same_volume_files => 75,
        admitted_files => 75,
    }, 'all execution/checking files retain the independently derived census');
};

for my $publisher (@publishers) {
    subtest "$publisher->{name} publication bytes and topology fail closed" => sub {
        exercise_publisher($publisher);
    };
}

done_testing;

sub exercise_publisher {
    my ($publisher) = @_;
    my $class = $publisher->{class};
    my $maximum = $publisher->{maximum};
    my $publish = $class->can('_publish_json');
    my $read = $class->can('_read_json_publication');
    my $read_directory = $class->can('_read_exact_publication_directory');
    my $read_file = $class->can('_read_exact_publication_file');

    my $limits = $class->publication_limits;
    is($limits->{publication_revision}, $publisher->{revision},
        'the public limit names one legacy publication revision');
    is($limits->{maximum_publication_bytes}, $maximum,
        'the public storage ceiling is exact');

    my ($cap_repo, $cap_device) = fresh_repository('exact-cap');
    my $cap_value = exact_sized_value($maximum);
    is(bytes::length($json->encode($cap_value) . "\n"), $maximum,
        'the boundary fixture is exactly the selected byte ceiling');
    my $cap_id = safe_id('exact-cap');
    my $published = $publish->({
        repository_root => $cap_repo,
        root_device => $cap_device,
        profile_id => $cap_id,
        filename => $publisher->{filename},
        value => $cap_value,
    });
    is($published->{bytes}, $maximum,
        'an exact-cap canonical publication is written');
    my ($reloaded, $metadata) = $read->({
        repository_root => $cap_repo,
        root_device => $cap_device,
        profile_id => $cap_id,
        filename => $publisher->{filename},
    });
    is($metadata->{bytes}, $maximum,
        'an exact-cap canonical publication is read through the bound');
    is_deeply($reloaded, $cap_value,
        'exact-cap reload returns the canonical value');

    my ($write_repo, $write_device) = fresh_repository('cap-plus-one-write');
    my $write_id = safe_id('cap-plus-one-write');
    like(dies(sub {
        $publish->({
            repository_root => $write_repo,
            root_device => $write_device,
            profile_id => $write_id,
            filename => $publisher->{filename},
            value => exact_sized_value($maximum + 1),
        });
    }), qr/exceeds its calibrated ceiling/,
        'cap-plus-one canonical bytes reject before staging');
    ok(!-e repo_path($write_repo, $staging_base),
        'rejected writer bytes create no staging hierarchy');

    my ($read_repo, $read_device) = fresh_repository('cap-plus-one-read');
    my $read_id = safe_id('cap-plus-one-read');
    write_publication($read_repo, $read_id, $publisher->{filename},
        'x' x ($maximum + 1));
    like(dies(sub {
        $read->({
            repository_root => $read_repo,
            root_device => $read_device,
            profile_id => $read_id,
            filename => $publisher->{filename},
        });
    }), qr/exceeds its calibrated ceiling/,
        'cap-plus-one existing bytes reject from stat before content use');

    my ($stage_repo, $stage_device) = fresh_repository('cap-plus-one-stage');
    my $stage_id = safe_id('cap-plus-one-stage');
    my $stage_value = {generation => 1};
    my $stage_bytes = $json->encode($stage_value) . "\n";
    my $stage = repo_path($stage_repo, join('/',
        $staging_base, "$stage_id-" . sha256_hex($stage_bytes),
    ));
    make_path($stage, {mode => 0700});
    write_raw(File::Spec->catfile($stage, $publisher->{filename}),
        'x' x ($maximum + 1));
    like(dies(sub {
        $publish->({
            repository_root => $stage_repo,
            root_device => $stage_device,
            profile_id => $stage_id,
            filename => $publisher->{filename},
            value => $stage_value,
        });
    }), qr/staging is not recoverable/,
        'cap-plus-one recovery bytes reject through the bounded reader');

    my ($malformed_repo, $malformed_device) =
        fresh_repository('malformed');
    my $malformed_id = safe_id('malformed');
    write_publication($malformed_repo, $malformed_id,
        $publisher->{filename}, "{\n");
    like(dies(sub {
        read_fixture($read, $malformed_repo, $malformed_device,
            $malformed_id, $publisher->{filename});
    }), qr/publication JSON is invalid/,
        'malformed JSON rejects before value admission');

    my ($newline_repo, $newline_device) =
        fresh_repository('missing-newline');
    my $newline_id = safe_id('missing-newline');
    write_publication($newline_repo, $newline_id,
        $publisher->{filename}, $json->encode({generation => 1}));
    like(dies(sub {
        read_fixture($read, $newline_repo, $newline_device,
            $newline_id, $publisher->{filename});
    }), qr/not newline-terminated/,
        'canonical JSON without its terminal newline rejects');

    my ($noncanonical_repo, $noncanonical_device) =
        fresh_repository('noncanonical');
    my $noncanonical_id = safe_id('noncanonical');
    write_publication($noncanonical_repo, $noncanonical_id,
        $publisher->{filename}, "{ \"generation\": 1 }\n");
    like(dies(sub {
        read_fixture($read, $noncanonical_repo, $noncanonical_device,
            $noncanonical_id, $publisher->{filename});
    }), qr/JSON is not canonical/,
        'decodable but noncanonical JSON rejects');

    my ($extra_repo, $extra_device) = fresh_repository('extra-entry');
    my $extra_id = safe_id('extra-entry');
    my $extra_path = write_publication($extra_repo, $extra_id,
        $publisher->{filename}, "{}\n");
    write_raw(File::Spec->catfile(dirname($extra_path), 'extra.json'), "{}\n");
    like(dies(sub {
        read_fixture($read, $extra_repo, $extra_device,
            $extra_id, $publisher->{filename});
    }), qr/publication census changed/,
        'a second directory entry rejects the publication');

    my ($race_repo, $race_device) = fresh_repository('directory-race');
    my $race_id = safe_id('directory-race');
    my $race_path = write_publication($race_repo, $race_id,
        $publisher->{filename}, "{}\n");
    my $race_directory = dirname($race_path);
    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"${class}::_read_exact_publication_file"} = sub {
            write_raw(File::Spec->catfile($race_directory, 'late.json'),
                "{}\n");
            return $read_file->(@_);
        };
        like(dies(sub {
            $read_directory->($race_directory, $race_device,
                $publisher->{filename});
        }), qr/publication directory changed while reading/,
            'a directory mutation during the bounded read rejects');
    }

    my ($symlink_repo, $symlink_device) = fresh_repository('symlink');
    my $symlink_id = safe_id('symlink');
    my $symlink_dir = publication_directory($symlink_repo, $symlink_id);
    make_path($symlink_dir, {mode => 0700});
    my $symlink_target = File::Spec->catfile($symlink_repo, 'target.json');
    write_raw($symlink_target, "{}\n");
    symlink(File::Spec->abs2rel($symlink_target, $symlink_dir),
        File::Spec->catfile($symlink_dir, $publisher->{filename}))
        or die "cannot create legacy publication symlink fixture: $!\n";
    like(dies(sub {
        read_fixture($read, $symlink_repo, $symlink_device,
            $symlink_id, $publisher->{filename});
    }), qr/publication artifact is invalid/,
        'a symlink cannot substitute for publication bytes');

    my ($hard_repo, $hard_device) = fresh_repository('hard-link');
    my $hard_id = safe_id('hard-link');
    my $hard_path = write_publication($hard_repo, $hard_id,
        $publisher->{filename}, "{}\n");
    link($hard_path, File::Spec->catfile($hard_repo, 'hard-alias.json'))
        or die "cannot create legacy publication hard-link fixture: $!\n";
    like(dies(sub {
        read_fixture($read, $hard_repo, $hard_device,
            $hard_id, $publisher->{filename});
    }), qr/publication artifact is hard-linked/,
        'a multiply linked publication rejects before content use');
}

sub immutable_publication_census {
    my $base = repo_path($repo_root, $publication_base);
    die "ignored revision-1 publication is absent\n" unless -d $base;
    my @root_stat = stat($repo_root);
    my %census = map {
        $_ => {
            count => 0,
            total_bytes => 0,
            maximum_bytes => 0,
            maximum_path => undef,
            canonical_files => 0,
            exact_directories => 0,
            regular_files => 0,
            one_link_files => 0,
            same_volume_files => 0,
            admitted_files => 0,
        }
    } qw(semantic_bridge execution_checking);
    find({
        no_chdir => 1,
        wanted => sub {
            return if -d $_;
            my $relative = File::Spec->abs2rel($_, $repo_root);
            $relative =~ tr{\\}{/};
            my $family = census_family($relative);
            return unless defined($family);
            my $row = $census{$family};
            my @stat = lstat($_);
            my $content = read_raw($_);
            my $bytes = bytes::length($content);
            my $value = eval { JSON::PP->new->utf8(1)->decode($content) };
            $row->{count}++;
            $row->{total_bytes} += $bytes;
            $row->{regular_files}++ if @stat && !-l _ && -f _;
            $row->{one_link_files}++ if @stat && $stat[3] == 1;
            $row->{same_volume_files}++
                if @stat && $stat[0] == $root_stat[0];
            $row->{canonical_files}++
                if !$@ && $json->encode($value) . "\n" eq $content;
            my $class = $family eq 'semantic_bridge'
                ? $publishers[0]{class} : $publishers[1]{class};
            my $reader = $class->can('_read_json_publication');
            my ($admitted, $metadata);
            my $admitted_ok = eval {
                ($admitted, $metadata) = $reader->({
                    repository_root => $repo_root,
                    root_device => $root_stat[0],
                    profile_id => basename(dirname($_)),
                    filename => basename($_),
                });
                1;
            };
            $row->{admitted_files}++
                if $admitted_ok
                    && $metadata->{bytes} == $bytes
                    && $json->encode($admitted) . "\n" eq $content;
            opendir my $dh, dirname($_)
                or die "cannot inspect immutable publication directory: $!\n";
            my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
            closedir $dh
                or die "cannot close immutable publication directory: $!\n";
            (my $filename = $_) =~ s{.*/}{};
            $row->{exact_directories}++
                if @entries == 1 && $entries[0] eq $filename;
            if ($bytes > $row->{maximum_bytes}) {
                $row->{maximum_bytes} = $bytes;
                $row->{maximum_path} = $relative;
            }
        },
    }, $base);
    return \%census;
}

sub census_family {
    my ($relative) = @_;
    return 'semantic_bridge'
        if $relative =~ m{\A[.]artifacts/qualification/vial-scale/v1/
            (?:semantic-catalog-v1|bridge-fanout-v1|
               semantic-bridge-complete-matrix-v1)}x;
    return 'execution_checking'
        if $relative =~ m{\A[.]artifacts/qualification/vial-scale/v1/
            (?:execution-graph-v1|checking-state-v1|
               execution-checking-complete-matrix-v1)}x;
    return undef;
}

sub exact_sized_value {
    my ($bytes) = @_;
    my $overhead = bytes::length($json->encode({payload => ''}) . "\n");
    die "requested publication fixture is too small\n" if $bytes < $overhead;
    return {payload => 'x' x ($bytes - $overhead)};
}

sub fresh_repository {
    my ($label) = @_;
    $sequence++;
    my $root = File::Spec->catdir(
        $fixture_root, sprintf('%03d-%s', $sequence, $label),
    );
    make_path($root, {mode => 0700});
    my @stat = stat($root);
    die "cannot stat synthetic repository\n" unless @stat;
    return ($root, $stat[0]);
}

sub safe_id {
    my ($label) = @_;
    return "synthetic-$label-v1";
}

sub publication_directory {
    my ($root, $profile_id) = @_;
    return repo_path($root, join('/', $publication_base, $profile_id));
}

sub write_publication {
    my ($root, $profile_id, $filename, $content) = @_;
    my $directory = publication_directory($root, $profile_id);
    make_path($directory, {mode => 0700});
    my $path = File::Spec->catfile($directory, $filename);
    write_raw($path, $content);
    return $path;
}

sub read_fixture {
    my ($reader, $root, $device, $profile_id, $filename) = @_;
    return $reader->({
        repository_root => $root,
        root_device => $device,
        profile_id => $profile_id,
        filename => $filename,
    });
}

sub write_raw {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path
        or die "cannot create legacy publication fixture: $!\n";
    print {$fh} $content
        or die "cannot write legacy publication fixture: $!\n";
    close $fh
        or die "cannot close legacy publication fixture: $!\n";
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path
        or die "cannot read immutable publication: $!\n";
    local $/;
    my $content = <$fh>;
    close $fh
        or die "cannot close immutable publication: $!\n";
    return $content;
}

sub repo_path {
    my ($root, $relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub dies {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}
