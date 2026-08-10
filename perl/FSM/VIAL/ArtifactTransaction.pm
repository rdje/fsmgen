package FSM::VIAL::ArtifactTransaction;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Spec;
use IO::Handle ();
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my @ARTIFACT_KEYS = qw(
    relpath kind language role content encoding source_layer generated_from
);

sub publish($class, @args) {
    return _failure('VIAL_TOOL_INVOCATION_ERROR', 'publish requires the exact ArtifactTransaction class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_TOOL_INVOCATION_ERROR', 'publish expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);

    my $result = eval { _publish($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa('FSM::VIAL::ArtifactTransaction::Failure');
    return _failure('VIAL_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _publish($raw) {
    _require_exact_keys($raw, [qw(repo_root artifact_root operation_id artifacts)], 'artifact transaction');
    confess 'repo_root must be a scalar directory path'
        unless defined($raw->{repo_root}) && !ref($raw->{repo_root});
    confess 'artifact_root must be a safe repository-relative directory'
        unless _safe_relpath($raw->{artifact_root}, 1);
    confess 'operation_id must be a stable safe identifier'
        unless defined($raw->{operation_id}) && !ref($raw->{operation_id})
            && $raw->{operation_id} =~ /\Aop-[0-9a-f]{64}\z/;
    confess 'artifacts must be a non-empty array'
        unless ref($raw->{artifacts}) eq 'ARRAY' && @{$raw->{artifacts}};

    my $repo_root = abs_path($raw->{repo_root});
    _throw('VIAL_ARTIFACT_PATH_ERROR', 'repository root is not a readable directory', '/')
        unless defined($repo_root) && -d $repo_root;
    my @root_stat = stat($repo_root);
    _throw('VIAL_ARTIFACT_PATH_ERROR', 'repository filesystem identity is unavailable', '/')
        unless @root_stat;

    my $artifacts = _validate_artifacts($raw->{artifacts});
    my $target_rel = $raw->{artifact_root};
    my $stage_rel = ".artifacts/tmp/vial/$raw->{operation_id}";
    my $target_abs = _validated_destination($repo_root, $target_rel, $root_stat[0]);
    my $stage_abs = _validated_destination($repo_root, $stage_rel, $root_stat[0]);

    if (-e $target_abs || -l $target_abs) {
        return {
            ok => JSON::PP::true,
            status => 'unchanged',
            artifact_root => $target_rel,
            staging_identity => $stage_rel,
            diagnostics => [],
        } if _tree_is_identical($target_abs, $artifacts);
        _throw(
            'VIAL_ARTIFACT_COLLISION',
            "artifact root '$target_rel' already exists and is not the exact declared tree",
            '/artifact_root',
        );
    }
    _throw(
        'VIAL_ARTIFACT_COLLISION',
        "staging root '$stage_rel' already exists",
        '/staging',
    ) if -e $stage_abs || -l $stage_abs;

    my $stage_created = 0;
    my $committed = 0;
    my $ok = eval {
        _make_directory($stage_abs, $stage_rel);
        $stage_created = 1;
        for my $artifact (@$artifacts) {
            my $path = File::Spec->catfile($stage_abs, split m{/}, $artifact->{relpath});
            my $parent = dirname($path);
            _make_directory($parent, "$stage_rel/" . _dirname_rel($artifact->{relpath}));
            _write_exact($path, $artifact->{content}, "$stage_rel/$artifact->{relpath}");
        }

        my $target_parent = dirname($target_abs);
        my $target_parent_rel = _dirname_rel($target_rel);
        _make_directory($target_parent, $target_parent_rel);
        _throw('VIAL_ARTIFACT_COLLISION', "artifact root '$target_rel' appeared during publication", '/artifact_root')
            if -e $target_abs || -l $target_abs;
        rename($stage_abs, $target_abs)
            or _throw('VIAL_HOST_ERROR', "cannot atomically publish artifact root '$target_rel'", '/artifact_root');
        $committed = 1;
        $stage_created = 0;
        1;
    };
    if (!$ok) {
        my $error = $@;
        if ($stage_created && !$committed && -d $stage_abs && !-l $stage_abs) {
            my $cleanup_error;
            remove_tree($stage_abs, {error => \$cleanup_error});
            if ($cleanup_error && @$cleanup_error) {
                _throw('VIAL_HOST_ERROR', "cannot remove failed staging root '$stage_rel'", '/staging');
            }
        }
        die $error;
    }

    return {
        ok => JSON::PP::true,
        status => 'planned',
        artifact_root => $target_rel,
        staging_identity => $stage_rel,
        diagnostics => [],
    };
}

sub _validate_artifacts($raw) {
    my (@out, %exact, %folded, %directory);
    for my $index (0 .. $#$raw) {
        my $artifact = $raw->[$index];
        confess "artifact $index must be an unblessed hash"
            unless ref($artifact) eq 'HASH' && !blessed($artifact);
        _require_exact_keys($artifact, \@ARTIFACT_KEYS, "artifact $index");
        confess "artifact $index relpath is unsafe"
            unless _safe_relpath($artifact->{relpath}, 0);
        confess "artifact $index content must be scalar"
            unless defined($artifact->{content}) && !ref($artifact->{content});
        confess "artifact $index encoding must be utf-8"
            unless defined($artifact->{encoding}) && !ref($artifact->{encoding})
                && lc($artifact->{encoding}) eq 'utf-8';
        for my $key (qw(kind language role source_layer)) {
            confess "artifact $index $key must be a non-empty scalar"
                unless defined($artifact->{$key}) && !ref($artifact->{$key})
                    && length($artifact->{$key});
        }
        confess "artifact $index generated_from must be an array"
            unless ref($artifact->{generated_from}) eq 'ARRAY';
        confess "duplicate artifact relpath '$artifact->{relpath}'"
            if $exact{$artifact->{relpath}}++;
        my $folded = lc($artifact->{relpath});
        confess "case-fold artifact collision at '$artifact->{relpath}'"
            if exists($folded{$folded}) && $folded{$folded} ne $artifact->{relpath};
        $folded{$folded} = $artifact->{relpath};
        my @parts = split m{/}, $artifact->{relpath};
        pop @parts;
        my $prefix = '';
        for my $part (@parts) {
            $prefix = length($prefix) ? "$prefix/$part" : $part;
            confess "artifact file/directory collision at '$prefix'" if $exact{$prefix};
            $directory{$prefix} = 1;
        }
        confess "artifact file/directory collision at '$artifact->{relpath}'"
            if $directory{$artifact->{relpath}};
        push @out, _clone($artifact);
    }
    return [sort { $a->{relpath} cmp $b->{relpath} } @out];
}

sub _validated_destination($repo_root, $relative, $root_device) {
    my $path = $repo_root;
    my $existing = $repo_root;
    for my $part (split m{/}, $relative) {
        $path = File::Spec->catfile($path, $part);
        if (-e $path || -l $path) {
            my @stat = lstat($path);
            _throw('VIAL_ARTIFACT_PATH_ERROR', "path '$relative' contains an unreadable component", '/artifact_root')
                unless @stat;
            _throw('VIAL_ARTIFACT_PATH_ERROR', "path '$relative' must not traverse a symlink", '/artifact_root')
                if -l _;
            $existing = $path;
        }
    }
    my @existing_stat = stat($existing);
    _throw('VIAL_ARTIFACT_PATH_ERROR', "path '$relative' filesystem identity is unavailable", '/artifact_root')
        unless @existing_stat;
    _throw('VIAL_ARTIFACT_PATH_ERROR', "path '$relative' must remain on the repository filesystem volume", '/artifact_root')
        unless $existing_stat[0] == $root_device;
    return $path;
}

sub _tree_is_identical($root, $artifacts) {
    return 0 unless -d $root && !-l $root;
    my (%expected, %expected_dir);
    for my $artifact (@$artifacts) {
        $expected{$artifact->{relpath}} = $artifact->{content};
        my @parts = split m{/}, $artifact->{relpath};
        pop @parts;
        my $prefix = '';
        for my $part (@parts) {
            $prefix = length($prefix) ? "$prefix/$part" : $part;
            $expected_dir{$prefix} = 1;
        }
    }
    my (@dirs, @files);
    return 0 unless _walk_tree($root, '', \@dirs, \@files);
    return 0 if grep { !$expected_dir{$_} } @dirs;
    return 0 unless @files == keys %expected;
    for my $rel (@files) {
        return 0 unless exists $expected{$rel};
        my $path = File::Spec->catfile($root, split m{/}, $rel);
        open my $fh, '<:raw', $path or return 0;
        local $/;
        my $content = <$fh>;
        close $fh or return 0;
        return 0 unless defined($content) && $content eq $expected{$rel};
    }
    return 1;
}

sub _walk_tree($root, $relative, $dirs, $files) {
    my $path = length($relative)
        ? File::Spec->catfile($root, split m{/}, $relative)
        : $root;
    opendir my $dh, $path or return 0;
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh or return 0;
    for my $name (@entries) {
        my $rel = length($relative) ? "$relative/$name" : $name;
        my $entry = File::Spec->catfile($path, $name);
        my @stat = lstat($entry);
        return 0 unless @stat && !-l _;
        if (-d _) {
            push @$dirs, $rel;
            return 0 unless _walk_tree($root, $rel, $dirs, $files);
        }
        elsif (-f _) {
            push @$files, $rel;
        }
        else {
            return 0;
        }
    }
    return 1;
}

sub _make_directory($path, $identity) {
    if (-e $path || -l $path) {
        _throw('VIAL_ARTIFACT_PATH_ERROR', "path '$identity' must be a non-symlink directory", '/artifact_root')
            unless -d $path && !-l $path;
        return;
    }
    eval { make_path($path); 1 }
        or _throw('VIAL_HOST_ERROR', "cannot create artifact directory '$identity'", '/artifact_root');
}

sub _write_exact($path, $content, $identity) {
    open my $fh, '>:raw', $path
        or _throw('VIAL_HOST_ERROR', "cannot create artifact '$identity'", '/artifacts');
    print {$fh} $content
        or _throw('VIAL_HOST_ERROR', "cannot write artifact '$identity'", '/artifacts');
    eval { $fh->sync(); 1 };
    close $fh
        or _throw('VIAL_HOST_ERROR', "cannot close artifact '$identity'", '/artifacts');
}

sub _dirname_rel($relative) {
    my @parts = split m{/}, $relative;
    pop @parts;
    return @parts ? join('/', @parts) : '.';
}

sub _safe_relpath($value, $directory) {
    return 0 unless defined($value) && !ref($value) && length($value);
    return 0 if $value =~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)};
    my @parts = split m{/}, $value, -1;
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @parts;
    return 0 if !$directory && $value =~ m{/\z};
    return 1;
}

sub _require_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'" if @unknown;
    confess "$label is missing key '$missing[0]'" if @missing;
}

sub _throw($code, $message, $path) {
    die bless {code => $code, message => $message, path => $path},
        'FSM::VIAL::ArtifactTransaction::Failure';
}

sub _failure($code, $message, $path) {
    return {
        ok => JSON::PP::false,
        status => 'error',
        artifact_root => undef,
        staging_identity => undef,
        diagnostics => [{
            code => $code,
            severity => 'error',
            message => $message,
            source_locations => [],
            semantic_path => $path,
            related => [],
            notes => [],
            hints => [],
        }],
    };
}

sub _sanitize_exception($exception) {
    my $text = "$exception";
    $text =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//s;
    $text =~ s/[\r\n]+/ /g;
    $text =~ s/^\s+|\s+$//g;
    return length($text) ? $text : 'artifact transaction failed';
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'artifact contains unsupported reference data' if ref($value);
    return $value;
}

package FSM::VIAL::ArtifactTransaction::Failure;

use overload '""' => sub { $_[0]{message} // 'VIAL artifact transaction failure' }, fallback => 1;

1;
