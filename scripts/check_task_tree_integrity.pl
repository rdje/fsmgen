#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

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
my $index_path = File::Spec->catfile($root, split m{/}, $index_relative);
my $index = read_file($index_path, $index_relative);

my @active_trees;
my %seen_index_tree;
for my $line (split /\n/, $index) {
    next if $line !~ /^\|\s*`([^`]+)`\s*\|\s*`active`\s*\|/;
    my $tree_id = $1;
    my ($task_path) = $line =~ m{\((docs/tasks/[^)]+\.md)\)};
    fail("$index_relative: active tree $tree_id has no docs/tasks/*.md link")
        if !defined $task_path;
    fail("$index_relative: active tree $tree_id is listed more than once")
        if $seen_index_tree{$tree_id}++;
    fail("$index_relative: active tree $tree_id uses unsafe task path $task_path")
        if File::Spec->file_name_is_absolute($task_path)
            || $task_path =~ m{(?:^|/)\.\.(?:/|$)};
    push @active_trees, [$tree_id, $task_path];
}

my %valid_status = map { $_ => 1 } qw(
    proposed active pending in_progress blocked done deferred superseded
);
my @errors;
my $total_nodes = 0;

for my $entry (@active_trees) {
    my ($tree_id, $task_relative) = @{$entry};
    my $task_path = File::Spec->catfile($root, split m{/}, $task_relative);
    if (!-f $task_path) {
        push @errors, "$task_relative: active task file is missing";
        next;
    }

    my $task = read_file($task_path, $task_relative);
    my ($section) = $task =~ /^## Task Tree\s*\n(.*?)(?=^## |\z)/ms;
    if (!defined $section) {
        push @errors, "$task_relative: missing ## Task Tree section";
        next;
    }

    my @nodes;
    my %node_by_id;
    while ($section =~ /^- ID: `([^`]+)`\s*\n(.*?)(?=^- ID: `|\z)/msg) {
        my ($node_id, $body) = ($1, $2);
        if (exists $node_by_id{$node_id}) {
            push @errors, "$task_relative: duplicate node ID $node_id";
            next;
        }
        my $node = { id => $node_id, body => $body };
        $node_by_id{$node_id} = $node;
        push @nodes, $node;
    }

    if (!@nodes) {
        push @errors, "$task_relative: ## Task Tree contains no nodes";
        next;
    }
    $total_nodes += scalar @nodes;

    my $root_node = $node_by_id{$tree_id};
    if (!defined $root_node) {
        push @errors, "$task_relative: active tree root $tree_id is missing";
    }
    elsif ($nodes[0]{id} ne $tree_id) {
        push @errors, "$task_relative: active tree root $tree_id is not the first node";
    }

    for my $node (@nodes) {
        my ($node_id, $body) = @{$node}{qw(id body)};
        if ($node_id ne $tree_id
            && $node_id !~ /^\Q$tree_id\E(?:\.[1-9][0-9]*)+$/) {
            push @errors,
                "$task_relative: node $node_id is not a descendant of root $tree_id";
        }
        my @statuses = $body =~ /^  Status: `([^`]+)`\s*$/mg;
        if (@statuses != 1) {
            push @errors,
                "$task_relative: node $node_id must have exactly one Status field";
            next;
        }
        my $status = $statuses[0];
        if (!$valid_status{$status}) {
            push @errors,
                "$task_relative: node $node_id has unknown status $status";
        }
        $node->{status} = $status;

        my @goals = $body =~ /^  Goal:/mg;
        if (@goals != 1) {
            push @errors,
                "$task_relative: node $node_id must have exactly one Goal field";
        }

        my @actual_children = sort_node_ids(
            grep { /^\Q$node_id\E\.[1-9][0-9]*$/ } keys %node_by_id
        );
        my @child_lines = $body =~ /^  Children(?: continuation(?: \d+)?)?:\s*(.*)$/mg;
        my @listed_children;
        for my $child_line (@child_lines) {
            if ($child_line !~ /^`(.*)`\s*$/) {
                push @errors,
                    "$task_relative: container $node_id has malformed Children field";
                next;
            }
            for my $child (split /,/, $1, -1) {
                $child =~ s/^\s+|\s+$//g;
                if ($child !~ /^\Q$node_id\E\.[1-9][0-9]*$/) {
                    push @errors,
                        "$task_relative: container $node_id has malformed direct child $child";
                    next;
                }
                push @listed_children, $child;
            }
        }

        if (@actual_children || @child_lines) {
            if (!@child_lines) {
                push @errors, "$task_relative: container $node_id has no Children field";
            }
            my %listed_count;
            $listed_count{$_}++ for @listed_children;
            for my $child (sort_node_ids(keys %listed_count)) {
                push @errors,
                    "$task_relative: container $node_id lists child $child more than once"
                    if $listed_count{$child} > 1;
            }
            my %actual = map { $_ => 1 } @actual_children;
            my %listed = map { $_ => 1 } @listed_children;
            my @missing = sort_node_ids(grep { !$listed{$_} } keys %actual);
            my @extra = sort_node_ids(grep { !$actual{$_} } keys %listed);
            push @errors,
                "$task_relative: container $node_id omits direct children "
                    . join(', ', @missing)
                if @missing;
            push @errors,
                "$task_relative: container $node_id lists nonexistent direct children "
                    . join(', ', @extra)
                if @extra;
            if ($status ne 'active' && $status ne 'done') {
                push @errors,
                    "$task_relative: container $node_id has non-container status $status";
            }
        }
        else {
            for my $field (qw(Acceptance Verification Commit)) {
                my @fields = $body =~ /^  \Q$field\E:/mg;
                push @errors,
                    "$task_relative: leaf $node_id must have exactly one $field field"
                    if @fields != 1;
            }
        }
    }

    for my $node (@nodes) {
        my $node_id = $node->{id};
        next if $node_id eq $tree_id;
        (my $parent_id = $node_id) =~ s/\.[1-9][0-9]*$//;
        push @errors,
            "$task_relative: node $node_id has missing parent $parent_id"
            if !exists $node_by_id{$parent_id};
    }

    for my $node (@nodes) {
        next if !defined $node->{status} || $node->{status} ne 'done';
        my $node_id = $node->{id};
        my @children = grep { /^\Q$node_id\E\.[1-9][0-9]*$/ } keys %node_by_id;
        my @nonterminal = sort_node_ids(grep {
            my $child_status = $node_by_id{$_}{status} // '';
            $child_status ne 'done'
                && $child_status ne 'deferred'
                && $child_status ne 'superseded';
        } @children);
        push @errors,
            "$task_relative: done container $node_id has nonterminal direct children "
                . join(', ', @nonterminal)
            if @nonterminal;
    }

    if (defined $root_node && defined $root_node->{status}
        && $root_node->{status} ne 'active') {
        push @errors,
            "$task_relative: indexed active tree root $tree_id has status $root_node->{status}";
    }
}

if (@errors) {
    print STDERR "[task-tree-integrity] FAIL: $_\n" for @errors;
    print STDERR "[task-tree-integrity] active task-tree invariants failed\n";
    exit 1;
}

printf "[task-tree-integrity] all active task-tree invariants hold (trees=%d, nodes=%d)\n",
    scalar(@active_trees), $total_nodes;
exit 0;

sub sort_node_ids {
    return sort {
        my ($a_tail) = $a =~ /\.([1-9][0-9]*)$/;
        my ($b_tail) = $b =~ /\.([1-9][0-9]*)$/;
        ($a_tail // 0) <=> ($b_tail // 0) || $a cmp $b;
    } @_;
}

sub read_file {
    my ($path, $display) = @_;
    open my $fh, '<', $path or fail("cannot read $display: $!");
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

Checks the authoritative node lists of active task trees indexed by
docs/TASK_TREE.md. PATH is intended for focused repository-local fixtures.
USAGE
    exit $exit;
}
