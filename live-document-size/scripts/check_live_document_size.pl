#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA;
use Encode qw(encode_utf8);
use File::Basename qw(basename dirname);
use File::Glob qw(bsd_glob GLOB_NOSORT);
use File::Spec;
use Getopt::Long qw(GetOptions);
use JSON::PP;

my ($root_arg, $registry_arg, $routes_arg, $archives_arg, $ledgers_arg,
    $evidence_maps_arg, $retention_contracts_arg, $coverage_stdin, $help);
my @adapter_proofs;
GetOptions(
    'root=s'          => \$root_arg,
    'registry=s'      => \$registry_arg,
    'routes=s'        => \$routes_arg,
    'archives=s'      => \$archives_arg,
    'ledgers=s'       => \$ledgers_arg,
    'evidence-maps=s' => \$evidence_maps_arg,
    'retention-contracts=s' => \$retention_contracts_arg,
    'coverage-stdin!' => \$coverage_stdin,
    'adapter-proof=s@' => \@adapter_proofs,
    'help|h'          => \$help,
) or usage(2);
usage(0) if $help;
usage(2) if !defined($root_arg) || !defined($registry_arg)
    || !defined($routes_arg) || !defined($archives_arg)
    || !defined($ledgers_arg)
    || !defined($evidence_maps_arg) || !defined($retention_contracts_arg);

my $root = abs_path($root_arg);
if (!defined($root) || !-d $root) {
    print STDERR "live-doc-size: invalid project root: $root_arg\n";
    exit 2;
}
my $root_device = (stat($root))[0];
my $fail = 0;
my $PORTABLE_MAX_REGISTRY_BYTES = 16 * 1024 * 1024;
my $PORTABLE_MAX_RECORD_BYTES = 64 * 1024;
my $PORTABLE_MAX_RECORDS = 10_000;

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_live_document_size.pl --root DIR --registry FILE --routes FILE
       --archives FILE --ledgers FILE --evidence-maps FILE
       --retention-contracts FILE
       [--coverage-stdin]
USAGE
    exit $status;
}

sub problem {
    my ($message) = @_;
    print STDERR "live-doc-size: $message\n";
    $fail = 1;
}

sub ok_note {
    my ($message) = @_;
    print "live-doc-size: ok:   $message\n";
}

sub relative_path_ok {
    my ($path) = @_;
    return 0 if !defined($path) || $path eq '' || $path =~ /\0/;
    return 0 if File::Spec->file_name_is_absolute($path) || $path =~ m{^~(?:/|$)};
    return 0 if grep { $_ eq '..' } split m{/+}, $path;
    return 1;
}

sub root_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub positive_integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A[1-9][0-9]*\z/;
}

sub nonnegative_integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A[0-9]+\z/;
}

sub signed_integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A-?[0-9]+\z/;
}

sub bounded_nonempty_string {
    my ($value, $max_bytes) = @_;
    return !ref($value) && defined($value) && $value ne ''
        && $value !~ /[\r\n]/ && length(encode_utf8($value)) <= $max_bytes;
}

sub expand_patterns {
    my ($surface_id, $patterns) = @_;
    my %seen;
    my @matches;
    for my $pattern (@{$patterns}) {
        if (!relative_path_ok($pattern)) {
            problem("surface $surface_id target must stay project-relative: $pattern");
            next;
        }
        my $absolute_pattern = root_path($pattern);
        for my $match (bsd_glob($absolute_pattern, GLOB_NOSORT)) {
            next if $seen{$match}++;
            push @matches, $match;
        }
    }
    return sort @matches;
}

sub assert_local_regular_file {
    my ($surface_id, $path) = @_;
    if (-l $path) {
        problem("surface $surface_id target is a symlink: " . display_path($path));
        return 0;
    }
    if (!-f $path) {
        problem("surface $surface_id target is not a regular file: " . display_path($path));
        return 0;
    }
    my $device = (stat($path))[0];
    if (!defined($device) || $device != $root_device) {
        problem("surface $surface_id target is not on the project-root volume: " . display_path($path));
        return 0;
    }
    return 1;
}

sub assert_local_directory {
    my ($surface_id, $path) = @_;
    if (-l $path) {
        problem("surface $surface_id target is a symlink: " . display_path($path));
        return 0;
    }
    if (!-d $path) {
        problem("surface $surface_id target directory is absent: " . display_path($path));
        return 0;
    }
    my $device = (stat($path))[0];
    if (!defined($device) || $device != $root_device) {
        problem("surface $surface_id directory is not on the project-root volume: " . display_path($path));
        return 0;
    }
    return 1;
}

sub display_path {
    my ($path) = @_;
    my $prefix = $root;
    $prefix .= '/' if $prefix !~ m{/$};
    return substr($path, length($prefix)) if index($path, $prefix) == 0;
    return $path;
}

sub file_measurement {
    my ($path) = @_;
    open my $fh, '<:raw', $path or do {
        problem("cannot read " . display_path($path) . ": $!");
        return (0, 0, 0);
    };
    my ($lines, $bytes, $max_line_bytes) = (0, 0, 0);
    while (my $line = <$fh>) {
        my $line_bytes = length($line);
        $bytes += $line_bytes;
        if ($line =~ /\n\z/) {
            $lines++;
            $line_bytes--;
            $line_bytes-- if $line_bytes > 0 && substr($line, $line_bytes - 1, 1) eq "\r";
        }
        $max_line_bytes = $line_bytes if $line_bytes > $max_line_bytes;
    }
    problem("cannot read " . display_path($path) . ": $!") if !eof($fh);
    close $fh or problem("cannot close " . display_path($path) . ": $!");
    return ($lines, $bytes, $max_line_bytes);
}

sub file_sha256 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or do {
        problem("cannot hash " . display_path($path) . ": $!");
        return '';
    };
    my $digest = Digest::SHA->new(256);
    $digest->addfile($fh);
    close $fh or problem("cannot close " . display_path($path) . ": $!");
    return $digest->hexdigest;
}

sub read_regular_file {
    my ($surface_id, $relative) = @_;
    return undef if !relative_path_ok($relative);
    my $path = root_path($relative);
    return undef if !assert_local_regular_file($surface_id, $path);
    open my $fh, '<:raw', $path or do {
        problem("cannot read " . display_path($path) . ": $!");
        return undef;
    };
    local $/;
    my $contents = <$fh> // '';
    close $fh or problem("cannot close " . display_path($path) . ": $!");
    return $contents;
}

sub raw_line_count {
    my ($contents) = @_;
    return ($contents =~ tr/\n//);
}

sub ledger_entries {
    my ($ledger_id, $contents, $prefix, $allow_preamble) = @_;
    my @starts;
    while ($contents =~ /(?:\A|\n)\Q$prefix\E/g) {
        my $start = $-[0];
        $start++ if $start > 0;
        push @starts, $start;
    }
    if (!@starts) {
        problem("ledger $ledger_id contains no entry beginning with its declared prefix");
        return (undef, []);
    }
    if (!$allow_preamble && $starts[0] != 0) {
        problem("ledger $ledger_id sealed range has bytes before its first whole entry");
    }
    my @entries;
    for my $index (0 .. $#starts) {
        my $end = $index == $#starts ? length($contents) : $starts[$index + 1];
        push @entries, substr($contents, $starts[$index], $end - $starts[$index]);
    }
    my $body = join('', @entries);
    return ($body, \@entries);
}

my %adapter_proof;
for my $proof (@adapter_proofs) {
    if ($proof !~ /\A(?:surface|archive|currency|ledger):[a-z][a-z0-9_.-]*\z/) {
        problem("invalid adapter proof id: $proof");
        next;
    }
    problem("adapter proof is declared more than once: $proof") if $adapter_proof{$proof}++;
}

sub execute_core_verifier {
    my ($label, $relative, $guidance) = @_;
    $guidance //= '';
    if (!relative_path_ok($relative) || !-f root_path($relative) || !-x root_path($relative)) {
        problem("$label core verifier is absent or not executable: $relative$guidance");
        return;
    }
    my $pid = fork();
    if (!defined $pid) {
        problem("$label cannot fork core verifier $relative: $!$guidance");
        return;
    }
    if ($pid == 0) {
        chdir $root or do {
            print STDERR "live-doc-size: $label cannot enter project root: $!\n";
            exit 126;
        };
        open STDIN, '<', File::Spec->devnull() or exit 126;
        my $absolute = root_path($relative);
        my $status = system {$absolute} $absolute;
        if ($status == -1) {
            print STDERR "live-doc-size: $label cannot execute $relative: $!\n";
            exit 126;
        }
        exit(128 + ($status & 127)) if $status & 127;
        exit($status >> 8);
    }
    waitpid($pid, 0);
    if ($? != 0) {
        my $status = $? & 127 ? 'signal ' . ($? & 127) : 'exit ' . ($? >> 8);
        problem("$label core verifier failed ($status): $relative$guidance");
        return;
    }
    ok_note("$label core verifier executed: $relative");
}

sub verify_execution {
    my ($label, $proof_id, $verifier, $guidance) = @_;
    $guidance //= '';
    if ($verifier =~ /\Acore:(.+)\z/) {
        execute_core_verifier($label, $1, $guidance);
    } elsif ($verifier =~ /\Aadapter:(.+)\z/) {
        my $relative = $1;
        problem("$label adapter verifier is absent or not executable: $relative$guidance")
            if !relative_path_ok($relative) || !-f root_path($relative) || !-x root_path($relative);
        if (!$adapter_proof{$proof_id}) {
            problem("$label adapter verifier lacks executed proof: $proof_id$guidance");
        } else {
            delete $adapter_proof{$proof_id};
            ok_note("$label adapter verifier execution proved: $proof_id");
        }
    } elsif ($verifier =~ /\Aexternal:(.+)\z/) {
        problem("$label external verification is declared but not locally proven; degraded result: $1$guidance");
    } else {
        problem("$label verifier must declare core:, adapter:, or external: execution$guidance");
    }
}

sub read_jsonl {
    my ($relative, $label) = @_;
    if (!relative_path_ok($relative)) {
        problem("$label path must stay project-relative: $relative");
        return [];
    }
    my $path = root_path($relative);
    if (-l $path) {
        problem("$label is a symlink: $relative");
        return [];
    }
    if (!-f $path) {
        problem("$label is missing: $relative");
        return [];
    }
    my $device = (stat($path))[0];
    if (!defined($device) || $device != $root_device) {
        problem("$label is not on the project-root volume: $relative");
        return [];
    }
    my $file_bytes = -s $path;
    if (!defined($file_bytes) || $file_bytes > $PORTABLE_MAX_REGISTRY_BYTES) {
        problem("$label exceeds portable file bound $PORTABLE_MAX_REGISTRY_BYTES bytes");
        return [];
    }
    open my $fh, '<:raw', $path or do {
        problem("cannot read $label $relative: $!");
        return [];
    };
    my @decoded;
    my @record_bytes;
    my $line_number = 0;
    while (my $line = <$fh>) {
        $line_number++;
        $line =~ s/\r?\n\z//;
        my $encoded_bytes = length($line);
        if ($encoded_bytes > $PORTABLE_MAX_RECORD_BYTES) {
            problem("$label line $line_number exceeds portable record bound $PORTABLE_MAX_RECORD_BYTES bytes");
            next;
        }
        if ($line eq '') {
            problem("$label line $line_number is blank; every JSONL line must be a JSON object");
            next;
        }
        my $record = eval { decode_json($line) };
        if ($@) {
            my $error = $@;
            $error =~ s/\s+\z//;
            problem("$label line $line_number is invalid JSON: $error");
            next;
        }
        if (ref($record) ne 'HASH') {
            problem("$label line $line_number must be a JSON object");
            next;
        }
        push @decoded, [$line_number, $record];
        push @record_bytes, [$line_number, $encoded_bytes];
    }
    close $fh or problem("cannot close $label $relative: $!");
    if (!@decoded) {
        problem("$label lacks its bounded registry metadata record");
        return [];
    }
    my ($metadata_line, $metadata) = @{shift @decoded};
    my ($ignored_metadata_line, $metadata_bytes) = @{shift @record_bytes};
    my @metadata_keys = qw(
        record_type schema_version max_records max_bytes max_record_bytes
    );
    my $metadata_valid = validate_keys(
        $label, $metadata_line, $metadata, \@metadata_keys, [],
    );
    if (($metadata->{record_type} // '') ne 'registry'
            || !nonnegative_integer($metadata->{schema_version})
            || $metadata->{schema_version} ne '1') {
        problem("$label must begin with a schema-version 1 registry metadata record");
        $metadata_valid = 0;
    }
    for my $key (qw(max_records max_bytes max_record_bytes)) {
        if (!positive_integer($metadata->{$key})) {
            problem("$label metadata has invalid positive $key");
            $metadata_valid = 0;
        }
    }
    if ($metadata_valid) {
        problem("$label max_records $metadata->{max_records} exceeds portable bound $PORTABLE_MAX_RECORDS")
            if $metadata->{max_records} > $PORTABLE_MAX_RECORDS;
        problem("$label max_bytes $metadata->{max_bytes} exceeds portable bound $PORTABLE_MAX_REGISTRY_BYTES")
            if $metadata->{max_bytes} > $PORTABLE_MAX_REGISTRY_BYTES;
        problem("$label max_record_bytes $metadata->{max_record_bytes} exceeds portable bound $PORTABLE_MAX_RECORD_BYTES")
            if $metadata->{max_record_bytes} > $PORTABLE_MAX_RECORD_BYTES;
        problem("$label max_record_bytes exceeds its max_bytes")
            if $metadata->{max_record_bytes} > $metadata->{max_bytes};
        problem("$label metadata line is $metadata_bytes bytes (> max_record_bytes $metadata->{max_record_bytes})")
            if $metadata_bytes > $metadata->{max_record_bytes};
        problem("$label record count " . scalar(@decoded)
            . " exceeds declared max_records $metadata->{max_records}")
            if @decoded > $metadata->{max_records};
        problem("$label size $file_bytes exceeds declared max_bytes $metadata->{max_bytes}")
            if $file_bytes > $metadata->{max_bytes};
        for my $measurement (@record_bytes) {
            my ($record_line, $bytes) = @{$measurement};
            problem("$label line $record_line is $bytes bytes (> max_record_bytes $metadata->{max_record_bytes})")
                if $bytes > $metadata->{max_record_bytes};
        }
    }
    return \@decoded;
}

sub validate_keys {
    my ($label, $line_number, $record, $required, $optional) = @_;
    my %allowed = map { $_ => 1 } (@{$required}, @{$optional});
    my $valid = 1;
    for my $key (@{$required}) {
        if (!exists $record->{$key}) {
            problem("$label line $line_number is missing required key: $key");
            $valid = 0;
        }
    }
    for my $key (sort keys %{$record}) {
        if (!$allowed{$key}) {
            problem("$label line $line_number has unknown key: $key");
            $valid = 0;
        }
    }
    return $valid;
}

sub string_array {
    my ($label, $line_number, $value, $allow_empty, $max_items, $max_entry_bytes) = @_;
    if (ref($value) ne 'ARRAY' || (!$allow_empty && !@{$value})) {
        problem("$label line $line_number must be a "
            . ($allow_empty ? '' : 'non-empty ') . 'array of strings');
        return [];
    }
    if (@{$value} > $max_items) {
        problem("$label line $line_number has " . scalar(@{$value})
            . " entries (> maximum $max_items)");
        return [];
    }
    for my $entry (@{$value}) {
        if (!bounded_nonempty_string($entry, $max_entry_bytes)) {
            problem("$label line $line_number must contain only non-empty single-line strings <= $max_entry_bytes bytes");
            return [];
        }
    }
    return $value;
}

sub exact_numeric_object {
    my ($label, $line_number, $value, $keys, $allow_zero) = @_;
    if (ref($value) ne 'HASH') {
        problem("$label line $line_number must be an object");
        return undef;
    }
    return undef if !validate_keys($label, $line_number, $value, $keys, []);
    for my $key (@{$keys}) {
        my $valid = $allow_zero
            ? nonnegative_integer($value->{$key})
            : positive_integer($value->{$key});
        if (!$valid) {
            problem("$label line $line_number has invalid "
                . ($allow_zero ? 'nonnegative ' : 'positive ') . $key);
            return undef;
        }
    }
    return $value;
}

sub reference_pressure_object {
    my ($label, $line_number, $value, $allow_zero) = @_;
    my @keys = qw(files lines_each bytes_each line_bytes_each lines_total bytes_total);
    if (ref($value) ne 'HASH') {
        problem("$label line $line_number must be an object");
        return undef;
    }
    return undef if !validate_keys($label, $line_number, $value, \@keys, []);
    for my $aggregate (qw(files lines_total bytes_total)) {
        problem("$label line $line_number must use null $aggregate for product-bounded aggregate scope")
            if defined $value->{$aggregate};
    }
    for my $part (qw(lines_each bytes_each line_bytes_each)) {
        my $valid = $allow_zero
            ? nonnegative_integer($value->{$part})
            : positive_integer($value->{$part});
        problem("$label line $line_number has invalid "
            . ($allow_zero ? 'nonnegative ' : 'positive ') . $part)
            if !$valid;
    }
    return $value;
}

my $surface_rows = read_jsonl($registry_arg, 'surface registry');

my %allowed_lifecycle = map { $_ => 1 } qw(
    bounded_snapshot partitioned_canonical maintained_reference
    generated_projection rolling_ledger archive_terminal external_terminal
    frozen_legacy
);
my %allowed_locator = map { $_ => 1 } qw(
    file collection generated_file query archive external frozen
);
my %compatible = (
    bounded_snapshot      => { file => 1 },
    partitioned_canonical => { collection => 1 },
    maintained_reference  => { collection => 1 },
    generated_projection  => { generated_file => 1, query => 1 },
    rolling_ledger        => { file => 1 },
    archive_terminal      => { archive => 1 },
    external_terminal     => { external => 1 },
    frozen_legacy         => { frozen => 1 },
);
my %allowed_state = map { $_ => 1 } qw(
    normal warning_debt rollover_debt structural_debt terminal frozen
);
my %surfaces;
my @surface_order;

for my $row (@{$surface_rows}) {
    my ($line_number, $json) = @{$row};
    my @required = qw(
        surface_id lifecycle locator targets index canonical_inputs routes_to
        owner health_targets enforcement_ceilings milestones containment_status
        state baseline verifier
    );
    next if !validate_keys(
        'surface registry', $line_number, $json, \@required,
        ['transition', 'currency', 'index_contract', 'classification',
            'reference_contract'],
    );

    my $id = $json->{surface_id};
    if (!bounded_nonempty_string($id, 128) || $id !~ /\A[a-z][a-z0-9_]*\z/) {
        problem("surface registry line $line_number has invalid surface_id");
        next;
    }
    if (exists $surfaces{$id}) {
        problem("surface $id is declared more than once");
        next;
    }
    for my $key (qw(lifecycle locator owner containment_status state verifier)) {
        if (!bounded_nonempty_string($json->{$key}, $key eq 'verifier' ? 1024 : 256)) {
            problem("surface $id has invalid string key: $key");
        }
    }
    my $targets = string_array(
        "surface $id targets", $line_number, $json->{targets}, 0, 128, 512,
    );
    my $routes = string_array(
        "surface $id routes_to", $line_number, $json->{routes_to}, 1, 128, 128,
    );
    my $canonical = string_array(
        "surface $id canonical_inputs", $line_number, $json->{canonical_inputs}, 1, 128, 512,
    );
    if (defined($json->{index}) && !bounded_nonempty_string($json->{index}, 512)) {
        problem("surface $id index must be a non-empty single-line string <= 512 bytes or null");
    }

    my %record = (
        %{$json},
        target          => join(';', @{$targets}),
        target_patterns => $targets,
        input_patterns  => $canonical,
        routes_to       => $routes,
    );
    if (!$allowed_lifecycle{$record{lifecycle}}) {
        problem("surface $id has unknown lifecycle: $record{lifecycle}");
    }
    if (!$allowed_locator{$record{locator}}) {
        problem("surface $id has unknown locator: $record{locator}");
    }
    if ($allowed_lifecycle{$record{lifecycle}}
            && $allowed_locator{$record{locator}}
            && !$compatible{$record{lifecycle}}{$record{locator}}) {
        problem("surface $id lifecycle $record{lifecycle} is incompatible with locator $record{locator}");
    }
    if (!$allowed_state{$record{state}}) {
        problem("surface $id has unknown state: $record{state}");
    }
    if ($record{owner} eq '') {
        problem("surface $id must declare an owner");
    }

    if (defined $json->{classification}) {
        if (ref($json->{classification}) ne 'HASH') {
            problem("surface $id classification must be an object or null");
        } elsif (validate_keys(
            "surface $id classification", $line_number, $json->{classification},
            [qw(audience role rationale)], [],
        )) {
            for my $key (qw(audience role rationale)) {
                problem("surface $id classification has invalid or oversized $key")
                    if !bounded_nonempty_string($json->{classification}{$key}, 512);
            }
            problem("surface $id classification role must be a stable identifier")
                if bounded_nonempty_string($json->{classification}{role}, 512)
                    && $json->{classification}{role} !~ /\A[a-z][a-z0-9_]*\z/;
            $record{classification_audience} = $json->{classification}{audience};
            $record{classification_role} = $json->{classification}{role};
            $record{classification_rationale} = $json->{classification}{rationale};
        }
    }

    if ($record{lifecycle} eq 'maintained_reference') {
        problem("surface $id maintained_reference requires an auditable classification rationale")
            if !defined $json->{classification};
        if (ref($json->{reference_contract}) ne 'HASH') {
            problem("surface $id maintained_reference requires a reference_contract object");
        } elsif (validate_keys(
            "surface $id reference_contract", $line_number, $json->{reference_contract},
            [qw(mandatory_read max_navigation_depth aggregate_change)], [],
        )) {
            my $mandatory = $json->{reference_contract}{mandatory_read};
            if (ref($mandatory) ne 'HASH') {
                problem("surface $id mandatory_read must be an object");
            } elsif (validate_keys(
                "surface $id mandatory_read", $line_number, $mandatory,
                [qw(path lines_ceiling bytes_ceiling)], [],
            )) {
                problem("surface $id mandatory_read path must be a project-relative string <= 512 bytes")
                    if !bounded_nonempty_string($mandatory->{path}, 512)
                        || !relative_path_ok($mandatory->{path});
                problem("surface $id mandatory_read lines_ceiling must be positive")
                    if !positive_integer($mandatory->{lines_ceiling});
                problem("surface $id mandatory_read bytes_ceiling must be positive")
                    if !positive_integer($mandatory->{bytes_ceiling});
                $record{mandatory_read_path} = $mandatory->{path};
                $record{mandatory_read_lines_ceiling} = $mandatory->{lines_ceiling};
                $record{mandatory_read_bytes_ceiling} = $mandatory->{bytes_ceiling};
            }
            my $depth = $json->{reference_contract}{max_navigation_depth};
            problem("surface $id max_navigation_depth must be a positive integer")
                if !positive_integer($depth);
            $record{max_navigation_depth} = $depth;

            my $change = $json->{reference_contract}{aggregate_change};
            if (ref($change) ne 'HASH') {
                problem("surface $id aggregate_change must be an object");
            } elsif (validate_keys(
                "surface $id aggregate_change", $line_number, $change,
                [qw(authority_id owner rationale baseline delta)], [],
            )) {
                problem("surface $id aggregate_change authority_id is invalid")
                    if ref($change->{authority_id})
                        || !bounded_nonempty_string($change->{authority_id}, 128)
                        || $change->{authority_id} !~ /\A[A-Z][A-Z0-9_.-]*\z/;
                for my $key (qw(owner rationale)) {
                    problem("surface $id aggregate_change has invalid or oversized $key")
                        if !bounded_nonempty_string($change->{$key}, 512);
                }
                my @aggregate_keys = qw(files lines_total bytes_total);
                my $baseline = exact_numeric_object(
                    "surface $id aggregate_change baseline", $line_number,
                    $change->{baseline}, \@aggregate_keys,
                );
                if (defined $baseline) {
                    @record{qw(reference_baseline_files reference_baseline_lines_total
                        reference_baseline_bytes_total)} = @{$baseline}{@aggregate_keys};
                }
                my $delta = $change->{delta};
                if (ref($delta) ne 'HASH') {
                    problem("surface $id aggregate_change delta must be an object");
                } elsif (validate_keys(
                    "surface $id aggregate_change delta", $line_number, $delta,
                    \@aggregate_keys, [],
                )) {
                    for my $key (@aggregate_keys) {
                        problem("surface $id aggregate_change delta has invalid $key")
                            if !signed_integer($delta->{$key});
                    }
                    @record{qw(reference_delta_files reference_delta_lines_total
                        reference_delta_bytes_total)} = @{$delta}{@aggregate_keys};
                }
                $record{reference_authority_id} = $change->{authority_id};
                $record{reference_authority_owner} = $change->{owner};
                $record{reference_authority_rationale} = $change->{rationale};
            }
        }
    } elsif (defined $json->{reference_contract}) {
        problem("surface $id non-maintained lifecycle must use null or absent reference_contract");
    }

    if (defined $json->{currency}) {
        if (ref($json->{currency}) ne 'HASH') {
            problem("surface $id currency must be an object or null");
        } elsif (validate_keys(
            "surface $id currency", $line_number, $json->{currency},
            [qw(contract_id verifier)], [],
        )) {
            my ($contract_id, $currency_verifier) =
                @{$json->{currency}}{qw(contract_id verifier)};
            if (ref($contract_id) || !defined($contract_id)
                    || !bounded_nonempty_string($contract_id, 128)
                    || $contract_id !~ /\A[a-z][a-z0-9_.-]*\z/) {
                problem("surface $id currency has invalid contract_id");
            } elsif (!bounded_nonempty_string($currency_verifier, 1024)
                    || $currency_verifier !~ /\A(?:core|adapter|external):.+\z/) {
                problem("surface $id currency verifier must declare core:, adapter:, or external: execution");
            } elsif ($record{lifecycle} =~ /\A(?:archive_terminal|external_terminal|frozen_legacy)\z/) {
                problem("surface $id historical or frozen lifecycle must not declare currency");
            } else {
                $record{currency_contract_id} = $contract_id;
                $record{currency_verifier} = $currency_verifier;
            }
        }
    }

    my @pressure_keys = qw(files lines_each bytes_each line_bytes_each lines_total bytes_total);
    my @milestone_keys = qw(warning_pct rollover_pct);
    my $measured = $record{locator} eq 'file' || $record{locator} eq 'collection'
        || $record{locator} eq 'generated_file';
    if ($measured) {
        problem("surface $id measured locator has invalid state: $record{state}")
            if $record{state} !~ /\A(?:normal|warning_debt|rollover_debt|structural_debt)\z/;
        @record{qw(target_files target_lines_each target_bytes_each target_line_bytes_each target_lines_total target_bytes_total)} = (0) x 6;
        @record{qw(ceiling_files ceiling_lines_each ceiling_bytes_each ceiling_line_bytes_each ceiling_lines_total ceiling_bytes_total)} = (0) x 6;
        @record{@milestone_keys} = (0) x 2;
        my $targets_object = $record{lifecycle} eq 'maintained_reference'
            ? reference_pressure_object(
                "surface $id health_targets", $line_number, $json->{health_targets}, 0,
            )
            : exact_numeric_object(
                "surface $id health_targets", $line_number, $json->{health_targets}, \@pressure_keys,
            );
        my $ceilings = $record{lifecycle} eq 'maintained_reference'
            ? reference_pressure_object(
                "surface $id enforcement_ceilings", $line_number,
                $json->{enforcement_ceilings}, 0,
            )
            : exact_numeric_object(
                "surface $id enforcement_ceilings", $line_number,
                $json->{enforcement_ceilings}, \@pressure_keys,
            );
        my $milestones = exact_numeric_object(
            "surface $id milestones", $line_number, $json->{milestones}, \@milestone_keys,
        );
        if (defined $targets_object) {
            @record{qw(target_files target_lines_each target_bytes_each target_line_bytes_each target_lines_total target_bytes_total)}
                = @{$targets_object}{@pressure_keys};
        }
        if (defined $ceilings) {
            @record{qw(ceiling_files ceiling_lines_each ceiling_bytes_each ceiling_line_bytes_each ceiling_lines_total ceiling_bytes_total)}
                = @{$ceilings}{@pressure_keys};
        }
        if (defined $milestones) {
            @record{@milestone_keys} = @{$milestones}{@milestone_keys};
        }
        if ($record{state} =~ /\A(?:warning_debt|rollover_debt|structural_debt)\z/) {
            @record{qw(baseline_files baseline_lines_each baseline_bytes_each baseline_line_bytes_each baseline_lines_total baseline_bytes_total)} = (0) x 6;
            my $baseline = $record{lifecycle} eq 'maintained_reference'
                ? reference_pressure_object(
                    "surface $id baseline", $line_number, $json->{baseline}, 0,
                )
                : exact_numeric_object(
                    "surface $id baseline", $line_number, $json->{baseline}, \@pressure_keys,
                );
            if (defined $baseline) {
                @record{qw(baseline_files baseline_lines_each baseline_bytes_each baseline_line_bytes_each baseline_lines_total baseline_bytes_total)}
                    = @{$baseline}{@pressure_keys};
            }
            @record{qw(transition_files transition_lines_each transition_bytes_each transition_line_bytes_each transition_lines_total transition_bytes_total)} = (0) x 6;
            @record{qw(ratchet_files ratchet_lines_each ratchet_bytes_each ratchet_line_bytes_each ratchet_lines_total ratchet_bytes_total)} = (0) x 6;
            if (defined $json->{transition}) {
                if (ref($json->{transition}) ne 'HASH') {
                    problem("surface $id transition must be an object or null");
                } elsif (validate_keys(
                    "surface $id transition", $line_number, $json->{transition},
                    [qw(owner max_growth ratchet_step)], [],
                )) {
                    my $transition_owner = $json->{transition}{owner};
                    if (!bounded_nonempty_string($transition_owner, 256)) {
                        problem("surface $id transition must declare a non-empty owner");
                    } else {
                        $record{transition_owner} = $transition_owner;
                    }
                    my $growth = $record{lifecycle} eq 'maintained_reference'
                        ? reference_pressure_object(
                            "surface $id transition max_growth", $line_number,
                            $json->{transition}{max_growth}, 1,
                        )
                        : exact_numeric_object(
                            "surface $id transition max_growth", $line_number,
                            $json->{transition}{max_growth}, \@pressure_keys, 1,
                        );
                    if (defined $growth) {
                        @record{qw(transition_files transition_lines_each transition_bytes_each transition_line_bytes_each transition_lines_total transition_bytes_total)}
                            = @{$growth}{@pressure_keys};
                    }
                    my $ratchet = $record{lifecycle} eq 'maintained_reference'
                        ? reference_pressure_object(
                            "surface $id transition ratchet_step", $line_number,
                            $json->{transition}{ratchet_step}, 0,
                        )
                        : exact_numeric_object(
                            "surface $id transition ratchet_step", $line_number,
                            $json->{transition}{ratchet_step}, \@pressure_keys,
                        );
                    if (defined $ratchet) {
                        @record{qw(ratchet_files ratchet_lines_each ratchet_bytes_each ratchet_line_bytes_each ratchet_lines_total ratchet_bytes_total)}
                            = @{$ratchet}{@pressure_keys};
                    }
                }
            }
        } elsif (defined $json->{baseline}) {
            problem("surface $id non-debt record must use null baseline");
        } elsif (defined $json->{transition}) {
            problem("surface $id non-debt record must use null or absent transition");
        }
    } else {
        problem("surface $id terminal record must use null health_targets")
            if defined $json->{health_targets};
        problem("surface $id terminal record must use null enforcement_ceilings")
            if defined $json->{enforcement_ceilings};
        problem("surface $id terminal record must use null milestones") if defined $json->{milestones};
        problem("surface $id terminal record must use null baseline") if defined $json->{baseline};
        problem("surface $id terminal record must use null or absent transition")
            if defined $json->{transition};
    }

    if ($record{locator} ne 'collection' && @{$targets} != 1) {
        problem("surface $id locator $record{locator} must declare exactly one target");
    }

    if ($record{locator} eq 'collection') {
        problem("surface $id collection index must be a string or null")
            if defined($record{index}) && ref($record{index});
        problem("surface $id collection must not declare canonical_inputs") if @{$canonical};
        if (!defined $record{index}) {
            problem("surface $id collection without an index must use null or absent index_contract")
                if defined $json->{index_contract};
        } elsif (ref($json->{index_contract}) ne 'HASH') {
            problem("surface $id indexed collection must declare an index_contract object");
        } elsif (validate_keys(
            "surface $id index_contract", $line_number, $json->{index_contract},
            [qw(kind verifier)], [],
        )) {
            my ($kind, $verifier) = @{$json->{index_contract}}{qw(kind verifier)};
            if (ref($kind) || !defined($kind)
                    || $kind !~ /\A(?:membership|generated|query)\z/) {
                problem("surface $id index_contract has invalid kind");
            } elsif (!bounded_nonempty_string($verifier, 1024)) {
                problem("surface $id index_contract must declare a verifier");
            } elsif ($kind eq 'membership' && $verifier ne 'builtin:markdown_links') {
                problem("surface $id membership index must use builtin:markdown_links");
            } elsif ($kind eq 'query' && $verifier ne 'builtin:registry_targets') {
                problem("surface $id query index must use builtin:registry_targets");
            } elsif ($kind eq 'generated' && $verifier !~ /\Asurface:[a-z][a-z0-9_]*\z/) {
                problem("surface $id generated index must name a surface verifier");
            } else {
                $record{index_contract_kind} = $kind;
                $record{index_contract_verifier} = $verifier;
            }
        }
    } elsif ($record{locator} eq 'generated_file') {
        problem("surface $id generated file must use null index") if defined $record{index};
        problem("surface $id generated file needs canonical_inputs") if !@{$canonical};
        problem("surface $id non-collection must use null or absent index_contract")
            if defined $json->{index_contract};
    } else {
        problem("surface $id must use null index") if defined $record{index};
        problem("surface $id must not declare canonical_inputs") if @{$canonical};
        problem("surface $id non-collection must use null or absent index_contract")
            if defined $json->{index_contract};
    }

    if (!@{$targets}) {
        problem("surface $id has no valid targets");
        next;
    }
    $surfaces{$id} = \%record;
    push @surface_order, $id;
}

if (!@surface_order) {
    problem('surface registry declares no surfaces');
}

my @coverage_patterns;
my %containment_pressure;
for my $id (@surface_order) {
    my $record = $surfaces{$id};
    my $locator = $record->{locator};
    my $measured = $locator eq 'file' || $locator eq 'collection'
        || $locator eq 'generated_file';
    my @target_fields = qw(target_files target_lines_each target_bytes_each target_line_bytes_each target_lines_total target_bytes_total);
    my @ceiling_fields = qw(ceiling_files ceiling_lines_each ceiling_bytes_each ceiling_line_bytes_each ceiling_lines_total ceiling_bytes_total);
    my @baseline_fields = qw(baseline_files baseline_lines_each baseline_bytes_each baseline_line_bytes_each baseline_lines_total baseline_bytes_total);

    if ($measured) {
        my @applicable_target_fields = $record->{lifecycle} eq 'maintained_reference'
            ? qw(target_lines_each target_bytes_each target_line_bytes_each)
            : @target_fields;
        my @applicable_ceiling_fields = $record->{lifecycle} eq 'maintained_reference'
            ? qw(ceiling_lines_each ceiling_bytes_each ceiling_line_bytes_each)
            : @ceiling_fields;
        for my $field (@applicable_target_fields, @applicable_ceiling_fields) {
            problem("surface $id has invalid positive $field: $record->{$field}")
                if !positive_integer($record->{$field});
        }
        if ($record->{lifecycle} eq 'maintained_reference') {
            for my $field (qw(target_files target_lines_total target_bytes_total
                    ceiling_files ceiling_lines_total ceiling_bytes_total)) {
                problem("surface $id maintained_reference unexpectedly defines aggregate pressure field $field")
                    if defined $record->{$field};
            }
        }
        for my $field (qw(warning_pct rollover_pct)) {
            problem("surface $id has invalid positive $field: $record->{$field}")
                if !positive_integer($record->{$field});
        }
        if (positive_integer($record->{warning_pct})
                && positive_integer($record->{rollover_pct})
                && !($record->{warning_pct} < $record->{rollover_pct}
                    && $record->{rollover_pct} <= 100)) {
            problem("surface $id pressure percentages must satisfy warning < rollover <= 100");
        }
        problem("surface $id has invalid containment_status: $record->{containment_status}")
            if $record->{containment_status} !~ /\A(?:steady|migrated|pinned_deferred)\z/;
        if ($record->{state} =~ /\A(?:warning_debt|rollover_debt|structural_debt)\z/) {
            my @applicable_baseline_fields = $record->{lifecycle} eq 'maintained_reference'
                ? qw(baseline_lines_each baseline_bytes_each baseline_line_bytes_each)
                : @baseline_fields;
            for my $field (@applicable_baseline_fields) {
                problem("surface $id debt has invalid positive $field: $record->{$field}")
                    if !positive_integer($record->{$field});
            }
            my @growth_fields = qw(
                transition_files transition_lines_each transition_bytes_each
                transition_line_bytes_each transition_lines_total transition_bytes_total
            );
            my @ratchet_fields = qw(
                ratchet_files ratchet_lines_each ratchet_bytes_each
                ratchet_line_bytes_each ratchet_lines_total ratchet_bytes_total
            );
            my @applicable_indexes = $record->{lifecycle} eq 'maintained_reference'
                ? (1, 2, 3)
                : (0 .. $#ceiling_fields);
            for my $index (@applicable_indexes) {
                next if !positive_integer($record->{$ceiling_fields[$index]})
                    || !positive_integer($record->{$baseline_fields[$index]})
                    || !nonnegative_integer($record->{$growth_fields[$index]});
                problem("surface $id baseline $baseline_fields[$index] exceeds $ceiling_fields[$index]")
                    if $record->{$baseline_fields[$index]} > $record->{$ceiling_fields[$index]};
                problem("surface $id transition baseline plus growth exceeds $ceiling_fields[$index]")
                    if $record->{$baseline_fields[$index]} + $record->{$growth_fields[$index]}
                        > $record->{$ceiling_fields[$index]};
                problem("surface $id debt has invalid positive $ratchet_fields[$index]")
                    if !positive_integer($record->{$ratchet_fields[$index]});
            }
        } else {
            for my $field (@baseline_fields) {
                problem("surface $id non-debt record unexpectedly defines $field")
                    if defined $record->{$field};
            }
        }
        push @coverage_patterns, @{$record->{target_patterns}};
    } else {
        problem("surface $id terminal record must use containment_status not_applicable")
            if $record->{containment_status} ne 'not_applicable';
        for my $field (@target_fields, @ceiling_fields, qw(warning_pct rollover_pct), @baseline_fields) {
            problem("surface $id terminal record unexpectedly defines $field")
                if defined $record->{$field};
        }
        push @coverage_patterns, @{$record->{target_patterns}} if $locator eq 'frozen';
    }

    if ($locator ne 'external') {
        for my $target (@{$record->{target_patterns}}) {
            problem("surface $id target must stay project-relative: $target")
                if !relative_path_ok($target);
        }
    }

    if ($record->{lifecycle} eq 'partitioned_canonical'
            || $record->{lifecycle} eq 'maintained_reference') {
        if (!defined $record->{index}) {
            problem("surface $id lacks a bounded index without structural debt")
                if $record->{state} ne 'structural_debt'
                    && $record->{state} ne 'warning_debt'
                    && $record->{state} ne 'rollover_debt';
        } elsif (!relative_path_ok($record->{index})
                || !assert_local_regular_file($id, root_path($record->{index}))) {
            problem("surface $id has an invalid bounded index: $record->{index}");
        } elsif (!defined $record->{index_contract_kind}) {
            problem("surface $id bounded index lacks a valid index_contract");
        }
        if ($record->{lifecycle} eq 'maintained_reference'
                && defined($record->{index}) && defined($record->{mandatory_read_path})
                && $record->{index} ne $record->{mandatory_read_path}) {
            problem("surface $id mandatory_read path must equal its bounded collection index");
        }
    } elsif ($record->{locator} eq 'generated_file') {
        my @canonical = expand_patterns($id, $record->{input_patterns});
        if (!@canonical) {
            problem("surface $id generated projection has no canonical inputs");
        } else {
            assert_local_regular_file($id, $_) for @canonical;
        }
    }

    if ($locator eq 'file' || $locator eq 'generated_file' || $locator eq 'collection') {
        my @files = expand_patterns($id, $record->{target_patterns});
        if (!@files) {
            problem("surface $id target matched no files: $record->{target}");
            next;
        }
        if ($locator ne 'collection' && @files != 1) {
            problem("surface $id $locator target must match exactly one file");
            next;
        }
        my ($total_lines, $total_bytes, $max_lines, $max_bytes, $max_line_bytes)
            = (0, 0, 0, 0, 0);
        for my $file (@files) {
            next if !assert_local_regular_file($id, $file);
            my ($lines, $bytes, $line_bytes) = file_measurement($file);
            $total_lines += $lines;
            $total_bytes += $bytes;
            $max_lines = $lines if $lines > $max_lines;
            $max_bytes = $bytes if $bytes > $max_bytes;
            $max_line_bytes = $line_bytes if $line_bytes > $max_line_bytes;
        }
        if ($record->{lifecycle} eq 'maintained_reference') {
            my @aggregate = (
                ['files', scalar(@files), 'reference_baseline_files', 'reference_delta_files'],
                ['lines_total', $total_lines, 'reference_baseline_lines_total', 'reference_delta_lines_total'],
                ['bytes_total', $total_bytes, 'reference_baseline_bytes_total', 'reference_delta_bytes_total'],
            );
            for my $dimension (@aggregate) {
                my ($name, $actual, $baseline_key, $delta_key) = @{$dimension};
                my $baseline = $record->{$baseline_key};
                my $delta = $record->{$delta_key};
                next if !positive_integer($baseline) || !signed_integer($delta);
                my $authorized = $baseline + $delta;
                problem("surface $id aggregate_change produces non-positive $name")
                    if $authorized <= 0;
                problem("surface $id aggregate $name is $actual but contract authorizes $authorized")
                    if $actual != $authorized;
            }
            my $index_relative = $record->{mandatory_read_path};
            if (defined($index_relative) && relative_path_ok($index_relative)) {
                my $index_path = root_path($index_relative);
                if (assert_local_regular_file($id, $index_path)) {
                    my ($index_lines, $index_bytes) = file_measurement($index_path);
                    problem("surface $id mandatory read lines are $index_lines (> ceiling $record->{mandatory_read_lines_ceiling})")
                        if positive_integer($record->{mandatory_read_lines_ceiling})
                            && $index_lines > $record->{mandatory_read_lines_ceiling};
                    problem("surface $id mandatory read bytes are $index_bytes (> ceiling $record->{mandatory_read_bytes_ceiling})")
                        if positive_integer($record->{mandatory_read_bytes_ceiling})
                            && $index_bytes > $record->{mandatory_read_bytes_ceiling};
                    my $navigation_depth = @files > 1 ? 1 : 0;
                    problem("surface $id navigation depth $navigation_depth exceeds $record->{max_navigation_depth}")
                        if positive_integer($record->{max_navigation_depth})
                            && $navigation_depth > $record->{max_navigation_depth};
                    ok_note("surface $id mandatory read $index_relative is $index_lines lines/$index_bytes bytes; navigation depth $navigation_depth");
                }
            }
        }
        my @dimensions = (
            ['max lines', 'lines_each', $max_lines, $record->{target_lines_each},
                $record->{ceiling_lines_each}, $record->{baseline_lines_each}],
            ['max bytes', 'bytes_each', $max_bytes, $record->{target_bytes_each},
                $record->{ceiling_bytes_each}, $record->{baseline_bytes_each}],
            ['max line bytes', 'line_bytes_each', $max_line_bytes,
                $record->{target_line_bytes_each}, $record->{ceiling_line_bytes_each},
                $record->{baseline_line_bytes_each}],
            ['total lines', 'lines_total', $total_lines, $record->{target_lines_total},
                $record->{ceiling_lines_total}, $record->{baseline_lines_total}],
            ['total bytes', 'bytes_total', $total_bytes, $record->{target_bytes_total},
                $record->{ceiling_bytes_total}, $record->{baseline_bytes_total}],
        );
        unshift @dimensions, ['files', 'files', scalar(@files), $record->{target_files},
            $record->{ceiling_files}, $record->{baseline_files}];
        my ($target_peak_pct, $ceiling_peak_pct) = (0, 0);
        for my $dimension (@dimensions) {
            my ($name, $key, $actual, $target, $ceiling, $baseline) = @{$dimension};
            next if !positive_integer($target) || !positive_integer($ceiling);
            my $target_pct = 100 * $actual / $target;
            my $ceiling_pct = 100 * $actual / $ceiling;
            if ($key ne 'files' || $locator eq 'collection') {
                $target_peak_pct = $target_pct if $target_pct > $target_peak_pct;
                $ceiling_peak_pct = $ceiling_pct if $ceiling_pct > $ceiling_peak_pct;
            }
            problem(sprintf(
                'surface %s %s is %d (> inclusive enforcement ceiling %d)',
                $id, $name, $actual, $ceiling,
            )) if $actual > $ceiling;
            my $allowance = $record->{"transition_$key"} // 0;
            if ($record->{state} =~ /\A(?:warning_debt|rollover_debt|structural_debt)\z/
                    && positive_integer($baseline) && $actual > $baseline + $allowance) {
                problem(sprintf(
                    'surface %s transition debt exceeded its owned allowance: %s is %d (> baseline %d + growth %d)',
                    $id, $name, $actual, $baseline, $allowance,
                ));
            }
            if ($record->{state} =~ /\A(?:warning_debt|rollover_debt|structural_debt)\z/) {
                my $ratchet = $record->{"ratchet_$key"};
                if (positive_integer($ratchet)) {
                    my $ratchet_base = $actual > $target ? $actual : $target;
                    my $ratchet_max = $ratchet_base + (2 * $ratchet);
                    problem(sprintf(
                        'surface %s %s ceiling %d retains stale excess headroom (> max(actual %d, target %d) + 2 * ratchet %d = %d)',
                        $id, $name, $ceiling, $actual, $target, $ratchet, $ratchet_max,
                    )) if $ceiling > $ratchet_max;
                }
            }
        }
        if (positive_integer($record->{warning_pct})
                && positive_integer($record->{rollover_pct})) {
            if ($target_peak_pct >= $record->{rollover_pct}) {
                problem(sprintf('surface %s is at %.1f%% and must declare rollover_debt', $id, $target_peak_pct))
                    if $record->{state} ne 'rollover_debt'
                        && $record->{state} ne 'structural_debt';
            } elsif ($target_peak_pct >= $record->{warning_pct}) {
                problem(sprintf('surface %s is at %.1f%% and must declare warning_debt', $id, $target_peak_pct))
                    if $record->{state} ne 'warning_debt'
                        && $record->{state} ne 'rollover_debt'
                        && $record->{state} ne 'structural_debt';
            } elsif ($record->{state} eq 'warning_debt' || $record->{state} eq 'rollover_debt') {
                problem(sprintf('surface %s is at %.1f%% but retains stale numeric debt state %s',
                    $id, $target_peak_pct, $record->{state}));
            }
        }
        if ($record->{verifier} ne 'builtin:budget'
                && $record->{verifier} ne 'builtin:maintained_reference'
                && $record->{verifier} !~ /\A(?:core|adapter|external):.+\z/) {
            problem("surface $id has invalid measured verifier: $record->{verifier}");
        }
        if ($record->{locator} eq 'generated_file') {
            problem("surface $id generated projection must declare executed freshness verification")
                if $record->{verifier} eq 'builtin:budget';
            verify_execution("surface $id freshness", "surface:$id", $record->{verifier})
                if $record->{verifier} ne 'builtin:budget';
        } elsif ($record->{lifecycle} eq 'maintained_reference') {
            problem("surface $id maintained reference must use builtin:maintained_reference")
                if $record->{verifier} ne 'builtin:maintained_reference';
        } elsif ($record->{verifier} ne 'builtin:budget') {
            problem("surface $id non-generated measurement must use builtin:budget");
        }
        push @{$containment_pressure{$record->{containment_status}}}, {
            id => $id, target_peak => $target_peak_pct, ceiling_peak => $ceiling_peak_pct,
        };
        if ($record->{lifecycle} eq 'maintained_reference') {
            ok_note(sprintf(
                'surface %s: maintained reference actual files=%d, lines_each=%d, bytes_each=%d, line_bytes_each=%d, lines_total=%d, bytes_total=%d; per-part health target lines_each=%d, bytes_each=%d, line_bytes_each=%d; inclusive per-part ceiling lines_each=%d, bytes_each=%d, line_bytes_each=%d; aggregate authority %s; target peak %.1f%%, ceiling peak %.1f%% (%s, %s)',
                $id, scalar(@files), $max_lines, $max_bytes, $max_line_bytes,
                $total_lines, $total_bytes,
                @{$record}{qw(target_lines_each target_bytes_each target_line_bytes_each)},
                @{$record}{qw(ceiling_lines_each ceiling_bytes_each ceiling_line_bytes_each)},
                $record->{reference_authority_id} // 'invalid',
                $target_peak_pct, $ceiling_peak_pct, $record->{state},
                $record->{containment_status},
            ));
        } else {
            ok_note(sprintf(
                'surface %s: actual files=%d, lines_each=%d, bytes_each=%d, line_bytes_each=%d, lines_total=%d, bytes_total=%d; health target files=%d, lines_each=%d, bytes_each=%d, line_bytes_each=%d, lines_total=%d, bytes_total=%d; inclusive enforcement ceiling files=%d, lines_each=%d, bytes_each=%d, line_bytes_each=%d, lines_total=%d, bytes_total=%d; target peak %.1f%%, ceiling peak %.1f%% (%s, %s)',
                $id, scalar(@files), $max_lines, $max_bytes, $max_line_bytes,
                $total_lines, $total_bytes,
                @{$record}{qw(target_files target_lines_each target_bytes_each target_line_bytes_each target_lines_total target_bytes_total)},
                @{$record}{qw(ceiling_files ceiling_lines_each ceiling_bytes_each ceiling_line_bytes_each ceiling_lines_total ceiling_bytes_total)},
                $target_peak_pct, $ceiling_peak_pct, $record->{state}, $record->{containment_status},
            ));
        }

        if ($locator eq 'collection' && defined $record->{index_contract_kind}) {
            my $kind = $record->{index_contract_kind};
            if ($kind eq 'membership') {
                my $index_relative = $record->{index};
                my $index_path = root_path($index_relative);
                if (assert_local_regular_file($id, $index_path)) {
                    if (!open my $fh, '<:raw', $index_path) {
                        problem("surface $id cannot read collection index $index_relative: $!");
                    } else {
                        local $/;
                        my $contents = <$fh> // '';
                        close $fh or problem("surface $id cannot close collection index $index_relative: $!");
                        my %linked;
                        while ($contents =~ /\]\((?:<([^>]+)>|([^\s\)]+))(?:\s+[^\)]*)?\)/g) {
                            my $destination = defined($1) ? $1 : $2;
                            $destination =~ s/[?#].*\z//;
                            next if $destination eq '' || $destination =~ /\A(?:[a-z]+:|#)/i;
                            my $resolved = File::Spec->canonpath(File::Spec->catfile(
                                dirname($index_relative), split(m{/+}, $destination),
                            ));
                            $resolved =~ s{\\}{/}g;
                            $resolved =~ s{\A\./}{};
                            $linked{$resolved} = 1 if relative_path_ok($resolved);
                        }
                        for my $file (@files) {
                            my $relative = display_path($file);
                            next if $relative eq $index_relative;
                            problem("surface $id collection index omits member: $relative")
                                if !$linked{$relative};
                        }
                        ok_note("surface $id collection index membership checked");
                    }
                }
            } elsif ($kind eq 'query') {
                ok_note("surface $id collection index declares complete registry-target query");
            }
        }
    } elsif ($locator eq 'query') {
        my $path = root_path($record->{target});
        problem("surface $id query target is absent or not executable: $record->{target}")
            if !-f $path || !-x $path;
        problem("surface $id query verifier must name its executable target")
            if $record->{verifier} ne "executable:$record->{target}";
        problem("surface $id query must use terminal state") if $record->{state} ne 'terminal';
        ok_note("surface $id: query terminal $record->{target}");
    } elsif ($locator eq 'archive') {
        assert_local_directory($id, root_path($record->{target}));
        problem("surface $id archive verifier must name its target")
            if $record->{verifier} ne "archive:$record->{target}";
        problem("surface $id archive must use terminal state") if $record->{state} ne 'terminal';
        ok_note("surface $id: archive terminal $record->{target}");
    } elsif ($locator eq 'external') {
        problem("surface $id external verifier must start with external:")
            if $record->{verifier} !~ /\Aexternal:.+/;
        problem("surface $id external target must be singular")
            if @{$record->{target_patterns}} != 1;
        problem("surface $id external target must use terminal state") if $record->{state} ne 'terminal';
        ok_note("surface $id: external terminal declared");
    } elsif ($locator eq 'frozen') {
        my $path = root_path($record->{target});
        if (assert_local_regular_file($id, $path)) {
            if ($record->{verifier} !~ /\Asha256:([0-9a-f]{64})\z/) {
                problem("surface $id frozen verifier must be sha256:<64 lowercase hex digits>");
            } else {
                my $actual = file_sha256($path);
                problem("surface $id frozen identity changed ($actual != $1)") if $actual ne $1;
            }
        }
        problem("surface $id frozen target must use frozen state") if $record->{state} ne 'frozen';
        ok_note("surface $id: frozen identity checked");
    }

    if (defined $record->{currency_contract_id}) {
        verify_execution(
            "surface $id currency $record->{currency_contract_id}",
            "currency:$id",
            $record->{currency_verifier},
        );
    }
}

for my $status (qw(migrated pinned_deferred steady)) {
    my $entries = $containment_pressure{$status} || [];
    next if !@{$entries};
    my ($target_peak, $ceiling_peak) = (0, 0);
    my @ids;
    for my $entry (@{$entries}) {
        push @ids, $entry->{id};
        $target_peak = $entry->{target_peak} if $entry->{target_peak} > $target_peak;
        $ceiling_peak = $entry->{ceiling_peak} if $entry->{ceiling_peak} > $ceiling_peak;
    }
    ok_note(sprintf(
        'containment pressure %s: %d surface(s), target peak %.1f%%, ceiling peak %.1f%% [%s]',
        $status, scalar(@ids), $target_peak, $ceiling_peak, join(',', sort @ids),
    ));
}

my $route_rows = read_jsonl($routes_arg, 'route registry');
my %route_ids;
my %route_pairs;
for my $row (@{$route_rows}) {
    my ($line_number, $record) = @{$row};
    my @route_keys = qw(
        route_id route_kind source_path source_surface_id marker target_surface_id
    );
    next if !validate_keys('route registry', $line_number, $record, \@route_keys, []);
    my ($route_id, $route_kind, $source_path, $source_id, $marker, $target_id) =
        @{$record}{@route_keys};
    if (!bounded_nonempty_string($route_id, 128)
            || !bounded_nonempty_string($route_kind, 32)
            || !bounded_nonempty_string($source_path, 512)
            || !bounded_nonempty_string($source_id, 128)
            || !bounded_nonempty_string($marker, 512)
            || !bounded_nonempty_string($target_id, 128)) {
        problem("route registry line $line_number contains an empty, multiline, or oversized scalar");
        next;
    }
    if ($route_id !~ /\A[a-z][a-z0-9_]*\z/) {
        problem("route registry line $line_number has invalid route_id: $route_id");
        next;
    }
    problem("route $route_id has invalid route_kind: $route_kind")
        if $route_kind !~ /\A(?:author_overflow|reader_navigation)\z/;
    if (!relative_path_ok($source_path)
            || !assert_local_regular_file("route $route_id", root_path($source_path))) {
        problem("route $route_id has invalid source_path: $source_path");
    }
    problem("route $route_id is declared more than once") if $route_ids{$route_id}++;
    if (!exists $surfaces{$source_id}) {
        problem("route $route_id has unknown source surface: $source_id");
        next;
    }
    if (!exists $surfaces{$target_id}) {
        problem("route $route_id has unknown target surface: $target_id");
        next;
    }
    my %declared_targets = map { $_ => 1 } @{$surfaces{$source_id}{routes_to}};
    problem("route $route_id edge $source_id -> $target_id is absent from source routes_to")
        if !$declared_targets{$target_id};
    $route_pairs{"$source_id\0$target_id"} = 1;
    if (relative_path_ok($source_path)) {
        my $source_file = root_path($source_path);
        if (-f $source_file) {
            open my $fh, '<:raw', $source_file or do {
                problem("route $route_id cannot read source $source_path: $!");
                next;
            };
            local $/;
            my $contents = <$fh>;
            close $fh;
            problem("route $route_id marker is absent from $source_path: $marker")
                if index($contents, $marker) < 0;
        }
    }
}

my %edges;
for my $id (@surface_order) {
    my @targets = @{$surfaces{$id}{routes_to}};
    for my $target (@targets) {
        if (!exists $surfaces{$target}) {
            problem("surface $id routes to unknown surface: $target");
            next;
        }
        push @{$edges{$id}}, $target;
        problem("surface edge $id -> $target lacks a route-registry row")
            if !$route_pairs{"$id\0$target"};
    }
}

my (%visiting, %visited);
sub visit_surface {
    my ($id, $stack) = @_;
    if ($visiting{$id}) {
        problem('surface route cycle: ' . join(' -> ', @{$stack}, $id));
        return;
    }
    return if $visited{$id};
    $visiting{$id} = 1;
    visit_surface($_, [@{$stack}, $id]) for @{$edges{$id} || []};
    delete $visiting{$id};
    $visited{$id} = 1;
}
visit_surface($_, []) for @surface_order;

for my $id (@surface_order) {
    my $record = $surfaces{$id};
    next if ($record->{index_contract_kind} // '') ne 'generated';
    my ($generated_id) = $record->{index_contract_verifier} =~ /\Asurface:(.+)\z/;
    if (!defined($generated_id) || !exists $surfaces{$generated_id}) {
        problem("surface $id generated index names unknown surface: "
            . ($generated_id // ''));
        next;
    }
    my $generated = $surfaces{$generated_id};
    problem("surface $id generated index verifier $generated_id is not a generated_file surface")
        if $generated->{locator} ne 'generated_file';
    problem("surface $id generated index does not match $generated_id target")
        if @{$generated->{target_patterns}} != 1
            || $generated->{target_patterns}[0] ne $record->{index};
    ok_note("surface $id collection index is generated by surface $generated_id");
}

my $evidence_rows = read_jsonl($evidence_maps_arg, 'evidence-map registry');
my %evidence_map_ids;
for my $row (@{$evidence_rows}) {
    my ($line_number, $record) = @{$row};
    my @keys = qw(map_id source_path begin_marker end_marker);
    next if !validate_keys('evidence-map registry', $line_number, $record, \@keys, []);
    my ($map_id, $source_path, $begin, $end) = @{$record}{@keys};
    if (!bounded_nonempty_string($map_id, 128)
            || !bounded_nonempty_string($source_path, 512)
            || !bounded_nonempty_string($begin, 512)
            || !bounded_nonempty_string($end, 512)) {
        problem("evidence-map registry line $line_number contains an empty, multiline, or oversized scalar");
        next;
    }
    if ($map_id !~ /\A[a-z][a-z0-9_]*\z/) {
        problem("evidence map has invalid map_id: $map_id");
        next;
    }
    problem("evidence map $map_id is declared more than once") if $evidence_map_ids{$map_id}++;
    if (!relative_path_ok($source_path)
            || !assert_local_regular_file("evidence map $map_id", root_path($source_path))) {
        problem("evidence map $map_id has invalid source_path: $source_path");
        next;
    }
    open my $fh, '<:raw', root_path($source_path) or do {
        problem("evidence map $map_id cannot read $source_path: $!");
        next;
    };
    local $/;
    my $contents = <$fh> // '';
    close $fh or problem("evidence map $map_id cannot close $source_path: $!");
    my $begin_at = index($contents, $begin);
    my $end_at = $begin_at < 0 ? -1 : index($contents, $end, $begin_at + length($begin));
    if ($begin_at < 0 || $end_at < 0 || index($contents, $begin, $begin_at + 1) >= 0
            || index($contents, $end, $end_at + 1) >= 0) {
        problem("evidence map $map_id must contain exactly one ordered marker pair");
        next;
    }
    my $body = substr($contents, $begin_at + length($begin),
        $end_at - ($begin_at + length($begin)));
    my @paths = $body =~ /^\|[^\n|]*\|\s*`([^`]+)`\s*\|\s*$/mg;
    if (!@paths) {
        problem("evidence map $map_id contains no path rows");
        next;
    }
    for my $path (@paths) {
        if (!relative_path_ok($path)
                || !assert_local_regular_file("evidence map $map_id", root_path($path))) {
            problem("evidence map $map_id path is absent or unsafe: $path");
        }
    }
    ok_note("evidence map $map_id resolves " . scalar(@paths) . " path(s)");
}

my $retention_rows = read_jsonl(
    $retention_contracts_arg, 'version-object retention contract registry'
);
my %retention_contracts;
for my $row (@{$retention_rows}) {
    my ($line_number, $record) = @{$row};
    my @keys = qw(record_type schema_version contract_id owner guarantee recovery);
    next if !validate_keys(
        'version-object retention contract registry', $line_number,
        $record, \@keys, [],
    );
    my ($type, $version, $id, $owner, $guarantee, $recovery) =
        @{$record}{@keys};
    if (!bounded_nonempty_string($type, 32)
            || !bounded_nonempty_string($version, 16)
            || !bounded_nonempty_string($id, 128)
            || !bounded_nonempty_string($owner, 256)
            || !bounded_nonempty_string($guarantee, 1024)
            || !bounded_nonempty_string($recovery, 1024)) {
        problem("version-object retention contract registry line $line_number contains an empty, multiline, or oversized scalar");
        next;
    }
    problem("version-object retention contract registry line $line_number must use record_type contract")
        if $type ne 'contract';
    problem("version-object retention contract $id has unsupported schema_version: $version")
        if $version ne '1';
    problem("version-object retention contract has invalid contract_id: $id")
        if $id !~ /\A[a-z][a-z0-9_.-]*\z/;
    problem("version-object retention contract $id is declared more than once")
        if exists $retention_contracts{$id};
    $retention_contracts{$id} = $record;
}

my $archive_rows = read_jsonl($archives_arg, 'archive descriptor registry');
my %descriptor_ids;
my %archive_descriptors;
for my $row (@{$archive_rows}) {
    my ($line_number, $record) = @{$row};
    if (($record->{record_type} // '') ne 'descriptor') {
        problem("archive descriptor registry line $line_number has unknown record_type");
        next;
    }
    my @archive_keys = qw(
        record_type schema_version descriptor_id surface_id former_path range_id revision lines bytes sha256
        retrieval_kind retrieval_locator current_pointer sealed_on verifier
    );
    next if !validate_keys(
        'archive descriptor registry', $line_number, $record, \@archive_keys,
        ['retention_contract'],
    );
    my ($record_type, $schema_version, $descriptor_id, $surface_id, $former_path, $range_id, $revision,
        $lines, $bytes, $sha256, $retrieval_kind, $retrieval_locator,
        $current_pointer, $sealed_on, $verifier) = @{$record}{@archive_keys};
    if (grep { ref($_) || !defined($_) } @{$record}{@archive_keys}) {
        problem("archive descriptor registry line $line_number must contain scalar values");
        next;
    }
    for my $field (
        [record_type => 32], [descriptor_id => 128], [surface_id => 128],
        [former_path => 512], [range_id => 128], [revision => 128],
        [retrieval_kind => 32], [retrieval_locator => 1024],
        [current_pointer => 512], [sealed_on => 32], [verifier => 1024],
    ) {
        my ($key, $max_bytes) = @{$field};
        problem("archive descriptor $descriptor_id has empty, multiline, or oversized $key")
            if !bounded_nonempty_string($record->{$key}, $max_bytes);
    }
    problem("archive descriptor $descriptor_id has unsupported schema_version: $schema_version")
        if $schema_version ne '1';
    problem("archive descriptor has invalid descriptor_id: $descriptor_id")
        if $descriptor_id !~ /\A[a-z][a-z0-9_.-]*\z/;
    my $duplicate_descriptor = $descriptor_ids{$descriptor_id}++;
    problem("archive descriptor $descriptor_id is declared more than once")
        if $duplicate_descriptor;
    problem("archive descriptor $descriptor_id names unknown surface: $surface_id")
        if !exists $surfaces{$surface_id};
    problem("archive descriptor $descriptor_id former_path must stay project-relative")
        if !relative_path_ok($former_path);
    problem("archive descriptor $descriptor_id current_pointer must stay project-relative")
        if !relative_path_ok($current_pointer);
    problem("archive descriptor $descriptor_id has empty range_id or revision")
        if $range_id eq '' || $revision eq '';
    problem("archive descriptor $descriptor_id has invalid line count: $lines")
        if !nonnegative_integer($lines);
    problem("archive descriptor $descriptor_id has invalid byte count: $bytes")
        if !nonnegative_integer($bytes);
    problem("archive descriptor $descriptor_id has invalid sha256")
        if $sha256 !~ /\A[0-9a-f]{64}\z/;
    problem("archive descriptor $descriptor_id has invalid sealed_on date")
        if $sealed_on !~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/;
    if ($retrieval_kind eq 'file') {
        if (!relative_path_ok($retrieval_locator)) {
            problem("archive descriptor $descriptor_id retrieval file must stay project-relative");
        } else {
            my $path = root_path($retrieval_locator);
            if (assert_local_regular_file($surface_id, $path)) {
                my ($actual_lines, $actual_bytes) = file_measurement($path);
                problem("archive descriptor $descriptor_id retrieval line count changed ($actual_lines != $lines)")
                    if nonnegative_integer($lines) && $actual_lines != $lines;
                problem("archive descriptor $descriptor_id retrieval byte count changed ($actual_bytes != $bytes)")
                    if nonnegative_integer($bytes) && $actual_bytes != $bytes;
                my $actual = file_sha256($path);
                problem("archive descriptor $descriptor_id retrieval digest changed ($actual != $sha256)")
                    if $actual ne $sha256;
            }
        }
        problem("archive descriptor $descriptor_id file verifier must be builtin:file")
            if $verifier ne 'builtin:file';
    } elsif ($retrieval_kind eq 'version_object') {
        problem("archive descriptor $descriptor_id has empty version-object locator")
            if $retrieval_locator eq '' || $retrieval_locator eq '-';
        my $contract_id = $record->{retention_contract};
        my $guidance = '';
        if (!defined $contract_id || ref $contract_id
            || $contract_id !~ /\A[a-z][a-z0-9_.-]*\z/) {
            problem("archive descriptor $descriptor_id has invalid or missing retention_contract");
        }
        elsif (!exists $retention_contracts{$contract_id}) {
            problem("archive descriptor $descriptor_id names unknown retention contract: $contract_id");
        }
        else {
            my $contract = $retention_contracts{$contract_id};
            $guidance = "; retention contract $contract_id owner $contract->{owner} "
                . "requires recovery: $contract->{recovery}";
        }
        verify_execution(
            "archive descriptor $descriptor_id version retrieval",
            "archive:$descriptor_id",
            $verifier,
            $guidance,
        );
    } elsif ($retrieval_kind eq 'external') {
        problem("archive descriptor $descriptor_id external locator is empty")
            if $retrieval_locator eq '' || $retrieval_locator eq '-';
        problem("archive descriptor $descriptor_id external verifier must start with external:")
            if $verifier !~ /\Aexternal:.+/;
    } else {
        problem("archive descriptor $descriptor_id has unknown retrieval_kind: $retrieval_kind");
    }
    $archive_descriptors{$descriptor_id} = $record
        if !$duplicate_descriptor
            && $descriptor_id =~ /\A[a-z][a-z0-9_.-]*\z/;
}

my $ledger_rows = read_jsonl($ledgers_arg, 'ledger manifest registry');
my (%ledgers, %ledger_ranges);
for my $row (@{$ledger_rows}) {
    my ($line_number, $record) = @{$row};
    my $type = $record->{record_type} // '';
    if ($type eq 'ledger') {
        my @keys = qw(
            record_type schema_version ledger_id surface_id current_path index_path
            entry_start_prefix ordering source_descriptor_id total_entries
            entries_lines entries_bytes entries_sha256 current_entry_limit
            index_lines_ceiling index_bytes_ceiling reconstruction_verifier
            archive_transition
        );
        next if !validate_keys(
            'ledger manifest registry', $line_number, $record, \@keys, [],
        );
        my $ledger_id = $record->{ledger_id} // '';
        for my $field (
            [record_type => 32], [ledger_id => 128], [surface_id => 128],
            [current_path => 512], [index_path => 512],
            [entry_start_prefix => 128], [ordering => 32],
            [source_descriptor_id => 128], [reconstruction_verifier => 1024],
        ) {
            my ($key, $max_bytes) = @{$field};
            problem("ledger $ledger_id has empty, multiline, or oversized $key")
                if !bounded_nonempty_string($record->{$key}, $max_bytes);
        }
        problem("ledger $ledger_id has unsupported schema_version: $record->{schema_version}")
            if !nonnegative_integer($record->{schema_version})
                || $record->{schema_version} ne '1';
        problem("ledger manifest has invalid ledger_id: $ledger_id")
            if $ledger_id !~ /\A[a-z][a-z0-9_.-]*\z/;
        problem("ledger $ledger_id is declared more than once")
            if exists $ledgers{$ledger_id};
        problem("ledger $ledger_id must declare append_only ordering")
            if ($record->{ordering} // '') ne 'append_only';
        problem("ledger $ledger_id entry_start_prefix must use printable ASCII")
            if ($record->{entry_start_prefix} // '') !~ /\A[\x20-\x7e]+\z/;
        problem("ledger $ledger_id current_path must stay project-relative")
            if !relative_path_ok($record->{current_path});
        problem("ledger $ledger_id index_path must stay project-relative")
            if !relative_path_ok($record->{index_path});
        problem("ledger $ledger_id current_path and index_path must be distinct")
            if ($record->{current_path} // '') eq ($record->{index_path} // '');
        for my $key (qw(total_entries entries_lines entries_bytes current_entry_limit index_lines_ceiling index_bytes_ceiling)) {
            problem("ledger $ledger_id has invalid positive $key")
                if !positive_integer($record->{$key});
        }
        problem("ledger $ledger_id has invalid entries_sha256")
            if ($record->{entries_sha256} // '') !~ /\A[0-9a-f]{64}\z/;
        my $transition = $record->{archive_transition};
        my @transition_keys = qw(
            archive_surface_id max_live_ranges max_live_lines max_live_bytes
        );
        if (ref($transition) ne 'HASH'
                || !validate_keys(
                    "ledger $ledger_id archive_transition", $line_number,
                    $transition, \@transition_keys, [],
                )) {
            problem("ledger $ledger_id archive_transition must be an exact object")
                if ref($transition) ne 'HASH';
        } else {
            problem("ledger $ledger_id archive_transition has invalid archive_surface_id")
                if !bounded_nonempty_string($transition->{archive_surface_id}, 128)
                    || $transition->{archive_surface_id} !~ /\A[a-z][a-z0-9_]*\z/;
            for my $key (qw(max_live_ranges max_live_lines max_live_bytes)) {
                problem("ledger $ledger_id archive_transition has invalid positive $key")
                    if !positive_integer($transition->{$key});
            }
        }
        $ledgers{$ledger_id} = $record
            if $ledger_id =~ /\A[a-z][a-z0-9_.-]*\z/;
    } elsif ($type eq 'range') {
        my @keys = qw(
            record_type schema_version range_id ledger_id sequence first_ordinal
            last_ordinal entry_count revision lines bytes sha256
            first_entry_sha256 last_entry_sha256 storage_kind storage_locator verifier
        );
        next if !validate_keys(
            'ledger manifest registry', $line_number, $record, \@keys, [],
        );
        my ($ledger_id, $range_id) = @{$record}{qw(ledger_id range_id)};
        $ledger_id //= '';
        $range_id //= '';
        for my $field (
            [record_type => 32], [ledger_id => 128], [range_id => 128],
            [revision => 128], [storage_kind => 32],
            [storage_locator => 1024], [verifier => 64],
        ) {
            my ($key, $max_bytes) = @{$field};
            problem("ledger range $range_id has empty, multiline, or oversized $key")
                if !bounded_nonempty_string($record->{$key}, $max_bytes);
        }
        problem("ledger range $range_id has unsupported schema_version: $record->{schema_version}")
            if !nonnegative_integer($record->{schema_version})
                || $record->{schema_version} ne '1';
        problem("ledger range has invalid range_id: $range_id")
            if $range_id !~ /\A[a-z][a-z0-9_.-]*\z/;
        problem("ledger range $range_id has invalid ledger_id: $ledger_id")
            if $ledger_id !~ /\A[a-z][a-z0-9_.-]*\z/;
        for my $key (qw(sequence first_ordinal last_ordinal entry_count lines bytes)) {
            problem("ledger range $range_id has invalid positive $key")
                if !positive_integer($record->{$key});
        }
        for my $key (qw(sha256 first_entry_sha256 last_entry_sha256)) {
            problem("ledger range $range_id has invalid $key")
                if ($record->{$key} // '') !~ /\A[0-9a-f]{64}\z/;
        }
        push @{$ledger_ranges{$ledger_id}}, $record
            if $ledger_id =~ /\A[a-z][a-z0-9_.-]*\z/;
    } else {
        problem("ledger manifest registry line $line_number has unknown record_type");
    }
}

for my $orphan (sort keys %ledger_ranges) {
    problem("ledger range names unknown ledger: $orphan") if !exists $ledgers{$orphan};
}

for my $ledger_id (sort keys %ledgers) {
    my $ledger = $ledgers{$ledger_id};
    my $surface_id = $ledger->{surface_id};
    my $surface = $surfaces{$surface_id};
    if (!$surface) {
        problem("ledger $ledger_id names unknown surface: $surface_id");
    } else {
        problem("ledger $ledger_id surface $surface_id is not a rolling ledger")
            if $surface->{lifecycle} ne 'rolling_ledger';
        problem("ledger $ledger_id current_path does not match its singular surface target")
            if @{$surface->{target_patterns}} != 1
                || $surface->{target_patterns}[0] ne $ledger->{current_path};
    }
    my $archive_surface_id = ref($ledger->{archive_transition}) eq 'HASH'
        ? $ledger->{archive_transition}{archive_surface_id} : '';
    my $archive_surface = $surfaces{$archive_surface_id};
    problem("ledger $ledger_id archive transition must name an archive_terminal surface")
        if !$archive_surface || $archive_surface->{lifecycle} ne 'archive_terminal';

    my $source_descriptor = $archive_descriptors{$ledger->{source_descriptor_id}};
    if (!$source_descriptor) {
        problem("ledger $ledger_id names unknown source descriptor: $ledger->{source_descriptor_id}");
    } else {
        problem("ledger $ledger_id source descriptor belongs to another surface")
            if $source_descriptor->{surface_id} ne $surface_id;
        problem("ledger $ledger_id source descriptor former_path differs from current_path")
            if $source_descriptor->{former_path} ne $ledger->{current_path};
        problem("ledger $ledger_id source descriptor current_pointer differs from current_path")
            if $source_descriptor->{current_pointer} ne $ledger->{current_path};
    }

    my $index_contents = read_regular_file($surface_id, $ledger->{index_path});
    if (defined $index_contents) {
        my $index_lines = raw_line_count($index_contents);
        my $index_bytes = length($index_contents);
        problem("ledger $ledger_id index lines are $index_lines (> ceiling $ledger->{index_lines_ceiling})")
            if positive_integer($ledger->{index_lines_ceiling})
                && $index_lines > $ledger->{index_lines_ceiling};
        problem("ledger $ledger_id index bytes are $index_bytes (> ceiling $ledger->{index_bytes_ceiling})")
            if positive_integer($ledger->{index_bytes_ceiling})
                && $index_bytes > $ledger->{index_bytes_ceiling};
    }
    my $current_view = read_regular_file($surface_id, $ledger->{current_path});
    problem("ledger $ledger_id current view does not route to its bounded index")
        if defined($current_view)
            && index($current_view, $ledger->{index_path}) < 0;

    my @ranges = sort {
        ($a->{sequence} // 0) <=> ($b->{sequence} // 0)
    } @{$ledger_ranges{$ledger_id} || []};
    if (!@ranges) {
        problem("ledger $ledger_id declares no ranges");
        next;
    }
    my (%range_ids, %sequences, $expected_ordinal, $expected_sequence);
    my ($current_ranges, $live_ranges, $live_lines, $live_bytes) = (0, 0, 0, 0);
    my ($total_entries, $total_lines, $total_bytes) = (0, 0, 0);
    my @available_bodies;
    my $all_bodies_available = 1;
    for my $range (@ranges) {
        my $range_id = $range->{range_id};
        problem("ledger $ledger_id duplicates range_id $range_id") if $range_ids{$range_id}++;
        problem("ledger $ledger_id duplicates sequence $range->{sequence}")
            if $sequences{$range->{sequence}}++;
        problem("ledger $ledger_id sequence is not contiguous at $range_id")
            if positive_integer($range->{sequence})
                && $range->{sequence} != ++$expected_sequence;
        problem("ledger $ledger_id ordinal range is not contiguous at $range_id")
            if positive_integer($range->{first_ordinal})
                && $range->{first_ordinal} != ++$expected_ordinal;
        if (positive_integer($range->{first_ordinal})
                && positive_integer($range->{last_ordinal})
                && positive_integer($range->{entry_count})) {
            problem("ledger $ledger_id range $range_id ordinal span does not match entry_count")
                if $range->{last_ordinal} - $range->{first_ordinal} + 1
                    != $range->{entry_count};
            $expected_ordinal = $range->{last_ordinal};
        }
        $total_entries += $range->{entry_count} if positive_integer($range->{entry_count});
        $total_lines += $range->{lines} if positive_integer($range->{lines});
        $total_bytes += $range->{bytes} if positive_integer($range->{bytes});
        problem("ledger $ledger_id index omits range $range_id")
            if defined($index_contents)
                && $index_contents !~ /(?<![a-z0-9_.-])\Q$range_id\E(?![a-z0-9_.-])/;

        my ($contents, $allow_preamble);
        if ($range->{storage_kind} eq 'current') {
            $current_ranges++;
            problem("ledger $ledger_id current range must use current_path")
                if $range->{storage_locator} ne $ledger->{current_path};
            problem("ledger $ledger_id current range must use builtin:current")
                if $range->{verifier} ne 'builtin:current';
            $contents = read_regular_file($surface_id, $range->{storage_locator});
            $allow_preamble = 1;
        } elsif ($range->{storage_kind} eq 'sealed_file') {
            problem("ledger $ledger_id sealed range path must stay project-relative")
                if !relative_path_ok($range->{storage_locator});
            problem("ledger $ledger_id sealed range must use builtin:file")
                if $range->{verifier} ne 'builtin:file';
            problem("ledger $ledger_id sealed range path must be content-addressed by its digest")
                if basename($range->{storage_locator})
                    !~ /\A\Q$range->{sha256}\E(?:\.[A-Za-z0-9]+)?\z/;
            $contents = read_regular_file($surface_id, $range->{storage_locator});
            $allow_preamble = 0;
            $live_ranges++;
            $live_lines += $range->{lines} if positive_integer($range->{lines});
            $live_bytes += $range->{bytes} if positive_integer($range->{bytes});
        } elsif ($range->{storage_kind} eq 'archive_descriptor') {
            problem("ledger $ledger_id archived range must use builtin:archive_descriptor")
                if $range->{verifier} ne 'builtin:archive_descriptor';
            my $descriptor = $archive_descriptors{$range->{storage_locator}};
            if (!$descriptor) {
                problem("ledger $ledger_id range $range_id names unknown archive descriptor");
            } else {
                for my $pair (
                    [range_id => $range_id], [surface_id => $surface_id],
                    [revision => $range->{revision}], [lines => $range->{lines}],
                    [bytes => $range->{bytes}], [sha256 => $range->{sha256}],
                    [current_pointer => $ledger->{current_path}],
                ) {
                    my ($key, $expected) = @{$pair};
                    problem("ledger $ledger_id range $range_id differs from archive descriptor $key")
                        if ($descriptor->{$key} // '') ne ($expected // '');
                }
                if ($descriptor->{retrieval_kind} eq 'file') {
                    $contents = read_regular_file(
                        $surface_id, $descriptor->{retrieval_locator},
                    );
                    $allow_preamble = 0;
                }
            }
        } else {
            problem("ledger $ledger_id range $range_id has unknown storage_kind: $range->{storage_kind}");
        }

        if (defined $contents) {
            my ($body, $entries) = ledger_entries(
                $ledger_id, $contents, $ledger->{entry_start_prefix}, $allow_preamble,
            );
            if (defined $body) {
                my $actual_lines = raw_line_count($body);
                my $actual_bytes = length($body);
                my $actual_sha = Digest::SHA::sha256_hex($body);
                problem("ledger $ledger_id range $range_id entry count changed")
                    if @{$entries} != $range->{entry_count};
                problem("ledger $ledger_id range $range_id line count changed")
                    if $actual_lines != $range->{lines};
                problem("ledger $ledger_id range $range_id byte count changed")
                    if $actual_bytes != $range->{bytes};
                problem("ledger $ledger_id range $range_id digest changed")
                    if $actual_sha ne $range->{sha256};
                problem("ledger $ledger_id range $range_id first-entry identity changed")
                    if Digest::SHA::sha256_hex($entries->[0]) ne $range->{first_entry_sha256};
                problem("ledger $ledger_id range $range_id last-entry identity changed")
                    if Digest::SHA::sha256_hex($entries->[-1]) ne $range->{last_entry_sha256};
                push @available_bodies, $body;
            } else {
                $all_bodies_available = 0;
            }
        } else {
            $all_bodies_available = 0;
        }
    }
    problem("ledger $ledger_id must declare exactly one current range")
        if $current_ranges != 1;
    problem("ledger $ledger_id current range must be the final append-only range")
        if @ranges && $ranges[-1]{storage_kind} ne 'current';
    problem("ledger $ledger_id current range exceeds current_entry_limit")
        if @ranges && positive_integer($ranges[-1]{entry_count})
            && $ranges[-1]{entry_count} > $ledger->{current_entry_limit};
    for my $dimension (
        [ranges => $live_ranges, 'max_live_ranges'],
        [lines => $live_lines, 'max_live_lines'],
        [bytes => $live_bytes, 'max_live_bytes'],
    ) {
        my ($name, $actual, $key) = @{$dimension};
        my $limit = ref($ledger->{archive_transition}) eq 'HASH'
            ? $ledger->{archive_transition}{$key} : undef;
        problem("ledger $ledger_id live sealed $name are $actual (> archive-transition limit $limit)")
            if positive_integer($limit) && $actual > $limit;
    }
    problem("ledger $ledger_id total_entries differs from its ordered ranges")
        if positive_integer($ledger->{total_entries})
            && $total_entries != $ledger->{total_entries};
    problem("ledger $ledger_id entries_lines differs from its ordered ranges")
        if positive_integer($ledger->{entries_lines})
            && $total_lines != $ledger->{entries_lines};
    problem("ledger $ledger_id entries_bytes differs from its ordered ranges")
        if positive_integer($ledger->{entries_bytes})
            && $total_bytes != $ledger->{entries_bytes};

    my $reconstructed = join('', @available_bodies);
    if ($all_bodies_available) {
        problem("ledger $ledger_id reconstructed line count changed")
            if raw_line_count($reconstructed) != $ledger->{entries_lines};
        problem("ledger $ledger_id reconstructed byte count changed")
            if length($reconstructed) != $ledger->{entries_bytes};
        problem("ledger $ledger_id reconstructed digest changed")
            if Digest::SHA::sha256_hex($reconstructed) ne $ledger->{entries_sha256};
    }
    my $source_contents;
    if ($source_descriptor
            && $source_descriptor->{retrieval_kind} eq 'file') {
        $source_contents = read_regular_file(
            $surface_id, $source_descriptor->{retrieval_locator},
        );
    }
    if (defined($source_contents) && $all_bodies_available) {
        my ($source_body) = ledger_entries(
            $ledger_id, $source_contents, $ledger->{entry_start_prefix}, 1,
        );
        problem("ledger $ledger_id reconstruction differs from its exact source entries")
            if !defined($source_body) || $source_body ne $reconstructed;
    }
    if ($ledger->{reconstruction_verifier} eq 'builtin:concatenate') {
        problem("ledger $ledger_id builtin reconstruction requires locally readable ranges and source")
            if !$all_bodies_available || !defined($source_contents);
    } else {
        verify_execution(
            "ledger $ledger_id reconstruction", "ledger:$ledger_id",
            $ledger->{reconstruction_verifier},
        );
    }
    ok_note("ledger $ledger_id: $total_entries ordered whole entries reconstructed across "
        . scalar(@ranges) . " range(s); live sealed $live_ranges/$live_lines/$live_bytes");
}

for my $proof (sort keys %adapter_proof) {
    problem("adapter proof does not match a declared adapter verifier: $proof");
}

if ($coverage_stdin) {
    local $/ = "\0";
    my ($covered, $seen) = (0, 0);
    while (defined(my $path = <STDIN>)) {
        $path =~ s/\0\z//;
        next if $path eq '';
        $seen++;
        if (!relative_path_ok($path)) {
            problem("coverage path must stay project-relative: $path");
            next;
        }
        my $matched = 0;
        for my $pattern (@coverage_patterns) {
            my $regex = quotemeta($pattern);
            $regex =~ s{\\\*\\\*}{.*}g;
            $regex =~ s{\\\*}{[^/]*}g;
            $regex =~ s{\\\?}{[^/]}g;
            if ($path =~ /\A$regex\z/) {
                $matched = 1;
                last;
            }
        }
        if ($matched) {
            $covered++;
        } else {
            problem("tracked document is not covered by any surface: $path");
        }
    }
    ok_note("coverage: $covered/$seen declared document path(s)");
}

if (!$fail) {
    print 'live-doc-size: all live-document size-containment invariants hold ('
        . scalar(@surface_order) . " surfaces)\n";
}
exit($fail ? 1 : 0);
