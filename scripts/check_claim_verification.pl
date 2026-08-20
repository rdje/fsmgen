#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use Encode qw(encode);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP;

my ($root_arg, $registry_arg, $help);
GetOptions(
    'root=s'     => \$root_arg,
    'registry=s' => \$registry_arg,
    'help|h'     => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
my $registry = $registry_arg // 'doctrine/claim_verification/claims.jsonl';
my @problems;

if (!defined($root) || !-d $root) {
    fail('invalid repository root');
}
if (!safe_relative_path($registry)) {
    fail("registry path is not repository-relative and local: $registry");
}

my %tracked = tracked_paths($root);
my ($records, $raw_lines) = read_registry($root, $registry);
validate_registry_bounds($records, $raw_lines, $registry);

my %claims;
my %source_records;
my $published = 0;
my $fixtures = 0;

for my $index (1 .. $#{$records}) {
    my $record = $records->[$index];
    my $where = "$registry line " . ($index + 1);
    next if ref($record) ne 'HASH';

    validate_record_shape($record, $where);
    my $id = string_value($record->{claim_id});
    if ($id !~ /\A[a-z][a-z0-9]*(?:-[a-z0-9]+)*\z/) {
        problem("$where has invalid claim_id");
        next;
    }
    if (exists $claims{$id}) {
        problem("$where duplicates claim_id $id");
        next;
    }
    $claims{$id} = $record;

    my $classification = string_value($record->{classification});
    if ($classification eq 'published_claim') {
        ++$published;
    } elsif ($classification eq 'conformance_fixture') {
        ++$fixtures;
    } else {
        problem("$where has invalid classification");
    }

    validate_scalar($record->{claim}, "$where claim", 1024);
    validate_scalar($record->{owner_task}, "$where owner_task", 160);
    my $owner_task = string_value($record->{owner_task});
    problem("$where has invalid owner_task")
        if $owner_task !~ /\A[A-Z][A-Z0-9-]*(?:\.[1-9][0-9]*)*\z/;

    my $source_path = validate_tracked_path(
        $root, \%tracked, $record->{source_path}, "$where source_path"
    );
    if (defined($source_path)
        && $classification eq 'published_claim'
        && $source_path !~ /\.md\z/) {
        problem("$where published source_path must name a Markdown file");
    }
    if (defined($source_path)
        && $classification eq 'conformance_fixture'
        && $source_path !~ m{\Adoctrine/claim_verification/fixtures/[^/]+\.txt\z}) {
        problem("$where conformance source_path must name a claim-verification text fixture");
    }
    my $owner_path = validate_tracked_path(
        $root, \%tracked, $record->{owner_path}, "$where owner_path"
    );
    if (defined($owner_path)
        && $owner_path !~ m{\Adocs/tasks/(?:[^/]+)\.md\z}) {
        problem("$where owner_path must name one docs/tasks/*.md file");
    }
    if (defined($owner_path) && $owner_task ne '') {
        my $owner_text = read_relative_file($root, $owner_path, "$where owner_path");
        if (defined($owner_text)
            && index($owner_text, "- ID: `$owner_task`") < 0) {
            problem("$where owner_task $owner_task is absent from $owner_path");
        }
    }

    my %leg_specs = (
        rederive => [qw(producer_paths)],
        falsify => [qw(oracle_paths)],
        durability => [qw(producer_paths watcher_paths)],
    );
    my %leg_display;
    my %leg_paths;
    for my $leg (qw(rederive falsify durability)) {
        my ($display, $paths) = validate_leg(
            $root, \%tracked, $record->{$leg}, $leg_specs{$leg},
            "$where $leg", $owner_path
        );
        $leg_display{$leg} = $display if defined $display;
        $leg_paths{$leg} = $paths;
    }

    for my $pair ([qw(rederive falsify)], [qw(rederive durability)],
                  [qw(falsify durability)]) {
        my ($left, $right) = @{$pair};
        next if !defined($leg_display{$left}) || !defined($leg_display{$right});
        problem("$where aliases $left and $right evidence")
            if $leg_display{$left} eq $leg_display{$right};
    }
    if (same_path_set(
            $leg_paths{rederive}{producer_paths},
            $leg_paths{falsify}{oracle_paths})) {
        problem("$where aliases rederive producer_paths and falsify oracle_paths");
    }
    if (same_path_set(
            $leg_paths{rederive}{producer_paths},
            $leg_paths{durability}{watcher_paths})) {
        problem("$where aliases rederive producer_paths and durability watcher_paths");
    }

    next if !defined($source_path)
        || !defined($leg_display{rederive})
        || !defined($leg_display{falsify})
        || !defined($leg_display{durability});
    my $claim = string_value($record->{claim});
    my $expected = encode('UTF-8', marker_block(
        $id, $claim, $leg_display{rederive}, $leg_display{falsify},
        $leg_display{durability}
    ));
    $source_records{$id} = {
        path => $source_path,
        expected => $expected,
    };
}

validate_record_order($records, $registry);
validate_markers($root, \%tracked, \%claims, \%source_records);

if (@problems) {
    print STDERR "claim-verification: $_\n" for @problems;
    exit 1;
}

my $count = @{$records} ? @{$records} - 1 : 0;
print "claim-verification: all bounded record invariants hold "
    . "(records=$count, published=$published, fixtures=$fixtures)\n";
exit 0;

sub usage {
    my ($status) = @_;
    print <<'USAGE';
Usage:
  scripts/check_claim_verification.pl [--root DIR] [--registry FILE]

Checks FSMGen's bounded claim registry, exact source markers, explicit
re-derive/falsify/durability legs, tracked evidence paths, and path locality.
USAGE
    exit $status;
}

sub fail {
    my ($message) = @_;
    print STDERR "claim-verification: $message\n";
    exit 1;
}

sub problem {
    push @problems, $_[0];
}

sub read_registry {
    my ($base, $relative) = @_;
    my $raw = read_relative_file($base, $relative, 'claim registry');
    return ([], []) if !defined $raw;
    problem("$relative must end with exactly one newline")
        if $raw eq '' || $raw !~ /\n\z/ || $raw =~ /\n\n\z/;
    my @lines = split /\n/, $raw, -1;
    pop @lines if @lines && $lines[-1] eq '';
    my @records;
    my $json = JSON::PP->new->canonical(1)->utf8(1);
    for my $index (0 .. $#lines) {
        my $line_number = $index + 1;
        my $line = $lines[$index];
        if ($line eq '') {
            problem("$relative line $line_number is blank");
            push @records, undef;
            next;
        }
        my $record = eval { $json->decode($line) };
        if ($@ || ref($record) ne 'HASH') {
            problem("$relative line $line_number is not a JSON object");
            push @records, undef;
            next;
        }
        my $canonical = $json->encode($record);
        problem("$relative line $line_number is not canonical JSON")
            if $canonical ne $line;
        push @records, $record;
    }
    return (\@records, \@lines);
}

sub validate_registry_bounds {
    my ($records, $lines, $relative) = @_;
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
        if string_value($meta->{record_type}) ne 'registry';
    validate_integer($meta->{schema_version}, 1, 1,
        "$relative line 1 schema_version");
    validate_integer($meta->{max_records}, 1, 256,
        "$relative line 1 max_records");
    validate_integer($meta->{max_bytes}, 1, 65_536,
        "$relative line 1 max_bytes");
    validate_integer($meta->{max_record_bytes}, 1, 4096,
        "$relative line 1 max_record_bytes");

    my $path = File::Spec->catfile($root, split m{/}, $relative);
    my $bytes = -f $path ? -s $path : 0;
    if (positive_integer($meta->{max_bytes}) && $bytes > $meta->{max_bytes}) {
        problem("$relative size $bytes exceeds max_bytes $meta->{max_bytes}");
    }
    my $record_count = @{$records} - 1;
    if (positive_integer($meta->{max_records})
        && $record_count > $meta->{max_records}) {
        problem("$relative record count $record_count exceeds max_records $meta->{max_records}");
    }
    if (positive_integer($meta->{max_record_bytes})) {
        for my $index (0 .. $#{$lines}) {
            my $line_bytes = length($lines->[$index]);
            problem("$relative line " . ($index + 1)
                . " is $line_bytes bytes (> max_record_bytes $meta->{max_record_bytes})")
                if $line_bytes > $meta->{max_record_bytes};
        }
    }
}

sub validate_record_shape {
    my ($record, $where) = @_;
    exact_keys(
        $record,
        [qw(classification claim claim_id durability falsify owner_path
            owner_task record_type rederive schema_version source_path)],
        $where
    );
    problem("$where record_type must be claim")
        if string_value($record->{record_type}) ne 'claim';
    validate_integer($record->{schema_version}, 1, 1,
        "$where schema_version");
}

sub validate_leg {
    my ($base, $tracked, $leg, $path_keys, $where, $owner_path) = @_;
    if (ref($leg) ne 'HASH') {
        problem("$where must be an object");
        return (undef, {});
    }
    exact_keys(
        $leg,
        [sort qw(evidence gap_owner gap_reason status), @{$path_keys}],
        $where
    );
    my $status = string_value($leg->{status});
    problem("$where status must be available or missing")
        if $status ne 'available' && $status ne 'missing';

    my %paths;
    for my $path_key (@{$path_keys}) {
        $paths{$path_key} = validate_path_list(
            $base, $tracked, $leg->{$path_key}, "$where $path_key"
        );
    }

    if ($status eq 'available') {
        validate_scalar($leg->{evidence}, "$where evidence", 768);
        problem("$where gap_owner must be null while available")
            if defined $leg->{gap_owner};
        problem("$where gap_reason must be null while available")
            if defined $leg->{gap_reason};
        for my $path_key (@{$path_keys}) {
            problem("$where $path_key must name at least one tracked path while available")
                if !@{$paths{$path_key}};
        }
        return (string_value($leg->{evidence}), \%paths);
    }

    if ($status eq 'missing') {
        problem("$where evidence must be null while missing")
            if defined $leg->{evidence};
        validate_scalar($leg->{gap_owner}, "$where gap_owner", 160);
        validate_scalar($leg->{gap_reason}, "$where gap_reason", 512);
        my $gap_owner = string_value($leg->{gap_owner});
        problem("$where gap_owner has invalid task-tree node syntax")
            if $gap_owner !~ /\A[A-Z][A-Z0-9-]*(?:\.[1-9][0-9]*)*\z/;
        if (defined($owner_path) && $gap_owner ne '') {
            my $owner_text = read_relative_file($base, $owner_path, "$where owner_path");
            problem("$where gap_owner $gap_owner is absent from $owner_path")
                if defined($owner_text)
                    && index($owner_text, "- ID: `$gap_owner`") < 0;
        }
        for my $path_key (@{$path_keys}) {
            problem("$where $path_key must be empty while missing")
                if @{$paths{$path_key}};
        }
        return (
            'MISSING - ' . string_value($leg->{gap_reason})
                . ' (owner: ' . $gap_owner . ')',
            \%paths
        );
    }
    return (undef, \%paths);
}

sub validate_path_list {
    my ($base, $tracked, $value, $where) = @_;
    if (ref($value) ne 'ARRAY') {
        problem("$where must be an array");
        return [];
    }
    problem("$where has more than 16 entries") if @{$value} > 16;
    my @valid;
    my %seen;
    for my $index (0 .. $#{$value}) {
        my $path = validate_tracked_path(
            $base, $tracked, $value->[$index], "$where entry " . ($index + 1)
        );
        next if !defined $path;
        problem("$where duplicates $path") if $seen{$path}++;
        push @valid, $path;
    }
    my @sorted = sort @valid;
    problem("$where must be lexically sorted")
        if join("\0", @valid) ne join("\0", @sorted);
    return \@valid;
}

sub validate_tracked_path {
    my ($base, $tracked, $value, $where) = @_;
    if (ref($value) || !defined($value) || !safe_relative_path($value)) {
        problem("$where is not a repository-relative local path");
        return undef;
    }
    if (!$tracked->{$value}) {
        problem("$where is not tracked: $value");
        return undef;
    }
    my $path = File::Spec->catfile($base, split m{/}, $value);
    if (-l $path || !-f $path) {
        problem("$where is not a regular non-symlink file: $value");
        return undef;
    }
    my $resolved = abs_path($path);
    if (!defined($resolved) || index($resolved, "$base/") != 0) {
        problem("$where resolves outside the repository: $value");
        return undef;
    }
    return $value;
}

sub validate_markers {
    my ($base, $tracked, $claims_by_id, $records_by_id) = @_;
    my %begins;
    my %ends;
    my %texts;
    for my $path (sort grep {
            /\.md\z/
                || m{\Adoctrine/claim_verification/fixtures/[^/]+\.txt\z}
        } keys %{$tracked}) {
        my $text = read_relative_file($base, $path, "tracked claim source $path");
        next if !defined($text)
            || index($text, '<!-- CLAIM-VERIFICATION:') < 0;
        $texts{$path} = $text;
        for my $line (split /\n/, $text, -1) {
            if (index($line, '<!-- CLAIM-VERIFICATION:BEGIN') >= 0) {
                if ($line =~ /\A<!-- CLAIM-VERIFICATION:BEGIN ([a-z][a-z0-9]*(?:-[a-z0-9]+)*) -->\z/) {
                    push @{$begins{$1}}, $path;
                } else {
                    problem("$path has malformed claim-verification BEGIN marker");
                }
            }
            if (index($line, '<!-- CLAIM-VERIFICATION:END') >= 0) {
                if ($line =~ /\A<!-- CLAIM-VERIFICATION:END ([a-z][a-z0-9]*(?:-[a-z0-9]+)*) -->\z/) {
                    push @{$ends{$1}}, $path;
                } else {
                    problem("$path has malformed claim-verification END marker");
                }
            }
        }
    }

    my %all_ids = map { $_ => 1 } (keys %begins, keys %ends, keys %{$records_by_id});
    for my $id (sort keys %all_ids) {
        my @begin_paths = @{$begins{$id} // []};
        my @end_paths = @{$ends{$id} // []};
        if (!$claims_by_id->{$id}) {
            problem("claim marker $id is not declared in the registry");
            next;
        }
        problem("claim $id must have exactly one BEGIN marker")
            if @begin_paths != 1;
        problem("claim $id must have exactly one END marker")
            if @end_paths != 1;
        my $record = $records_by_id->{$id};
        next if !$record;
        my $path = $record->{path};
        problem("claim $id BEGIN marker is not in declared source_path $path")
            if @begin_paths == 1 && $begin_paths[0] ne $path;
        problem("claim $id END marker is not in declared source_path $path")
            if @end_paths == 1 && $end_paths[0] ne $path;
        my $text = exists($texts{$path})
            ? $texts{$path}
            : read_relative_file($base, $path, "claim $id source");
        next if !defined $text;
        my $expected = $record->{expected};
        my $matches = () = $text =~ /\Q$expected\E/g;
        problem("claim $id source does not contain its exact registered record block")
            if $matches != 1;
    }
}

sub validate_record_order {
    my ($records, $relative) = @_;
    my @ids = map {
        ref($_) eq 'HASH' ? string_value($_->{claim_id}) : ''
    } @{$records}[1 .. $#{$records}];
    return if !@ids;
    my @sorted = sort @ids;
    problem("$relative claim records must be sorted by claim_id")
        if join("\0", @ids) ne join("\0", @sorted);
}

sub marker_block {
    my ($id, $claim, $rederive, $falsify, $durability) = @_;
    return "<!-- CLAIM-VERIFICATION:BEGIN $id -->\n"
        . "- Claim: $claim\n"
        . "- Re-derive: $rederive\n"
        . "- Falsify: $falsify\n"
        . "- Durability: $durability\n"
        . "<!-- CLAIM-VERIFICATION:END $id -->";
}

sub same_path_set {
    my ($left, $right) = @_;
    return 0 if ref($left) ne 'ARRAY' || ref($right) ne 'ARRAY';
    return 0 if !@{$left} || !@{$right};
    return join("\0", @{$left}) eq join("\0", @{$right});
}

sub tracked_paths {
    my ($base) = @_;
    my %paths;
    open my $git, '-|', 'git', '-C', $base, 'ls-files', '-z'
        or fail('cannot execute git ls-files');
    local $/ = "\0";
    while (my $path = <$git>) {
        chop $path;
        $paths{$path} = 1 if $path ne '';
    }
    close $git or fail('git ls-files failed');
    return %paths;
}

sub read_relative_file {
    my ($base, $relative, $label) = @_;
    if (!safe_relative_path($relative)) {
        problem("$label path is not repository-relative and local");
        return undef;
    }
    my $path = File::Spec->catfile($base, split m{/}, $relative);
    open my $fh, '<:raw', $path or do {
        problem("cannot read $label: $relative: $!");
        return undef;
    };
    local $/;
    my $text = <$fh>;
    close $fh or problem("cannot close $label: $relative: $!");
    return $text;
}

sub safe_relative_path {
    my ($path) = @_;
    return 0 if ref($path) || !defined($path) || $path eq '';
    return 0 if File::Spec->file_name_is_absolute($path);
    return 0 if $path =~ /[\\\0\r\n]/ || $path =~ m{\A/|/\z|//};
    my @parts = split m{/}, $path, -1;
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } @parts;
    return 1;
}

sub validate_scalar {
    my ($value, $where, $maximum) = @_;
    if (ref($value) || !defined($value) || $value eq ''
        || $value =~ /[\0\r\n]/ || $value =~ /\A\s|\s\z/
        || length(encode('UTF-8', $value)) > $maximum) {
        problem("$where must be a nonempty single-line scalar <= $maximum bytes");
    }
}

sub validate_integer {
    my ($value, $minimum, $maximum, $where) = @_;
    if (!positive_integer($value) || $value < $minimum || $value > $maximum) {
        problem("$where must be an integer from $minimum through $maximum");
    }
}

sub positive_integer {
    my ($value) = @_;
    return defined($value) && !ref($value) && "$value" =~ /\A[1-9][0-9]*\z/;
}

sub exact_keys {
    my ($object, $required, $where) = @_;
    return if ref($object) ne 'HASH';
    my %allowed = map { $_ => 1 } @{$required};
    for my $key (@{$required}) {
        problem("$where is missing required key $key") if !exists $object->{$key};
    }
    for my $key (sort keys %{$object}) {
        problem("$where has unknown key $key") if !$allowed{$key};
    }
}

sub string_value {
    my ($value) = @_;
    return '' if !defined($value) || ref($value);
    return "$value";
}
