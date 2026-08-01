#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode FB_CROAK);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use JSON::PP qw(decode_json);
use Symbol qw(gensym);

my $activation = 'aadbd14a5';
my $archives = 'doctrine/live_document_size/archive_descriptors.jsonl';
my ($root_arg, $current_root_arg, $materialize, $help);
GetOptions(
    'root=s' => \$root_arg,
    'current-root=s' => \$current_root_arg,
    'archives=s' => \$archives,
    'materialize' => \$materialize,
    'help|h' => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "knowledge-card-history: invalid repository root\n"
    if !defined($root) || !-d $root;
my $current_root = abs_path($current_root_arg // $root);
die "knowledge-card-history: invalid current-card root\n"
    if !defined($current_root) || !-d $current_root;
die "knowledge-card-history: current-card root must stay inside the repository\n"
    if $current_root ne $root && index($current_root, "$root/") != 0;

my @sources = (
    {
        descriptor_id => 'knowledge-ial2-priority-pre-containment-2026-08-01',
        path => 'docs/knowledge/ial2-feature-completeness-priority.md',
        lines => 855, bytes => 62_994, longest => 5_498,
        sha256 => '2ac368ed2aee2f16f5f0ac919b8d59417228ddd5a7ce5768b82fe7d982102452',
        current_pointer => 'docs/knowledge/ial2-feature-completeness-priority.md',
    },
    {
        descriptor_id => 'knowledge-ial2-next-slice-pre-containment-2026-08-01',
        path => 'docs/knowledge/ial2-feature-completeness-next-slice.md',
        lines => 381, bytes => 26_769, longest => 2_759,
        sha256 => 'd2767ec705e2f1ccd036439e2166a545e1bb5ef832335cabfc4f79617c400f6b',
        current_pointer => 'docs/knowledge/ial2-feature-completeness-next-slice.md',
    },
    {
        descriptor_id => 'knowledge-direct-vhdl-pre-containment-2026-08-01',
        path => 'docs/knowledge/direct-vhdl-scaffold.md',
        lines => 493, bytes => 33_380, longest => 635,
        sha256 => '624ac722cfb501db3502cf1c4a5f385b52b9ee874cc8bd2a4669d587e26463f5',
        current_pointer => 'docs/knowledge/direct-vhdl-scaffold.md',
    },
);

my @problems;
my %source_text;
for my $source (@sources) {
    my ($status, $text, $stderr) = run_git('show', "$activation:$source->{path}");
    if ($status != 0) {
        push @problems, "cannot retrieve $activation:$source->{path}: $stderr";
        next;
    }
    $source_text{$source->{path}} = $text;
    check_identity("retrieved $source->{path}", $text, $source);
}

my $expected = expected_cards(\%source_text);
if ($materialize) {
    die "knowledge-card-history: source retrieval failed; refusing materialization\n"
        if @problems;
    for my $path (sort keys %{$expected}) {
        write_current_regular($path, $expected->{$path});
    }
    print "knowledge-card-history: materialized " . scalar(keys %{$expected})
        . " bounded cards from exact activation sources\n";
    exit 0;
}

my %descriptors = map {
    ($_->{record_type} // '') eq 'descriptor'
        ? (($_->{descriptor_id} // '') => $_) : ()
} @{read_jsonl($archives)};
for my $source (@sources) {
    my $descriptor = $descriptors{$source->{descriptor_id}};
    if (!$descriptor) {
        push @problems, "missing descriptor $source->{descriptor_id}";
        next;
    }
    my %required = (
        surface_id => 'exact_history', former_path => $source->{path},
        range_id => 'complete-activation-source', revision => $activation,
        lines => $source->{lines}, bytes => $source->{bytes},
        sha256 => $source->{sha256}, retrieval_kind => 'version_object',
        retrieval_locator => "git show $activation:$source->{path}",
        current_pointer => $source->{current_pointer},
        verifier => 'adapter:scripts/check_knowledge_card_history.pl',
        retention_contract => 'fsmgen_required_history',
    );
    for my $field (sort keys %required) {
        my $actual = $descriptor->{$field};
        $actual = '' if !defined($actual) || ref($actual);
        push @problems, "descriptor $source->{descriptor_id} field $field changed"
            if "$actual" ne "$required{$field}";
    }
}

for my $path (sort keys %{$expected}) {
    my $current = read_current_regular($path);
    if (!defined $current) {
        push @problems, "bounded replacement is missing or irregular: $path";
        next;
    }
    push @problems, "bounded replacement drifted from the stable partition: $path"
        if $current ne $expected->{$path};
    my ($lines, $bytes, $longest) = dimensions($current);
    push @problems, "$path exceeds 512 lines" if $lines > 512;
    push @problems, "$path exceeds 32768 bytes" if $bytes > 32_768;
    push @problems, "$path exceeds 819-byte lines" if $longest > 819;
}

my @old_ial2 = unique_answers(
    $source_text{$sources[0]{path}} // '',
    $source_text{$sources[1]{path}} // '',
);
my @new_ial2 = unique_answers(map { $expected->{$_} }
    grep { /ial2-feature/ } sort keys %{$expected});
compare_answer_sets('IAL2 priority/next-slice', \@old_ial2, \@new_ial2);

my @old_vhdl = unique_answers($source_text{$sources[2]{path}} // '');
my @new_vhdl = unique_answers(map { $expected->{$_} }
    grep { !/ial2-feature/ } sort keys %{$expected});
compare_answer_sets('direct/composition VHDL', \@old_vhdl, \@new_vhdl);

my $next_card = read_current_regular(
    'docs/knowledge/ial2-feature-completeness-next-slice.md') // '';
push @problems, 'current next-slice card still claims stale .276 ownership'
    if $next_card =~ /next active .*\.276|next slice is .*\.276/i;
push @problems, 'current next-slice card omits the active task-tree authority route'
    if index($next_card, 'docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md') < 0;

if (@problems) {
    print STDERR "knowledge-card-history: $_\n" for @problems;
    exit 1;
}
print "knowledge-card-history: exact sources, stable partitions, answer-set equality, "
    . "boundedness, and current routing verified\n";
exit 0;

sub expected_cards {
    my ($sources_by_path) = @_;
    return {} if grep { !defined $sources_by_path->{$_->{path}} } @sources;
    my @ial2_answers = unique_answers(
        $sources_by_path->{$sources[0]{path}},
        $sources_by_path->{$sources[1]{path}},
    );
    my %ial2_groups = map { $_ => [] } qw(current 136-169 170-197 211-238 250-276 522-524);
    my $range_state = 'current';
    for my $answer (@ial2_answers) {
        my $group = classify_ial2_answer($answer, \$range_state);
        die "knowledge-card-history: unclassified IAL2 answer: $answer\n" if !$group;
        push @{$ial2_groups{$group}}, $answer;
    }

    my @vhdl_answers = unique_answers($sources_by_path->{$sources[2]{path}});
    my %vhdl_groups = map { $_ => [] } qw(direct composition package validation);
    for my $answer (@vhdl_answers) {
        my $group = classify_vhdl_answer($answer);
        die "knowledge-card-history: unclassified VHDL answer: $answer\n" if !$group;
        push @{$vhdl_groups{$group}}, $answer;
    }

    my %cards;
    my %next_route = map { $_ => 1 } (
        'what is the next IAL2 feature completeness slice?',
        'what is the next IAL2 PNT task?',
        'what is the next AXI manager slice?',
    );
    my @priority_answers = grep { !$next_route{$_} } @{$ial2_groups{current}};
    my @next_answers = grep { $next_route{$_} } @{$ial2_groups{current}};
    $cards{'docs/knowledge/ial2-feature-completeness-priority.md'} = card(
        id => 'ial2-feature-completeness-priority',
        title => 'IAL2 remains the feature-completeness priority on the SystemVerilog-backed path',
        answers => \@priority_answers, date => '2026-08-01', status => 'current',
        tags => '[ial2, systemverilog, roadmap, task-tree, feature-completeness]',
        evidence => 'docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md; docs/book/src/16c-ial2-ahb.md',
        reverify => q{rg -n 'Status: `active`|Current frontier|Next action|IAL2-FEATURE-COMPLETENESS-FRONTIER\.813' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md},
        body => <<'BODY',
IAL2 remains the active feature-completeness priority on the shipped
SystemVerilog-backed path. The exact frontier is intentionally not duplicated
here: read `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`, then use its
frontier row as the current authority.

IAL2 work may select and ship owned IAL1 or IAL0 prerequisites when a higher-
layer feature cannot be expressed correctly without them. VHDL remains a
separate backend lane rather than a reason to stop feature-completeness work.

Historical priority-card prose is exactly recoverable with:
`git show aadbd14a5:docs/knowledge/ial2-feature-completeness-priority.md`.
BODY
    );
    $cards{'docs/knowledge/ial2-feature-completeness-next-slice.md'} = card(
        id => 'ial2-feature-completeness-next-slice',
        title => 'The active IAL2 next slice is selected by the task-tree frontier',
        answers => \@next_answers,
        date => '2026-08-01', status => 'current',
        tags => '[ial2, task-tree, pnt, current-routing]',
        evidence => 'docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md',
        reverify => q{rg -n 'Current frontier|Next action|Status: `active`' docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md},
        body => <<'BODY',
The next IAL2 slice is whatever the active frontier row in
`docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md` selects. This card is a
stable route to that live authority; it deliberately does not copy a leaf ID
that becomes stale after every completed slice.

The pre-containment card's `.211`–`.276` chronology is split into bounded
historical cards and remains exactly version-retrievable from activation
commit `aadbd14a5`.
BODY
    );

    my %range_title = (
        '136-169' => 'IAL2 frontier 136–169 history has a bounded retrieval card',
        '170-197' => 'IAL2 frontier 170–197 history has a bounded retrieval card',
        '211-238' => 'IAL2 frontier 211–238 history has a bounded retrieval card',
        '250-276' => 'IAL2 frontier 250–276 history has a bounded retrieval card',
        '522-524' => 'IAL2 frontier 522–524 history has a bounded retrieval card',
    );
    for my $range (sort grep { $_ ne 'current' } keys %ial2_groups) {
        my $id = "ial2-feature-frontier-$range-history";
        $cards{"docs/knowledge/$id.md"} = card(
            id => $id, title => $range_title{$range},
            answers => $ial2_groups{$range}, date => '2026-08-01',
            status => 'superseded', tags => '[ial2, feature-completeness, history, retrieval]',
            evidence => 'docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/book/src/14-feature-backlog.md; doctrine/live_document_size/archive_descriptors.jsonl',
            reverify => "git show aadbd14a5:docs/knowledge/ial2-feature-completeness-priority.md; git show aadbd14a5:docs/knowledge/ial2-feature-completeness-next-slice.md",
            body => "This card preserves question-shaped retrieval for the stable `$range` "
                . "frontier range without retaining a live chronology blob. Canonical node "
                . "outcomes remain in `docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md`; "
                . "user-visible behavior remains in the Chapter 14 topic pages.\n\n"
                . "Exact pre-containment priority and next-slice prose is retrievable from "
                . "activation commit `aadbd14a5`.\n",
        );
    }

    my %vhdl = (
        direct => {
            path => 'docs/knowledge/direct-vhdl-scaffold.md', id => 'direct-vhdl-scaffold',
            title => 'Direct single-FSM VHDL generation has a scoped shipped subset',
            tags => '[vhdl, backend, direct-generation]',
            body => "Direct single-FSM roots support the VHDL subset documented in "
                . "`docs/VHDL_SCOPE.md` and the mdBook. The card is a bounded signpost; "
                . "the backend, focused tests, and user documentation remain canonical.\n",
        },
        composition => {
            path => 'docs/knowledge/composition-vhdl-scaffold.md', id => 'composition-vhdl-scaffold',
            title => 'Composition VHDL generation has a separately scoped shipped subset',
            tags => '[vhdl, backend, composition, generics]',
            body => "Composition roots have a separately bounded VHDL contract covering "
                . "the shipped child, generic-map, and structural-type shapes. Read "
                . "`docs/VHDL_SCOPE.md` and the mdBook for the complete current boundary.\n",
        },
        package => {
            path => 'docs/knowledge/vhdl-package-emission.md', id => 'vhdl-package-emission',
            title => 'VHDL package declarations and package-backed composition are explicit capabilities',
            tags => '[vhdl, backend, packages, composition]',
            body => "Package-root and package-backed composition behavior is independent "
                . "from the direct-FSM scaffold. Its current contract and examples live in "
                . "`docs/VHDL_SCOPE.md` and the mdBook.\n",
        },
        validation => {
            path => 'docs/knowledge/vhdl-external-validation.md', id => 'vhdl-external-validation',
            title => 'GHDL is the external validation authority for generated VHDL',
            tags => '[vhdl, ghdl, validation, backend]',
            body => "Generated VHDL validation is routed through the repository's external "
                . "HDL validation contract. GHDL availability and validation evidence are "
                . "reported explicitly rather than inferred from generation success.\n",
        },
    );
    for my $group (sort keys %vhdl) {
        my $item = $vhdl{$group};
        $cards{$item->{path}} = card(
            id => $item->{id}, title => $item->{title},
            answers => $vhdl_groups{$group}, date => '2026-08-01', status => 'current',
            tags => $item->{tags},
            evidence => 'docs/VHDL_SCOPE.md; docs/book/src/14l-backends-validation-and-apis.md; docs/book/src/10-errors-strict-mode-and-troubleshooting.md; docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md',
            reverify => 'prove -Iperl t/1420-vhdl-direct-backend-scaffold.t t/386-hdl-generator-facade-target-language-boundary-audit.t t/114-composition-target-support-diagnostics.t t/313-hdl-external-validation-contract.t',
            body => $item->{body}
                . "\nExact pre-containment combined prose is retrievable with "
                . "`git show aadbd14a5:docs/knowledge/direct-vhdl-scaffold.md`.\n",
        );
    }
    return \%cards;
}

sub classify_ial2_answer {
    my ($answer, $state_ref) = @_;
    if ($answer =~ /current feature completeness priority|prioritized before VHDL|task owns IAL2 feature completeness|next IAL2 PNT frontier|\.812|two-subordinate exact-two paired AHB alias|require new IAL1 features|next IAL2 feature completeness slice|next IAL2 PNT task|next AXI manager slice/i) {
        ${$state_ref} = 'current';
        return 'current';
    }
    if ($answer =~ /\.(?:522|523|524)\b|mixed issue-order queue multi-beat|broader mixed write BID|write depth-3 queue-head|support-detail expectation/i) {
        ${$state_ref} = '522-524';
        return '522-524';
    }
    if ($answer =~ /counted capacity|counted admitted|counted group-local/i) {
        ${$state_ref} = '211-238';
        return '211-238';
    }
    if ($answer =~ /multiple dynamic runtime|multiple dynamic read-data/i) {
        ${$state_ref} = '250-276';
        return '250-276';
    }
    if ($answer =~ /\.(\d+)\b/) {
        my $number = 0 + $1;
        for my $range (
            ['136-169', 136, 169], ['170-197', 170, 197],
            ['211-238', 211, 238], ['250-276', 250, 276],
            ['522-524', 522, 524],
        ) {
            if ($number >= $range->[1] && $number <= $range->[2]) {
                ${$state_ref} = $range->[0];
                return $range->[0];
            }
        }
    }
    return ${$state_ref};
}

sub classify_vhdl_answer {
    my ($answer) = @_;
    return 'validation' if $answer =~ /GHDL|external validation/i;
    return 'package' if $answer =~ /package roots?|VHDL packages?|package declaration\/emission|\?pkg generate HDL/i;
    return 'composition' if $answer =~ /composition|generic maps?|generic actuals?|standalone-DT|generated-FSM children|external RTL|structural types?|record\/array declarations|VHDL records or arrays|list generic|record generic|package-backed generic|package constants/i;
    return 'direct';
}

sub card {
    my %arg = @_;
    die "knowledge-card-history: empty generated answer list for $arg{id}\n"
        if !@{$arg{answers}};
    my $text = "---\nid: $arg{id}\ntitle: $arg{title}\nanswers:\n";
    for my $answer (@{$arg{answers}}) {
        die "knowledge-card-history: answer contains an unsupported quote: $answer\n"
            if $answer =~ /"/;
        $text .= "  - \"$answer\"\n";
    }
    $text .= "date: $arg{date}\nstatus: $arg{status}\ntags: $arg{tags}\n";
    $text .= folded('evidence', $arg{evidence});
    $text .= folded('reverify', $arg{reverify});
    $text .= "---\n\n$arg{body}";
    $text .= "\n" if $text !~ /\n\z/;
    return $text;
}

sub folded {
    my ($key, $value) = @_;
    my @parts;
    while (length($value) > 100) {
        my $break = rindex(substr($value, 0, 101), ' ');
        die "knowledge-card-history: cannot fold $key\n" if $break < 1;
        push @parts, substr($value, 0, $break);
        $value = substr($value, $break + 1);
    }
    push @parts, $value;
    return "$key: >-\n" . join('', map { "  $_\n" } @parts);
}

sub unique_answers {
    my @texts = @_;
    my %seen;
    my @answers;
    for my $text (@texts) {
        for my $answer (extract_answers($text)) {
            push @answers, $answer if !$seen{$answer}++;
        }
    }
    return @answers;
}

sub extract_answers {
    my ($text) = @_;
    my @answers;
    my $inside = 0;
    for my $line (split /\n/, $text) {
        if ($line eq 'answers:') { $inside = 1; next; }
        if ($inside && $line =~ /^  -[ ]+"(.*)"$/) { push @answers, $1; next; }
        $inside = 0 if $inside && $line =~ /^[A-Za-z_][A-Za-z0-9_]*:/;
    }
    return @answers;
}

sub compare_answer_sets {
    my ($label, $old, $new) = @_;
    my %old = map { $_ => 1 } @{$old};
    my %new = map { $_ => 1 } @{$new};
    push @problems, "$label answer lost: $_" for grep { !$new{$_} } sort keys %old;
    push @problems, "$label answer introduced: $_" for grep { !$old{$_} } sort keys %new;
    push @problems, "$label replacement duplicates answer: $_"
        for duplicate_values(map { extract_answers($_) }
            map { $expected->{$_} } grep {
                $label =~ /IAL2/ ? /ial2-feature/ : !/ial2-feature/
            } sort keys %{$expected});
}

sub duplicate_values {
    my %seen;
    return grep { $seen{$_}++ } @_;
}

sub dimensions {
    my ($text) = @_;
    my $lines = () = $text =~ /\n/g;
    my $longest = 0;
    for my $line (split /\n/, $text, -1) {
        my $width = length(encode('UTF-8', $line));
        $longest = $width if $width > $longest;
    }
    my $bytes = encode('UTF-8', $text);
    return ($lines, length($bytes), $longest, sha256_hex($bytes));
}

sub check_identity {
    my ($label, $text, $expected) = @_;
    my ($lines, $bytes, $longest, $sha256) = dimensions($text);
    push @problems, "$label line count changed" if $lines != $expected->{lines};
    push @problems, "$label byte count changed" if $bytes != $expected->{bytes};
    push @problems, "$label longest line changed" if $longest != $expected->{longest};
    push @problems, "$label digest changed" if $sha256 ne $expected->{sha256};
}

sub relative_path_ok {
    my ($path) = @_;
    return defined($path) && $path ne '' && $path !~ /\0/
        && !File::Spec->file_name_is_absolute($path)
        && !grep { $_ eq '..' } split m{/+}, $path;
}

sub root_path {
    my ($relative) = @_;
    die "knowledge-card-history: unsafe project path: $relative\n"
        if !relative_path_ok($relative);
    assert_no_symlink_below($root, $relative, 'project path');
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub current_path {
    my ($relative) = @_;
    die "knowledge-card-history: unsafe current-card path: $relative\n"
        if !relative_path_ok($relative);
    assert_no_symlink_below($current_root, $relative, 'current-card path');
    return File::Spec->catfile($current_root, split m{/+}, $relative);
}

sub assert_no_symlink_below {
    my ($base, $relative, $label) = @_;
    my $cursor = $base;
    for my $part (grep { $_ ne '' && $_ ne '.' } split m{/+}, $relative) {
        $cursor = File::Spec->catfile($cursor, $part);
        die "knowledge-card-history: unsafe $label symlink component: $relative\n"
            if -l $cursor;
    }
}

sub read_regular {
    my ($relative) = @_;
    my $path = root_path($relative);
    return undef if !-f $path || -l $path;
    open my $fh, '<:raw', $path or return undef;
    local $/;
    my $bytes = <$fh> // '';
    close $fh;
    return decode('UTF-8', $bytes, FB_CROAK);
}

sub read_current_regular {
    my ($relative) = @_;
    my $path = current_path($relative);
    return undef if !-f $path || -l $path;
    open my $fh, '<:raw', $path or return undef;
    local $/;
    my $bytes = <$fh> // '';
    close $fh;
    return decode('UTF-8', $bytes, FB_CROAK);
}

sub write_current_regular {
    my ($relative, $text) = @_;
    my $path = current_path($relative);
    make_path(dirname($path)) if !-d dirname($path);
    my $tmp = "$path.tmp.$$";
    open my $fh, '>:raw', $tmp or die "knowledge-card-history: cannot write $tmp: $!\n";
    print {$fh} encode('UTF-8', $text) or die "knowledge-card-history: cannot write $tmp: $!\n";
    close $fh or die "knowledge-card-history: cannot close $tmp: $!\n";
    rename $tmp, $path or die "knowledge-card-history: cannot replace $relative: $!\n";
}

sub read_jsonl {
    my ($relative) = @_;
    my $text = read_regular($relative);
    if (!defined $text) {
        push @problems, "missing JSONL registry: $relative";
        return [];
    }
    my @records;
    for my $line (grep { $_ ne '' } split /\n/, $text) {
        my $record = eval { decode_json(encode('UTF-8', $line)) };
        if (!$record || ref($record) ne 'HASH') {
            push @problems, "invalid JSON object in $relative";
            next;
        }
        push @records, $record;
    }
    return \@records;
}

sub run_git {
    my (@args) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr, 'git', '-C', $root, @args);
    close $stdin;
    binmode $stdout;
    binmode $stderr;
    local $/;
    my $out = <$stdout> // '';
    my $err = <$stderr> // '';
    waitpid($pid, 0);
    my $text = eval { decode('UTF-8', $out, FB_CROAK) };
    return ($? >> 8, $text // '', $err);
}

sub usage {
    my ($status) = @_;
    print STDERR "Usage: check_knowledge_card_history.pl [--root DIR] [--current-root DIR] [--archives PATH] [--materialize]\n";
    exit $status;
}
