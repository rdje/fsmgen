#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IO::Select;
use IPC::Open3 qw(open3);
use JSON::PP;
use Symbol qw(gensym);

my ($root_arg, $registry, $authorities, $source_digest, $index_digest, $help);
$registry = 'doctrine/live_document_size/surfaces.jsonl';
$authorities = 'doctrine/live_document_size/ceiling_increase_authorities.jsonl';
GetOptions(
    'root=s'        => \$root_arg,
    'registry=s'    => \$registry,
    'authorities=s' => \$authorities,
    'source-sha256=s' => \$source_digest,
    'index-sha256=s' => \$index_digest,
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
if (defined($source_digest) || defined($index_digest)) {
    if (!defined($root_arg) || $root eq $default_root
            || !defined($source_digest) || !defined($index_digest)
            || $source_digest !~ /\A[0-9a-f]{64}\z/ || $index_digest !~ /\A[0-9a-f]{64}\z/) {
        problem('supplied store fingerprints require an explicit other root and both independent digests');
        exit 1;
    }
}

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_live_document_ceiling_authority.pl [--root DIR]
       [--registry FILE] [--authorities FILE]
       [--source-sha256 HEX --index-sha256 HEX] (explicit supplied fixture only)
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
    local $ENV{GIT_NO_LAZY_FETCH} = 1;
    local $ENV{GIT_OPTIONAL_LOCKS} = 0;
    my $pid = open3(my $stdin, my $stdout, $stderr, 'git', '--no-replace-objects', '-C', $root, @args);
    close $stdin;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    return ($? == 0 ? 0 : 1, $out, $err);
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

sub bounded_registry_rows {
    my ($contents, $label, $allow_legacy) = @_;
    my @rows = @{parse_jsonl($contents, $label, $allow_legacy)};
    return \@rows if !@rows && $allow_legacy;
    problem("$label exceeds portable file bound 16777216")
        if defined($contents) && length($contents) > 16 * 1024 * 1024;
    problem("$label exceeds portable record-count bound 10000")
        if @rows > 10_001;
    for my $line (split /\n/, $contents // '') {
        problem("$label has a record exceeding portable bound 65536")
            if length($line) > 64 * 1024;
    }
    my $metadata = $rows[0];
    if (($metadata->{record_type} // '') ne 'registry') {
        if ($allow_legacy) {
            return \@rows;
        }
        problem("$label must begin with bounded schema-version 1 registry metadata");
        return \@rows;
    }
    shift @rows;
    my @keys = qw(record_type schema_version max_records max_bytes max_record_bytes);
    if ($allow_legacy && !exists($metadata->{max_record_bytes})) {
        return \@rows;
    }
    exact_keys($metadata, "$label metadata", @keys);
    problem("$label metadata has unsupported schema_version")
        if ref($metadata->{schema_version}) || ($metadata->{schema_version} // '') ne '1';
    for my $key (qw(max_records max_bytes max_record_bytes)) {
        problem("$label metadata has invalid positive $key")
            if !positive_integer($metadata->{$key});
    }
    if (positive_integer($metadata->{max_records})) {
        problem("$label record count exceeds max_records $metadata->{max_records}")
            if @rows > $metadata->{max_records};
        problem("$label max_records exceeds portable bound 10000")
            if $metadata->{max_records} > 10_000;
    }
    if (positive_integer($metadata->{max_bytes})) {
        problem("$label size exceeds max_bytes $metadata->{max_bytes}")
            if defined($contents) && length($contents) > $metadata->{max_bytes};
        problem("$label max_bytes exceeds portable bound 16777216")
            if $metadata->{max_bytes} > 16 * 1024 * 1024;
    }
    if (positive_integer($metadata->{max_record_bytes})) {
        problem("$label max_record_bytes exceeds portable bound 65536")
            if $metadata->{max_record_bytes} > 64 * 1024;
        problem("$label max_record_bytes exceeds its max_bytes")
            if positive_integer($metadata->{max_bytes})
                && $metadata->{max_record_bytes} > $metadata->{max_bytes};
        for my $line (split /\n/, $contents // '') {
            problem("$label has a record exceeding max_record_bytes $metadata->{max_record_bytes}")
                if length($line) > $metadata->{max_record_bytes};
        }
    }
    return \@rows;
}

sub registry_ceilings {
    my ($contents, $label, $allow_absent) = @_;
    my %by_surface;
    for my $record (@{bounded_registry_rows($contents, $label, $allow_absent)}) {
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
            lifecycle => $record->{lifecycle},
        };
    }
    return \%by_surface;
}

sub authority_records {
    my ($contents, $label, $allow_absent) = @_;
    my @rows = @{bounded_registry_rows($contents, $label, $allow_absent)};
    return [] if !@rows && $allow_absent;
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
            if ref($record->{schema_version}) || ($record->{schema_version} // '') ne '1';
        my $id = $record->{authority_id} // '';
        problem("$row_label has invalid authority_id")
            if ref($id) || length($id) > 128 || $id !~ /\A[A-Z][A-Z0-9_.-]*\z/;
        problem("$row_label repeats authority_id $id") if $ids{$id}++;
        problem("$row_label has invalid surface_id")
            if ref($record->{surface_id}) || length($record->{surface_id} // '') > 128
                || ($record->{surface_id} // '') !~ /\A[a-z][a-z0-9_]*\z/;
        problem("$row_label has invalid dimension")
            if ref($record->{dimension})
                || ($record->{dimension} // '') !~ /\A(?:files|lines_each|bytes_each|line_bytes_each|lines_total|bytes_total)\z/;
        problem("$row_label previous/new values must be positive integers with new > previous")
            if !positive_integer($record->{previous}) || !positive_integer($record->{new})
                || $record->{new} <= $record->{previous};
        problem("$row_label decision must be a project-relative docs/decisions Markdown path")
            if ref($record->{decision}) || length($record->{decision} // '') > 512
                || !relative_path_ok($record->{decision})
                || $record->{decision} !~ m{\Adocs/decisions/(?:[0-9]{4}[-a-z0-9]*|current/(?:continuity|language-api|verification)/[0-9]{4}-[a-z0-9]+(?:-[a-z0-9]+)*)\.md\z};
        problem("$row_label has invalid approved_on date")
            if ref($record->{approved_on})
                || ($record->{approved_on} // '') !~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/;
    }
    return \@rows;
}

sub catalog_change_product {
    my ($prior_revision, $current_selector, $prior_registry, $current_registry,
        $prior_authorities, $current_authorities, $paths) = @_;
    my $catalog_path = 'docs/decisions/current/catalog.json';
    my $prior_present = defined($prior_revision) && blob_exists("$prior_revision:$catalog_path");
    my $current_present = $current_selector eq 'worktree'
        ? (-e File::Spec->catfile($root, split m{/}, $catalog_path)
            || -l File::Spec->catfile($root, split m{/}, $catalog_path))
        : blob_exists(($current_selector eq 'index' ? ':' : "$current_selector:") . $catalog_path);
    if (!$prior_present && !$current_present) {
        problem('canonical authority requires an authenticated catalog store') if @{$paths};
        return {};
    }
    if (!defined $prior_revision) {
        problem('catalog continuity requires a selected predecessor commit');
        return {};
    }
    my @command = ('python3', '-B', File::Spec->catfile($default_root, 'scripts', 'decision_records.py'),
        '--root', $root, '--snapshot', $current_selector, '--prior-snapshot', $prior_revision,
        '--bind-file', $registry, '--bind-file', $authorities);
    push @command, ('--source-sha256', $source_digest, '--index-sha256', $index_digest)
        if defined $source_digest;
    push @command, ('check-continuity', @{$paths});
    my ($out, $err, $status, $pid, $stdout, $stderr) = ('', '', undef);
    my $ok = eval {
        $stderr = gensym;
        $pid = open3(my $stdin, $stdout, $stderr, @command);
        close $stdin;
        my $output_fd = fileno($stdout);
        my $streams = IO::Select->new($stdout, $stderr);
        while (my @ready = $streams->can_read) {
            for my $stream (@ready) {
                my $count = sysread($stream, my $chunk, 8192);
                die "cannot read authenticated reader output: $!\n" if !defined $count;
                if ($count == 0) {
                    $streams->remove($stream);
                    close $stream;
                    next;
                }
                if (fileno($stream) == $output_fd) {
                    $out .= $chunk;
                    die "authenticated reader output exceeds byte bound\n" if length($out) > 1_048_576;
                } else {
                    $err .= $chunk;
                    die "authenticated reader diagnostic exceeds byte bound\n" if length($err) > 65536;
                }
            }
        }
        waitpid($pid, 0);
        $status = $?;
        undef $pid;
        1;
    };
    if (defined $pid) {
        kill 'TERM', $pid;
        close $stdout if defined(fileno($stdout));
        close $stderr if defined(fileno($stderr));
        waitpid($pid, 0);
    }
    if (!$ok || $status != 0) {
        my $message = $ok ? $err : $@;
        $message =~ s/\s+\z//;
        problem('authenticated catalog change check failed: ' . $message);
        return {};
    }
    my $product = eval { decode_json($out) };
    if ($@ || length($out) > 1_048_576 || ref($product) ne 'HASH'
            || !JSON::PP::is_bool($product->{catalog}) || !$product->{catalog}
            || ref($product->{resolved}) ne 'ARRAY' || ref($product->{file_bindings}) ne 'HASH') {
        problem('authenticated catalog change product is malformed or unbounded');
        return {};
    }
    my %expected = ($registry => [$prior_registry, $current_registry],
                    $authorities => [$prior_authorities, $current_authorities]);
    for my $path (sort keys %expected) {
        my $binding = $product->{file_bindings}{$path};
        if (ref($binding) ne 'HASH') {
            problem("selected control-file binding is absent: $path");
            next;
        }
        for my $index (0, 1) {
            my $which = $index == 0 ? 'prior' : 'current';
            my $bytes = $expected{$path}[$index];
            my $digest = defined($bytes) ? sha256_hex($bytes) : undef;
            my $actual = $binding->{$which};
            problem("selected $which control bytes differ from authenticated snapshot: $path")
                if defined($digest) != defined($actual)
                    || defined($digest) && (ref($actual) || $digest ne $actual);
        }
    }
    my %requested = map { $_ => 1 } @{$paths};
    my %resolved;
    for my $row (@{$product->{resolved}}) {
        if (ref($row) ne 'HASH' || ref($row->{path}) || !defined($row->{path})
                || !$requested{$row->{path}} || exists($resolved{$row->{path}})
                || !JSON::PP::is_bool($row->{fresh_identity}) || !JSON::PP::is_bool($row->{new_file})
                || ref($row->{authority_markers}) ne 'ARRAY' || ref($row->{text}) || !defined($row->{text})) {
            problem('authenticated canonical authority binding is malformed');
            next;
        }
        $resolved{$row->{path}} = $row;
    }
    problem('authenticated canonical authority bindings are incomplete')
        if scalar(keys %resolved) != scalar(keys %requested);
    return \%resolved;
}

my ($inside_status) = run_git('rev-parse', '--is-inside-work-tree');
if ($inside_status != 0) {
    problem('project root is not a Git work tree');
    exit 1;
}

my @controlled = ($registry, $authorities, 'docs/decisions',
    'docs/audits/decision-store-transition-census.json',
    'docs/audits/decision-record-rollover-census-20260927.json',
    map { "scripts/$_.py" } qw(decision_records decision_catalog decision_store decision_store_git));
my $staged = git_output('diff', '--cached', '--name-only', '--', @controlled);
my $unstaged = git_output('diff', '--name-only', '--', @controlled)
    . git_output('ls-files', '--others', '--exclude-standard', '--', @controlled);
my ($prior_registry, $current_registry, $prior_authorities, $current_authorities);
my ($mode, @added_decisions);
my ($prior_revision, $current_selector);

if ($staged ne '') {
    problem('controlled files differ between the staged index and worktree') if $unstaged ne '';
    $mode = 'staged';
    $prior_revision = git_output('rev-parse', '--verify', 'HEAD');
    chomp $prior_revision;
    $current_selector = 'index';
    $prior_registry = read_blob("$prior_revision:$registry", 1);
    $current_registry = read_blob(":$registry", 1);
    $prior_authorities = read_blob("$prior_revision:$authorities", 0);
    $current_authorities = read_blob(":$authorities", 1);
    @added_decisions = grep { $_ ne '' } split /\n/,
        git_output('diff', '--cached', '--diff-filter=A', '--name-only', '--', 'docs/decisions');
} elsif ($unstaged ne '') {
    $mode = 'worktree';
    $prior_revision = git_output('rev-parse', '--verify', 'HEAD');
    chomp $prior_revision;
    $current_selector = 'worktree';
    $prior_registry = read_blob("$prior_revision:$registry", 1);
    $current_registry = read_worktree_file($registry, 1);
    $prior_authorities = read_blob("$prior_revision:$authorities", 0);
    $current_authorities = read_worktree_file($authorities, 1);
    @added_decisions = grep { $_ ne '' } split /\n/,
        git_output('ls-files', '--others', '--exclude-standard', '--', 'docs/decisions');
} else {
    $mode = 'committed';
    $current_selector = git_output('rev-parse', '--verify', 'HEAD');
    chomp $current_selector;
    my ($parent_status) = run_git('rev-parse', '--verify', "$current_selector^");
    $prior_revision = $parent_status == 0 ? git_output('rev-parse', '--verify', "$current_selector^") : undef;
    chomp $prior_revision if defined $prior_revision;
    $prior_registry = defined($prior_revision) ? read_blob("$prior_revision:$registry", 0) : undef;
    $current_registry = read_blob("$current_selector:$registry", 1);
    $prior_authorities = defined($prior_revision) ? read_blob("$prior_revision:$authorities", 0) : undef;
    $current_authorities = read_blob("$current_selector:$authorities", 1);
    @added_decisions = defined($prior_revision)
        ? grep { $_ ne '' } split /\n/,
            git_output('diff', '--diff-filter=A', '--name-only', $prior_revision, $current_selector, '--', 'docs/decisions')
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

my @dimensions = qw(files lines_each bytes_each line_bytes_each lines_total bytes_total);
my @increases;
for my $surface (sort keys %{$current}) {
    next if !exists $prior->{$surface};
    my $maintained_reference_migration =
        ($prior->{$surface}{lifecycle} // '') eq 'partitioned_canonical'
        && ($current->{$surface}{lifecycle} // '') eq 'maintained_reference';
    if (!$maintained_reference_migration
            && defined($prior->{$surface}{baseline}) && defined($current->{$surface}{baseline})) {
        my %keys = map { $_ => 1 }
            (keys %{$prior->{$surface}{baseline}}, keys %{$current->{$surface}{baseline}});
        for my $key (sort keys %keys) {
            next if $key eq 'line_bytes_each'
                && !exists($prior->{$surface}{baseline}{$key})
                && exists($current->{$surface}{baseline}{$key});
            my $before = $prior->{$surface}{baseline}{$key};
            my $after = $current->{$surface}{baseline}{$key};
            my $shape_changed = !defined($before) != !defined($after);
            my $invalid_value = defined($before) && defined($after)
                && (ref($before) || ref($after)
                    || $before !~ /\A[0-9]+\z/ || $after !~ /\A[0-9]+\z/);
            my $increased = defined($before) && defined($after)
                && !$invalid_value && $after > $before;
            if ($shape_changed || $invalid_value || $increased) {
                problem("surface $surface increased or reshaped its transition baseline");
                last;
            }
        }
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

my %canonical_request = map { $_->{decision} => 1 }
    grep { !ref($_->{decision}) && ($_->{decision} // '') =~ m{\Adocs/decisions/current/} }
    @new_authorities;
my $canonical = $fail ? {} : catalog_change_product(
    $prior_revision, $current_selector, $prior_registry, $current_registry,
    $prior_authorities, $current_authorities, [sort keys %canonical_request]);

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
    my $binding = $canonical->{$decision};
    my $is_canonical = ($decision // '') =~ m{\Adocs/decisions/current/};
    if ($is_canonical && (!defined($binding) || !$binding->{fresh_identity} || !$binding->{new_file})) {
        problem("authority $authority->{authority_id} requires a fresh canonical ID and file in the selected change: $decision");
        next;
    }
    if (!$is_canonical && !$added_decision{$decision}) {
        problem("authority $authority->{authority_id} must cite a decision newly added with this increase: $decision");
        next;
    }
    my $decision_contents = $is_canonical ? $binding->{text} : $mode eq 'staged'
        ? read_blob(":$decision", 1)
        : $mode eq 'worktree'
            ? read_worktree_file($decision, 1)
            : read_blob("$current_selector:$decision", 1);
    next if !defined $decision_contents;
    my @markers = (
        "- Ceiling authority: `$authority->{authority_id}`",
        "- Surface: `$authority->{surface_id}`",
        "- Dimension: `$authority->{dimension}`",
        "- Change: `$authority->{previous} -> $authority->{new}`",
    );
    my %canonical_marker = $is_canonical ? map { $_ => 1 } @{$binding->{authority_markers}} : ();
    for my $marker (@markers) {
        problem("authority $authority->{authority_id} decision lacks marker: $marker")
            if $is_canonical ? !$canonical_marker{$marker} : index($decision_contents, $marker) < 0;
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
