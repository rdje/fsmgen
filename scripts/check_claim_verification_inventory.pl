#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode FB_CROAK);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP;

my ($root_arg, $scope_arg, $inventory_arg, $write, $report, $help);
GetOptions(
    'root=s'      => \$root_arg,
    'scope=s'     => \$scope_arg,
    'inventory=s' => \$inventory_arg,
    'write'       => \$write,
    'report'      => \$report,
    'help|h'      => \$help,
) or usage(2);
usage(0) if $help;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "claim-inventory: invalid repository root\n"
    if !defined($root) || !-d $root;
my $scope_relative = $scope_arg
    // 'doctrine/claim_verification/inventory_scope.json';
my @problems;
my $json = JSON::PP->new->canonical(1)->utf8(1);
my %tracked = tracked_paths($root);
my $scope = read_scope($scope_relative);
my $inventory_relative = $inventory_arg // string_value($scope->{inventory_path});
validate_local_path($inventory_relative, 'inventory path');

my ($markdown_paths, $constant_paths) = expand_scope($scope, \%tracked);
my ($published, $partitions, $numeric_lines, $census_rows) =
    inventory_markdown($scope, $markdown_paths, \%tracked);
my $independent = independent_numeric_census($markdown_paths, $scope);
compare_census($census_rows, $independent);
my $constants = inventory_constants($constant_paths, \%tracked);
my $expected = render_inventory(
    $scope, $markdown_paths, $constant_paths, $published, $constants,
    $partitions, $numeric_lines, $census_rows
);

if (@problems) {
    print STDERR "claim-inventory: $_\n" for @problems;
    exit 1;
}

if ($write) {
    write_inventory($inventory_relative, $expected);
    print "claim-inventory: wrote $inventory_relative\n";
}

if (!$write || $report) {
    my $actual = read_relative($inventory_relative, 'tracked inventory');
    if (!defined($actual) || $actual ne $expected) {
        print STDERR "claim-inventory: inventory drift; run "
            . "scripts/check_claim_verification_inventory.pl --write\n";
        exit 1;
    }
}

my $quantified = grep {
    $_->{classification} eq 'actionable_quantitative'
} @{$published};
my $conservative = @{$published} - $quantified;
my $untracked = grep { $_->{producer_status} eq 'untracked' } @{$published};
my $unwatched = grep { $_->{watcher_status} eq 'missing' } @{$published};
print "claim-inventory: current-surface census and independent census agree "
    . "(numeric_lines=$numeric_lines, candidates=" . scalar(@{$published})
    . ", quantified=$quantified, conservative=$conservative, constants="
    . scalar(@{$constants}) . ", untracked_producers=$untracked, "
    . "unwatched_candidates=$unwatched)\n";
if ($report) {
    for my $name (sort keys %{$partitions}) {
        print "claim-inventory: partition $name=$partitions->{$name}\n";
    }
}
exit 0;

sub usage {
    my ($status) = @_;
    print <<'USAGE';
Usage:
  scripts/check_claim_verification_inventory.pl [--root DIR]
      [--scope FILE] [--inventory FILE] [--write] [--report]

Derives the current quantitative-claim and repository-constant census from
the governed live-document surfaces, proves an independent numeric-line census
has the same domain, and checks or regenerates the bounded JSONL inventory.
USAGE
    exit $status;
}

sub read_scope {
    my ($relative) = @_;
    validate_local_path($relative, 'scope path');
    my $raw = read_relative($relative, 'inventory scope');
    return {} if !defined $raw;
    problem('inventory scope exceeds 4096 bytes')
        if length($raw) > 4096;
    problem('inventory scope must be exactly one newline-terminated JSON object')
        if $raw !~ /\A[^\n]+\n\z/;
    my $scope = eval { $json->decode($raw) };
    if ($@ || ref($scope) ne 'HASH') {
        problem('inventory scope is not valid JSON');
        return {};
    }
    exact_keys(
        $scope,
        [qw(constant_globs derived_projection_paths excluded_operational_paths
            inventory_path local_adoption_paths portable_policy_paths
            record_type schema_version surface_ids surface_registry)],
        'inventory scope'
    );
    problem('inventory scope is not canonical JSON')
        if $json->encode($scope) . "\n" ne $raw;
    problem('inventory scope record_type must be scope')
        if string_value($scope->{record_type}) ne 'scope';
    problem('inventory scope schema_version must be 1')
        if string_value($scope->{schema_version}) ne '1';
    for my $field (qw(constant_globs derived_projection_paths
                      excluded_operational_paths local_adoption_paths
                      portable_policy_paths surface_ids)) {
        validate_string_array($scope->{$field}, "inventory scope $field", 64);
    }
    validate_local_path($scope->{surface_registry}, 'surface registry path');
    validate_local_path($scope->{inventory_path}, 'declared inventory path');
    return $scope;
}

sub expand_scope {
    my ($scope, $tracked) = @_;
    my $surface_relative = string_value($scope->{surface_registry});
    my $raw = read_relative($surface_relative, 'surface registry');
    my %wanted = map { $_ => 1 } @{$scope->{surface_ids} // []};
    my %seen_surface;
    my @patterns;
    my $line_number = 0;
    for my $line (split /\n/, $raw // '') {
        ++$line_number;
        next if $line eq '';
        my $record = eval { $json->decode($line) };
        if ($@ || ref($record) ne 'HASH') {
            problem("$surface_relative line $line_number is invalid JSON");
            next;
        }
        my $id = string_value($record->{surface_id});
        next if !$wanted{$id};
        $seen_surface{$id} = 1;
        if (ref($record->{targets}) ne 'ARRAY') {
            problem("selected surface $id has no target array");
            next;
        }
        push @patterns, @{$record->{targets}};
    }
    for my $id (sort keys %wanted) {
        problem("selected surface is absent: $id") if !$seen_surface{$id};
    }

    my %markdown;
    for my $pattern (@patterns) {
        my $regex = glob_regex($pattern);
        for my $path (keys %{$tracked}) {
            $markdown{$path} = 1 if $path =~ $regex && $path =~ /\.md\z/;
        }
    }
    my %constants;
    for my $pattern (@{$scope->{constant_globs} // []}) {
        my $regex = glob_regex($pattern);
        for my $path (keys %{$tracked}) {
            $constants{$path} = 1 if $path =~ $regex;
        }
    }
    problem('inventory scope expands to no Markdown paths') if !keys %markdown;
    problem('inventory scope expands to no constant paths') if !keys %constants;
    my %classified_scope_path;
    for my $field (qw(derived_projection_paths excluded_operational_paths
                      local_adoption_paths portable_policy_paths)) {
        for my $path (@{$scope->{$field} // []}) {
            problem("inventory scope $field path is not tracked: $path")
                if !$tracked->{$path};
            problem("inventory scope $field path is outside selected Markdown surfaces: $path")
                if !$markdown{$path};
            problem("inventory scope path has multiple structural classifications: $path")
                if $classified_scope_path{$path}++;
        }
    }
    return ([sort keys %markdown], [sort keys %constants]);
}

sub inventory_markdown {
    my ($scope, $paths, $tracked) = @_;
    my %excluded = map { $_ => 1 } @{$scope->{excluded_operational_paths} // []};
    my %portable = map { $_ => 1 } @{$scope->{portable_policy_paths} // []};
    my %derived_projection = map {
        $_ => 1
    } @{$scope->{derived_projection_paths} // []};
    my %local_adoption = map { $_ => 1 } @{$scope->{local_adoption_paths} // []};
    my %partitions = (
        adoption_reference_or_structure => 0,
        code_or_data_example => 0,
        derived_and_watched_projection => 0,
        identifier_literal_or_navigation => 0,
    );
    my @published;
    my @census_rows;
    my $numeric_lines = 0;

    for my $path (@{$paths}) {
        next if $excluded{$path};
        my $raw = read_relative($path, "current surface $path");
        next if !defined $raw;
        my $text = eval { decode('UTF-8', $raw, FB_CROAK) };
        if ($@) {
            problem("current surface is not UTF-8: $path");
            next;
        }
        my @lines = split /\n/, $text, -1;
        my $in_fence = 0;
        my $adoption_body = $local_adoption{$path}
            ? adoption_body_line(\@lines) : undef;
        my %occurrence;
        for my $index (0 .. $#lines) {
            my $line_number = $index + 1;
            my $line = $lines[$index];
            if ($line =~ /^\s*```/) {
                $in_fence = !$in_fence;
                next;
            }
            next if $line !~ /[0-9]/;
            ++$numeric_lines;
            my $line_bytes = encode('UTF-8', $line);
            my $line_sha = sha256_hex($line_bytes);
            push @census_rows, "$path\0$line_number\0$line_sha";

            if ($in_fence || $line =~ /\A(?: {4}|\t)/) {
                ++$partitions{code_or_data_example};
                next;
            }
            if ($portable{$path}
                || (defined($adoption_body) && $line_number >= $adoption_body)) {
                ++$partitions{adoption_reference_or_structure};
                next;
            }
            if ($derived_projection{$path}) {
                ++$partitions{derived_and_watched_projection};
                next;
            }
            my ($classification, $reason, $tokens) = classify_prose($line);
            if ($classification eq 'incidental') {
                ++$partitions{identifier_literal_or_navigation};
                next;
            }
            my $normalized = $line;
            $normalized =~ s/^\s+|\s+$//g;
            $normalized =~ s/\s+/ /g;
            my $ordinal = ++$occurrence{$normalized};
            my $id = 'published-' . substr(
                sha256_hex(encode(
                    'UTF-8', join("\0", $path, $normalized, $ordinal)
                )), 0, 24
            );
            my ($producer_status, $producer_paths, $untracked_paths) =
                referenced_producers($line, $tracked);
            push @published, {
                candidate_id => $id,
                classification => $classification,
                excerpt => truncate_utf8($normalized, 512),
                line => $line_number,
                migration_owner => 'CLAIM-VERIFICATION-ADOPTION.5',
                path => $path,
                producer_paths => $producer_paths,
                producer_status => $producer_status,
                reason => $reason,
                record_type => 'published_candidate',
                schema_version => 1,
                source_line_sha256 => $line_sha,
                tokens => $tokens,
                untracked_paths => $untracked_paths,
                verification_legs => {
                    durability => 'missing',
                    falsify => 'missing',
                    rederive => 'missing',
                },
                watcher_paths => [],
                watcher_status => 'missing',
            };
        }
        problem("unclosed Markdown fence in $path") if $in_fence;
    }
    @published = sort {
        $a->{path} cmp $b->{path}
            || $a->{line} <=> $b->{line}
            || $a->{candidate_id} cmp $b->{candidate_id}
    } @published;
    return (\@published, \%partitions, $numeric_lines, \@census_rows);
}

sub classify_prose {
    my ($line) = @_;
    return ('incidental', 'identifier_literal_or_navigation', [])
        if $line =~ /^\s*\[[^]]+\]\([^)]*\)\s*$/;
    my $scan = $line;
    $scan =~ s{\]\([^)]*\)}{]}g;
    my $number = qr{(?:[0-9][0-9_,]*(?:\.[0-9]+)?|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)}i;
    my $noun = qr{(?:%|percent|bytes?|lines?|files?|tests?|facts?|questions?|occurrences?|shards?|records?|paths?|chapters?|commands?|cases?|examples?|entries?|rows?|nodes?|trees?|segments?|migrations?|surfaces?|members?|actors?|states?|transitions?|cycles?|ticks?|seconds?|minutes?|hours?|days?|weeks?|KiB|MiB|GiB|KB|MB|GB|bits?|ports?|signals?|operations?|scenarios?|fibers?|types?|bindings?|maps?|attempts?|levels?|lanes?|beats?|requests?|responses?|slots?|events?|declarations?|parameters?|fields?|rules?|families?|symbols?|instruments?|artifacts?|profiles?|ranges?|parts?|inputs?)}i;
    my @tokens;
    while ($scan =~ /(\b$number\s*(?:-|\s)\s*$noun\b|\b(?:exactly|at least|at most|more than|fewer than|less than|up to)\s+$number\b|\b$number\s*(?:x|×)\b)/ig) {
        push @tokens, $1;
    }
    if (@tokens) {
        my %seen;
        @tokens = grep { !$seen{$_}++ } @tokens;
        splice @tokens, 16 if @tokens > 16;
        return ('actionable_quantitative', 'quantified_prose', \@tokens);
    }

    my $outside = $scan;
    $outside =~ s/`[^`]*`//g;
    $outside =~ s{https?://\S+}{}g;
    $outside =~ s/^\s*[0-9]+[.)]\s+//;
    $outside =~ s/\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b//g;
    $outside =~ s/\[[0-9][0-9., -]*\]//g;
    $outside =~ s/\b(?:revision|version|phase|chapter|section|decision)\s+[0-9]+(?:\.[0-9]+)*\b//ig;
    $outside =~ s/\b(?:intent\s+abstraction\s+)?layer\s+[0-9]+\b//ig;
    $outside =~ s/\b(?:v?\d+(?:\.\d+)+|[A-Z]+\d+(?:\.\d+)*)\b//g;
    $outside =~ s/\b[A-Za-z_][A-Za-z0-9_.-]*[0-9][A-Za-z0-9_.-]*\b//g;
    $outside =~ s/(?:\A|\s)\.[0-9]+(?=\s|\z)//g;
    if ($outside !~ /[0-9]/
        || $outside =~ /^\s*#{1,6}\s*(?:\d+[a-z]?|[A-Z]+\d+)[.):-]?\s*/
        || $outside =~ /^\s*[-*]\s+\[[ x]\]\s+[A-Z0-9.-]+/) {
        return ('incidental', 'identifier_literal_or_navigation', []);
    }
    return ('actionable_review_debt', 'numeric_prose_requires_review', []);
}

sub referenced_producers {
    my ($line, $tracked) = @_;
    my @tokens;
    while ($line =~ /`([^`]+)`/g) {
        push @tokens, split /\s+/, $1;
    }
    my (%seen_tracked, %seen_untracked);
    for my $token (@tokens) {
        $token =~ s/^[('"\[]+|[),;'"\]]+$//g;
        $token =~ s/[#:].*\z// if $token =~ m{/};
        next if $token =~ m{/\z};
        next if $token !~ m{\A(?:bin|scripts|t|perl|rust|doctrine|knowledge-map)/[A-Za-z0-9_./-]+\z};
        next if $token =~ m{(?:^|/)\.\.(?:/|$)};
        if ($tracked->{$token}) {
            $seen_tracked{$token} = 1;
        } elsif ($token =~ m{\At/[0-9]+\z}) {
            my @resolved = sort grep {
                /^\Q$token\E(?:[-.])/
            } keys %{$tracked};
            if (@resolved == 1) {
                $seen_tracked{$resolved[0]} = 1;
            } else {
                $seen_untracked{$token} = 1;
            }
        } else {
            $seen_untracked{$token} = 1;
        }
    }
    my @tracked_paths = sort keys %seen_tracked;
    my @untracked_paths = sort keys %seen_untracked;
    my $status = @untracked_paths ? 'untracked'
        : @tracked_paths ? 'referenced_tracked' : 'missing';
    return ($status, \@tracked_paths, \@untracked_paths);
}

sub inventory_constants {
    my ($paths, $tracked) = @_;
    my @records;
    for my $path (@{$paths}) {
        my $raw = read_relative($path, "constant source $path");
        next if !defined $raw;
        my $line_number = 0;
        for my $line (split /\n/, $raw) {
            ++$line_number;
            next if $line eq '';
            my $object = eval { $json->decode($line) };
            if ($@ || ref($object) ne 'HASH') {
                problem("constant source $path line $line_number is invalid JSON");
                next;
            }
            walk_numeric_leaves($path, $line_number, '', $object, \@records, $tracked);
        }
    }
    @records = sort {
        $a->{path} cmp $b->{path}
            || $a->{line} <=> $b->{line}
            || $a->{source_pointer} cmp $b->{source_pointer}
    } @records;
    return \@records;
}

sub walk_numeric_leaves {
    my ($path, $line, $pointer, $value, $records, $tracked) = @_;
    if (ref($value) eq 'HASH') {
        for my $key (sort keys %{$value}) {
            my $escaped = $key;
            $escaped =~ s/~/~0/g;
            $escaped =~ s{/}{~1}g;
            walk_numeric_leaves(
                $path, $line, "$pointer/$escaped", $value->{$key}, $records, $tracked
            );
        }
        return;
    }
    if (ref($value) eq 'ARRAY') {
        for my $index (0 .. $#{$value}) {
            walk_numeric_leaves(
                $path, $line, "$pointer/$index", $value->[$index], $records, $tracked
            );
        }
        return;
    }
    return if !defined($value) || ref($value)
        || string_value($value) !~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?\z/;
    my ($classification, $reason, $legs, $producer, $oracle) =
        constant_disposition($path, $pointer);
    my @watchers = grep { $tracked->{$_} } ('scripts/check_doctrines.sh');
    my @producer_paths = grep { $tracked->{$_} } @{$producer};
    my @oracle_paths = grep { $tracked->{$_} } @{$oracle};
    if ($classification ne 'incidental_schema_identifier') {
        problem("repository constant has no tracked producer: $path$pointer")
            if !@producer_paths;
        problem("repository constant has no tracked falsification oracle: $path$pointer")
            if !@oracle_paths;
        problem("repository constant has no tracked doctrine watcher: $path$pointer")
            if !@watchers;
    }
    my $id = 'constant-' . substr(
        sha256_hex(join("\0", $path, $line, $pointer)), 0, 24
    );
    push @{$records}, {
        classification => $classification,
        constant_id => $id,
        line => $line,
        migration_owner => undef,
        oracle_paths => \@oracle_paths,
        path => $path,
        producer_paths => \@producer_paths,
        reason => $reason,
        record_type => 'repository_constant',
        schema_version => 1,
        source_pointer => $pointer,
        value => string_value($value),
        verification_legs => $legs,
        watcher_paths => \@watchers,
    };
}

sub constant_disposition {
    my ($path, $pointer) = @_;
    my ($producer, $oracle);
    if ($path =~ m{\Adoctrine/task_tree/}) {
        $producer = ['scripts/check_task_tree_integrity.pl'];
        $oracle = ['t/1549-task-tree-integrity-doctrine.t'];
    } elsif ($path =~ m{\Adoctrine/claim_verification/disposition}) {
        $producer = ['scripts/check_claim_verification_dispositions.pl'];
        $oracle = ['t/1638-claim-verification-dispositions.t'];
    } elsif ($path =~ m{\Adoctrine/claim_verification/}) {
        $producer = ['scripts/check_claim_verification.pl'];
        $oracle = ['t/1636-claim-verification-doctrine.t'];
    } else {
        $producer = ['scripts/check_live_document_size.sh'];
        $oracle = ['t/1554-live-document-size-doctrine.t'];
    }
    if ($pointer =~ m{/schema_version\z}) {
        return (
            'incidental_schema_identifier', 'schema_identifier',
            {durability => 'not_applicable', falsify => 'not_applicable',
             rederive => 'not_applicable'}, $producer, $oracle
        );
    }
    if ($pointer =~ m{/(?:baseline|delta|lines|bytes|files|count|entries|nodes|terminal_rows|unique_tree_ids)(?:/|\z)}) {
        return (
            'repository_derived_constant', 'derived_and_watched_control_value',
            {durability => 'available', falsify => 'available',
             rederive => 'available'}, $producer, $oracle
        );
    }
    return (
        'configured_policy_constant', 'declared_and_watched_policy_input',
        {durability => 'available', falsify => 'available',
         rederive => 'not_applicable_policy_input'}, $producer, $oracle
    );
}

sub independent_numeric_census {
    my ($paths, $scope) = @_;
    my %excluded = map { $_ => 1 } @{$scope->{excluded_operational_paths} // []};
    my @included = grep { !$excluded{$_} } @{$paths};
    open my $git, '-|', 'git', '-C', $root, 'grep', '-n', '-I',
        '-e', '[0-9]', '--', @included
        or do {
            problem('cannot execute independent git-grep census');
            return [];
        };
    my @rows;
    while (my $line = <$git>) {
        chomp $line;
        if ($line !~ /\A(.+?):([0-9]+):(.*)\z/s) {
            problem('independent census emitted an unparsable row');
            next;
        }
        my ($path, $line_number, $text) = ($1, $2, $3);
        push @rows, "$path\0$line_number\0" . sha256_hex($text);
    }
    close $git or problem('independent git-grep census failed');
    return \@rows;
}

sub compare_census {
    my ($direct, $independent) = @_;
    my @left = sort @{$direct};
    my @right = sort @{$independent};
    if (join("\n", @left) ne join("\n", @right)) {
        problem('direct and independent numeric-line censuses disagree');
    }
}

sub render_inventory {
    my ($scope, $markdown, $constants_paths, $published, $constants,
        $partitions, $numeric_lines, $census_rows) = @_;
    my $metadata = {
        max_bytes => 8_388_608,
        max_record_bytes => 4096,
        max_records => 8192,
        record_type => 'registry',
        schema_version => 1,
    };
    for my $path (
        'doctrine/claim_verification/inventory_scope.json',
        'scripts/check_claim_verification_inventory.pl',
        'scripts/check_doctrines.sh',
        't/1637-claim-verification-inventory.t'
    ) {
        problem("inventory verification path is not tracked: $path")
            if !$tracked{$path};
    }
    my $scope_sha = sha256_hex($json->encode($scope));
    my $census = {
        candidate_records => scalar(@{$published}),
        constant_records => scalar(@{$constants}),
        constant_source_paths => scalar(@{$constants_paths}),
        excluded_operational_paths => scalar(
            @{$scope->{excluded_operational_paths} // []}
        ),
        incidental_partitions => $partitions,
        markdown_source_paths => scalar(@{$markdown}),
        numeric_census_sha256 => sha256_hex(join("\n", sort @{$census_rows})),
        numeric_lines => $numeric_lines,
        record_type => 'census',
        schema_version => 1,
        scope_paths_sha256 => sha256_hex(join("\n", @{$markdown}, @{$constants_paths})),
        scope_sha256 => $scope_sha,
        verification_legs => {
            durability => {
                evidence => 'The registered CLAIM-INVENTORY doctrine compares the tracked JSONL byte-for-byte with a fresh derivation.',
                producer_paths => [
                    'doctrine/claim_verification/inventory_scope.json',
                    'scripts/check_claim_verification_inventory.pl',
                ],
                status => 'available',
                watcher_paths => ['scripts/check_doctrines.sh'],
            },
            falsify => {
                competing_hypothesis => 'The direct scanner missed numeric lines or an unknown numeric form was silently classified as incidental.',
                evidence => 'An independent git-grep census must agree; source and classifier mutations in t/1637 must make the tracked inventory RED or create owned actionable debt.',
                oracle_paths => ['t/1637-claim-verification-inventory.t'],
                status => 'available',
            },
            rederive => {
                evidence => 'Run scripts/check_claim_verification_inventory.pl --write --report from the repository root.',
                producer_paths => ['scripts/check_claim_verification_inventory.pl'],
                status => 'available',
            },
        },
    };
    my @records = ($metadata, $census, @{$published}, @{$constants});
    my @lines = map { $json->encode($_) } @records;
    my $raw = join("\n", @lines) . "\n";
    problem('rendered inventory exceeds max_records')
        if @records - 1 > $metadata->{max_records};
    problem('rendered inventory exceeds max_bytes')
        if length($raw) > $metadata->{max_bytes};
    for my $index (0 .. $#lines) {
        problem('rendered inventory line ' . ($index + 1)
            . ' exceeds max_record_bytes')
            if length($lines[$index]) > $metadata->{max_record_bytes};
    }
    return $raw;
}

sub write_inventory {
    my ($relative, $contents) = @_;
    die "claim-inventory: unsafe inventory output path\n"
        if !validate_local_path($relative, 'inventory output path');
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    die "claim-inventory: inventory output cannot be a symlink: $relative\n"
        if -l $path;
    my $parent = abs_path(dirname($path));
    die "claim-inventory: inventory output parent escapes repository: $relative\n"
        if !defined($parent) || !within_root($parent);
    open my $fh, '>:raw', $path
        or die "claim-inventory: cannot write $relative: $!\n";
    print {$fh} $contents;
    close $fh or die "claim-inventory: cannot close $relative: $!\n";
}

sub adoption_body_line {
    my ($lines) = @_;
    my $saw_end = 0;
    for my $index (0 .. $#{$lines}) {
        $saw_end = 1 if $lines->[$index] =~ /LOCAL-ADOPTION:END -->/;
        return $index + 2 if $saw_end && $lines->[$index] eq '---';
    }
    problem('local-adoption path has no fenced neutral body boundary');
    return undef;
}

sub glob_regex {
    my ($glob) = @_;
    if (ref($glob) || !defined($glob) || $glob eq '' || $glob =~ /[\\\0]/) {
        problem('invalid scope glob');
        return qr/\A\b\B\z/;
    }
    my $regex = '';
    my @chars = split //, $glob;
    for (my $index = 0; $index < @chars; ++$index) {
        if ($chars[$index] eq '*' && $index + 1 < @chars
            && $chars[$index + 1] eq '*') {
            $regex .= '.*';
            ++$index;
        } elsif ($chars[$index] eq '*') {
            $regex .= '[^/]*';
        } elsif ($chars[$index] eq '?') {
            $regex .= '[^/]';
        } else {
            $regex .= quotemeta($chars[$index]);
        }
    }
    return qr/\A$regex\z/;
}

sub tracked_paths {
    my ($base) = @_;
    my %paths;
    open my $git, '-|', 'git', '-C', $base, 'ls-files', '-z'
        or die "claim-inventory: cannot execute git ls-files\n";
    local $/ = "\0";
    while (my $path = <$git>) {
        chop $path;
        $paths{$path} = 1 if $path ne '';
    }
    close $git or die "claim-inventory: git ls-files failed\n";
    return %paths;
}

sub read_relative {
    my ($relative, $label) = @_;
    return undef if !validate_local_path($relative, "$label path");
    my $path = File::Spec->catfile($root, split m{/}, $relative);
    if (-l $path) {
        problem("cannot read $label through a symlink: $relative");
        return undef;
    }
    my $resolved = abs_path($path);
    if (!defined($resolved) || !within_root($resolved) || !-f $resolved) {
        problem("cannot read $label as a repository-local regular file: $relative");
        return undef;
    }
    open my $fh, '<:raw', $path or do {
        problem("cannot read $label: $relative: $!");
        return undef;
    };
    local $/;
    my $raw = <$fh>;
    close $fh or problem("cannot close $label: $relative: $!");
    return $raw;
}

sub within_root {
    my ($path) = @_;
    return $path eq $root || index($path, "$root/") == 0;
}

sub validate_local_path {
    my ($path, $where) = @_;
    if (ref($path) || !defined($path) || $path eq ''
        || File::Spec->file_name_is_absolute($path)
        || $path =~ /[\\\0\r\n]/ || $path =~ m{\A/|/\z|//}
        || grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/}, $path) {
        problem("$where is not a repository-relative local path");
        return 0;
    }
    return 1;
}

sub validate_string_array {
    my ($value, $where, $maximum) = @_;
    if (ref($value) ne 'ARRAY') {
        problem("$where must be an array");
        return;
    }
    problem("$where exceeds $maximum entries") if @{$value} > $maximum;
    my %seen;
    for my $item (@{$value}) {
        problem("$where has an invalid scalar")
            if ref($item) || !defined($item) || $item eq '';
        problem("$where duplicates $item") if $seen{$item}++;
    }
    my @sorted = sort @{$value};
    problem("$where must be sorted")
        if join("\0", @{$value}) ne join("\0", @sorted);
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

sub truncate_utf8 {
    my ($text, $maximum) = @_;
    return $text if length(encode('UTF-8', $text)) <= $maximum;
    while (length(encode('UTF-8', $text . '...')) > $maximum) {
        chop $text;
    }
    return $text . '...';
}

sub string_value {
    my ($value) = @_;
    return '' if !defined($value) || ref($value);
    return "$value";
}

sub problem {
    push @problems, $_[0];
}
