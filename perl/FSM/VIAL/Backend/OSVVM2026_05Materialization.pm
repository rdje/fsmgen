package FSM::VIAL::Backend::OSVVM2026_05Materialization;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Spec;
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $SCHEMA = 'fsmgen.vial_osvvm_materialization.v1';
my $VERSION = '2026.05';
my $DEPENDENCY_ROOT = '.artifacts/cache/providers/osvvm/2026.05/source';
my $JSON = JSON::PP->new->canonical(1);

my @REPOSITORIES = (
    _repository('.', 'OsvvmLibraries', 'https://github.com/OSVVM/OsvvmLibraries.git',
        '2f7c391051dfb11890fa4bdbda9918d1db492250',
        'bd4fdc594f2c26d564cf8907ff599578b9a39e22', 35),
    _repository('AXI4', 'AXI4', 'https://github.com/OSVVM/AXI4.git',
        '19a50724bf94bd61e1a5515f74a7f4a55d688e57',
        'cf915880a8f1914372bc4793afd93110040d735e', 399),
    _repository('CoSim', 'CoSim', 'https://github.com/OSVVM/CoSim.git',
        'aa0fb69ead20f666ccad52707d1c5f2dfc9288e4',
        '3bbb953b12c2ab73f479e62574fc1a6de3faa789', 149),
    _repository('CoSimPCIe', 'CoSimPCIe', 'https://github.com/OSVVM/CoSimPCIe.git',
        'acb605ffe516dc598b22a6cded29cb4cefb37a49',
        'a71cbe2a94baa8fc7928cc8911fd78083cddec72', 105),
    _repository('Common', 'OSVVM-Common', 'https://github.com/OSVVM/OSVVM-Common.git',
        'b2ec7481e6744427d2f6ca5ba6cc8d1966a9aeba',
        '9efe59a83674ddb040ffdc7f1bcf107d536b9ec1', 242),
    _repository('Documentation', 'Documentation',
        'https://github.com/OSVVM/Documentation.git',
        'a4fd58f749f11b2d66b9c1011e0bf5a6e3dc7e0f',
        'a8706ff03b62ae5f0170f1c69cec12635f33f974', 47),
    _repository('DpRam', 'DpRam', 'https://github.com/OSVVM/DpRam.git',
        '96cd28f7d9abbf9ad1f209f2a9484adba3372081',
        'c5b6d039f7d979b29b6d552f2560fe7d1df795f3', 19),
    _repository('Ethernet', 'Ethernet', 'https://github.com/OSVVM/Ethernet.git',
        'ca2ea560f9b0f06a2ea3b49561c88fd203cf055b',
        'c68a22e1a2e2102d43d4b0aec779f75e74e4b0d6', 24),
    _repository('SPI_GuyEschemann', 'SPI_GuyEschemann',
        'https://github.com/OSVVM/SPI_GuyEschemann.git',
        'f7cfe171ad26c361241367845af4408e34716b94',
        '2a3d78f05e4690614aeaa62e911ef440fb079f4e', 26),
    _repository('Scripts', 'OSVVM-Scripts', 'https://github.com/OSVVM/OSVVM-Scripts.git',
        'b93f63b8f4bbc030c95aa0a15966afa93b239a78',
        '320790356c236493699f78fdec56a1c97c9e68b8', 115),
    _repository('UART', 'UART', 'https://github.com/OSVVM/UART.git',
        'f214a00ab65c45e9c351a73ee7d5c796430329ce',
        '3b0932b965f7cead5903e373b97e1e5d513e0dd2', 60),
    _repository('VideoBus_LouisAdriaens', 'VideoBus_LouisAdriaens',
        'https://github.com/OSVVM/VideoBus_LouisAdriaens.git',
        '9870d9317630c55ef6147a7fa0c3a7a6ce134697',
        'b029ded8038d91833501d55a03b81779df631cd9', 21),
    _repository('Wishbone', 'Wishbone', 'https://github.com/OSVVM/Wishbone.git',
        '2e76b71ece2d0bf0dc559cc1c5cd491ac0031f57',
        'fc0c14d266ef7e75a34e8a2320afa0653533d45e', 25),
    _repository('osvvm', 'OSVVM', 'https://github.com/OSVVM/OSVVM.git',
        'dd5f7fd76996d1ed9a18a9a93ff53d5c6bb1171a',
        'c7063be70cd51c8132194f9ebaf6a145897eaf2f', 78),
);

my @LICENSE_NOTICE = (
    _license('LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('AXI4/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('CoSim/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('CoSimPCIe/LICENSE', 11_357,
        'c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4'),
    _license('Common/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('DpRam/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('Ethernet/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('SPI_GuyEschemann/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('Scripts/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('Scripts/doc/License.rst', 10_851,
        '16e0fbcd0710e08f3476338d6089f1889ca7106bb4098914deff1b04fe2b96b8'),
    _license('UART/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('VideoBus_LouisAdriaens/LICENSE', 11_356,
        '43070e2d4e532684de521b885f385d0841030efa2b1a20bafb76133a5e1379c1'),
    _license('Wishbone/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
    _license('osvvm/LICENSE.md', 10_571,
        '0c5e2bf896eccff640498e158d5d1965569a1d8907f5adb4064544c69abc7681'),
);

sub manifest_keys($class) {
    _exact_class($class, 'manifest_keys');
    return [qw(
        schema schema_version provider version release_tag dependency_root
        root_commit root_tree repositories recursive_gitlinks
        license_notice_files license_notice_summary materialization
        verification limitations
    )];
}

sub verify($class, @args) {
    return _failure('OSVVM_MATERIALIZATION_INVOCATION_ERROR',
        'verify requires the exact materialization class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('OSVVM_MATERIALIZATION_INVOCATION_ERROR',
        'verify expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _verify($args[0]) };
    return $result if defined $result;
    my $error = $@ || 'unknown materialization error';
    $error =~ s/\s+\z//;
    return _failure('OSVVM_MATERIALIZATION_VERIFICATION_ERROR', $error, '/');
}

sub _verify($raw) {
    confess "materialization invocation has unknown keys\n"
        unless join("\0", sort keys %$raw) eq 'dependency_root';
    confess "dependency_root must be the exact repository-relative OSVVM root\n"
        unless defined($raw->{dependency_root}) && !ref($raw->{dependency_root})
            && $raw->{dependency_root} eq $DEPENDENCY_ROOT;
    my $root = File::Spec->catdir(split m{/}, $DEPENDENCY_ROOT);
    confess "OSVVM dependency root is not materialized\n"
        unless -d $root && -e File::Spec->catfile($root, '.git');

    my @actual_repository;
    for my $expected (@REPOSITORIES) {
        my $repository_root = $expected->{path} eq '.'
            ? $root
            : File::Spec->catdir($root, split m{/}, $expected->{path});
        confess "OSVVM repository '$expected->{path}' is absent\n"
            unless -d $repository_root && -e File::Spec->catfile($repository_root, '.git');
        my $commit = _git_line($repository_root, 'rev-parse', 'HEAD');
        my $tree = _git_line($repository_root, 'rev-parse', 'HEAD^{tree}');
        my $origin = _git_line($repository_root, 'remote', 'get-url', 'origin');
        my $tracked = _git_zlist($repository_root, 'ls-files', '-z');
        my $dirty = _git_raw($repository_root, 'status', '--porcelain=v1',
            '--ignore-submodules=none');
        confess "OSVVM repository '$expected->{path}' commit drifted\n"
            unless $commit eq $expected->{commit};
        confess "OSVVM repository '$expected->{path}' tree drifted\n"
            unless $tree eq $expected->{tree};
        confess "OSVVM repository '$expected->{path}' origin drifted\n"
            unless $origin eq $expected->{origin};
        confess "OSVVM repository '$expected->{path}' tracked-entry count drifted\n"
            unless @$tracked == $expected->{tracked_entries};
        confess "OSVVM repository '$expected->{path}' is dirty\n"
            if length($dirty);
        push @actual_repository, {%$expected, clean => JSON::PP::true};
    }

    my $submodule_status = _git_raw($root, 'submodule', 'status', '--recursive');
    my @gitlinks;
    for my $line (split /\n/, $submodule_status) {
        next unless length($line);
        confess "OSVVM recursive submodule is not exactly checked out: $line\n"
            unless $line =~ /\A ([0-9a-f]{40}) ([^ ]+)(?: .*)?\z/;
        push @gitlinks, {path => $2, commit => $1};
    }
    my @expected_gitlinks = map {
        +{path => $_->{path}, commit => $_->{commit}}
    } grep { $_->{path} ne '.' } @REPOSITORIES;
    confess "OSVVM recursive gitlink graph drifted\n"
        unless $JSON->encode(\@gitlinks) eq $JSON->encode(\@expected_gitlinks);

    my @found_license_notice;
    for my $repository (@REPOSITORIES) {
        my $repository_root = $repository->{path} eq '.'
            ? $root
            : File::Spec->catdir($root, split m{/}, $repository->{path});
        for my $tracked (@{_git_zlist($repository_root, 'ls-files', '-z')}) {
            my ($basename) = $tracked =~ m{([^/]+)\z};
            next unless defined($basename)
                && $basename =~ /\A(?:license|notice|copying|copyright)(?:[._-].*)?\z/i;
            my $relative = $repository->{path} eq '.'
                ? $tracked : "$repository->{path}/$tracked";
            my $path = File::Spec->catfile($root, split m{/}, $relative);
            confess "OSVVM licence/notice '$relative' is not a regular file\n"
                unless -f $path;
            my $bytes = _slurp($path);
            push @found_license_notice, {
                kind => $basename =~ /\Anotice/i ? 'notice' : 'license',
                relpath => $relative,
                byte_length => bytes::length($bytes),
                sha256 => sha256_hex($bytes),
            };
        }
    }
    @found_license_notice = sort { $a->{relpath} cmp $b->{relpath} }
        @found_license_notice;
    my @expected_license_notice = sort { $a->{relpath} cmp $b->{relpath} }
        map { +{%$_} } @LICENSE_NOTICE;
    confess "OSVVM licence/notice inventory drifted\n"
        unless $JSON->encode(\@found_license_notice)
            eq $JSON->encode(\@expected_license_notice);

    my %repository_with_license = map {
        my $path = $_->{relpath};
        my ($first) = split m{/}, $path, 2;
        ($path =~ m{/} ? $first : '.') => 1;
    } @found_license_notice;
    my @without_license_notice = map { $_->{path} }
        grep { !$repository_with_license{$_->{path}} } @REPOSITORIES;

    my $manifest = {
        schema => $SCHEMA,
        schema_version => 1,
        provider => 'OSVVM',
        version => $VERSION,
        release_tag => $VERSION,
        dependency_root => $DEPENDENCY_ROOT,
        root_commit => $REPOSITORIES[0]{commit},
        root_tree => $REPOSITORIES[0]{tree},
        repositories => \@actual_repository,
        recursive_gitlinks => \@gitlinks,
        license_notice_files => \@found_license_notice,
        license_notice_summary => {
            license_file_count => scalar(grep { $_->{kind} eq 'license' }
                @found_license_notice),
            notice_file_count => scalar(grep { $_->{kind} eq 'notice' }
                @found_license_notice),
            repositories_without_tracked_license_or_notice =>
                \@without_license_notice,
            inferred_license_coverage => JSON::PP::false,
        },
        materialization => {
            state => 'complete_recursive_verified',
            repository_count => scalar(@actual_repository),
            gitlink_count => scalar(@gitlinks),
            network_fetch_during_emission => JSON::PP::false,
            same_volume_repository_local => JSON::PP::true,
        },
        verification => {
            clone_command => join(' ',
                'git clone --recursive --branch 2026.05 --single-branch',
                'https://github.com/OSVVM/OsvvmLibraries.git', $DEPENDENCY_ROOT),
            local_verify_entrypoint =>
                'FSM::VIAL::Backend::OSVVM2026_05Materialization->verify({...})',
            tag_commit_verified => JSON::PP::true,
            recursive_status_verified => JSON::PP::true,
            clean_worktrees_verified => JSON::PP::true,
            tree_identities_verified => JSON::PP::true,
            licence_notice_identities_verified => JSON::PP::true,
        },
        limitations => [
            'Documentation has no tracked licence or notice file at its exact pinned commit; no licence coverage is inferred for that repository.',
            'Materialization and identity verification are not VHDL analysis, elaboration, execution, result, parity, or product-support evidence.',
        ],
    };
    return {
        ok => JSON::PP::true,
        status => 'complete_recursive_verified',
        manifest => $manifest,
        diagnostics => [],
    };
}

sub _repository($path, $name, $origin, $commit, $tree, $tracked_entries) {
    return {
        path => $path,
        name => $name,
        origin => $origin,
        commit => $commit,
        tree => $tree,
        tracked_entries => $tracked_entries,
    };
}

sub _license($relpath, $byte_length, $sha256) {
    return {
        kind => 'license',
        relpath => $relpath,
        byte_length => $byte_length,
        sha256 => $sha256,
    };
}

sub _git_line($root, @args) {
    my $output = _git_raw($root, @args);
    $output =~ s/\n\z//;
    confess "git output for '@args' was not one line\n" if $output =~ /\n/;
    return $output;
}

sub _git_zlist($root, @args) {
    my $output = _git_raw($root, @args);
    return [] unless length($output);
    confess "git zero-delimited output for '@args' lacked its terminator\n"
        unless $output =~ /\0\z/;
    my @entry = split /\0/, $output, -1;
    pop @entry;
    return \@entry;
}

sub _git_raw($root, @args) {
    open my $fh, '-|', 'git', '-C', $root, @args
        or confess "cannot start git '@args': $!\n";
    binmode $fh;
    local $/;
    my $output = <$fh> // '';
    close $fh;
    confess "git '@args' failed with status " . ($? >> 8) . "\n" if $?;
    return $output;
}

sub _slurp($path) {
    open my $fh, '<:raw', $path or confess "cannot read '$path': $!\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or confess "cannot close '$path': $!\n";
    return $bytes;
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'failed',
        manifest => undef,
        diagnostics => [{code => $code, message => $message, path => $path}],
    };
}

sub _exact_class($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

1;
