#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(realpath);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use Symbol qw(gensym);
use Test::More;

my $root = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $fixture = File::Spec->catdir(
    $root, '.artifacts', 'tmp',
    "vial-regression-promotion-failed-prefix-verifier-$$",
);
my $archive_relative = join '/', qw(
    .artifacts qualification vial-scale history
    610ed7869642ee57f9df608204cfbad3a0b187e4
    regression-promotion-report-coordinate-failure-ordinal-5-v1
);
my $active_relative = join '/', qw(
    .artifacts qualification vial-scale v2 regression-promotion-corpus-v1
);
my $script_relative =
    'scripts/verify_vial_regression_promotion_failed_prefix.pl';
my $json = JSON::PP->new->canonical(1)->utf8(1);

die "failed-prefix verifier fixture root already exists\n"
    if -e $fixture || -l $fixture;
make_path($fixture, {mode => 0700});

END {
    remove_tree($fixture)
        if defined($fixture) && -d($fixture) && !-l($fixture);
}

copy_file(
    File::Spec->catfile($root, split m{/}, $script_relative),
    File::Spec->catfile($fixture, split m{/}, $script_relative),
);
copy_tree(
    File::Spec->catdir($root, split m{/}, $archive_relative),
    File::Spec->catdir($fixture, split m{/}, $archive_relative),
);
copy_tree(
    File::Spec->catdir($root, split m{/}, $active_relative),
    File::Spec->catdir($fixture, split m{/}, $active_relative),
);

my $script = File::Spec->catfile($fixture, split m{/}, $script_relative);
my $active = File::Spec->catdir($fixture, split m{/}, $active_relative);
my $archive = File::Spec->catdir($fixture, split m{/}, $archive_relative);
my $current_profile = first_matching_file(
    $active, qr{/profiles/01-[^/]+/measurement-report[.]json\z},
);
my $archived_profile = first_matching_file(
    $archive, qr{/profiles/01-[^/]+/measurement-report[.]json\z},
);

subtest 'real current corpus and historical prefix authenticate separately' => sub {
    my $result = run_verifier($script);
    is($result->{exit}, 0, 'verifier accepts copied exact evidence')
        or diag($result->{stderr});
    my $decoded = eval { $json->decode($result->{stdout}) };
    is($@, '', 'successful verifier output is JSON');
    is($decoded->{schema_version}, 2, 'verification contract advances to v2');
    is($decoded->{file_count}, 5, 'historical archive retains five files');
    is($decoded->{active_namespace}{status}, 'authenticated_current',
        'current namespace is authenticated rather than rejected as residue');
    is($decoded->{active_namespace}{profile_count}, 11,
        'current namespace retains eleven profiles');
    is($decoded->{active_namespace}{file_count}, 13,
        'current namespace retains eleven reports plus its two-file seal');
};

subtest 'current content, census, and archive alias controls fail closed' => sub {
    my $original = read_raw($current_profile);
    write_raw($current_profile, $original . " ");
    my $mutated = run_verifier($script);
    isnt($mutated->{exit}, 0, 'mutated current profile rejects');
    like($mutated->{stderr}, qr/current regression-promotion profile (?:artifact|content) changed/,
        'mutation diagnostic names current profile evidence');
    is($mutated->{stdout}, '', 'current-profile rejection emits no result');
    write_raw($current_profile, $original);

    my $extra = File::Spec->catfile($active, 'foreign.json');
    write_raw($extra, "{}\n");
    my $foreign = run_verifier($script);
    isnt($foreign->{exit}, 0, 'foreign active file rejects');
    like($foreign->{stderr}, qr/current regression-promotion namespace file census changed/,
        'foreign-file diagnostic names active census');
    unlink($extra) or die "cannot remove verifier foreign-file control\n";

    unlink($current_profile)
        or die "cannot replace current profile with alias control\n";
    if (link($archived_profile, $current_profile)) {
        my $aliased = run_verifier($script);
        isnt($aliased->{exit}, 0, 'hard-linked historical/current evidence rejects');
        like($aliased->{stderr}, qr/(?:archive file shape changed|aliases failed-prefix bytes)/,
            'alias is rejected by archive or cross-namespace inode shape');
        unlink($current_profile)
            or die "cannot remove verifier alias control\n";
    } else {
        fail("cannot create same-volume verifier alias control: $!");
    }
    write_raw($current_profile, $original);
};

subtest 'archive mutation still rejects and archive-only replay remains valid' => sub {
    my $original = read_raw($archived_profile);
    write_raw($archived_profile, $original . " ");
    my $mutated = run_verifier($script);
    isnt($mutated->{exit}, 0, 'mutated historical report still rejects');
    like($mutated->{stderr}, qr/failed-prefix archive file identity changed/,
        'historical mutation retains exact archive diagnostic');
    is($mutated->{stdout}, '', 'historical rejection emits no result');
    write_raw($archived_profile, $original);

    remove_tree($active);
    my $archive_only = run_verifier($script);
    is($archive_only->{exit}, 0, 'archive remains independently replayable')
        or diag($archive_only->{stderr});
    my $decoded = $json->decode($archive_only->{stdout});
    is_deeply($decoded->{active_namespace}, {status => 'absent'},
        'absent current namespace is distinguished from authenticated current');
};

done_testing();

sub copy_tree {
    my ($source, $destination) = @_;
    die "verifier fixture source tree is unavailable\n"
        unless -d $source && !-l $source;
    find({
        no_chdir => 1,
        wanted => sub {
            my $path = $File::Find::name;
            die "verifier fixture source contains a symlink\n" if -l $path;
            my $relative = File::Spec->abs2rel($path, $source);
            my $target = $relative eq '.'
                ? $destination
                : File::Spec->catfile($destination, $relative);
            if (-d _) {
                make_path($target, {mode => 0700});
                return;
            }
            die "verifier fixture source contains a non-file\n" unless -f _;
            copy_file($path, $target);
        },
    }, $source);
}

sub copy_file {
    my ($source, $destination) = @_;
    make_path(dirname($destination), {mode => 0700});
    copy($source, $destination)
        or die "cannot copy verifier fixture file\n";
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
    die "verifier fixture expected exactly one matching file\n"
        unless @matches == 1;
    return $matches[0];
}

sub run_verifier {
    my ($path) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, $^X, $path);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return {exit => $? >> 8, stdout => $out, stderr => $err};
}

sub read_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read verifier fixture file\n";
    local $/;
    my $bytes = <$fh>;
    close $fh or die "cannot close verifier fixture file\n";
    return $bytes;
}

sub write_raw {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path or die "cannot write verifier fixture file\n";
    print {$fh} $bytes or die "cannot write verifier fixture bytes\n";
    close $fh or die "cannot close verifier fixture file\n";
}
