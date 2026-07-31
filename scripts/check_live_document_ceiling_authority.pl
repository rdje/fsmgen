#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use JSON::PP;
use Symbol qw(gensym);

my ($root_arg, $registry, $authorities, $help);
$registry = 'doctrine/live_document_size/surfaces.jsonl';
$authorities = 'doctrine/live_document_size/ceiling_increase_authorities.jsonl';
GetOptions(
    'root=s'        => \$root_arg,
    'registry=s'    => \$registry,
    'authorities=s' => \$authorities,
    'help|h'        => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $default_root = abs_path(File::Spec->catdir(dirname($script), '..'));
my $root = abs_path($root_arg // $default_root);
if (!defined($root) || !-d $root) {
    print STDERR "live-doc-ceiling-authority: invalid project root\n";
    exit 2;
}

my $json = JSON::PP->new->canonical(1)->utf8(1);
my $fail = 0;

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_live_document_ceiling_authority.pl [--root DIR]
       [--registry FILE] [--authorities FILE]
USAGE
    exit $status;
}

sub problem {
    my ($message) = @_;
    print STDERR "live-doc-ceiling-authority: $message\n";
    $fail = 1;
}

sub relative_path_ok {
    my ($path) = @_;
    return 0 if !defined($path) || $path eq '' || $path =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($path) || $path =~ m{^~(?:/|$)};
    return 0 if grep { $_ eq '..' } split m{/+}, $path;
    return 1;
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

sub blob_exists {
    my ($spec) = @_;
    my ($status) = run_git('cat-file', '-e', $spec);
    return $status == 0;
}

sub read_blob {
    my ($spec, $required) = @_;
    if (!blob_exists($spec)) {
        problem("required Git object is absent: $spec") if $required;
        return undef;
    }
    return git_output('show', $spec);
}

sub read_worktree_file {
    my ($relative, $required) = @_;
    if (!relative_path_ok($relative)) {
        problem("path must stay project-relative: $relative");
        return undef;
    }
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    if (!-f $path || -l $path) {
        problem("required regular file is absent: $relative") if $required;
        return undef;
    }
    open my $fh, '<:raw', $path or do {
        problem("cannot read $relative: $!");
        return undef;
    };
    local $/;
    my $contents = <$fh> // '';
    close $fh or problem("cannot close $relative: $!");
    return $contents;
}

sub parse_jsonl {
    my ($contents, $label, $allow_absent) = @_;
    return [] if !defined($contents) && $allow_absent;
    if (!defined $contents) {
        problem("$label is absent");
        return [];
    }
    my @records;
    my $line_number = 0;
    for my $line (split /\n/, $contents, -1) {
        $line_number++;
        next if $line_number > 1 && $line eq '' && $line_number == 1 + ($contents =~ tr/\n//);
        if ($line eq '') {
            problem("$label line $line_number is blank");
            next;
        }
        my $record = eval { decode_json($line) };
        if ($@ || ref($record) ne 'HASH') {
            problem("$label line $line_number is not a JSON object");
            next;
        }
        push @records, $record;
    }
    return \@records;
}

sub exact_keys {
    my ($record, $label, @keys) = @_;
    my %expected = map { $_ => 1 } @keys;
    for my $key (@keys) {
        problem("$label is missing key $key") if !exists $record->{$key};
    }
    for my $key (sort keys %{$record}) {
        problem("$label has unknown key $key") if !$expected{$key};
    }
}

sub positive_integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A[1-9][0-9]*\z/;
}

sub registry_ceilings {
    my ($contents, $label, $allow_absent) = @_;
    my %by_surface;
    for my $record (@{parse_jsonl($contents, $label, $allow_absent)}) {
        my $id = $record->{surface_id};
        next if !defined($id) || ref($id) || $id eq '';
        my $values = $record->{enforcement_ceilings};
        $values = $record->{budgets} if !defined($values) && exists($record->{budgets});
        next if !defined($values);
        if (ref($values) ne 'HASH') {
            problem("$label surface $id has invalid enforcement ceilings");
            next;
        }
        $by_surface{$id} = {
            ceilings => $values,
            baseline => $record->{baseline},
        };
    }
    return \%by_surface;
}

sub authority_records {
    my ($contents, $label, $allow_absent) = @_;
    my @rows = @{parse_jsonl($contents, $label, $allow_absent)};
    return [] if !@rows && $allow_absent;
    my $metadata = shift @rows;
    if (!defined($metadata)
            || ($metadata->{record_type} // '') ne 'registry'
            || ($metadata->{schema_version} // '') ne '1') {
        problem("$label must begin with schema-version 1 registry metadata");
    } else {
        exact_keys($metadata, "$label metadata", qw(record_type schema_version));
    }
    my %ids;
    for my $index (0 .. $#rows) {
        my $record = $rows[$index];
        my $row_label = "$label authority row " . ($index + 2);
        exact_keys(
            $record, $row_label,
            qw(record_type schema_version authority_id surface_id dimension previous new decision approved_on),
        );
        problem("$row_label has invalid record_type")
            if ($record->{record_type} // '') ne 'ceiling_increase_authority';
        problem("$row_label has unsupported schema_version")
            if ($record->{schema_version} // '') ne '1';
        my $id = $record->{authority_id} // '';
        problem("$row_label has invalid authority_id")
            if ref($id) || $id !~ /\A[A-Z][A-Z0-9_.-]*\z/;
        problem("$row_label repeats authority_id $id") if $ids{$id}++;
        problem("$row_label has invalid surface_id")
            if ref($record->{surface_id}) || ($record->{surface_id} // '') !~ /\A[a-z][a-z0-9_]*\z/;
        problem("$row_label has invalid dimension")
            if ref($record->{dimension})
                || ($record->{dimension} // '') !~ /\A(?:files|lines_each|bytes_each|lines_total|bytes_total)\z/;
        problem("$row_label previous/new values must be positive integers with new > previous")
            if !positive_integer($record->{previous}) || !positive_integer($record->{new})
                || $record->{new} <= $record->{previous};
        problem("$row_label decision must be a project-relative docs/decisions Markdown path")
            if ref($record->{decision}) || !relative_path_ok($record->{decision})
                || $record->{decision} !~ m{\Adocs/decisions/[0-9]{4}[-a-z0-9]*\.md\z};
        problem("$row_label has invalid approved_on date")
            if ref($record->{approved_on})
                || ($record->{approved_on} // '') !~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/;
    }
    return \@rows;
}

my ($inside_status) = run_git('rev-parse', '--is-inside-work-tree');
if ($inside_status != 0) {
    problem('project root is not a Git work tree');
    exit 1;
}

my $staged = git_output('diff', '--cached', '--name-only', '--', $registry, $authorities);
my $unstaged = git_output('diff', '--name-only', '--', $registry, $authorities);
my ($prior_registry, $current_registry, $prior_authorities, $current_authorities);
my ($mode, @added_decisions);

if ($staged ne '') {
    problem('controlled files differ between the staged index and worktree') if $unstaged ne '';
    $mode = 'staged';
    $prior_registry = read_blob("HEAD:$registry", 1);
    $current_registry = read_blob(":$registry", 1);
    $prior_authorities = read_blob("HEAD:$authorities", 0);
    $current_authorities = read_blob(":$authorities", 1);
    @added_decisions = grep { $_ ne '' } split /\n/,
        git_output('diff', '--cached', '--diff-filter=A', '--name-only', '--', 'docs/decisions');
} elsif ($unstaged ne '') {
    $mode = 'worktree';
    $prior_registry = read_blob("HEAD:$registry", 1);
    $current_registry = read_worktree_file($registry, 1);
    $prior_authorities = read_blob("HEAD:$authorities", 0);
    $current_authorities = read_worktree_file($authorities, 1);
    @added_decisions = grep { $_ ne '' } split /\n/,
        git_output('ls-files', '--others', '--exclude-standard', '--', 'docs/decisions');
} else {
    $mode = 'committed';
    my ($parent_status) = run_git('rev-parse', '--verify', 'HEAD^');
    my $prior_revision = $parent_status == 0 ? 'HEAD^' : undef;
    $prior_registry = defined($prior_revision) ? read_blob("$prior_revision:$registry", 0) : undef;
    $current_registry = read_blob("HEAD:$registry", 1);
    $prior_authorities = defined($prior_revision) ? read_blob("$prior_revision:$authorities", 0) : undef;
    $current_authorities = read_blob("HEAD:$authorities", 1);
    @added_decisions = defined($prior_revision)
        ? grep { $_ ne '' } split /\n/,
            git_output('diff', '--diff-filter=A', '--name-only', $prior_revision, 'HEAD', '--', 'docs/decisions')
        : ();
}

my $prior = registry_ceilings($prior_registry, 'prior surface registry', 1);
my $current = registry_ceilings($current_registry, 'current surface registry', 0);
my $old_authorities = authority_records($prior_authorities, 'prior ceiling-authority registry', 1);
my $all_authorities = authority_records($current_authorities, 'current ceiling-authority registry', 0);

for my $index (0 .. $#{$old_authorities}) {
    if ($index > $#{$all_authorities}
            || $json->encode($old_authorities->[$index]) ne $json->encode($all_authorities->[$index])) {
        problem('ceiling-authority registry is not append-only; prior authority changed or disappeared');
        last;
    }
}
my @new_authorities = $#{$all_authorities} >= $#{$old_authorities} + 1
    ? @{$all_authorities}[scalar(@{$old_authorities}) .. $#{$all_authorities}]
    : ();

my @dimensions = qw(files lines_each bytes_each lines_total bytes_total);
my @increases;
for my $surface (sort keys %{$current}) {
    next if !exists $prior->{$surface};
    if (defined($prior->{$surface}{baseline}) && defined($current->{$surface}{baseline})
            && $json->encode($prior->{$surface}{baseline}) ne $json->encode($current->{$surface}{baseline})) {
        problem("surface $surface changed its immutable transition baseline");
    }
    for my $dimension (@dimensions) {
        my $before = $prior->{$surface}{ceilings}{$dimension};
        my $after = $current->{$surface}{ceilings}{$dimension};
        next if !positive_integer($before) || !positive_integer($after) || $after <= $before;
        push @increases, {
            surface_id => $surface, dimension => $dimension,
            previous => 0 + $before, new => 0 + $after,
        };
    }
}

my %added_decision = map { $_ => 1 } @added_decisions;
my %used_authority;
for my $increase (@increases) {
    my @matches = grep {
        ($_->{surface_id} // '') eq $increase->{surface_id}
            && ($_->{dimension} // '') eq $increase->{dimension}
            && ($_->{previous} // -1) == $increase->{previous}
            && ($_->{new} // -1) == $increase->{new}
    } @new_authorities;
    if (@matches != 1) {
        problem(sprintf(
            'unauthorized enforcement-ceiling increase: %s %s %d -> %d requires exactly one new authority record',
            @{$increase}{qw(surface_id dimension previous new)},
        ));
        next;
    }
    my $authority = $matches[0];
    $used_authority{$authority->{authority_id}} = 1;
    my $decision = $authority->{decision};
    if (!$added_decision{$decision}) {
        problem("authority $authority->{authority_id} must cite a decision newly added with this increase: $decision");
        next;
    }
    my $decision_contents = $mode eq 'staged'
        ? read_blob(":$decision", 1)
        : $mode eq 'worktree'
            ? read_worktree_file($decision, 1)
            : read_blob("HEAD:$decision", 1);
    next if !defined $decision_contents;
    my @markers = (
        "- Ceiling authority: `$authority->{authority_id}`",
        "- Surface: `$authority->{surface_id}`",
        "- Dimension: `$authority->{dimension}`",
        "- Change: `$authority->{previous} -> $authority->{new}`",
    );
    for my $marker (@markers) {
        problem("authority $authority->{authority_id} decision lacks marker: $marker")
            if index($decision_contents, $marker) < 0;
    }
}

for my $authority (@new_authorities) {
    problem("new authority $authority->{authority_id} does not match a ceiling increase in the same change")
        if !$used_authority{$authority->{authority_id}};
}

if (!$fail) {
    print 'live-doc-ceiling-authority: all ceiling-change invariants hold ('
        . scalar(@increases) . " increase(s), mode $mode)\n";
}
exit($fail ? 1 : 0);
