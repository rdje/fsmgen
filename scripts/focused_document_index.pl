#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use File::Glob qw(bsd_glob GLOB_NOSORT);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP qw(decode_json);

my ($root_arg, $print_output, $help);
GetOptions(
    'root=s'       => \$root_arg,
    'print-output' => \$print_output,
    'help|h'       => \$help,
) or usage(2);
usage(0) if $help;

my $command = shift(@ARGV) // 'check';
usage(2) if @ARGV || $command !~ /\A(?:check|generate)\z/;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "focused-document-index: invalid project root\n" if !defined($root) || !-d $root;

my $registry_relative = 'doctrine/live_document_size/surfaces.jsonl';
my $output_relative = 'docs/index/FOCUSED_DOCUMENTS.md';
if ($print_output) {
    print "$output_relative\n";
    exit 0;
}

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: focused_document_index.pl [--root DIR] [check|generate]
       focused_document_index.pl --print-output
USAGE
    exit $status;
}

sub root_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub relative_path_ok {
    my ($path) = @_;
    return 0 if !defined($path) || $path eq '' || $path =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($path) || $path =~ m{^~(?:/|$)};
    return 0 if grep { $_ eq '..' } split m{/+}, $path;
    return 1;
}

sub read_registry {
    my $path = root_path($registry_relative);
    die "focused-document-index: missing registry: $registry_relative\n"
        if !-f $path || -l $path;
    open my $fh, '<:raw', $path
        or die "focused-document-index: cannot read $registry_relative: $!\n";
    my %records;
    my $line_number = 0;
    while (my $line = <$fh>) {
        $line_number++;
        $line =~ s/\r?\n\z//;
        die "focused-document-index: blank registry line $line_number\n" if $line eq '';
        my $record = eval { decode_json($line) };
        die "focused-document-index: invalid registry line $line_number\n"
            if $@ || ref($record) ne 'HASH';
        next if !defined $record->{surface_id};
        die "focused-document-index: duplicate surface $record->{surface_id}\n"
            if exists $records{$record->{surface_id}};
        $records{$record->{surface_id}} = $record;
    }
    close $fh or die "focused-document-index: cannot close $registry_relative: $!\n";
    return \%records;
}

sub expand_surface {
    my ($record, $surface_id) = @_;
    die "focused-document-index: missing surface $surface_id\n" if !defined $record;
    die "focused-document-index: surface $surface_id targets must be an array\n"
        if ref($record->{targets}) ne 'ARRAY' || !@{$record->{targets}};
    my %paths;
    for my $pattern (@{$record->{targets}}) {
        die "focused-document-index: unsafe target for $surface_id: $pattern\n"
            if !relative_path_ok($pattern);
        my $absolute = root_path($pattern);
        for my $match (bsd_glob($absolute, GLOB_NOSORT)) {
            next if !-f $match;
            die "focused-document-index: symlink target for $surface_id: $match\n" if -l $match;
            my $resolved = abs_path($match);
            die "focused-document-index: unresolved target for $surface_id: $match\n"
                if !defined $resolved;
            die "focused-document-index: target escapes project root: $match\n"
                if index($resolved, "$root/") != 0;
            my $relative = substr($resolved, length($root) + 1);
            $relative =~ s{\\}{/}g;
            $paths{$relative} = 1;
        }
    }
    return [sort keys %paths];
}

my %exact_group = (
    maintained_isf_reference => [qw(
        docs/ISF_SPEC.md
        docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md
        docs/ISF_PUBLIC_INTERFACE_CONTRACT.md
    )],
    live_maintainer_reference => [qw(
        docs/BIN_FSMGEN_IMPORT_TREE.md
        docs/COMPOSITION_SCOPE.md
        docs/DOWNSTREAM_ISSUE_REPORTING.md
        docs/EXTENSION_MODEL.md
        docs/FEATURE_BACKLOG.md
        docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md
        docs/FSMGEN_SOURCE_HIR_V1_CONTRACT.md
        docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md
        docs/IAL2_NEW_PROTOCOL_SUPPORT_WORKFLOW.md
        docs/ISF_LIBRARY_CATALOG.md
        docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md
        docs/PDF_EXTRACTION_WORKFLOW.md
        docs/REGRESSION_CORPUS.md
        docs/TASK_TREE_LIVE_NODE_INTEGRITY.md
        docs/VHDL_SCOPE.md
        docs/VIAL_EXECUTION_IR_V1_CONTRACT.md
        docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md
        docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md
        docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md
    )],
    project_governance => [qw(
        docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_ADOPTION_GUIDE.md
        docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md
        docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_PACKET.md
        docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_REVIEW.md
        docs/TASK_TREE.md
        docs/TASK_TREE_README.md
    )],
    historical_design => [qw(
        docs/AXI_MANAGER_USER_API_BRAINSTORM.md
        docs/INTENT_CAPTURE_AXI_CASE_STUDY.md
        docs/INTENT_SCHEDULING_BRAINSTORM.md
    )],
);

my @group_order = qw(
    maintained_isf_reference
    live_maintainer_reference
    project_governance
    historical_design
    work_unit_evidence
    ancillary_bootstrap_tooling
    ancillary_audit_review
);

my %group_metadata = (
    maintained_isf_reference => {
        title => 'Maintained ISF reference landings',
        audience => 'ISF authors, downstream integrators, and maintainers',
        lifecycle => 'maintained_reference',
        owner => 'ISF language and public-contract slices',
        role => 'bounded landing pages for the semantically partitioned ISF reference',
    },
    live_maintainer_reference => {
        title => 'Live maintainer reference',
        audience => 'FSMGen maintainers and implementation reviewers',
        lifecycle => 'partitioned_canonical',
        owner => 'the named subsystem or architecture task-tree',
        role => 'current architecture, workflow, corpus, scope, or contract truth',
    },
    project_governance => {
        title => 'Project governance and containment evidence',
        audience => 'project maintainers and continuity reviewers',
        lifecycle => 'partitioned_canonical or frozen_legacy as registered',
        owner => 'repository-governance task trees and decisions',
        role => 'active navigation, doctrine evidence, or immutable review evidence',
    },
    historical_design => {
        title => 'Retained design context',
        audience => 'maintainers investigating design provenance',
        lifecycle => 'bounded_snapshot',
        owner => 'the successor architecture or feature task-tree',
        role => 'historical design context retained because current references still consume it',
    },
    work_unit_evidence => {
        title => 'Work-unit evidence',
        audience => 'maintainers auditing a specific implementation slice',
        lifecycle => 'partitioned_canonical',
        owner => 'the work-unit ID encoded by the document name',
        role => 'bounded readiness, selection, behavior, audit, repair, or synchronization evidence',
    },
    ancillary_bootstrap_tooling => {
        title => 'Ancillary bootstrap and tooling reference',
        audience => 'agents, contributors, and tool maintainers',
        lifecycle => 'partitioned_canonical',
        owner => 'the corresponding bootstrap, CI, Knowledge Map, checker, or crate workflow',
        role => 'operational instructions outside the focused docs root',
    },
    ancillary_audit_review => {
        title => 'Ancillary audit and review records',
        audience => 'maintainers and external reviewers',
        lifecycle => 'bounded_snapshot',
        owner => 'the audit or review task-tree',
        role => 'bounded audit evidence outside the focused docs root',
    },
);

my $work_unit_name = qr/(?:AUDIT|READINESS|SELECTION|BEHAVIOR|FIRST_SLICE|NEXT_SLICE|CONTRACT_SELECTION|RESPONSE|REPAIR|CLEANUP|SYNC|ALIGNMENT|INVENTORY|PREREQUISITE|BLOCKER|EVIDENCE|PROBE|WORKSHEET|EVALUATION|MAPPING|CHRONOLOGY|SUPPORT_DETAIL|SURFACE|POLICY|TAXONOMY|MATRIX|FIXTURE|PROPOSAL|FRONTIER|IMPORT)/;

my $records = read_registry();
my $focused = expand_surface($records->{focused_documents}, 'focused_documents');
my $ancillary = expand_surface($records->{ancillary_documents}, 'ancillary_documents');

my %member = map { $_ => 'focused' } @{$focused};
for my $path (@{$ancillary}) {
    die "focused-document-index: path belongs to both source collections: $path\n"
        if exists $member{$path};
    $member{$path} = 'ancillary';
}

my (%exact_path_group, %groups);
for my $group (keys %exact_group) {
    for my $path (@{$exact_group{$group}}) {
        die "focused-document-index: duplicate exact classification: $path\n"
            if exists $exact_path_group{$path};
        $exact_path_group{$path} = $group;
        die "focused-document-index: expected classified path is absent: $path\n"
            if !exists $member{$path};
    }
}

for my $path (sort keys %member) {
    my $group;
    if (exists $exact_path_group{$path}) {
        $group = $exact_path_group{$path};
    } elsif ($member{$path} eq 'focused' && basename($path) =~ $work_unit_name) {
        $group = 'work_unit_evidence';
    } elsif ($member{$path} eq 'ancillary' && $path =~ m{\Adocs/audits/}) {
        $group = 'ancillary_audit_review';
    } elsif ($member{$path} eq 'ancillary') {
        $group = 'ancillary_bootstrap_tooling';
    } else {
        die "focused-document-index: unclassified focused document: $path\n";
    }
    push @{$groups{$group}}, $path;
}

sub markdown_link {
    my ($relative) = @_;
    my $from = dirname(root_path($output_relative));
    my $target = File::Spec->abs2rel(root_path($relative), $from);
    $target =~ s{\\}{/}g;
    return $target;
}

my $generated = <<'HEADER';
# Focused and Ancillary Document Index

This is the complete generated classification index for the focused
`docs/*.md` collection and every ancillary Markdown pattern registered in
`doctrine/live_document_size/surfaces.jsonl`. Regenerate it with
`scripts/focused_document_index.pl generate`; the doctrine gate rejects stale,
missing, duplicate, or unclassified membership.

Each section's audience, lifecycle, owner, and role apply to every linked
member in that section. The links are the bounded browse surface; task-tree and
Git history remain the authoritative chronology for completed work.
HEADER

for my $group (@group_order) {
    my $meta = $group_metadata{$group};
    my @paths = @{$groups{$group} || []};
    die "focused-document-index: classification group is empty: $group\n" if !@paths;
    $generated .= "\n## $meta->{title}\n\n";
    $generated .= "- Audience: $meta->{audience}\n";
    $generated .= "- Lifecycle: `$meta->{lifecycle}`\n";
    $generated .= "- Owner: $meta->{owner}\n";
    $generated .= "- Role: $meta->{role}\n\n";
    for my $path (@paths) {
        $generated .= '- [' . basename($path) . '](' . markdown_link($path) . ")\n";
    }
}

my $output = root_path($output_relative);
if ($command eq 'generate') {
    my $directory = dirname($output);
    if (!-d $directory) {
        mkdir $directory or die "focused-document-index: cannot create $directory: $!\n";
    }
    my $temporary = File::Spec->catfile($directory, '.' . basename($output) . ".new.$$" );
    open my $fh, '>:raw', $temporary
        or die "focused-document-index: cannot write $temporary: $!\n";
    print {$fh} $generated or die "focused-document-index: cannot write $temporary: $!\n";
    close $fh or die "focused-document-index: cannot close $temporary: $!\n";
    rename $temporary, $output
        or die "focused-document-index: cannot replace $output_relative: $!\n";
    print "focused-document-index: generated $output_relative ("
        . scalar(keys %member) . " members)\n";
    exit 0;
}

die "focused-document-index: generated index is absent: $output_relative\n"
    if !-f $output || -l $output;
open my $fh, '<:raw', $output
    or die "focused-document-index: cannot read $output_relative: $!\n";
local $/;
my $actual = <$fh> // '';
close $fh or die "focused-document-index: cannot close $output_relative: $!\n";
die "focused-document-index: stale generated index; run scripts/focused_document_index.pl generate\n"
    if $actual ne $generated;

my @lines = split /(?<=\n)/, $actual;
my $max_line = 0;
$max_line = length($_) > $max_line ? length($_) : $max_line for @lines;
die "focused-document-index: output exceeds 1,400 lines\n" if @lines > 1_400;
die "focused-document-index: output exceeds 196,608 bytes\n" if length($actual) > 196_608;
die "focused-document-index: output line exceeds 1,024 bytes\n" if $max_line > 1_024;
my $member_count = scalar keys %member;
print "focused-document-index: current ($member_count members; "
    . scalar(@lines) . " lines; " . length($actual) . " bytes)\n";
