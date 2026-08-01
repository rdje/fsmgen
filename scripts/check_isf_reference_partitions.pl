#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode_utf8);
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Spec;
use Getopt::Long qw(GetOptions);
use IPC::Open3 qw(open3);
use JSON::PP qw(decode_json);
use Symbol qw(gensym);

my ($root_arg, $current_root_arg, $manifest_relative, $verify_activation, $help);
$manifest_relative = 'doctrine/live_document_size/isf_reference_partitions.jsonl';
GetOptions(
    'root=s'                    => \$root_arg,
    'current-root=s'            => \$current_root_arg,
    'manifest=s'                => \$manifest_relative,
    'verify-activation-content' => \$verify_activation,
    'help|h'                    => \$help,
) or usage(2);
usage(0) if $help;
my $command = shift(@ARGV) // 'check';
usage(2) if @ARGV || $command !~ /\A(?:check|materialize)\z/;

my $script = abs_path(__FILE__);
my $root = abs_path($root_arg // File::Spec->catdir(dirname($script), '..'));
die "isf-reference-partitions: invalid project root\n" if !defined($root) || !-d $root;
my $current_root = abs_path($current_root_arg // $root);
die "isf-reference-partitions: invalid current root\n"
    if !defined($current_root) || !-d $current_root;
my @root_stat = stat $root;
die "isf-reference-partitions: cannot stat project root\n" if !@root_stat;
my @current_root_stat = stat $current_root;
die "isf-reference-partitions: current root is off the project volume\n"
    if !@current_root_stat || $current_root_stat[0] != $root_stat[0];

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: check_isf_reference_partitions.pl [--root DIR] [--current-root DIR]
       [--manifest FILE]
       [--verify-activation-content] [check|materialize]

The materialize command is activation-only: it reconstructs the declared
semantic parts from the exact Git source objects and replaces the three source
paths with bounded landing pages. Ordinary enforcement uses check.
USAGE
    exit $status;
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
    die "isf-reference-partitions: unsafe project-relative path: $relative\n"
        if !relative_path_ok($relative);
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub current_path {
    my ($relative) = @_;
    die "isf-reference-partitions: unsafe current project-relative path: $relative\n"
        if !relative_path_ok($relative);
    return File::Spec->catfile($current_root, split m{/+}, $relative);
}

sub bounded_string {
    my ($value, $limit) = @_;
    return !ref($value) && defined($value) && $value ne ''
        && $value !~ /[\r\n\0]/ && length($value) <= $limit;
}

sub positive_integer {
    my ($value) = @_;
    return !ref($value) && defined($value) && $value =~ /\A[1-9][0-9]*\z/;
}

sub git_show {
    my ($revision, $path) = @_;
    my $stderr = gensym;
    my $pid = open3(my $stdin, my $stdout, $stderr,
        'git', '-C', $root, 'show', "$revision:$path");
    close $stdin;
    binmode $stdout, ':raw';
    local $/;
    my $contents = <$stdout> // '';
    my $error = <$stderr> // '';
    waitpid($pid, 0);
    if ($? != 0) {
        $error =~ s/\s+\z//;
        die "isf-reference-partitions: cannot retrieve $revision:$path"
            . ($error eq '' ? "\n" : ": $error\n");
    }
    return $contents;
}

sub dimensions {
    my ($contents) = @_;
    my $lines = ($contents =~ tr/\n//);
    my $max_line = 0;
    for my $line (split /\n/, $contents, -1) {
        my $bytes = length($line);
        $max_line = $bytes if $bytes > $max_line;
    }
    return ($lines, length($contents), $max_line);
}

sub content_mismatch {
    my ($relative, $actual, $expected) = @_;
    my @actual_lines = split /\n/, $actual, -1;
    my @expected_lines = split /\n/, $expected, -1;
    my $limit = @actual_lines > @expected_lines ? @actual_lines : @expected_lines;
    for my $index (0 .. $limit - 1) {
        my $actual_line = $actual_lines[$index] // '<absent>';
        my $expected_line = $expected_lines[$index] // '<absent>';
        next if $actual_line eq $expected_line;
        return "isf-reference-partitions: activation content mismatch at "
            . "$relative:" . ($index + 1) . "\n"
            . "  expected: $expected_line\n  actual:   $actual_line\n";
    }
    return "isf-reference-partitions: activation content mismatch: $relative\n";
}

sub read_manifest {
    my $path = root_path($manifest_relative);
    die "isf-reference-partitions: missing manifest: $manifest_relative\n"
        if !-f $path || -l $path;
    open my $fh, '<:raw', $path
        or die "isf-reference-partitions: cannot read $manifest_relative: $!\n";
    my @stat = stat $fh;
    die "isf-reference-partitions: manifest is off the project volume\n"
        if !@stat || $stat[0] != $root_stat[0];
    my @lines = <$fh>;
    close $fh or die "isf-reference-partitions: cannot close $manifest_relative: $!\n";
    die "isf-reference-partitions: manifest is empty\n" if !@lines;
    my @records;
    for my $index (0 .. $#lines) {
        my $line_number = $index + 1;
        my $line = $lines[$index];
        $line =~ s/\r?\n\z//;
        die "isf-reference-partitions: blank manifest line $line_number\n" if $line eq '';
        my $record = eval { decode_json($line) };
        die "isf-reference-partitions: invalid JSON at line $line_number\n"
            if $@ || ref($record) ne 'HASH';
        push @records, $record;
    }
    my $header = shift @records;
    my @header_keys = sort keys %{$header};
    die "isf-reference-partitions: invalid registry header\n"
        if join(',', @header_keys) ne 'max_bytes,max_record_bytes,max_records,record_type,schema_version'
            || ($header->{record_type} // '') ne 'registry'
            || ($header->{schema_version} // 0) != 1
            || !positive_integer($header->{max_records})
            || !positive_integer($header->{max_bytes})
            || !positive_integer($header->{max_record_bytes});
    my $manifest_bytes = -s $path;
    die "isf-reference-partitions: manifest exceeds max_records\n"
        if @records + 1 > $header->{max_records};
    die "isf-reference-partitions: manifest exceeds max_bytes\n"
        if $manifest_bytes > $header->{max_bytes};
    for my $index (0 .. $#lines) {
        die "isf-reference-partitions: manifest line " . ($index + 1)
            . " exceeds max_record_bytes\n"
            if length($lines[$index]) > $header->{max_record_bytes};
    }
    return \@records;
}

sub validate_source {
    my ($record) = @_;
    my @required = qw(record_type schema_version source_id source_path revision lines bytes sha256 landing title summary lines_each bytes_each line_bytes_each);
    my %allowed = map { $_ => 1 } @required;
    die "isf-reference-partitions: source has unknown or missing fields\n"
        if (grep { !$allowed{$_} } keys %{$record})
            || (grep { !exists $record->{$_} } @required);
    die "isf-reference-partitions: invalid source id\n"
        if ($record->{source_id} // '') !~ /\A[a-z][a-z0-9_]*\z/;
    die "isf-reference-partitions: invalid source paths for $record->{source_id}\n"
        if !relative_path_ok($record->{source_path}) || !relative_path_ok($record->{landing});
    die "isf-reference-partitions: source and landing must be the same path for $record->{source_id}\n"
        if $record->{source_path} ne $record->{landing};
    die "isf-reference-partitions: invalid source identity for $record->{source_id}\n"
        if ($record->{revision} // '') !~ /\A[0-9a-f]{40}\z/
            || ($record->{sha256} // '') !~ /\A[0-9a-f]{64}\z/
            || grep { !positive_integer($record->{$_}) }
                qw(lines bytes lines_each bytes_each line_bytes_each);
    die "isf-reference-partitions: invalid source prose for $record->{source_id}\n"
        if !bounded_string($record->{title}, 256) || !bounded_string($record->{summary}, 512);
}

sub validate_part {
    my ($record) = @_;
    my @required = qw(record_type schema_version source_id sequence source_start source_end path label first_heading last_heading);
    my %allowed = map { $_ => 1 } @required;
    die "isf-reference-partitions: part has unknown or missing fields\n"
        if (grep { !$allowed{$_} } keys %{$record})
            || (grep { !exists $record->{$_} } @required);
    die "isf-reference-partitions: invalid part source id\n"
        if ($record->{source_id} // '') !~ /\A[a-z][a-z0-9_]*\z/;
    die "isf-reference-partitions: invalid part path\n" if !relative_path_ok($record->{path});
    die "isf-reference-partitions: invalid part range for $record->{path}\n"
        if (grep { !positive_integer($record->{$_}) }
                qw(sequence source_start source_end))
            || $record->{source_start} > $record->{source_end};
    die "isf-reference-partitions: invalid part prose for $record->{path}\n"
        if !bounded_string($record->{label}, 256)
            || !bounded_string($record->{first_heading}, 256)
            || !bounded_string($record->{last_heading}, 256);
}

sub transform_links_for_nested_part {
    my ($source_id, $sequence, $contents, $rewrites_by_part) = @_;
    my $rewrite_key = "$source_id:$sequence";
    for my $rewrite (@{$rewrites_by_part->{$rewrite_key} || []}) {
        my $count = ($contents =~ s/\Q$rewrite->{original}\E/$rewrite->{replacement}/g);
        die "isf-reference-partitions: activation rewrite count mismatch for $source_id\n"
            if $count != $rewrite->{occurrences};
    }
    $contents =~ s{\]\(([^\s\)]+)([^\)]*)\)}{
        my ($target, $suffix) = ($1, $2);
        if ($target !~ m{\A(?:[a-z][a-z0-9+.-]*:|#|/)}i) {
            $target = "../$target";
        }
        "]($target$suffix)";
    }gex;
    return $contents;
}

sub source_segment {
    my ($source_contents, $part) = @_;
    my @lines = ($source_contents =~ /.*(?:\n|\z)/g);
    pop @lines if @lines && $lines[-1] eq '';
    return join '', @lines[$part->{source_start} - 1 .. $part->{source_end} - 1];
}

sub link_from_landing {
    my ($landing, $target) = @_;
    my $from = dirname(root_path($landing));
    my $relative = File::Spec->abs2rel(root_path($target), $from);
    $relative =~ s{\\}{/}g;
    return $relative;
}

sub expected_landing {
    my ($source, $sources, $parts_by_source) = @_;
    my $landing = $source->{landing};
    my $text = "# $source->{title}\n\n";
    $text .= "$source->{summary}\n\n";
    $text .= "This maintained reference is split at stable semantic boundaries so every\n";
    $text .= "review unit stays bounded. The exact pre-partition source remains retrievable\n";
    $text .= "from Git through the registered archive descriptor. Edit the relevant part and\n";
    $text .= "keep this landing, the other contracts, tests, and mdBook synchronized.\n\n";
    $text .= "## Parts\n\n";
    for my $part (@{$parts_by_source->{$source->{source_id}}}) {
        $text .= '- [' . $part->{label} . '](' . link_from_landing($landing, $part->{path}) . ")\n";
    }
    if ($source->{source_id} eq 'isf_spec') {
        $text .= "\n## Complete ISF reference set\n\n";
        for my $other (@{$sources}) {
            if ($other->{landing} ne $landing) {
                $text .= '- [' . $other->{title} . ']('
                    . link_from_landing($landing, $other->{landing}) . ")\n";
            }
            for my $part (@{$parts_by_source->{$other->{source_id}}}) {
                next if $other->{source_id} eq $source->{source_id};
                $text .= '  - [' . $part->{label} . ']('
                    . link_from_landing($landing, $part->{path}) . ")\n";
            }
        }
    } else {
        $text .= "\n## Related maintained contracts\n\n";
        for my $other (@{$sources}) {
            next if $other->{source_id} eq $source->{source_id};
            $text .= '- [' . $other->{title} . ']('
                . link_from_landing($landing, $other->{landing}) . ")\n";
        }
    }
    return $text;
}

sub read_current {
    my ($relative) = @_;
    my $path = current_path($relative);
    die "isf-reference-partitions: missing current file: $relative\n" if !-f $path || -l $path;
    my @stat = stat $path;
    die "isf-reference-partitions: current file is off the project volume: $relative\n"
        if !@stat || $stat[0] != $current_root_stat[0];
    open my $fh, '<:raw', $path
        or die "isf-reference-partitions: cannot read $relative: $!\n";
    local $/;
    my $contents = <$fh> // '';
    close $fh or die "isf-reference-partitions: cannot close $relative: $!\n";
    return $contents;
}

sub verify_local_links {
    my ($relative, $contents) = @_;
    while ($contents =~ /\]\((?:<([^>]+)>|([^\s\)]+))(?:\s+[^\)]*)?\)/g) {
        my $destination = defined($1) ? $1 : $2;
        $destination =~ s/[?#].*\z//;
        next if $destination eq '' || $destination =~ /\A(?:[a-z][a-z0-9+.-]*:|#)/i;
        my $candidate = File::Spec->catfile(
            $current_root, dirname($relative), split(m{/+}, $destination),
        );
        my $target = abs_path($candidate);
        die "isf-reference-partitions: broken local link in $relative: $destination\n"
            if !defined($target) || !-e $target;
        die "isf-reference-partitions: local link escapes project root in $relative: $destination\n"
            if $target ne $current_root && index($target, "$current_root/") != 0;
        die "isf-reference-partitions: symlink local-link target in $relative: $destination\n"
            if -l $candidate;
    }
}

sub write_atomic {
    my ($relative, $contents) = @_;
    my $path = current_path($relative);
    my $directory = dirname($path);
    make_path($directory) if !-d $directory;
    my @stat = stat $directory;
    die "isf-reference-partitions: output directory is off the project volume: $relative\n"
        if !@stat || $stat[0] != $current_root_stat[0];
    my $temporary = File::Spec->catfile($directory, '.' . basename($path) . ".new.$$" );
    open my $fh, '>:raw', $temporary
        or die "isf-reference-partitions: cannot write $temporary: $!\n";
    print {$fh} $contents or die "isf-reference-partitions: cannot write $temporary: $!\n";
    close $fh or die "isf-reference-partitions: cannot close $temporary: $!\n";
    rename $temporary, $path
        or die "isf-reference-partitions: cannot replace $relative: $!\n";
}

my $records = read_manifest();
my (
    @sources,
    %source_by_id,
    %parts_by_source,
    %rewrites_by_part,
    %seen_path,
    %seen_rewrite_original,
);
for my $record (@{$records}) {
    die "isf-reference-partitions: unsupported schema version\n"
        if ($record->{schema_version} // 0) != 1;
    if (($record->{record_type} // '') eq 'source') {
        validate_source($record);
        die "isf-reference-partitions: duplicate source id $record->{source_id}\n"
            if exists $source_by_id{$record->{source_id}};
        die "isf-reference-partitions: duplicate source path $record->{source_path}\n"
            if $seen_path{$record->{source_path}}++;
        push @sources, $record;
        $source_by_id{$record->{source_id}} = $record;
    } elsif (($record->{record_type} // '') eq 'part') {
        validate_part($record);
        die "isf-reference-partitions: duplicate part path $record->{path}\n"
            if $seen_path{$record->{path}}++;
        push @{$parts_by_source{$record->{source_id}}}, $record;
    } elsif (($record->{record_type} // '') eq 'rewrite') {
        my @required = qw(record_type schema_version source_id sequence occurrences original replacement rationale);
        my %allowed = map { $_ => 1 } @required;
        die "isf-reference-partitions: rewrite has unknown or missing fields\n"
            if (grep { !$allowed{$_} } keys %{$record})
                || (grep { !exists $record->{$_} } @required);
        die "isf-reference-partitions: invalid rewrite record\n"
            if ($record->{source_id} // '') !~ /\A[a-z][a-z0-9_]*\z/
                || !positive_integer($record->{sequence})
                || !positive_integer($record->{occurrences})
                || !bounded_string($record->{original}, 512)
                || !bounded_string($record->{replacement}, 512)
                || !bounded_string($record->{rationale}, 512);
        my $rewrite_key = "$record->{source_id}:$record->{sequence}";
        die "isf-reference-partitions: duplicate rewrite original for $rewrite_key\n"
            if $seen_rewrite_original{$rewrite_key}{$record->{original}}++;
        push @{$rewrites_by_part{$rewrite_key}}, $record;
    } else {
        die "isf-reference-partitions: unknown record type\n";
    }
}
die "isf-reference-partitions: expected exactly three source records\n" if @sources != 3;
for my $rewrite_key (keys %rewrites_by_part) {
    my ($source_id) = split /:/, $rewrite_key, 2;
    die "isf-reference-partitions: rewrite names unknown source $source_id\n"
        if !exists $source_by_id{$source_id};
}

my %archived_contents;
for my $source (@sources) {
    my $id = $source->{source_id};
    my @parts = sort { $a->{sequence} <=> $b->{sequence} }
        @{$parts_by_source{$id} || []};
    die "isf-reference-partitions: source $id has no parts\n" if !@parts;
    my $next_line = 1;
    for my $index (0 .. $#parts) {
        my $part = $parts[$index];
        die "isf-reference-partitions: source $id has non-contiguous sequence\n"
            if $part->{sequence} != $index + 1;
        die "isf-reference-partitions: source $id has a gap or overlap before $part->{path}\n"
            if $part->{source_start} != $next_line;
        $next_line = $part->{source_end} + 1;
    }
    die "isf-reference-partitions: source $id coverage ends at " . ($next_line - 1)
        . ", expected $source->{lines}\n"
        if $next_line - 1 != $source->{lines};
    $parts_by_source{$id} = \@parts;

    for my $rewrite_key (grep { /^\Q$id\E:/ } keys %rewrites_by_part) {
        my (undef, $sequence) = split /:/, $rewrite_key, 2;
        die "isf-reference-partitions: rewrite names missing part $rewrite_key\n"
            if $sequence > @parts;
    }

    my $archived = git_show($source->{revision}, $source->{source_path});
    my ($lines, $bytes) = dimensions($archived);
    die "isf-reference-partitions: archived identity mismatch for $source->{source_path}\n"
        if $lines != $source->{lines} || $bytes != $source->{bytes}
            || sha256_hex($archived) ne $source->{sha256};
    $archived_contents{$id} = $archived;
}

for my $rewrite_key (keys %rewrites_by_part) {
    my ($source_id, $sequence) = split /:/, $rewrite_key, 2;
    my $segment = source_segment(
        $archived_contents{$source_id},
        $parts_by_source{$source_id}[$sequence - 1],
    );
    for my $rewrite (@{$rewrites_by_part{$rewrite_key}}) {
        my $count = () = $segment =~ /\Q$rewrite->{original}\E/g;
        die "isf-reference-partitions: declared rewrite count mismatch for $rewrite_key\n"
            if $count != $rewrite->{occurrences};
    }
}

if ($command eq 'materialize') {
    for my $source (@sources) {
        my $current = read_current($source->{source_path});
        die "isf-reference-partitions: activation source already changed: $source->{source_path}\n"
            if sha256_hex($current) ne $source->{sha256};
    }
    for my $source (@sources) {
        for my $part (@{$parts_by_source{$source->{source_id}}}) {
            my $contents = transform_links_for_nested_part(
                $source->{source_id},
                $part->{sequence},
                source_segment($archived_contents{$source->{source_id}}, $part),
                \%rewrites_by_part,
            );
            write_atomic($part->{path}, $contents);
        }
    }
    for my $source (@sources) {
        write_atomic($source->{landing}, expected_landing($source, \@sources, \%parts_by_source));
    }
    print "isf-reference-partitions: materialized 3 landings and 11 semantic parts\n";
    exit 0;
}

for my $source (@sources) {
    my $landing = read_current($source->{landing});
    my $expected = expected_landing($source, \@sources, \%parts_by_source);
    die "isf-reference-partitions: stale landing page: $source->{landing}\n"
        if $landing ne $expected;
    verify_local_links($source->{landing}, $landing);
    for my $part (@{$parts_by_source{$source->{source_id}}}) {
        my $current = read_current($part->{path});
        my ($lines, $bytes, $line_bytes) = dimensions($current);
        die "isf-reference-partitions: $part->{path} exceeds per-part line limit\n"
            if $lines > $source->{lines_each};
        die "isf-reference-partitions: $part->{path} exceeds per-part byte limit\n"
            if $bytes > $source->{bytes_each};
        die "isf-reference-partitions: $part->{path} exceeds maximum line width\n"
            if $line_bytes > $source->{line_bytes_each};
        die "isf-reference-partitions: $part->{path} lost first heading marker\n"
            if index($current, encode_utf8($part->{first_heading})) < 0;
        die "isf-reference-partitions: $part->{path} lost last heading marker\n"
            if index($current, encode_utf8($part->{last_heading})) < 0;
        verify_local_links($part->{path}, $current);
        if ($verify_activation) {
            my $expected_part = transform_links_for_nested_part(
                $source->{source_id},
                $part->{sequence},
                source_segment($archived_contents{$source->{source_id}}, $part),
                \%rewrites_by_part,
            );
            die content_mismatch($part->{path}, $current, $expected_part)
                if $current ne $expected_part;
        }
    }
}

print "isf-reference-partitions: 3 exact sources map contiguously to 11 bounded semantic parts"
    . ($verify_activation ? " with activation-content equality\n" : "\n");
