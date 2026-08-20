#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP;

my ($root_arg, $inventory_arg, $claims_arg, $dispositions_arg, $groups_arg,
    $report, $help);
GetOptions(
    'root=s'         => \$root_arg,
    'inventory=s'    => \$inventory_arg,
    'claims=s'       => \$claims_arg,
    'dispositions=s' => \$dispositions_arg,
    'groups=s'       => \$groups_arg,
    'report'         => \$report,
    'help|h'         => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "claim-dispositions: invalid repository root\n"
    if !defined($root) || !-d $root;
my $inventory = $inventory_arg
    // 'doctrine/claim_verification/inventory.jsonl';
my $claims = $claims_arg // 'doctrine/claim_verification/claims.jsonl';
my $dispositions = $dispositions_arg
    // 'doctrine/claim_verification/dispositions.jsonl';
my $groups = $groups_arg
    // 'doctrine/claim_verification/disposition_groups.jsonl';

my @problems;
my $json = JSON::PP->new->canonical(1)->utf8(1);
my %tracked = tracked_paths();
for my $registry_path ($inventory, $claims, $dispositions, $groups) {
    problem("registry path is not tracked: $registry_path")
        if !$tracked{$registry_path};
}

my ($inventory_records, $inventory_lines) = read_jsonl($inventory, 'inventory');
validate_registry(
    $inventory_records, $inventory_lines, $inventory,
    {bytes => 8_388_608, records => 8192, record_bytes => 4096}
);
my %candidates;
for my $index (1 .. $#{$inventory_records}) {
    my $record = $inventory_records->[$index];
    next if ref($record) ne 'HASH'
        || text($record->{record_type}) ne 'published_candidate';
    my $where = "$inventory line " . ($index + 1);
    my $id = text($record->{candidate_id});
    problem("$where has invalid candidate_id")
        if $id !~ /\Apublished-[0-9a-f]{24}\z/;
    problem("$where duplicates candidate_id $id") if $candidates{$id};
    my $path = validate_tracked_path($record->{path}, "$where path");
    problem("$where candidate path must be Markdown")
        if defined($path) && $path !~ /[.]md\z/;
    problem("$where has unexpected migration_owner")
        if text($record->{migration_owner}) ne 'CLAIM-VERIFICATION-ADOPTION.5';
    $candidates{$id} = {path => $path} if $id ne '';
}
problem("$inventory contains no published candidates") if !keys %candidates;

my ($claim_records, $claim_lines) = read_jsonl($claims, 'claim registry');
validate_registry(
    $claim_records, $claim_lines, $claims,
    {bytes => 65_536, records => 256, record_bytes => 4096}
);
my %claim_by_id;
for my $index (1 .. $#{$claim_records}) {
    my $record = $claim_records->[$index];
    next if ref($record) ne 'HASH' || text($record->{record_type}) ne 'claim';
    my $id = text($record->{claim_id});
    next if $id eq '';
    problem("$claims duplicates claim_id $id") if $claim_by_id{$id};
    $claim_by_id{$id} = {
        classification => text($record->{classification}),
        source_path => text($record->{source_path}),
    };
}

my ($group_records, $group_lines) = read_jsonl($groups, 'group registry');
validate_registry(
    $group_records, $group_lines, $groups,
    {bytes => 32_768, records => 8, record_bytes => 8192}
);
my (%group_by_id, %group_for_path);
my @group_order;
for my $index (1 .. $#{$group_records}) {
    my $record = $group_records->[$index];
    my $where = "$groups line " . ($index + 1);
    next if ref($record) ne 'HASH';
    exact_keys(
        $record,
        [qw(group_id owner_task paths record_type required_complete schema_version)],
        $where
    );
    problem("$where record_type must be candidate_group")
        if text($record->{record_type}) ne 'candidate_group';
    validate_integer($record->{schema_version}, 1, 1, "$where schema_version");
    my $id = text($record->{group_id});
    problem("$where has invalid group_id")
        if $id !~ /\A[a-z][a-z0-9]*(?:_[a-z0-9]+)*\z/;
    problem("$where duplicates group_id $id") if $group_by_id{$id};
    my $owner = validate_task_id($record->{owner_task}, "$where owner_task");
    if (!JSON::PP::is_bool($record->{required_complete})) {
        problem("$where required_complete must be JSON true or false");
    }
    my @paths = validate_path_array($record->{paths}, "$where paths", 128);
    problem("$where paths must be non-empty") if !@paths;
    for my $path (@paths) {
        problem("$where path belongs to multiple groups: $path")
            if exists $group_for_path{$path};
        $group_for_path{$path} = $id;
    }
    $group_by_id{$id} = {
        owner_task => $owner,
        paths => \@paths,
        required_complete => $record->{required_complete} ? 1 : 0,
    };
    push @group_order, $id;
}
problem("$groups group records must be ordered by group_id")
    if join("\0", @group_order) ne join("\0", sort @group_order);
problem("$groups declares no candidate groups") if !keys %group_by_id;

my %candidate_group;
my %group_candidates;
for my $id (sort keys %candidates) {
    my $path = $candidates{$id}{path};
    next if !defined $path;
    my $group = $group_for_path{$path};
    if (!defined $group) {
        problem("candidate $id path is absent from every group: $path");
        next;
    }
    $candidate_group{$id} = $group;
    ++$group_candidates{$group};
}

my ($disposition_records, $disposition_lines) =
    read_jsonl($dispositions, 'disposition registry');
validate_registry(
    $disposition_records, $disposition_lines, $dispositions,
    {bytes => 4_194_304, records => 2048, record_bytes => 8192}
);
my (%seen_disposition, %group_disposed);
my @disposition_order;
my %counts = (
    claim_record => 0,
    derived_gate => 0,
    owned_gap => 0,
    reviewed_incidental => 0,
);
for my $index (1 .. $#{$disposition_records}) {
    my $record = $disposition_records->[$index];
    my $where = "$dispositions line " . ($index + 1);
    next if ref($record) ne 'HASH';
    my $id = text($record->{candidate_id});
    problem("$where has invalid candidate_id")
        if $id !~ /\Apublished-[0-9a-f]{24}\z/;
    problem("$where duplicates candidate_id $id") if $seen_disposition{$id}++;
    problem("$where names a stale or unknown candidate_id $id")
        if !exists $candidates{$id};
    push @disposition_order, $id;

    my $disposition = text($record->{disposition});
    if (!exists $counts{$disposition}) {
        problem("$where has unknown disposition");
        next;
    }
    ++$counts{$disposition};
    my $owner_path = validate_tracked_path(
        $record->{owner_path}, "$where owner_path"
    );
    problem("$where owner_path must name docs/tasks/*.md")
        if defined($owner_path) && $owner_path !~ m{\Adocs/tasks/[^/]+[.]md\z};
    my $owner_task = validate_task_id($record->{owner_task}, "$where owner_task");
    if (defined($owner_path) && defined($owner_task)) {
        my $owner_text = read_file($owner_path, "$where owner_path");
        problem("$where owner_task $owner_task is absent from $owner_path")
            if defined($owner_text)
                && index($owner_text, "- ID: `$owner_task`") < 0;
    }
    my $group = $candidate_group{$id};
    if (defined($group)) {
        problem("$where owner_task does not match candidate group $group")
            if defined($owner_task)
                && $owner_task ne $group_by_id{$group}{owner_task};
        ++$group_disposed{$group};
    }

    if ($disposition eq 'claim_record') {
        validate_claim_record($record, $where, $id, \%claim_by_id, \%candidates);
    } elsif ($disposition eq 'derived_gate') {
        validate_derived_gate($record, $where);
    } elsif ($disposition eq 'reviewed_incidental') {
        validate_reviewed_incidental($record, $where);
    } elsif ($disposition eq 'owned_gap') {
        validate_owned_gap($record, $where);
    }
}
problem("$dispositions records must be ordered by candidate_id")
    if join("\0", @disposition_order) ne join("\0", sort @disposition_order);

for my $group (sort keys %group_by_id) {
    my $total = $group_candidates{$group} // 0;
    my $disposed = $group_disposed{$group} // 0;
    if ($group_by_id{$group}{required_complete} && $disposed != $total) {
        problem("group $group requires completeness but has "
            . ($total - $disposed) . " open candidate(s)");
    }
}

if (@problems) {
    print STDERR "claim-dispositions: $_\n" for @problems;
    exit 1;
}

my $disposed = scalar keys %seen_disposition;
my $open = scalar(keys %candidates) - $disposed;
print "claim-dispositions: bounded disposition join holds "
    . "(candidates=" . scalar(keys %candidates)
    . ", disposed=$disposed, claim_records=$counts{claim_record}, "
    . "gates=$counts{derived_gate}, reviewed=$counts{reviewed_incidental}, "
    . "gaps=$counts{owned_gap}, open=$open, groups="
    . scalar(keys %group_by_id) . ")\n";
if ($report) {
    for my $group (sort keys %group_by_id) {
        my $total = $group_candidates{$group} // 0;
        my $done = $group_disposed{$group} // 0;
        print "claim-dispositions: group $group disposed=$done total=$total "
            . "open=" . ($total - $done) . " required_complete="
            . $group_by_id{$group}{required_complete} . "\n";
    }
}
exit 0;

sub usage {
    my ($status) = @_;
    print <<'USAGE';
Usage:
  scripts/check_claim_verification_dispositions.pl [--root DIR]
      [--inventory FILE] [--claims FILE] [--dispositions FILE]
      [--groups FILE] [--report]

Validates the bounded join from current inventory candidate IDs to claim
records, three-leg derived gates, reviewed-incidental reasons, or owned gaps.
USAGE
    exit $status;
}

sub validate_claim_record {
    my ($record, $where, $candidate_id, $claim_by_id, $candidate_by_id) = @_;
    exact_keys(
        $record,
        [qw(candidate_id claim_id disposition owner_path owner_task record_type schema_version)],
        $where
    );
    validate_common($record, $where);
    my $claim_id = text($record->{claim_id});
    problem("$where has invalid claim_id")
        if $claim_id !~ /\A[a-z][a-z0-9]*(?:-[a-z0-9]+)*\z/;
    my $claim = $claim_by_id->{$claim_id};
    if (!$claim) {
        problem("$where claim_id is absent from the claim registry: $claim_id");
        return;
    }
    problem("$where claim_id must name a published_claim")
        if $claim->{classification} ne 'published_claim';
    return if !exists $candidate_by_id->{$candidate_id};
    problem("$where claim source_path does not match the candidate path")
        if $claim->{source_path} ne $candidate_by_id->{$candidate_id}{path};
}

sub validate_derived_gate {
    my ($record, $where) = @_;
    exact_keys(
        $record,
        [qw(candidate_id disposition durability falsify owner_path owner_task record_type rederive schema_version)],
        $where
    );
    validate_common($record, $where);
    my ($rederive_evidence, $rederive_paths) = validate_leg(
        $record->{rederive}, "$where rederive", 'producer_paths'
    );
    my ($falsify_evidence, $oracle_paths) = validate_leg(
        $record->{falsify}, "$where falsify", 'oracle_paths',
        'competing_hypothesis'
    );
    my ($durability_evidence, $producer_paths, $watcher_paths) =
        validate_durability($record->{durability}, "$where durability");
    my @evidence = grep { defined } (
        $rederive_evidence, $falsify_evidence, $durability_evidence
    );
    problem("$where aliases evidence text across verification legs")
        if @evidence == 3 && scalar(keys %{ {map { $_ => 1 } @evidence} }) != 3;
    problem("$where aliases rederive producers and falsification oracles")
        if same_set($rederive_paths, $oracle_paths);
    problem("$where aliases rederive producers and durability watchers")
        if same_set($rederive_paths, $watcher_paths);
}

sub validate_reviewed_incidental {
    my ($record, $where) = @_;
    exact_keys(
        $record,
        [qw(candidate_id disposition owner_path owner_task reason reason_code record_type schema_version)],
        $where
    );
    validate_common($record, $where);
    my %allowed = map { $_ => 1 } qw(
        historical_measurement identifier_or_navigation policy_input
        structural_reference syntax_or_example_value
    );
    problem("$where has unknown reason_code")
        if !$allowed{text($record->{reason_code})};
    validate_text($record->{reason}, "$where reason", 24, 1024);
}

sub validate_owned_gap {
    my ($record, $where) = @_;
    exact_keys(
        $record,
        [qw(candidate_id disposition gap_owner gap_owner_path gap_reason missing_legs owner_path owner_task record_type schema_version)],
        $where
    );
    validate_common($record, $where);
    my $gap_owner = validate_task_id($record->{gap_owner}, "$where gap_owner");
    my $gap_path = validate_tracked_path(
        $record->{gap_owner_path}, "$where gap_owner_path"
    );
    problem("$where gap_owner_path must name docs/tasks/*.md")
        if defined($gap_path) && $gap_path !~ m{\Adocs/tasks/[^/]+[.]md\z};
    if (defined($gap_path) && defined($gap_owner)) {
        my $text = read_file($gap_path, "$where gap_owner_path");
        problem("$where gap_owner $gap_owner is absent from $gap_path")
            if defined($text) && index($text, "- ID: `$gap_owner`") < 0;
        problem("$where gap_owner $gap_owner is not a live repair task")
            if defined($text)
                && $text !~ /- ID: `\Q$gap_owner\E`\n  Status: `(?:active|pending)`/;
    }
    problem("$where gap_owner must differ from the disposition owner_task")
        if defined($gap_owner) && $gap_owner eq text($record->{owner_task});
    validate_text($record->{gap_reason}, "$where gap_reason", 24, 1024);
    if (ref($record->{missing_legs}) ne 'ARRAY') {
        problem("$where missing_legs must be an array");
    } else {
        my @legs = @{$record->{missing_legs}};
        my %allowed = map { $_ => 1 } qw(durability falsify rederive);
        problem("$where missing_legs must be non-empty") if !@legs;
        problem("$where missing_legs has an unknown leg")
            if grep { ref($_) || !$allowed{$_} } @legs;
        problem("$where missing_legs must be sorted and unique")
            if join("\0", @legs) ne join("\0", sort keys %{ {map { $_ => 1 } @legs} });
    }
}

sub validate_common {
    my ($record, $where) = @_;
    problem("$where record_type must be disposition")
        if text($record->{record_type}) ne 'disposition';
    validate_integer($record->{schema_version}, 1, 1, "$where schema_version");
}

sub validate_leg {
    my ($leg, $where, $path_key, @extra_keys) = @_;
    if (ref($leg) ne 'HASH') {
        problem("$where must be an object");
        return;
    }
    exact_keys($leg, [sort ('evidence', $path_key, @extra_keys)], $where);
    validate_text($leg->{evidence}, "$where evidence", 16, 1024);
    for my $key (@extra_keys) {
        validate_text($leg->{$key}, "$where $key", 16, 1024);
    }
    my @paths = validate_path_array($leg->{$path_key}, "$where $path_key", 32);
    problem("$where $path_key must be non-empty") if !@paths;
    return (text($leg->{evidence}), \@paths);
}

sub validate_durability {
    my ($leg, $where) = @_;
    if (ref($leg) ne 'HASH') {
        problem("$where must be an object");
        return;
    }
    exact_keys($leg, [qw(evidence producer_paths watcher_paths)], $where);
    validate_text($leg->{evidence}, "$where evidence", 16, 1024);
    my @producers = validate_path_array(
        $leg->{producer_paths}, "$where producer_paths", 32
    );
    my @watchers = validate_path_array(
        $leg->{watcher_paths}, "$where watcher_paths", 32
    );
    problem("$where producer_paths must be non-empty") if !@producers;
    problem("$where watcher_paths must be non-empty") if !@watchers;
    return (text($leg->{evidence}), \@producers, \@watchers);
}

sub validate_registry {
    my ($records, $lines, $relative, $caps) = @_;
    if (!@{$records} || ref($records->[0]) ne 'HASH') {
        problem("$relative must begin with registry metadata");
        return;
    }
    my $meta = $records->[0];
    exact_keys(
        $meta,
        [qw(max_bytes max_record_bytes max_records record_type schema_version)],
        "$relative line 1"
    );
    problem("$relative line 1 record_type must be registry")
        if text($meta->{record_type}) ne 'registry';
    validate_integer($meta->{schema_version}, 1, 1,
        "$relative line 1 schema_version");
    validate_integer($meta->{max_bytes}, 1, $caps->{bytes},
        "$relative line 1 max_bytes");
    validate_integer($meta->{max_records}, 1, $caps->{records},
        "$relative line 1 max_records");
    validate_integer($meta->{max_record_bytes}, 1, $caps->{record_bytes},
        "$relative line 1 max_record_bytes");
    my $bytes = length(join("\n", @{$lines}) . "\n");
    problem("$relative exceeds declared max_bytes")
        if integer($meta->{max_bytes}) && $bytes > $meta->{max_bytes};
    problem("$relative exceeds declared max_records")
        if integer($meta->{max_records})
            && @{$records} - 1 > $meta->{max_records};
    if (integer($meta->{max_record_bytes})) {
        for my $index (0 .. $#{$lines}) {
            problem("$relative line " . ($index + 1)
                . " exceeds declared max_record_bytes")
                if length($lines->[$index]) > $meta->{max_record_bytes};
        }
    }
}

sub read_jsonl {
    my ($relative, $label) = @_;
    my $raw = read_file($relative, $label);
    return ([], []) if !defined $raw;
    problem("$relative must end with exactly one newline")
        if $raw eq '' || $raw !~ /\n\z/ || $raw =~ /\n\n\z/;
    my @lines = split /\n/, $raw, -1;
    pop @lines if @lines && $lines[-1] eq '';
    my @records;
    for my $index (0 .. $#lines) {
        my $record = eval { $json->decode($lines[$index]) };
        if ($@ || ref($record) ne 'HASH') {
            problem("$relative line " . ($index + 1) . " is not a JSON object");
            push @records, undef;
            next;
        }
        problem("$relative line " . ($index + 1) . " is not canonical JSON")
            if $json->encode($record) ne $lines[$index];
        push @records, $record;
    }
    return (\@records, \@lines);
}

sub validate_path_array {
    my ($value, $where, $maximum) = @_;
    if (ref($value) ne 'ARRAY') {
        problem("$where must be an array");
        return;
    }
    problem("$where exceeds $maximum paths") if @{$value} > $maximum;
    my @paths;
    for my $item (@{$value}) {
        my $path = validate_tracked_path($item, $where);
        push @paths, $path if defined $path;
    }
    my %unique = map { $_ => 1 } @paths;
    problem("$where must be sorted and unique")
        if join("\0", @paths) ne join("\0", sort keys %unique);
    return @paths;
}

sub validate_tracked_path {
    my ($value, $where) = @_;
    my $path = text($value);
    if (!safe_relative_path($path)) {
        problem("$where is not a repository-relative local path");
        return;
    }
    if (!$tracked{$path}) {
        problem("$where is not tracked: $path");
        return;
    }
    my $absolute = File::Spec->catfile($root, split m{/}, $path);
    my $resolved = abs_path($absolute);
    if (-l $absolute || !defined($resolved) || !within_root($resolved)
        || !-f $resolved) {
        problem("$where is not a repository-local regular file: $path");
        return;
    }
    return $path;
}

sub read_file {
    my ($relative, $label) = @_;
    if (!safe_relative_path($relative)) {
        problem("$label path is not repository-relative and local");
        return;
    }
    my $absolute = File::Spec->catfile($root, split m{/}, $relative);
    my $resolved = abs_path($absolute);
    if (-l $absolute || !defined($resolved) || !within_root($resolved)
        || !-f $resolved) {
        problem("cannot read $label as a repository-local regular file: $relative");
        return;
    }
    open my $fh, '<:raw', $absolute or do {
        problem("cannot read $label: $relative: $!");
        return;
    };
    local $/;
    my $raw = <$fh>;
    close $fh or problem("cannot close $label: $relative: $!");
    return $raw;
}

sub tracked_paths {
    my %paths;
    open my $git, '-|', 'git', '-C', $root, 'ls-files', '-z'
        or die "claim-dispositions: cannot execute git ls-files\n";
    local $/ = "\0";
    while (my $path = <$git>) {
        chop $path;
        $paths{$path} = 1 if $path ne '';
    }
    close $git or die "claim-dispositions: git ls-files failed\n";
    return %paths;
}

sub safe_relative_path {
    my ($path) = @_;
    return 0 if ref($path) || !defined($path) || $path eq ''
        || File::Spec->file_name_is_absolute($path)
        || $path =~ /[\\\0\r\n]/ || $path =~ m{\A/|/\z|//};
    return !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $path;
}

sub within_root {
    my ($path) = @_;
    return $path eq $root || index($path, "$root/") == 0;
}

sub validate_task_id {
    my ($value, $where) = @_;
    my $id = text($value);
    if ($id !~ /\A[A-Z][A-Z0-9-]*(?:[.][1-9][0-9]*)*\z/) {
        problem("$where has invalid task ID");
        return;
    }
    return $id;
}

sub validate_text {
    my ($value, $where, $minimum, $maximum) = @_;
    my $string = text($value);
    problem("$where must be $minimum..$maximum characters")
        if length($string) < $minimum || length($string) > $maximum;
    problem("$where contains a control character")
        if $string =~ /[\x00-\x1f\x7f]/;
}

sub validate_integer {
    my ($value, $minimum, $maximum, $where) = @_;
    problem("$where must be an integer in $minimum..$maximum")
        if !integer($value) || $value < $minimum || $value > $maximum;
}

sub integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
}

sub exact_keys {
    my ($object, $required, $where) = @_;
    return if ref($object) ne 'HASH';
    my %allowed = map { $_ => 1 } @{$required};
    problem("$where is missing required key $_")
        for grep { !exists $object->{$_} } @{$required};
    problem("$where has unknown key $_")
        for grep { !$allowed{$_} } sort keys %{$object};
}

sub same_set {
    my ($left, $right) = @_;
    return 0 if !defined($left) || !defined($right)
        || @{$left} != @{$right};
    return join("\0", sort @{$left}) eq join("\0", sort @{$right});
}

sub text {
    my ($value) = @_;
    return '' if ref($value) || !defined($value);
    return "$value";
}

sub problem {
    push @problems, $_[0];
}
