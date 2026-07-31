#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Glob qw(bsd_glob GLOB_NOSORT);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use JSON::PP;
use Symbol qw(gensym);

my ($root_arg, $registry, $help);
$registry = 'doctrine/live_document_size/surfaces.jsonl';
GetOptions(
    'root=s'     => \$root_arg,
    'registry=s' => \$registry,
    'help|h'     => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
if (!defined($root) || !-d $root) {
    print STDERR "live-doc-reference-authority: invalid project root\n";
    exit 2;
}

my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fail = 0;

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_live_document_reference_authority.pl [--root DIR]
       [--registry FILE]
USAGE
    exit $status;
}

sub problem {
    my ($message) = @_;
    print STDERR "live-doc-reference-authority: $message\n";
    $fail = 1;
}

sub relative_path_ok {
    my ($path) = @_;
    return 0 if !defined($path) || $path eq '' || $path =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($path) || $path =~ m{^~(?:/|$)};
    return 0 if grep { $_ eq '..' } split m{/+}, $path;
    return 1;
}

sub signed_integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A-?[0-9]+\z/;
}

sub run_git {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, 'git', '-C', $root, @args);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? >> 8, $out, $err);
}

sub git_output {
    my (@args) = @_;
    my ($status, $out, $err) = run_git(@args);
    if ($status != 0) {
        $err =~ s/\s+\z//;
        problem("git @args failed" . ($err eq '' ? '' : ": $err"));
        return '';
    }
    return $out;
}

sub read_worktree_file {
    my ($relative) = @_;
    return undef if !relative_path_ok($relative);
    my $path = File::Spec->catfile($root, split m{/+}, $relative);
    return undef if !-f $path || -l $path;
    open my $fh, '<:raw', $path or return undef;
    local $/;
    my $contents = <$fh> // '';
    close $fh;
    return $contents;
}

sub read_tree_file {
    my ($tree, $relative) = @_;
    return read_worktree_file($relative) if $tree eq 'worktree';
    my $spec = $tree eq 'index' ? ":$relative" : "$tree:$relative";
    my ($status, $out) = run_git('show', $spec);
    return $status == 0 ? $out : undef;
}

sub parse_registry {
    my ($contents, $label) = @_;
    my %records;
    if (!defined $contents) {
        problem("$label is absent");
        return \%records;
    }
    my $line_number = 0;
    for my $line (split /\n/, $contents) {
        $line_number++;
        next if $line eq '';
        my $record = eval { decode_json($line) };
        if ($@ || ref($record) ne 'HASH') {
            problem("$label line $line_number is not a JSON object");
            next;
        }
        my $id = $record->{surface_id} // '';
        next if ref($id) || $id eq '';
        $records{$id} = $record;
    }
    return \%records;
}

sub pattern_regex {
    my ($pattern) = @_;
    my $quoted = quotemeta($pattern);
    $quoted =~ s/\\\*/[^\/]*/g;
    $quoted =~ s/\\\?/[^\/]/g;
    return qr/\A$quoted\z/;
}

sub tree_paths {
    my ($tree, $patterns) = @_;
    my %paths;
    if ($tree eq 'worktree') {
        for my $pattern (@{$patterns}) {
            next if !relative_path_ok($pattern);
            my $absolute = File::Spec->catfile($root, split m{/+}, $pattern);
            for my $match (bsd_glob($absolute, GLOB_NOSORT)) {
                next if !-f $match || -l $match;
                my $relative = substr($match, length($root) + 1);
                $relative =~ s{\\}{/}g;
                $paths{$relative} = 1;
            }
        }
    } else {
        my $listing = $tree eq 'index'
            ? git_output('ls-files')
            : git_output('ls-tree', '-r', '--name-only', $tree);
        my @regexes = map { pattern_regex($_) } grep { relative_path_ok($_) } @{$patterns};
        for my $path (grep { $_ ne '' } split /\n/, $listing) {
            $paths{$path} = 1 if grep { $path =~ $_ } @regexes;
        }
    }
    return sort keys %paths;
}

sub measurement {
    my ($tree, $record) = @_;
    my @paths = tree_paths($tree, $record->{targets} || []);
    my ($lines, $bytes) = (0, 0);
    for my $path (@paths) {
        my $contents = read_tree_file($tree, $path);
        if (!defined $contents) {
            problem("cannot read $tree:$path while measuring $record->{surface_id}");
            next;
        }
        $lines += ($contents =~ tr/\n//);
        $bytes += length($contents);
    }
    return { files => scalar(@paths), lines_total => $lines, bytes_total => $bytes };
}

sub aggregate_change {
    my ($record) = @_;
    return undef if ref($record->{reference_contract}) ne 'HASH';
    return $record->{reference_contract}{aggregate_change};
}

sub exact_aggregate {
    my ($label, $actual, $expected) = @_;
    for my $key (qw(files lines_total bytes_total)) {
        problem("$label $key is $actual->{$key}, expected $expected->{$key}")
            if !defined($expected->{$key}) || $actual->{$key} != $expected->{$key};
    }
}

my ($inside_status) = run_git('rev-parse', '--is-inside-work-tree');
if ($inside_status != 0) {
    problem('project root is not a Git work tree');
    exit 1;
}

my $staged = git_output('diff', '--cached', '--name-only');
my $unstaged = git_output('diff', '--name-only');
my ($mode, $prior_tree, $current_tree);
if ($staged ne '') {
    $mode = 'staged';
    $prior_tree = 'HEAD';
    $current_tree = 'index';
} elsif ($unstaged ne '') {
    $mode = 'worktree';
    $prior_tree = 'HEAD';
    $current_tree = 'worktree';
} else {
    my ($parent_status) = run_git('rev-parse', '--verify', 'HEAD^');
    $mode = 'committed';
    $prior_tree = $parent_status == 0 ? 'HEAD^' : 'HEAD';
    $current_tree = 'HEAD';
}

my $prior_registry = read_tree_file($prior_tree, $registry);
my $current_registry = read_tree_file($current_tree, $registry);
my $prior = parse_registry($prior_registry, 'prior surface registry');
my $current = parse_registry($current_registry, 'current surface registry');
my $changed = 0;
my $references = 0;

for my $id (sort keys %{$current}) {
    my $record = $current->{$id};
    next if ($record->{lifecycle} // '') ne 'maintained_reference';
    $references++;
    my $current_metrics = measurement($current_tree, $record);
    my $change = aggregate_change($record);
    if (ref($change) ne 'HASH' || ref($change->{baseline}) ne 'HASH'
            || ref($change->{delta}) ne 'HASH') {
        problem("surface $id lacks a complete aggregate_change contract");
        next;
    }
    my %authorized;
    for my $key (qw(files lines_total bytes_total)) {
        if (!signed_integer($change->{baseline}{$key})
                || !signed_integer($change->{delta}{$key})) {
            problem("surface $id has invalid aggregate_change $key values");
            next;
        }
        $authorized{$key} = $change->{baseline}{$key} + $change->{delta}{$key};
    }
    exact_aggregate("surface $id authorized aggregate", $current_metrics, \%authorized);

    my $prior_record = $prior->{$id};
    if (defined $prior_record) {
        my $prior_metrics = measurement($prior_tree, $prior_record);
        my %delta = map {
            $_ => $current_metrics->{$_} - $prior_metrics->{$_}
        } qw(files lines_total bytes_total);
        my $prior_change = aggregate_change($prior_record);
        if (grep { $delta{$_} != 0 } keys %delta) {
            $changed++;
            exact_aggregate("surface $id aggregate baseline", $prior_metrics, $change->{baseline});
            exact_aggregate("surface $id aggregate delta", \%delta, $change->{delta});
            if (ref($prior_change) eq 'HASH'
                    && ($prior_change->{authority_id} // '') eq ($change->{authority_id} // '')) {
                problem("surface $id aggregate change reuses authority_id $change->{authority_id}");
            }
        } elsif (($prior_record->{lifecycle} // '') eq 'maintained_reference') {
            if (ref($prior_change) ne 'HASH') {
                problem("prior maintained_reference surface $id lacks aggregate authority");
            } elsif ($json->encode($prior_change) ne $json->encode($change)) {
                problem("surface $id changed aggregate authority without an aggregate change");
            }
        } else {
            exact_aggregate("surface $id initial aggregate baseline", $prior_metrics, $change->{baseline});
            exact_aggregate("surface $id initial aggregate delta", \%delta, $change->{delta});
        }
    } else {
        exact_aggregate("surface $id initial aggregate baseline", $current_metrics, $change->{baseline});
        exact_aggregate("surface $id initial aggregate delta", { files => 0, lines_total => 0, bytes_total => 0 }, $change->{delta});
    }
}

for my $id (sort keys %{$prior}) {
    next if ($prior->{$id}{lifecycle} // '') ne 'maintained_reference';
    problem("maintained_reference surface $id disappeared or changed lifecycle without an owned authority-contract migration")
        if !exists($current->{$id})
            || ($current->{$id}{lifecycle} // '') ne 'maintained_reference';
}

if (!$fail) {
    print "live-doc-reference-authority: all maintained-reference aggregate invariants hold ($references reference(s), $changed changed, mode $mode)\n";
}
exit($fail ? 1 : 0);
