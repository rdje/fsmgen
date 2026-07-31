#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Cmd qw(run);
use JSON::PP;

my $root;
my $help;
GetOptions(
    'root=s' => \$root,
    'help|h' => \$help,
) or usage(2);
usage(0) if $help;

$root //= File::Spec->catdir(dirname(__FILE__), '..');
$root = abs_path($root);
fail("repository root does not exist") if !defined $root || !-d $root;

my $index_relative = 'docs/TASK_TREE.md';
my $index_path = local_path($index_relative);
my $index = read_file($index_path, $index_relative);

my @active_trees;
my %seen_index_tree;
my $active_index_section =
    extract_section($index, 'Active Task Trees') // $index;
for my $line (split /\n/, $active_index_section) {
    next if $line !~ /^\|\s*`([^`]+)`\s*\|\s*`active`\s*\|/;
    my $tree_id = $1;
    my ($task_path) = $line =~ m{\((docs/tasks/[^)]+\.md)\)};
    fail("$index_relative: active tree $tree_id has no docs/tasks/*.md link")
        if !defined $task_path;
    fail("$index_relative: active tree $tree_id is listed more than once")
        if $seen_index_tree{$tree_id}++;
    fail("$index_relative: active tree $tree_id uses unsafe task path $task_path")
        if !safe_relative_path($task_path);
    push @active_trees, [$tree_id, $task_path];
}

my %valid_status = map { $_ => 1 } qw(
    proposed active pending in_progress blocked done deferred superseded
);
my %terminal_status = map { $_ => 1 } qw(done deferred superseded);
my @errors;
my $total_nodes = 0;
my $total_segments = 0;
my $total_compact_terminals = 0;
my $total_index_archives = 0;
my $total_migrations = 0;
my $retention_registry_relative =
    'doctrine/live_document_size/version_retention_contracts.jsonl';
my %retention_contracts;
my $retention_contracts_loaded = 0;

my @index_archive_fields =
    $index =~ /^- Completed-history manifest: `([^`]+)`\s*$/mg;
if (@index_archive_fields > 1) {
    push @errors,
        "$index_relative: must have at most one Completed-history manifest field";
}
elsif (@index_archive_fields == 1) {
    $total_index_archives = load_index_archive_manifest(
        manifest => $index_archive_fields[0],
        index    => $index,
    );
}

for my $entry (@active_trees) {
    my ($tree_id, $task_relative) = @{$entry};
    my $task_path = local_path($task_relative);
    if (!-f $task_path) {
        push @errors, "$task_relative: active task file is missing";
        next;
    }

    my $task = read_file($task_path, $task_relative);
    my $section = extract_section($task, 'Task Tree');
    if (!defined $section) {
        push @errors, "$task_relative: missing ## Task Tree section";
        next;
    }

    my @live_nodes = parse_nodes($section, $task_relative, 'live');
    if (!@live_nodes) {
        push @errors, "$task_relative: ## Task Tree contains no nodes";
        next;
    }

    my @manifest_fields =
        $task =~ /^- Segment manifest: `([^`]+)`\s*$/mg;
    if (@manifest_fields > 1) {
        push @errors, "$task_relative: must have at most one Segment manifest field";
    }

    my (@segment_nodes, @segment_paths);
    if (@manifest_fields == 1) {
        my ($nodes, $segments, $paths) = load_segment_manifest(
            tree_id       => $tree_id,
            task_relative => $task_relative,
            manifest      => $manifest_fields[0],
        );
        @segment_nodes = @{$nodes};
        @segment_paths = @{$paths};
        $total_segments += $segments;
    }

    my @migration_fields =
        $task =~ /^- Migration manifest: `([^`]+)`\s*$/mg;
    if (@migration_fields > 1) {
        push @errors, "$task_relative: must have at most one Migration manifest field";
    }
    elsif (@migration_fields == 1) {
        $total_migrations += load_migration_manifest(
            tree_id          => $tree_id,
            task_relative    => $task_relative,
            task_raw         => $task,
            manifest         => $migration_fields[0],
            segment_manifest => $manifest_fields[0],
            segment_nodes    => \@segment_nodes,
            segment_paths    => \@segment_paths,
        );
    }

    my @nodes = (@live_nodes, @segment_nodes);
    $total_nodes += scalar @nodes;
    validate_tree(
        tree_id       => $tree_id,
        task_relative => $task_relative,
        live_nodes    => \@live_nodes,
        nodes         => \@nodes,
    );
}

if (@errors) {
    print STDERR "[task-tree-integrity] FAIL: $_\n" for @errors;
    print STDERR "[task-tree-integrity] active task-tree invariants failed\n";
    exit 1;
}

printf "[task-tree-integrity] all active task-tree invariants hold "
    . "(trees=%d, nodes=%d, segments=%d, compact_terminals=%d, "
    . "index_archives=%d, migrations=%d)\n",
    scalar(@active_trees), $total_nodes, $total_segments,
    $total_compact_terminals, $total_index_archives, $total_migrations;
exit 0;

sub load_index_archive_manifest {
    my (%args) = @_;
    my $manifest_relative = $args{manifest};
    my $current_index = $args{index};

    if (!safe_relative_path($manifest_relative)
        || $manifest_relative !~ /\.jsonl\z/) {
        push @errors,
            "$index_relative: unsafe or non-JSONL completed-history manifest "
                . $manifest_relative;
        return 0;
    }
    my $manifest_path = checked_local_file(
        $manifest_relative, "$index_relative: completed-history manifest"
    );
    return 0 if !defined $manifest_path;

    my $raw = read_file($manifest_path, $manifest_relative);
    my @records = decode_jsonl($raw, $manifest_relative);
    return 0 if !@records;

    my $registry = shift @records;
    check_keys(
        $registry,
        [qw(record_type schema_version max_records max_bytes)],
        [],
        "$manifest_relative: registry record",
    );
    check_equal($registry->{record_type}, 'registry',
        "$manifest_relative: registry record_type");
    check_integer($registry->{schema_version}, 1, 1,
        "$manifest_relative: registry schema_version");
    check_integer($registry->{max_records}, 1, undef,
        "$manifest_relative: registry max_records");
    check_integer($registry->{max_bytes}, 1, undef,
        "$manifest_relative: registry max_bytes");
    if (is_positive_integer($registry->{max_records})
        && @records > $registry->{max_records}) {
        push @errors,
            "$manifest_relative: archive record count " . scalar(@records)
                . " exceeds max_records $registry->{max_records}";
    }
    if (is_positive_integer($registry->{max_bytes})
        && length($raw) > $registry->{max_bytes}) {
        push @errors,
            "$manifest_relative: size " . length($raw)
                . " exceeds max_bytes $registry->{max_bytes}";
    }
    if (!@records) {
        push @errors,
            "$manifest_relative: contains no completed-history archive records";
        return 0;
    }

    my %seen_archive_id;
    my $record_number = 1;
    for my $record (@records) {
        $record_number++;
        my $where = "$manifest_relative: record $record_number";
        check_keys(
            $record,
            [qw(record_type schema_version archive_id revision path sha256
                lines bytes terminal_rows unique_tree_ids statuses
                current_pointer sealed_on retention_contract)],
            [],
            $where,
        );
        check_equal($record->{record_type}, 'version_object',
            "$where record_type");
        check_integer($record->{schema_version}, 1, 1,
            "$where schema_version");

        my $archive_id = $record->{archive_id};
        if (!defined $archive_id || ref $archive_id
            || $archive_id !~ /\A[a-z][a-z0-9_.-]*\z/) {
            push @errors, "$where has invalid archive_id";
        }
        elsif ($seen_archive_id{$archive_id}++) {
            push @errors, "$where duplicates archive_id $archive_id";
        }

        my $revision = $record->{revision};
        if (!defined $revision || ref $revision
            || $revision !~ /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) {
            push @errors, "$where has invalid exact revision";
            next;
        }
        my $path = $record->{path};
        my $current_pointer = $record->{current_pointer};
        for my $path_field (
            ['path', $path], ['current_pointer', $current_pointer]
        ) {
            my ($name, $value) = @{$path_field};
            push @errors, "$where has unsafe $name"
                if !defined $value || ref $value
                    || !safe_relative_path($value) || $value !~ /\.md\z/;
        }
        next if !defined $path || ref $path || !safe_relative_path($path);
        if ($path ne $index_relative) {
            push @errors, "$where path must identify $index_relative";
        }
        if (defined $current_pointer && !ref $current_pointer
            && $current_pointer ne $index_relative) {
            push @errors,
                "$where current_pointer must identify $index_relative";
        }

        my $digest = $record->{sha256};
        push @errors, "$where has invalid sha256"
            if !defined $digest || ref $digest
                || $digest !~ /\A[0-9a-f]{64}\z/;
        for my $field (qw(lines bytes terminal_rows unique_tree_ids)) {
            check_integer($record->{$field}, 1, undef, "$where $field");
        }
        my $statuses = $record->{statuses};
        if (ref($statuses) ne 'ARRAY'
            || join(',', sort @{$statuses}) ne 'deferred,done,superseded') {
            push @errors,
                "$where statuses must be exactly done, deferred, superseded";
        }
        my $sealed_on = $record->{sealed_on};
        push @errors, "$where has invalid sealed_on date"
            if !defined $sealed_on || ref $sealed_on
                || $sealed_on !~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/;

        my $source = retrieve_version_object(
            $revision, $path, "$where completed-history source",
            $record->{retention_contract},
        );
        next if !defined $source;
        if (defined $digest && !ref $digest
            && $digest =~ /\A[0-9a-f]{64}\z/
            && sha256_hex($source) ne $digest) {
            push @errors, "$where completed-history digest mismatch";
        }
        if (is_positive_integer($record->{lines})
            && line_count($source) != $record->{lines}) {
            push @errors,
                "$where completed-history line count $record->{lines} does not "
                    . "match retrieved count " . line_count($source);
        }
        if (is_positive_integer($record->{bytes})
            && length($source) != $record->{bytes}) {
            push @errors,
                "$where completed-history byte count $record->{bytes} does not "
                    . "match retrieved count " . length($source);
        }

        my @terminal_rows = terminal_index_rows($source, $where);
        my %tree_ids;
        for my $row (@terminal_rows) {
            if ($tree_ids{$row->{tree_id}}++) {
                push @errors,
                    "$where completed-history duplicates tree ID $row->{tree_id}";
            }
        }
        if (is_positive_integer($record->{terminal_rows})
            && @terminal_rows != $record->{terminal_rows}) {
            push @errors,
                "$where terminal_rows $record->{terminal_rows} does not match "
                    . scalar(@terminal_rows) . " retrieved rows";
        }
        if (is_positive_integer($record->{unique_tree_ids})
            && scalar(keys %tree_ids) != $record->{unique_tree_ids}) {
            push @errors,
                "$where unique_tree_ids $record->{unique_tree_ids} does not match "
                    . scalar(keys %tree_ids) . " retrieved IDs";
        }

        my ($ok, undef, undef, $stdout, $stderr) = run(
            command => [
                'git', '-C', $root, 'ls-tree', '-r', '--name-only',
                $revision, '--', 'docs/tasks'
            ],
        );
        if (!$ok) {
            my $detail = join('', @{$stderr || []});
            $detail =~ s/\s+/ /g;
            push @errors,
                "$where cannot enumerate exact task files"
                    . ($detail ne '' ? " ($detail)" : '');
        }
        else {
            my %source_paths = map { $_ => 1 }
                grep { $_ ne '' } split /\n/, join('', @{$stdout || []});
            for my $row (@terminal_rows) {
                push @errors,
                    "$where archived tree $row->{tree_id} cannot retrieve "
                        . "$revision:$row->{task_path}"
                    if !$source_paths{$row->{task_path}};
                checked_local_file(
                    $row->{task_path},
                    "$where current task $row->{tree_id}",
                );
            }
        }
    }

    validate_live_index_views($current_index, $index_relative);
    return scalar @records;
}

sub terminal_index_rows {
    my ($contents, $where) = @_;
    my @rows;
    for my $heading ('Active Task Trees', 'Completed Task Trees') {
        my $section = extract_section($contents, $heading);
        if (!defined $section) {
            push @errors, "$where source is missing ## $heading";
            next;
        }
        for my $line (split /\n/, $section) {
            next if $line !~ /^\|\s*`([^`]+)`\s*\|\s*`
                (done|deferred|superseded)`\s*\|/x;
            my ($tree_id, $status) = ($1, $2);
            my ($task_path) =
                $line =~ m{\((docs/tasks/[^)]+\.md)\)\s*\|\s*\z};
            if (!defined $task_path || !safe_relative_path($task_path)) {
                push @errors,
                    "$where archived tree $tree_id has unsafe or missing task link";
                next;
            }
            push @rows, {
                tree_id => $tree_id,
                status => $status,
                task_path => $task_path,
            };
        }
    }
    return @rows;
}

sub validate_live_index_views {
    my ($contents, $where) = @_;
    for my $view (
        ['Active Task Trees', 'active'],
        ['Proposed Task Trees', 'proposed'],
    ) {
        my ($heading, $expected) = @{$view};
        my $section = extract_section($contents, $heading);
        if (!defined $section) {
            push @errors, "$where is missing ## $heading";
            next;
        }
        for my $line (split /\n/, $section) {
            next if $line !~ /^\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|/;
            my ($tree_id, $status) = ($1, $2);
            push @errors,
                "$where $heading row $tree_id has status $status, expected $expected"
                if $status ne $expected;
        }
    }
    my $completed = extract_section($contents, 'Completed Task Trees');
    if (!defined $completed) {
        push @errors, "$where is missing ## Completed Task Trees";
    }
    elsif ($completed =~ /^\|\s*`([^`]+)`\s*\|/m) {
        push @errors,
            "$where Completed Task Trees retains live row $1 instead of query-first history";
    }
}

sub load_segment_manifest {
    my (%args) = @_;
    my $tree_id = $args{tree_id};
    my $task_relative = $args{task_relative};
    my $manifest_relative = $args{manifest};

    if (!safe_relative_path($manifest_relative)
        || $manifest_relative !~ /\.jsonl\z/) {
        push @errors,
            "$task_relative: unsafe or non-JSONL segment manifest $manifest_relative";
        return ([], 0, []);
    }
    my $manifest_path = checked_local_file(
        $manifest_relative, "$task_relative: segment manifest"
    );
    return ([], 0, []) if !defined $manifest_path;

    my $raw = read_file($manifest_path, $manifest_relative);
    my @records = decode_jsonl($raw, $manifest_relative);
    return ([], 0, []) if !@records;

    my $registry = shift @records;
    check_keys(
        $registry,
        [qw(record_type schema_version tree_id max_records max_bytes
            max_segment_nodes max_segment_lines max_segment_bytes
            max_total_nodes max_total_lines max_total_bytes)],
        [],
        "$manifest_relative: registry record",
    );
    check_equal($registry->{record_type}, 'registry',
        "$manifest_relative: registry record_type");
    check_integer($registry->{schema_version}, 1, 1,
        "$manifest_relative: registry schema_version");
    check_equal($registry->{tree_id}, $tree_id,
        "$manifest_relative: registry tree_id");
    check_integer($registry->{max_records}, 1, undef,
        "$manifest_relative: registry max_records");
    check_integer($registry->{max_bytes}, 1, undef,
        "$manifest_relative: registry max_bytes");
    for my $dimension (qw(nodes lines bytes)) {
        check_integer(
            $registry->{"max_segment_$dimension"}, 1, undef,
            "$manifest_relative: registry max_segment_$dimension"
        );
        check_integer(
            $registry->{"max_total_$dimension"}, 1, undef,
            "$manifest_relative: registry max_total_$dimension"
        );
        if (is_positive_integer($registry->{"max_segment_$dimension"})
            && is_positive_integer($registry->{"max_total_$dimension"})
            && $registry->{"max_segment_$dimension"}
                > $registry->{"max_total_$dimension"}) {
            push @errors,
                "$manifest_relative: max_segment_$dimension exceeds max_total_$dimension";
        }
    }

    if (is_positive_integer($registry->{max_records})
        && @records > $registry->{max_records}) {
        push @errors,
            "$manifest_relative: segment record count " . scalar(@records)
                . " exceeds max_records $registry->{max_records}";
    }
    if (is_positive_integer($registry->{max_bytes})
        && length($raw) > $registry->{max_bytes}) {
        push @errors,
            "$manifest_relative: size " . length($raw)
                . " exceeds max_bytes $registry->{max_bytes}";
    }

    my @nodes;
    my %seen_segment_id;
    my %seen_segment_path;
    my %seen_root_id;
    my $record_number = 1;
    my %totals = (nodes => 0, lines => 0, bytes => 0);
    for my $record (@records) {
        $record_number++;
        my $where = "$manifest_relative: record $record_number";
        check_keys(
            $record,
            [qw(record_type schema_version segment_id path root_ids node_count sha256 source_revision source_path retention_contract)],
            [],
            $where,
        );
        check_equal($record->{record_type}, 'segment', "$where record_type");
        check_integer($record->{schema_version}, 1, 1,
            "$where schema_version");

        my $segment_id = $record->{segment_id};
        if (!defined $segment_id || ref $segment_id
            || $segment_id !~ /\A[A-Za-z0-9][A-Za-z0-9_.-]*\z/) {
            push @errors, "$where has invalid segment_id";
        }
        elsif ($seen_segment_id{$segment_id}++) {
            push @errors, "$where duplicates segment_id $segment_id";
        }

        my $segment_relative = $record->{path};
        if (!defined $segment_relative || ref $segment_relative
            || !safe_relative_path($segment_relative)
            || $segment_relative !~ /\.md\z/) {
            push @errors, "$where has unsafe or non-Markdown segment path";
            next;
        }
        if ($seen_segment_path{$segment_relative}++) {
            push @errors, "$where duplicates segment path $segment_relative";
        }

        my $digest = $record->{sha256};
        if (!defined $digest || ref $digest || $digest !~ /\A[0-9a-f]{64}\z/) {
            push @errors, "$where has invalid sha256";
            next;
        }
        if (basename($segment_relative) ne "$digest.md") {
            push @errors,
                "$where segment path basename must be the content digest $digest.md";
        }

        my $segment_path = checked_local_file(
            $segment_relative, "$where segment"
        );
        next if !defined $segment_path;
        my $segment_raw = read_file($segment_path, $segment_relative);
        my $segment_lines = line_count($segment_raw);
        my $actual_digest = sha256_hex($segment_raw);
        if ($actual_digest ne $digest) {
            push @errors,
                "$where sha256 mismatch for $segment_relative "
                    . "(declared $digest, actual $actual_digest)";
        }

        my $segment_section = extract_section($segment_raw, 'Task Tree Segment');
        if (!defined $segment_section) {
            push @errors,
                "$segment_relative: missing ## Task Tree Segment section";
            next;
        }
        my @part_nodes = parse_nodes(
            $segment_section, $segment_relative, 'segment'
        );
        if (!@part_nodes) {
            push @errors,
                "$segment_relative: ## Task Tree Segment contains no nodes";
            next;
        }

        my %measured = (
            nodes => scalar(@part_nodes),
            lines => $segment_lines,
            bytes => length($segment_raw),
        );
        for my $dimension (qw(nodes lines bytes)) {
            my $per_limit = $registry->{"max_segment_$dimension"};
            if (is_positive_integer($per_limit)
                && $measured{$dimension} > $per_limit) {
                push @errors,
                    "$where $dimension $measured{$dimension} exceeds "
                        . "max_segment_$dimension $per_limit";
            }
            $totals{$dimension} += $measured{$dimension};
        }

        check_integer($record->{node_count}, 1, undef, "$where node_count");
        if (is_positive_integer($record->{node_count})
            && $record->{node_count} != @part_nodes) {
            push @errors,
                "$where node_count $record->{node_count} does not match "
                    . scalar(@part_nodes) . " segment nodes";
        }

        my $root_ids = $record->{root_ids};
        if (ref($root_ids) ne 'ARRAY' || !@{$root_ids}) {
            push @errors, "$where root_ids must be a non-empty array";
            next;
        }
        my %part_by_id = map { $_->{id} => $_ } @part_nodes;
        report_duplicate_ids(\@part_nodes, "$where segment");
        my %covered;
        my %local_root;
        for my $root_id (@{$root_ids}) {
            if (!defined $root_id || ref $root_id
                || $root_id !~ /^\Q$tree_id\E(?:\.[1-9][0-9]*)+\z/) {
                push @errors, "$where has invalid root_id";
                next;
            }
            if ($local_root{$root_id}++ || $seen_root_id{$root_id}++) {
                push @errors, "$where duplicates sealed root_id $root_id";
            }
            my @overlap = grep {
                $_ ne $root_id
                    && ($_ =~ /^\Q$root_id\E\./ || $root_id =~ /^\Q$_\E\./)
            } keys %local_root;
            push @errors,
                "$where has overlapping sealed root_ids $root_id and "
                    . join(', ', sort_node_ids(@overlap))
                if @overlap;
            if (!exists $part_by_id{$root_id}) {
                push @errors,
                    "$where root_id $root_id is absent from $segment_relative";
            }
            for my $node_id (keys %part_by_id) {
                $covered{$node_id} = 1
                    if $node_id eq $root_id || $node_id =~ /^\Q$root_id\E\./;
            }
        }
        my @uncovered = sort_node_ids(
            grep { !$covered{$_} } keys %part_by_id
        );
        push @errors,
            "$where has nodes outside root_ids: " . join(', ', @uncovered)
            if @uncovered;

        my $source_revision = $record->{source_revision};
        my $source_path = $record->{source_path};
        if (!defined $source_revision || ref $source_revision
            || $source_revision !~ /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) {
            push @errors, "$where has invalid exact source_revision";
            next;
        }
        if (!defined $source_path || ref $source_path
            || !safe_relative_path($source_path)
            || $source_path !~ /\.md\z/) {
            push @errors, "$where has unsafe or non-Markdown source_path";
            next;
        }
        my $source_raw = retrieve_version_object(
            $source_revision, $source_path, "$where source",
            $record->{retention_contract},
        );
        next if !defined $source_raw;
        my $source_section = extract_section($source_raw, 'Task Tree');
        if (!defined $source_section) {
            push @errors,
                "$where source $source_revision:$source_path has no ## Task Tree section";
            next;
        }
        my @source_nodes = parse_nodes(
            $source_section, "$source_revision:$source_path", 'retrieved'
        );
        report_duplicate_ids(
            \@source_nodes, "$where exact source $source_revision:$source_path"
        );
        my %source_by_id = map { $_->{id} => $_ } @source_nodes;
        if (!exists $source_by_id{$tree_id}) {
            push @errors,
                "$where exact source does not contain tree root $tree_id";
        }

        for my $node (@part_nodes) {
            my $node_id = $node->{id};
            if (!exists $source_by_id{$node_id}) {
                push @errors,
                    "$where segment node $node_id is absent from exact source";
                next;
            }
            if (canonical_node($node) ne canonical_node($source_by_id{$node_id})) {
                push @errors,
                    "$where segment node $node_id differs from exact source";
            }
            my $status = one_field($node, 'Status');
            if (!defined $status || !$terminal_status{$status}) {
                push @errors,
                    "$where segment node $node_id is not terminal";
            }
        }
        for my $root_id (@{$root_ids}) {
            next if !defined $root_id || ref $root_id;
            my @source_subtree = grep {
                $_ eq $root_id || /^\Q$root_id\E\./
            } keys %source_by_id;
            my @missing = sort_node_ids(
                grep { !exists $part_by_id{$_} } @source_subtree
            );
            push @errors,
                "$where sealed root $root_id omits exact-source descendants "
                    . join(', ', @missing)
                if @missing;
        }
        push @nodes, @part_nodes;
    }

    for my $dimension (qw(nodes lines bytes)) {
        my $total_limit = $registry->{"max_total_$dimension"};
        if (is_positive_integer($total_limit)
            && $totals{$dimension} > $total_limit) {
            push @errors,
                "$manifest_relative: total segment $dimension $totals{$dimension} "
                    . "exceeds max_total_$dimension $total_limit";
        }
    }

    my @paths = ($manifest_relative, sort keys %seen_segment_path);
    return (\@nodes, scalar @records, \@paths);
}

sub load_migration_manifest {
    my (%args) = @_;
    my $tree_id = $args{tree_id};
    my $task_relative = $args{task_relative};
    my $manifest_relative = $args{manifest};

    if (!safe_relative_path($manifest_relative)
        || $manifest_relative !~ /\.jsonl\z/) {
        push @errors,
            "$task_relative: unsafe or non-JSONL migration manifest $manifest_relative";
        return 0;
    }
    my $manifest_path = checked_local_file(
        $manifest_relative, "$task_relative: migration manifest"
    );
    return 0 if !defined $manifest_path;
    my $raw = read_file($manifest_path, $manifest_relative);
    my @records = decode_jsonl($raw, $manifest_relative);
    return 0 if !@records;

    my $registry = shift @records;
    check_keys(
        $registry,
        [qw(record_type schema_version tree_id max_records max_bytes)],
        [], "$manifest_relative: registry record",
    );
    check_equal($registry->{record_type}, 'registry',
        "$manifest_relative: registry record_type");
    check_integer($registry->{schema_version}, 1, 1,
        "$manifest_relative: registry schema_version");
    check_equal($registry->{tree_id}, $tree_id,
        "$manifest_relative: registry tree_id");
    check_integer($registry->{max_records}, 1, undef,
        "$manifest_relative: registry max_records");
    check_integer($registry->{max_bytes}, 1, undef,
        "$manifest_relative: registry max_bytes");
    if (is_positive_integer($registry->{max_records})
        && @records > $registry->{max_records}) {
        push @errors,
            "$manifest_relative: migration record count " . scalar(@records)
                . " exceeds max_records $registry->{max_records}";
    }
    if (is_positive_integer($registry->{max_bytes})
        && length($raw) > $registry->{max_bytes}) {
        push @errors,
            "$manifest_relative: size " . length($raw)
                . " exceeds max_bytes $registry->{max_bytes}";
    }
    if (@records != 1) {
        push @errors,
            "$manifest_relative: must contain exactly one migration record";
        return scalar @records;
    }

    my $record = $records[0];
    my $where = "$manifest_relative: record 2";
    check_keys(
        $record,
        [qw(record_type schema_version migration_id outcome source_revision
            source_path source_sha256 source_lines source_bytes
            retention_contract semantic_manifest authoritative_nodes
            working_set_paths working_set_lines working_set_bytes
            product_relationship loss_residue_kind loss_residue_path
            loss_residue_sha256 loss_residue_lines loss_residue_bytes)],
        [], $where,
    );
    check_equal($record->{record_type}, 'migration', "$where record_type");
    check_integer($record->{schema_version}, 1, 1, "$where schema_version");
    my $migration_id = $record->{migration_id};
    push @errors, "$where has invalid migration_id"
        if !defined $migration_id || ref $migration_id
            || $migration_id !~ /\A[a-z][a-z0-9_.-]*\z/;
    check_equal($record->{outcome}, 're-form', "$where outcome");

    my $source_revision = $record->{source_revision};
    my $source_path = $record->{source_path};
    if (!defined $source_revision || ref $source_revision
        || $source_revision !~ /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) {
        push @errors, "$where has invalid exact source_revision";
    }
    if (!defined $source_path || ref $source_path
        || !safe_relative_path($source_path) || $source_path !~ /\.md\z/) {
        push @errors, "$where has unsafe or non-Markdown source_path";
    }
    my $source_sha = $record->{source_sha256};
    push @errors, "$where has invalid source_sha256"
        if !defined $source_sha || ref $source_sha
            || $source_sha !~ /\A[0-9a-f]{64}\z/;
    check_integer($record->{source_lines}, 1, undef, "$where source_lines");
    check_integer($record->{source_bytes}, 1, undef, "$where source_bytes");

    if (defined $source_revision && !ref $source_revision
        && $source_revision =~ /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/
        && defined $source_path && !ref $source_path
        && safe_relative_path($source_path)) {
        my $source = retrieve_version_object(
            $source_revision, $source_path, "$where complete source",
            $record->{retention_contract},
        );
        if (defined $source) {
            push @errors, "$where complete-source digest mismatch"
                if defined $source_sha && !ref $source_sha
                    && $source_sha =~ /\A[0-9a-f]{64}\z/
                    && sha256_hex($source) ne $source_sha;
            push @errors,
                "$where source_lines $record->{source_lines} does not match retrieved count "
                    . line_count($source)
                if is_positive_integer($record->{source_lines})
                    && line_count($source) != $record->{source_lines};
            push @errors,
                "$where source_bytes $record->{source_bytes} does not match retrieved count "
                    . length($source)
                if is_positive_integer($record->{source_bytes})
                    && length($source) != $record->{source_bytes};
        }
    }

    my $semantic_manifest = $record->{semantic_manifest};
    if (!defined $args{segment_manifest}) {
        push @errors, "$where semantic closure requires a Segment manifest";
    }
    elsif (!defined $semantic_manifest || ref $semantic_manifest
        || $semantic_manifest ne $args{segment_manifest}) {
        push @errors,
            "$where semantic_manifest must match $args{segment_manifest}";
    }
    check_integer($record->{authoritative_nodes}, 1, undef,
        "$where authoritative_nodes");
    if (is_positive_integer($record->{authoritative_nodes})
        && $record->{authoritative_nodes} != @{$args{segment_nodes}}) {
        push @errors,
            "$where authoritative_nodes $record->{authoritative_nodes} does not "
                . "match sealed semantic node count " . scalar(@{$args{segment_nodes}});
    }

    my @expected_paths = ($task_relative, @{$args{segment_paths}});
    my $declared_paths = $record->{working_set_paths};
    if (ref($declared_paths) ne 'ARRAY' || !@{$declared_paths}) {
        push @errors, "$where working_set_paths must be a non-empty array";
    }
    else {
        my %seen;
        my @unsafe = grep {
            !defined $_ || ref $_ || !safe_relative_path($_) || $seen{$_}++
        } @{$declared_paths};
        push @errors, "$where working_set_paths contains unsafe or duplicate paths"
            if @unsafe;
        my $expected = join("\0", sort @expected_paths);
        my $declared = join("\0", sort @{$declared_paths});
        push @errors,
            "$where working_set_paths does not exactly match the live root, segment manifest, and segment files"
            if $declared ne $expected;

        my ($lines, $bytes) = (0, 0);
        for my $path (@{$declared_paths}) {
            next if !defined $path || ref $path || !safe_relative_path($path);
            my $local = checked_local_file($path, "$where working-set path");
            next if !defined $local;
            my $contents = read_file($local, $path);
            $lines += line_count($contents);
            $bytes += length($contents);
        }
        check_integer($record->{working_set_lines}, 1, undef,
            "$where working_set_lines");
        check_integer($record->{working_set_bytes}, 1, undef,
            "$where working_set_bytes");
        push @errors,
            "$where working_set_lines $record->{working_set_lines} does not match measured count $lines"
            if is_positive_integer($record->{working_set_lines})
                && $record->{working_set_lines} != $lines;
        push @errors,
            "$where working_set_bytes $record->{working_set_bytes} does not match measured count $bytes"
            if is_positive_integer($record->{working_set_bytes})
                && $record->{working_set_bytes} != $bytes;
    }

    check_equal($record->{product_relationship}, 'overlapping_non_partition',
        "$where product_relationship");
    validate_loss_residue($record, $where);
    return 1;
}

sub validate_loss_residue {
    my ($record, $where) = @_;
    my $kind = $record->{loss_residue_kind};
    check_integer($record->{loss_residue_lines}, 0, undef,
        "$where loss_residue_lines");
    check_integer($record->{loss_residue_bytes}, 0, undef,
        "$where loss_residue_bytes");
    if (defined $kind && !ref $kind && $kind eq 'none') {
        push @errors, "$where zero loss residue must use path '-' and sha256 '-'"
            if ($record->{loss_residue_path} // '') ne '-'
                || ($record->{loss_residue_sha256} // '') ne '-';
        push @errors, "$where loss residue declared none but dimensions are nonzero"
            if ($record->{loss_residue_lines} // -1) != 0
                || ($record->{loss_residue_bytes} // -1) != 0;
        return;
    }
    if (!defined $kind || ref $kind || $kind ne 'content_addressed_file') {
        push @errors,
            "$where loss_residue_kind must be none or content_addressed_file";
        return;
    }
    my $path = $record->{loss_residue_path};
    my $digest = $record->{loss_residue_sha256};
    if (!defined $path || ref $path || !safe_relative_path($path)
        || !defined $digest || ref $digest
        || $digest !~ /\A[0-9a-f]{64}\z/
        || basename($path) !~ /\A\Q$digest\E\.(?:md|txt)\z/) {
        push @errors,
            "$where loss residue must be a content-addressed repository Markdown/text file";
        return;
    }
    my $local = checked_local_file($path, "$where loss residue");
    return if !defined $local;
    my $contents = read_file($local, $path);
    push @errors, "$where loss-residue digest mismatch"
        if sha256_hex($contents) ne $digest;
    push @errors, "$where loss-residue line count mismatch"
        if line_count($contents) != ($record->{loss_residue_lines} // -1);
    push @errors, "$where loss-residue byte count mismatch"
        if length($contents) != ($record->{loss_residue_bytes} // -1);
}

sub validate_tree {
    my (%args) = @_;
    my $tree_id = $args{tree_id};
    my $task_relative = $args{task_relative};
    my @live_nodes = @{$args{live_nodes}};
    my @nodes = @{$args{nodes}};

    my %node_by_id;
    for my $node (@nodes) {
        my $node_id = $node->{id};
        if (exists $node_by_id{$node_id}) {
            push @errors,
                "$task_relative: duplicate node ID $node_id across "
                    . "$node_by_id{$node_id}{display} and $node->{display}";
            next;
        }
        $node_by_id{$node_id} = $node;
    }

    my $root_node = $node_by_id{$tree_id};
    if (!defined $root_node) {
        push @errors, "$task_relative: active tree root $tree_id is missing";
    }
    elsif ($live_nodes[0]{id} ne $tree_id) {
        push @errors,
            "$task_relative: active tree root $tree_id is not the first live node";
    }
    elsif ($root_node->{origin} ne 'live') {
        push @errors, "$task_relative: active tree root $tree_id is not live";
    }

    for my $node (@nodes) {
        my ($node_id, $body) = @{$node}{qw(id body)};
        my $display = $node->{display};
        if ($node_id ne $tree_id
            && $node_id !~ /^\Q$tree_id\E(?:\.[1-9][0-9]*)+\z/) {
            push @errors,
                "$display: node $node_id is not a descendant of root $tree_id";
        }

        my @statuses = field_values($node, 'Status');
        if (@statuses != 1) {
            push @errors,
                "$display: node $node_id must have exactly one Status field";
            next;
        }
        my $status = $statuses[0];
        if (!$valid_status{$status}) {
            push @errors, "$display: node $node_id has unknown status $status";
        }
        $node->{status} = $status;

        my $goal_count = field_count($node, 'Goal');
        if ($goal_count != 1) {
            push @errors,
                "$display: node $node_id must have exactly one Goal field";
        }
        if ($node->{origin} eq 'segment' && !$terminal_status{$status}) {
            push @errors,
                "$display: sealed segment node $node_id has nonterminal status $status";
        }

        my @actual_children = sort_node_ids(
            grep { /^\Q$node_id\E\.[1-9][0-9]*\z/ } keys %node_by_id
        );
        my @child_lines =
            $body =~ /^  Children(?: continuation(?: \d+)?)?:\s*(.*)$/mg;
        my @listed_children = parse_child_lines(
            $display, $node_id, \@child_lines
        );

        my @terminal_kinds = field_values($node, 'Terminal');
        if (@terminal_kinds) {
            validate_compact_terminal(
                node            => $node,
                actual_children => \@actual_children,
                child_lines     => \@child_lines,
            );
            next;
        }

        validate_child_closure(
            display         => $display,
            node_id         => $node_id,
            status          => $status,
            actual_children => \@actual_children,
            child_lines     => \@child_lines,
            listed_children => \@listed_children,
        );
        if (@actual_children || @child_lines) {
            if ($status ne 'active' && $status ne 'done') {
                push @errors,
                    "$display: container $node_id has non-container status $status";
            }
        }
        else {
            validate_leaf_fields($node, $node->{origin} eq 'segment');
        }
    }

    for my $node (@nodes) {
        my $node_id = $node->{id};
        next if $node_id eq $tree_id;
        (my $parent_id = $node_id) =~ s/\.[1-9][0-9]*\z//;
        if (!exists $node_by_id{$parent_id}) {
            push @errors,
                "$node->{display}: node $node_id has missing parent $parent_id";
            next;
        }
        if (defined $node->{status} && !$terminal_status{$node->{status}}
            && $node_by_id{$parent_id}{origin} ne 'live') {
            push @errors,
                "$node->{display}: nonterminal node $node_id has non-live ancestor $parent_id";
        }
    }

    for my $node (@nodes) {
        next if !defined $node->{status} || $node->{status} ne 'done';
        next if scalar(field_values($node, 'Terminal'));
        my $node_id = $node->{id};
        my @children = grep {
            /^\Q$node_id\E\.[1-9][0-9]*\z/
        } keys %node_by_id;
        my @nonterminal = sort_node_ids(grep {
            my $child_status = $node_by_id{$_}{status} // '';
            !$terminal_status{$child_status};
        } @children);
        push @errors,
            "$node->{display}: done container $node_id has nonterminal direct children "
                . join(', ', @nonterminal)
            if @nonterminal;
    }

    if (defined $root_node && defined $root_node->{status}
        && $root_node->{status} ne 'active') {
        push @errors,
            "$task_relative: indexed active tree root $tree_id has status $root_node->{status}";
    }
}

sub validate_compact_terminal {
    my (%args) = @_;
    my $node = $args{node};
    my $node_id = $node->{id};
    my $display = $node->{display};

    my @terminal = field_values($node, 'Terminal');
    if (@terminal != 1 || $terminal[0] ne 'version_object') {
        push @errors,
            "$display: compact terminal $node_id must use Terminal version_object";
        return;
    }
    if ($node->{origin} ne 'live') {
        push @errors,
            "$display: compact terminal $node_id must remain in the live root";
    }
    if (($node->{status} // '') ne 'done') {
        push @errors,
            "$display: compact terminal $node_id must have status done";
    }
    if (@{$args{actual_children}} || @{$args{child_lines}}) {
        push @errors,
            "$display: compact terminal $node_id must not carry live children";
    }
    if (field_count($node, 'Acceptance')) {
        push @errors,
            "$display: compact terminal $node_id must retrieve Acceptance from its version object";
    }

    for my $field (
        'Revision', 'Retrieval path', 'Retrieved SHA256',
        'Archived node count', 'Retention contract', 'Verification', 'Commit'
    ) {
        my $count = field_count($node, $field);
        push @errors,
            "$display: compact terminal $node_id must have exactly one $field field"
            if $count != 1;
    }

    my $revision = one_field($node, 'Revision');
    my $retrieval_path = one_field($node, 'Retrieval path');
    my $digest = one_field($node, 'Retrieved SHA256');
    my $node_count = one_field($node, 'Archived node count');
    my $retention_contract = one_field($node, 'Retention contract');
    my $verification = one_field($node, 'Verification');
    my $commit = one_field($node, 'Commit');
    return if !defined $revision || !defined $retrieval_path
        || !defined $digest || !defined $node_count;

    if ($revision !~ /\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) {
        push @errors,
            "$display: compact terminal $node_id has invalid exact Revision";
        return;
    }
    if (!safe_relative_path($retrieval_path)
        || $retrieval_path !~ /\.md\z/) {
        push @errors,
            "$display: compact terminal $node_id has unsafe Retrieval path";
        return;
    }
    if ($digest !~ /\A[0-9a-f]{64}\z/) {
        push @errors,
            "$display: compact terminal $node_id has invalid Retrieved SHA256";
        return;
    }
    if (!is_positive_integer($node_count)) {
        push @errors,
            "$display: compact terminal $node_id has invalid Archived node count";
        return;
    }
    if (!defined $verification || $verification eq '' || $verification eq 'pending'
        || !defined $commit || $commit eq '' || $commit eq 'pending') {
        push @errors,
            "$display: compact terminal $node_id has pending verification or commit evidence";
    }

    my $retrieved = retrieve_version_object(
        $revision, $retrieval_path, "$display: compact terminal $node_id",
        $retention_contract,
    );
    return if !defined $retrieved;
    my $actual_digest = sha256_hex($retrieved);
    if ($actual_digest ne $digest) {
        push @errors,
            "$display: compact terminal $node_id retrieved digest mismatch "
                . "(declared $digest, actual $actual_digest)";
        return;
    }

    my $section = extract_section($retrieved, 'Task Tree');
    if (!defined $section) {
        push @errors,
            "$display: compact terminal $node_id version object has no ## Task Tree section";
        return;
    }
    my @retrieved_nodes = parse_nodes(
        $section, "$revision:$retrieval_path", 'retrieved'
    );
    report_duplicate_ids(
        \@retrieved_nodes,
        "$display: compact terminal $node_id version object"
    );
    my %retrieved_by_id = map { $_->{id} => $_ } @retrieved_nodes;
    (my $retrieved_tree_id = $node_id) =~ s/\..*\z//;
    if (!exists $retrieved_by_id{$retrieved_tree_id}) {
        push @errors,
            "$display: compact terminal $node_id version object has no tree root $retrieved_tree_id";
    }
    if (!exists $retrieved_by_id{$node_id}) {
        push @errors,
            "$display: compact terminal $node_id is absent from its version object";
        return;
    }

    my @subtree_ids = sort_node_ids(grep {
        $_ eq $node_id || /^\Q$node_id\E\./
    } keys %retrieved_by_id);
    if (@subtree_ids != $node_count) {
        push @errors,
            "$display: compact terminal $node_id Archived node count $node_count "
                . "does not match retrieved count " . scalar(@subtree_ids);
    }

    my $current_goal = one_field($node, 'Goal');
    my $retrieved_goal = one_field($retrieved_by_id{$node_id}, 'Goal');
    if (!defined $current_goal || !defined $retrieved_goal
        || $current_goal ne $retrieved_goal) {
        push @errors,
            "$display: compact terminal $node_id Goal differs from its version object";
    }

    my %subtree = map { $_ => 1 } @subtree_ids;
    for my $archived_id (@subtree_ids) {
        my $archived = $retrieved_by_id{$archived_id};
        my $archived_status = one_field($archived, 'Status');
        if (!defined $archived_status || !$terminal_status{$archived_status}) {
            push @errors,
                "$display: compact terminal $node_id retrieves nonterminal node $archived_id";
            next;
        }
        my @actual_children = sort_node_ids(grep {
            /^\Q$archived_id\E\.[1-9][0-9]*\z/ && $subtree{$_}
        } keys %retrieved_by_id);
        my @child_lines =
            $archived->{body} =~ /^  Children(?: continuation(?: \d+)?)?:\s*(.*)$/mg;
        my @listed_children = parse_child_lines(
            "$revision:$retrieval_path", $archived_id, \@child_lines
        );
        validate_child_closure(
            display         => "$revision:$retrieval_path",
            node_id         => $archived_id,
            status          => $archived_status,
            actual_children => \@actual_children,
            child_lines     => \@child_lines,
            listed_children => \@listed_children,
        );
        if (!@actual_children && !@child_lines) {
            validate_leaf_fields($archived, 1);
        }
    }
    $total_compact_terminals++;
}

sub validate_child_closure {
    my (%args) = @_;
    my @actual = @{$args{actual_children}};
    my @lines = @{$args{child_lines}};
    my @listed = @{$args{listed_children}};
    my $display = $args{display};
    my $node_id = $args{node_id};

    if (@actual || @lines) {
        if (!@lines) {
            push @errors, "$display: container $node_id has no Children field";
        }
        my %listed_count;
        $listed_count{$_}++ for @listed;
        for my $child (sort_node_ids(keys %listed_count)) {
            push @errors,
                "$display: container $node_id lists child $child more than once"
                if $listed_count{$child} > 1;
        }
        my %actual = map { $_ => 1 } @actual;
        my %listed = map { $_ => 1 } @listed;
        my @missing = sort_node_ids(grep { !$listed{$_} } keys %actual);
        my @extra = sort_node_ids(grep { !$actual{$_} } keys %listed);
        push @errors,
            "$display: container $node_id omits direct children "
                . join(', ', @missing)
            if @missing;
        push @errors,
            "$display: container $node_id lists nonexistent direct children "
                . join(', ', @extra)
            if @extra;
    }
}

sub validate_leaf_fields {
    my ($node, $require_closed_evidence) = @_;
    my $node_id = $node->{id};
    my $display = $node->{display};
    for my $field (qw(Acceptance Verification Commit)) {
        my $count = field_count($node, $field);
        push @errors,
            "$display: leaf $node_id must have exactly one $field field"
            if $count != 1;
    }
    return if !$require_closed_evidence;
    if (field_count($node, 'Verification') != 1
        || field_count($node, 'Commit') != 1
        || field_is_pending($node, 'Verification')
        || field_is_pending($node, 'Commit')) {
        push @errors,
            "$display: sealed terminal leaf $node_id has pending verification or commit evidence";
    }
}

sub parse_child_lines {
    my ($display, $node_id, $lines) = @_;
    my @listed;
    for my $child_line (@{$lines}) {
        if ($child_line !~ /^`(.*)`\s*$/) {
            push @errors,
                "$display: container $node_id has malformed Children field";
            next;
        }
        for my $child (split /,/, $1, -1) {
            $child =~ s/^\s+|\s+$//g;
            if ($child !~ /^\Q$node_id\E\.[1-9][0-9]*\z/) {
                push @errors,
                    "$display: container $node_id has malformed direct child $child";
                next;
            }
            push @listed, $child;
        }
    }
    return @listed;
}

sub parse_nodes {
    my ($section, $display, $origin) = @_;
    my @nodes;
    while ($section =~ /^- ID: `([^`]+)`\s*\n(.*?)(?=^- ID: `|\z)/msg) {
        push @nodes, {
            id      => $1,
            body    => $2,
            display => $display,
            origin  => $origin,
        };
    }
    return @nodes;
}

sub extract_section {
    my ($contents, $heading) = @_;
    my ($section) =
        $contents =~ /^## \Q$heading\E\s*\n(.*?)(?=^## |\z)/ms;
    return $section;
}

sub canonical_node {
    my ($node) = @_;
    my $body = $node->{body};
    $body =~ s/[ \t]+$//mg;
    $body =~ s/\s+\z//;
    return "- ID: `$node->{id}`\n$body\n";
}

sub field_values {
    my ($node, $field) = @_;
    return $node->{body} =~ /^  \Q$field\E: `([^`]*)`\s*$/mg;
}

sub field_count {
    my ($node, $field) = @_;
    my @matches = $node->{body} =~ /^  \Q$field\E:/mg;
    return scalar @matches;
}

sub field_is_pending {
    my ($node, $field) = @_;
    return $node->{body} =~ /^  \Q$field\E:\s*`pending`\s*$/m;
}

sub one_field {
    my ($node, $field) = @_;
    my @values = field_values($node, $field);
    return @values == 1 ? $values[0] : undef;
}

sub decode_jsonl {
    my ($raw, $display) = @_;
    my @records;
    my $json = JSON::PP->new->utf8;
    my $line_number = 0;
    my @lines = split /\n/, $raw, -1;
    for my $line (@lines) {
        $line_number++;
        next if $line_number == @lines && $line eq '';
        if ($line eq '') {
            push @errors, "$display:$line_number: blank JSONL line";
            next;
        }
        my $record = eval { $json->decode($line) };
        if ($@ || ref($record) ne 'HASH') {
            push @errors, "$display:$line_number: malformed JSON object";
            next;
        }
        push @records, $record;
    }
    push @errors, "$display: contains no JSONL records" if !@records;
    return @records;
}

sub check_keys {
    my ($record, $required, $optional, $where) = @_;
    my %allowed = map { $_ => 1 } (@{$required}, @{$optional});
    for my $key (@{$required}) {
        push @errors, "$where is missing required key $key"
            if !exists $record->{$key};
    }
    for my $key (sort keys %{$record}) {
        push @errors, "$where has unknown key $key" if !$allowed{$key};
    }
}

sub check_equal {
    my ($actual, $expected, $where) = @_;
    push @errors, "$where must be $expected"
        if !defined $actual || ref $actual || $actual ne $expected;
}

sub check_integer {
    my ($actual, $minimum, $maximum, $where) = @_;
    if (!defined $actual || ref $actual || $actual !~ /\A[0-9]+\z/
        || $actual < $minimum
        || (defined $maximum && $actual > $maximum)) {
        my $range = defined $maximum
            ? "$minimum..$maximum"
            : ">=$minimum";
        push @errors, "$where must be an integer $range";
    }
}

sub is_positive_integer {
    my ($value) = @_;
    return defined $value && !ref $value
        && $value =~ /\A[1-9][0-9]*\z/;
}

sub line_count {
    my ($contents) = @_;
    return 0 if $contents eq '';
    my $lines = ($contents =~ tr/\n//);
    $lines++ if $contents !~ /\n\z/;
    return $lines;
}

sub load_retention_contracts {
    return if $retention_contracts_loaded++;
    my $path = checked_local_file(
        $retention_registry_relative, 'version-object retention registry'
    );
    return if !defined $path;
    my $raw = read_file($path, $retention_registry_relative);
    my @records = decode_jsonl($raw, $retention_registry_relative);
    return if !@records;
    my $registry = shift @records;
    check_keys(
        $registry,
        [qw(record_type schema_version max_records max_bytes)], [],
        "$retention_registry_relative: registry record",
    );
    check_equal($registry->{record_type}, 'registry',
        "$retention_registry_relative: registry record_type");
    check_integer($registry->{schema_version}, 1, 1,
        "$retention_registry_relative: registry schema_version");
    check_integer($registry->{max_records}, 1, undef,
        "$retention_registry_relative: registry max_records");
    check_integer($registry->{max_bytes}, 1, undef,
        "$retention_registry_relative: registry max_bytes");
    push @errors,
        "$retention_registry_relative: contract count " . scalar(@records)
            . " exceeds max_records $registry->{max_records}"
        if is_positive_integer($registry->{max_records})
            && @records > $registry->{max_records};
    push @errors,
        "$retention_registry_relative: size " . length($raw)
            . " exceeds max_bytes $registry->{max_bytes}"
        if is_positive_integer($registry->{max_bytes})
            && length($raw) > $registry->{max_bytes};
    my $number = 1;
    for my $record (@records) {
        $number++;
        my $where = "$retention_registry_relative: record $number";
        check_keys(
            $record,
            [qw(record_type schema_version contract_id owner guarantee recovery)],
            [], $where,
        );
        check_equal($record->{record_type}, 'contract', "$where record_type");
        check_integer($record->{schema_version}, 1, 1, "$where schema_version");
        my $id = $record->{contract_id};
        if (!defined $id || ref $id || $id !~ /\A[a-z][a-z0-9_.-]*\z/) {
            push @errors, "$where has invalid contract_id";
            next;
        }
        push @errors, "$where duplicates contract_id $id"
            if exists $retention_contracts{$id};
        for my $field (qw(owner guarantee recovery)) {
            my $value = $record->{$field};
            push @errors, "$where has empty or multiline $field"
                if !defined $value || ref $value || $value eq ''
                    || $value =~ /[\r\n\t]/;
        }
        $retention_contracts{$id} = $record;
    }
}

sub require_retention_contract {
    my ($id, $where) = @_;
    load_retention_contracts();
    if (!defined $id || ref $id
        || $id !~ /\A[a-z][a-z0-9_.-]*\z/) {
        push @errors, "$where has invalid or missing retention contract";
        return undef;
    }
    if (!exists $retention_contracts{$id}) {
        push @errors, "$where names unknown retention contract $id";
        return undef;
    }
    return $retention_contracts{$id};
}

sub retrieve_version_object {
    my ($revision, $path, $where, $retention_contract) = @_;
    my $contract = require_retention_contract($retention_contract, $where);
    return undef if !defined $contract;
    my ($ok, undef, undef, $stdout, $stderr) = run(
        command => ['git', '-C', $root, 'show', "$revision:$path"],
    );
    if (!$ok) {
        my $detail = join('', @{$stderr || []});
        $detail =~ s/\s+/ /g;
        $detail =~ s/^\s+|\s+$//g;
        push @errors,
            "$where cannot retrieve exact version object $revision:$path"
                . ($detail ne '' ? " ($detail)" : '')
                . "; retention contract $retention_contract owner "
                . "$contract->{owner} requires recovery: $contract->{recovery}";
        return undef;
    }
    return join('', @{$stdout || []});
}

sub checked_local_file {
    my ($relative, $where) = @_;
    if (!safe_relative_path($relative)) {
        push @errors, "$where uses unsafe path $relative";
        return undef;
    }
    my $path = local_path($relative);
    if (!-f $path) {
        push @errors, "$where file $relative is missing";
        return undef;
    }
    my $cursor = $root;
    for my $part (split m{/}, $relative) {
        $cursor = File::Spec->catfile($cursor, $part);
        if (-l $cursor) {
            push @errors, "$where path $relative crosses a symlink";
            return undef;
        }
    }
    my @root_stat = stat $root;
    my @file_stat = stat $path;
    if (!@root_stat || !@file_stat || $root_stat[0] != $file_stat[0]) {
        push @errors, "$where file $relative is not on the repository volume";
        return undef;
    }
    return $path;
}

sub safe_relative_path {
    my ($path) = @_;
    return 0 if !defined $path || ref $path || $path eq '';
    return 0 if File::Spec->file_name_is_absolute($path);
    return 0 if $path =~ /\\/;
    return 0 if $path =~ m{(?:^|/)\.{1,2}(?:/|$)};
    return 0 if $path =~ m{//};
    return 1;
}

sub report_duplicate_ids {
    my ($nodes, $where) = @_;
    my %seen;
    for my $node (@{$nodes}) {
        push @errors, "$where duplicates node ID $node->{id}"
            if $seen{$node->{id}}++;
    }
}

sub local_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/}, $relative);
}

sub sort_node_ids {
    return sort {
        my ($a_tail) = $a =~ /\.([1-9][0-9]*)\z/;
        my ($b_tail) = $b =~ /\.([1-9][0-9]*)\z/;
        ($a_tail // 0) <=> ($b_tail // 0) || $a cmp $b;
    } @_;
}

sub read_file {
    my ($path, $display) = @_;
    open my $fh, '<:raw', $path or fail("cannot read $display: $!");
    local $/;
    my $contents = <$fh>;
    close $fh or fail("cannot close $display: $!");
    return $contents;
}

sub fail {
    my ($message) = @_;
    print STDERR "[task-tree-integrity] FAIL: $message\n";
    exit 1;
}

sub usage {
    my ($exit) = @_;
    print <<'USAGE';
Usage:
  scripts/check_task_tree_integrity.pl [--root PATH]

Checks active task trees indexed by docs/TASK_TREE.md. The live task file is
authoritative; optional bounded JSONL manifests may add exact-source sealed
subtree segments, and compact completed terminals must retrieve their full
terminal subtree from an exact version object. A bounded completed-history
manifest may prove query-first terminal index rows from an exact version while
the live PNT tables retain only active/proposed work. PATH is intended for
focused repository-local fixtures.
USAGE
    exit $exit;
}
