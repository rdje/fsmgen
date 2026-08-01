#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use Encode qw(decode encode FB_CROAK);
use File::Basename qw(dirname);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP;

my $command = shift(@ARGV) // '';
usage(2) if $command !~ /\A(?:generate|check|query|format)\z/;

my $root = resolve_root();
my $scan_dirs = env_words('KM_SCAN_DIRS', 'docs/knowledge docs/decisions');
my $map_path = env_path('KM_OUTPUT', 'KNOWLEDGE_MAP.md');
my $shard_dir = env_path('KM_SHARD_DIR', 'knowledge-map/generated');
my $cache_dir = env_path('KM_QUERY_CACHE_DIR', '.artifacts/knowledge-map/query');
my $title = $ENV{KM_TITLE} // 'Knowledge Map';
my %limits = (
    card_lines       => env_positive('KM_CARD_MAX_LINES', 512),
    card_bytes       => env_positive('KM_CARD_MAX_BYTES', 32_768),
    card_line_bytes  => env_positive('KM_CARD_MAX_LINE_BYTES', 819),
    root_lines       => env_positive('KM_ROOT_MAX_LINES', 512),
    root_bytes       => env_positive('KM_ROOT_MAX_BYTES', 131_072),
    root_line_bytes  => env_positive('KM_ROOT_MAX_LINE_BYTES', 819),
    shard_files      => env_positive('KM_SHARD_MAX_FILES', 256),
    shard_lines      => env_positive('KM_SHARD_MAX_LINES', 3_276),
    shard_bytes      => env_positive('KM_SHARD_MAX_BYTES', 419_430),
    shard_line_bytes => env_positive('KM_SHARD_MAX_LINE_BYTES', 819),
    total_lines      => env_positive('KM_SHARD_MAX_TOTAL_LINES', 50_000),
    total_bytes      => env_positive('KM_SHARD_MAX_TOTAL_BYTES', 8_388_608),
);

if ($command eq 'generate') {
    my ($facts, $problems) = load_facts();
    fail_problems($problems) if @{$problems};
    my ($root_text, $shards) = render_projection($facts);
    write_projection($root_text, $shards);
    my $question_count = unique_question_count($facts);
    my $answer_count = answer_count($facts);
    print STDERR "knowledge-map: wrote $map_path plus " . scalar(keys %{$shards})
        . " topic shards (" . scalar(@{$facts}) . " facts, $question_count unique questions, "
        . "$answer_count answer occurrences)\n";
    exit 0;
}

if ($command eq 'check') {
    exit check_projection();
}

if ($command eq 'query') {
    exit run_query(@ARGV);
}

exit format_cards();

sub usage {
    my ($status) = @_;
    print STDERR <<'USAGE';
Usage: knowledge_map.pl generate
       knowledge_map.pl check
       knowledge_map.pl query [--no-cache] [--all | TEXT]
       knowledge_map.pl format [--check]
USAGE
    exit $status;
}

sub resolve_root {
    my $candidate = $ENV{KM_ROOT};
    if (!defined($candidate) || $candidate eq '') {
        my $script = abs_path(__FILE__);
        $candidate = File::Spec->catdir(dirname($script), '..', '..');
    }
    my $resolved = abs_path($candidate);
    die "knowledge-map: invalid repository root\n"
        if !defined($resolved) || !-d $resolved;
    return $resolved;
}

sub env_words {
    my ($name, $default) = @_;
    my $value = $ENV{$name} // $default;
    my @words = grep { $_ ne '' } split /\s+/, $value;
    die "knowledge-map: $name must name at least one path\n" if !@words;
    for my $word (@words) {
        assert_relative($word, $name);
        assert_no_symlink_below($root, $word, $name);
    }
    return \@words;
}

sub env_path {
    my ($name, $default) = @_;
    my $value = $ENV{$name} // $default;
    assert_relative($value, $name);
    assert_no_symlink_below($root, $value, $name);
    return $value;
}

sub env_positive {
    my ($name, $default) = @_;
    my $value = $ENV{$name} // $default;
    die "knowledge-map: $name must be a positive integer\n"
        if $value !~ /\A[1-9][0-9]*\z/;
    return 0 + $value;
}

sub assert_relative {
    my ($path, $label) = @_;
    die "knowledge-map: unsafe $label path: $path\n"
        if !defined($path) || $path eq '' || $path =~ /\0/
            || File::Spec->file_name_is_absolute($path)
            || $path =~ m{\A~(?:/|\z)}
            || grep { $_ eq '..' } split m{/+}, $path;
}

sub assert_no_symlink_below {
    my ($base, $relative, $label) = @_;
    my $cursor = $base;
    for my $part (grep { $_ ne '' && $_ ne '.' } split m{/+}, $relative) {
        $cursor = File::Spec->catfile($cursor, $part);
        die "knowledge-map: unsafe $label symlink component: $relative\n"
            if -l $cursor;
    }
}

sub root_path {
    my ($relative) = @_;
    return File::Spec->catfile($root, split m{/+}, $relative);
}

sub destination_root {
    my $relative = $ENV{KM_DEST_ROOT} // '.';
    assert_relative($relative, 'KM_DEST_ROOT');
    assert_no_symlink_below($root, $relative, 'KM_DEST_ROOT');
    my $path = $relative eq '.' ? $root : root_path($relative);
    make_path($path) if !-d $path;
    my $resolved = abs_path($path);
    die "knowledge-map: KM_DEST_ROOT is outside the repository\n"
        if !defined($resolved)
            || ($resolved ne $root && index($resolved, "$root/") != 0);
    return $resolved;
}

sub destination_path {
    my ($dest_root, $relative) = @_;
    assert_no_symlink_below($dest_root, $relative, 'generated destination');
    return File::Spec->catfile($dest_root, split m{/+}, $relative);
}

sub source_files {
    my @files;
    for my $relative (@{$scan_dirs}) {
        my $dir = root_path($relative);
        next if !-d $dir;
        find({
            no_chdir => 1,
            wanted => sub {
                return if !-f $_ || -l $_ || $_ !~ /\.md\z/;
                my $absolute = $File::Find::name;
                my $rel = File::Spec->abs2rel($absolute, $root);
                $rel =~ s{\\}{/}g;
                push @files, $rel;
            },
        }, $dir);
    }
    return sort @files;
}

sub read_utf8 {
    my ($relative) = @_;
    my $path = root_path($relative);
    open my $fh, '<:raw', $path
        or die "knowledge-map: cannot read $relative: $!\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh or die "knowledge-map: cannot close $relative: $!\n";
    my $text = eval { decode('UTF-8', $bytes, FB_CROAK) };
    die "knowledge-map: $relative is not valid UTF-8\n" if !defined $text;
    return ($text, $bytes);
}

sub load_facts {
    my @facts;
    my @problems;
    my %ids;
    for my $relative (source_files()) {
        my ($text, $bytes) = read_utf8($relative);
        my $fact = parse_fact($relative, $text);
        next if !$fact;
        $fact->{bytes} = length($bytes);
        my @lines = split /\n/, $text, -1;
        pop @lines if @lines && $lines[-1] eq '';
        $fact->{lines} = scalar @lines;
        $fact->{line_bytes} = 0;
        for my $line (@lines) {
            my $width = length(encode('UTF-8', $line));
            $fact->{line_bytes} = $width if $width > $fact->{line_bytes};
        }
        for my $field (qw(id title date)) {
            push @problems, "$relative: missing required field $field"
                if !defined($fact->{$field}) || $fact->{$field} eq '';
        }
        push @problems, "$relative: missing required field evidence-or-reverify"
            if !$fact->{evidence} && !$fact->{reverify};
        push @problems, "$relative: id must be kebab-case"
            if ($fact->{id} // '') !~ /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/;
        push @problems, "$relative: date must use YYYY-MM-DD"
            if ($fact->{date} // '') !~ /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/;
        if (defined($fact->{id}) && $fact->{id} ne '') {
            push @problems, "duplicate fact id '$fact->{id}': $ids{$fact->{id}} and $relative"
                if exists $ids{$fact->{id}};
            $ids{$fact->{id}} = $relative;
        }
        my %seen_answer;
        for my $answer (@{$fact->{answers}}) {
            push @problems, "$relative: empty answer entry" if $answer eq '';
            push @problems, "$relative: duplicate answer in one card: $answer"
                if $seen_answer{$answer}++;
        }
        push @problems, "$relative: card lines $fact->{lines} exceed $limits{card_lines}"
            if $fact->{lines} > $limits{card_lines};
        push @problems, "$relative: card bytes $fact->{bytes} exceed $limits{card_bytes}"
            if $fact->{bytes} > $limits{card_bytes};
        push @problems, "$relative: card line width $fact->{line_bytes} exceeds $limits{card_line_bytes}"
            if $fact->{line_bytes} > $limits{card_line_bytes};
        push @facts, $fact;
    }
    @facts = sort { $a->{id} cmp $b->{id} } @facts;
    return (\@facts, \@problems);
}

sub parse_fact {
    my ($relative, $text) = @_;
    my @lines = split /\n/, $text, -1;
    return undef if !@lines || $lines[0] !~ /\A---[ \t]*\z/;
    my %value;
    my @answers;
    my ($current_list, $block_key, @block_lines);
    my $closed = 0;
    for (my $i = 1; $i < @lines; ++$i) {
        my $line = $lines[$i];
        if ($line =~ /\A---[ \t]*\z/) {
            finish_block(\%value, $block_key, \@block_lines) if defined $block_key;
            $closed = 1;
            last;
        }
        die "knowledge-map: $relative front matter contains a tab\n"
            if $line =~ /\t/;
        if (defined $block_key) {
            if ($line =~ /\A[ ]{2,}(.*)\z/) {
                push @block_lines, $1;
                next;
            }
            finish_block(\%value, $block_key, \@block_lines);
            undef $block_key;
            @block_lines = ();
        }
        if (defined($current_list) && $line =~ /\A[ ]+-[ ]+(.*)\z/) {
            my $item = strip_scalar($1);
            push @answers, $item if $current_list eq 'answers';
            next;
        }
        if ($line =~ /\A([A-Za-z_][A-Za-z0-9_]*):[ ]*(.*)\z/) {
            my ($key, $rest) = ($1, $2);
            undef $current_list;
            if ($rest eq '>-') {
                $block_key = $key;
                @block_lines = ();
            } elsif ($rest =~ /\A\[(.*)\]\z/) {
                if ($key eq 'answers') {
                    push @answers, map { strip_scalar($_) } split /,/, $1;
                }
            } elsif ($rest eq '') {
                $current_list = $key;
            } else {
                $value{$key} = strip_scalar($rest);
            }
        }
    }
    die "knowledge-map: $relative has unterminated front matter\n" if !$closed;
    return undef if !@answers;
    return {
        %value,
        answers => \@answers,
        path => $relative,
        status => $value{status} || 'current',
    };
}

sub finish_block {
    my ($values, $key, $lines) = @_;
    die "knowledge-map: folded scalar $key must contain an indented line\n"
        if !@{$lines};
    my @parts = map {
        my $part = $_;
        $part =~ s/\A[ ]+//;
        $part =~ s/[ ]+\z//;
        $part;
    } @{$lines};
    $values->{$key} = strip_scalar(join(' ', @parts));
}

sub strip_scalar {
    my ($value) = @_;
    $value =~ s/\A[ ]+//;
    $value =~ s/[ ]+\z//;
    $value =~ s/\A"//;
    $value =~ s/"\z//;
    return $value;
}

sub topic_for {
    my ($id) = @_;
    my @parts = split /-/, lc $id;
    return @parts > 1 ? "$parts[0]-$parts[1]" : $parts[0];
}

sub question_index {
    my ($facts) = @_;
    my %questions;
    for my $fact (@{$facts}) {
        push @{$questions{$_}}, $fact for @{$fact->{answers}};
    }
    for my $question (keys %questions) {
        my %seen;
        @{$questions{$question}} = grep { !$seen{$_->{id}}++ }
            sort { $a->{id} cmp $b->{id} } @{$questions{$question}};
    }
    return \%questions;
}

sub unique_question_count {
    my ($facts) = @_;
    return scalar keys %{question_index($facts)};
}

sub answer_count {
    my ($facts) = @_;
    my $count = 0;
    $count += scalar(@{$_->{answers}}) for @{$facts};
    return $count;
}

sub render_projection {
    my ($facts) = @_;
    my %facts_by_topic;
    push @{$facts_by_topic{topic_for($_->{id})}}, $_ for @{$facts};
    my $questions = question_index($facts);
    my %questions_by_topic;
    for my $question (sort keys %{$questions}) {
        my $owner = $questions->{$question}[0];
        push @{$questions_by_topic{topic_for($owner->{id})}}, $question;
    }
    my %topics = map { $_ => 1 } (keys %facts_by_topic, keys %questions_by_topic);
    my @topics = sort keys %topics;
    my %shards;
    for my $topic (@topics) {
        my @topic_facts = @{$facts_by_topic{$topic} || []};
        my @topic_questions = sort @{$questions_by_topic{$topic} || []};
        my $text = "# $title: `$topic`\n\n";
        $text .= "> **AUTO-GENERATED — DO NOT EDIT.** Return to the "
            . "[Knowledge Map](../../$map_path).\n";
        $text .= "> **" . scalar(@topic_facts) . "** facts · **"
            . scalar(@topic_questions) . "** uniquely owned question entries.\n\n";
        $text .= "## Questions → facts\n\n";
        if (@topic_questions) {
            for my $question (@topic_questions) {
                my @links = map {
                    my $href = "../../$_->{path}";
                    "[$_->{id}]($href)"
                } @{$questions->{$question}};
                $text .= '- q=' . json_string($question) . ' · facts=' . join(', ', @links) . "\n";
            }
        } else {
            $text .= "_(no question entries are owned by this topic)_\n";
        }
        $text .= "\n## Facts\n";
        for my $fact (@topic_facts) {
            my $href = "../../$fact->{path}";
            $text .= "\n### $fact->{id}\n\n";
            $text .= "_$fact->{title}_\n\n";
            $text .= "- **date:** $fact->{date} · **status:** $fact->{status}\n";
            $text .= "- **source and verification:** [`$fact->{path}`]($href)\n";
        }
        $shards{"$topic.md"} = $text;
    }

    my $answer_total = answer_count($facts);
    my $root_text = "# $title\n\n";
    $root_text .= "> **AUTO-GENERATED — DO NOT EDIT.** Regenerate with "
        . "`knowledge-map/scripts/gen_knowledge_map.sh`.\n";
    my $scan_display = join(' ', @{$scan_dirs});
    $root_text .= "> Canonical facts remain in `$scan_display`; shards are bounded "
        . "derived views, and `.artifacts/` query caches are disposable.\n";
    $root_text .= "> **" . scalar(@{$facts}) . "** facts · **"
        . scalar(keys %{$questions}) . "** unique questions · **$answer_total** answer "
        . "occurrences · **" . scalar(@topics) . "** topic shards.\n\n";
    $root_text .= "Query first:\n\n";
    $root_text .= "```bash\nknowledge-map/scripts/query_knowledge_map.sh 'your question words'\n```\n\n";
    $root_text .= "The query is a case-insensitive fixed-substring search. Add `--no-cache` "
        . "to read committed shards directly.\n\n";
    $root_text .= "## Topic shards\n\n";
    $root_text .= "| Topic | Facts | Questions | Shard |\n";
    $root_text .= "|---|---:|---:|---|\n";
    for my $topic (@topics) {
        my $facts_count = scalar @{$facts_by_topic{$topic} || []};
        my $question_count = scalar @{$questions_by_topic{$topic} || []};
        $root_text .= "| `$topic` | $facts_count | $question_count | "
            . "[`$topic.md`]($shard_dir/$topic.md) |\n";
    }
    return ($root_text, \%shards);
}

sub json_string {
    my ($value) = @_;
    return JSON::PP->new->ascii(1)->allow_nonref(1)->encode($value);
}

sub write_projection {
    my ($root_text, $shards) = @_;
    my $dest_root = destination_root();
    my $map_absolute = destination_path($dest_root, $map_path);
    my $shards_absolute = destination_path($dest_root, $shard_dir);
    make_path(dirname($map_absolute), $shards_absolute);
    my $marker = File::Spec->catfile($shards_absolute, '.knowledge-map-generated');
    my @existing = glob(File::Spec->catfile($shards_absolute, '*.md'));
    die "knowledge-map: refusing to replace unowned shard directory $shard_dir\n"
        if @existing && !-f $marker;
    write_atomic($marker, "generated by knowledge-map/scripts/knowledge_map.pl\n");
    write_atomic($map_absolute, $root_text);
    my %wanted;
    for my $name (sort keys %{$shards}) {
        $wanted{$name} = 1;
        write_atomic(File::Spec->catfile($shards_absolute, $name), $shards->{$name});
    }
    for my $path (@existing) {
        my (undef, undef, $name) = File::Spec->splitpath($path);
        next if $wanted{$name};
        unlink $path or die "knowledge-map: cannot remove stale shard $path: $!\n";
    }
}

sub write_atomic {
    my ($path, $text) = @_;
    make_path(dirname($path)) if !-d dirname($path);
    my $temporary = "$path.tmp.$$";
    open my $fh, '>:raw', $temporary
        or die "knowledge-map: cannot write $temporary: $!\n";
    print {$fh} encode('UTF-8', $text)
        or die "knowledge-map: cannot write $temporary: $!\n";
    close $fh or die "knowledge-map: cannot close $temporary: $!\n";
    rename $temporary, $path
        or die "knowledge-map: cannot replace $path: $!\n";
}

sub projection_files {
    my $map_absolute = root_path($map_path);
    my $shards_absolute = root_path($shard_dir);
    my @shards = -d $shards_absolute
        ? sort glob(File::Spec->catfile($shards_absolute, '*.md'))
        : ();
    return ($map_absolute, \@shards);
}

sub check_projection {
    my ($facts, $problems) = load_facts();
    my @problems = @{$problems};
    my ($expected_root, $expected_shards) = render_projection($facts);
    my ($map_absolute, $actual_shards) = projection_files();
    if (!-f $map_absolute || -l $map_absolute) {
        push @problems, "$map_path is missing or irregular";
    } else {
        my ($actual) = read_absolute_utf8($map_absolute);
        push @problems, "$map_path is out of sync with canonical facts"
            if $actual ne $expected_root;
        push @problems, measurement_problem('root', $actual,
            $limits{root_lines}, $limits{root_bytes}, $limits{root_line_bytes});
    }
    my %actual_name = map {
        my (undef, undef, $name) = File::Spec->splitpath($_);
        $name => $_
    } @{$actual_shards};
    for my $name (sort keys %{$expected_shards}) {
        if (!exists $actual_name{$name}) {
            push @problems, "missing generated shard: $shard_dir/$name";
            next;
        }
        my ($actual) = read_absolute_utf8($actual_name{$name});
        push @problems, "$shard_dir/$name is out of sync with canonical facts"
            if $actual ne $expected_shards->{$name};
        push @problems, measurement_problem("shard $name", $actual,
            $limits{shard_lines}, $limits{shard_bytes}, $limits{shard_line_bytes});
    }
    for my $name (sort keys %actual_name) {
        push @problems, "unexpected generated shard: $shard_dir/$name"
            if !exists $expected_shards->{$name};
    }
    push @problems, "generated shard count " . scalar(@{$actual_shards})
        . " exceeds $limits{shard_files}"
        if @{$actual_shards} > $limits{shard_files};
    my ($total_lines, $total_bytes) = (0, 0);
    for my $text (values %{$expected_shards}) {
        my ($lines, $bytes) = dimensions($text);
        $total_lines += $lines;
        $total_bytes += $bytes;
    }
    push @problems, "generated shard aggregate lines $total_lines exceed $limits{total_lines}"
        if $total_lines > $limits{total_lines};
    push @problems, "generated shard aggregate bytes $total_bytes exceed $limits{total_bytes}"
        if $total_bytes > $limits{total_bytes};

    if (!@problems) {
        my ($rows, $parse_problems) = read_question_rows($actual_shards);
        push @problems, @{$parse_problems};
        my $expected_questions = question_index($facts);
        my %seen_question;
        for my $row (@{$rows}) {
            ++$seen_question{$row->{question}};
            my @expected_ids = map { $_->{id} } @{$expected_questions->{$row->{question}} || []};
            push @problems, "question row has wrong fact set: $row->{question}"
                if join("\0", @expected_ids) ne join("\0", @{$row->{ids}});
        }
        for my $question (keys %{$expected_questions}) {
            push @problems, "question is missing or duplicated in shards: $question"
                if ($seen_question{$question} // 0) != 1;
        }
        my %fact_count;
        for my $path (@{$actual_shards}) {
            my ($text) = read_absolute_utf8($path);
            ++$fact_count{$1} while $text =~ /^### ([a-z0-9]+(?:-[a-z0-9]+)*)$/mg;
        }
        for my $fact (@{$facts}) {
            push @problems, "fact is missing or duplicated in shards: $fact->{id}"
                if ($fact_count{$fact->{id}} // 0) != 1;
        }
        my $direct = query_rows($rows, '');
        my $cached = cached_query_rows($rows, '');
        push @problems, 'cached and direct query results differ'
            if $direct ne $cached;
    }
    if (@problems) {
        print STDERR "knowledge-map: $_\n" for @problems;
        return 1;
    }
    print STDERR "knowledge-map: OK (" . scalar(@{$facts}) . " facts, "
        . unique_question_count($facts) . " unique questions, "
        . answer_count($facts) . " answer occurrences, "
        . scalar(keys %{$expected_shards}) . " bounded topic shards; query parity verified)\n";
    return 0;
}

sub fail_problems {
    my ($problems) = @_;
    print STDERR "knowledge-map: $_\n" for @{$problems};
    exit 1;
}

sub read_absolute_utf8 {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "knowledge-map: cannot read $path: $!\n";
    local $/;
    my $bytes = <$fh> // '';
    close $fh;
    return (decode('UTF-8', $bytes, FB_CROAK), $bytes);
}

sub dimensions {
    my ($text) = @_;
    my $bytes = encode('UTF-8', $text);
    my @lines = split /\n/, $text, -1;
    pop @lines if @lines && $lines[-1] eq '';
    my $longest = 0;
    for my $line (@lines) {
        my $width = length(encode('UTF-8', $line));
        $longest = $width if $width > $longest;
    }
    return (scalar(@lines), length($bytes), $longest);
}

sub measurement_problem {
    my ($label, $text, $max_lines, $max_bytes, $max_line) = @_;
    my ($lines, $bytes, $line) = dimensions($text);
    my @problems;
    push @problems, "$label lines $lines exceed $max_lines" if $lines > $max_lines;
    push @problems, "$label bytes $bytes exceed $max_bytes" if $bytes > $max_bytes;
    push @problems, "$label line width $line exceeds $max_line" if $line > $max_line;
    return @problems;
}

sub read_question_rows {
    my ($paths) = @_;
    my @rows;
    my @problems;
    for my $path (@{$paths}) {
        my ($text) = read_absolute_utf8($path);
        for my $line (split /\n/, $text) {
            next if $line !~ /\A- q=(.*) · facts=(.*)\z/;
            my ($question_json, $links) = ($1, $2);
            my $question = eval { JSON::PP->new->decode($question_json) };
            if (!defined($question) || ref($question)) {
                push @problems, "$path has invalid question JSON";
                next;
            }
            my (@ids, @sources);
            while ($links =~ /\[([a-z0-9]+(?:-[a-z0-9]+)*)\]\(\.\.\/\.\.\/([^\)]+)\)/g) {
                push @ids, $1;
                push @sources, $2;
            }
            if (!@ids) {
                push @problems, "$path question row has no fact link";
                next;
            }
            push @rows, {question => $question, ids => \@ids, sources => \@sources};
        }
    }
    @rows = sort { $a->{question} cmp $b->{question} } @rows;
    return (\@rows, \@problems);
}

sub projection_fingerprint {
    my ($paths) = @_;
    my $material = '';
    for my $path (@{$paths}) {
        my ($text, $bytes) = read_absolute_utf8($path);
        my $relative = File::Spec->abs2rel($path, $root);
        $relative =~ s{\\}{/}g;
        $material .= "$relative\0$bytes\0";
    }
    return sha256_hex($material);
}

sub cache_path {
    my $dir = root_path($cache_dir);
    make_path($dir) if !-d $dir;
    my $resolved = abs_path($dir);
    die "knowledge-map: query cache is outside the repository\n"
        if !defined($resolved) || ($resolved ne $root && index($resolved, "$root/") != 0);
    return File::Spec->catfile($dir, 'questions.jsonl');
}

sub write_query_cache {
    my ($rows, $fingerprint) = @_;
    my $json = JSON::PP->new->canonical(1)->ascii(1);
    my $text = $json->encode({record_type => 'cache', schema_version => 1,
        fingerprint => $fingerprint}) . "\n";
    for my $row (@{$rows}) {
        $text .= $json->encode({record_type => 'question', %{$row}}) . "\n";
    }
    my $path = cache_path();
    write_atomic($path, $text);
    return $path;
}

sub read_query_cache {
    my ($path, $fingerprint) = @_;
    return undef if !-f $path || -l $path;
    my ($text) = read_absolute_utf8($path);
    my @records;
    for my $line (grep { $_ ne '' } split /\n/, $text) {
        my $record = eval { JSON::PP->new->decode($line) };
        return undef if !$record || ref($record) ne 'HASH';
        push @records, $record;
    }
    return undef if !@records || ($records[0]{record_type} // '') ne 'cache'
        || ($records[0]{schema_version} // 0) != 1
        || ($records[0]{fingerprint} // '') ne $fingerprint;
    shift @records;
    for my $record (@records) {
        return undef if ($record->{record_type} // '') ne 'question'
            || ref($record->{ids}) ne 'ARRAY' || ref($record->{sources}) ne 'ARRAY'
            || !defined($record->{question}) || ref($record->{question});
    }
    return \@records;
}

sub query_rows {
    my ($rows, $needle) = @_;
    my $folded = lc $needle;
    my $result = '';
    for my $row (@{$rows}) {
        next if $folded ne '' && index(lc($row->{question}), $folded) < 0;
        $result .= join("\t", $row->{question}, join(',', @{$row->{ids}}),
            join(',', @{$row->{sources}})) . "\n";
    }
    return $result;
}

sub cached_query_rows {
    my ($direct_rows, $needle) = @_;
    my (undef, $paths) = projection_files();
    my $fingerprint = projection_fingerprint($paths);
    my $path = cache_path();
    my $rows = read_query_cache($path, $fingerprint);
    $rows = undef
        if $rows && query_rows($rows, '') ne query_rows($direct_rows, '');
    if (!$rows) {
        write_query_cache($direct_rows, $fingerprint);
        $rows = read_query_cache($path, $fingerprint);
        die "knowledge-map: cannot rebuild query cache\n" if !$rows;
    }
    return query_rows($rows, $needle);
}

sub run_query {
    my (@args) = @_;
    my $no_cache = 0;
    my $all = 0;
    my @text;
    for my $arg (@args) {
        if ($arg eq '--no-cache') { $no_cache = 1; next; }
        if ($arg eq '--all') { $all = 1; next; }
        push @text, $arg;
    }
    usage(2) if !$all && !@text;
    usage(2) if $all && @text;
    my $needle = $all ? '' : join(' ', @text);
    my (undef, $paths) = projection_files();
    die "knowledge-map: no generated shards; run gen_knowledge_map.sh\n" if !@{$paths};
    my ($rows, $problems) = read_question_rows($paths);
    fail_problems($problems) if @{$problems};
    my $result = $no_cache ? query_rows($rows, $needle) : cached_query_rows($rows, $needle);
    print encode('UTF-8', $result);
    return 0;
}

sub format_cards {
    my $check_only = @ARGV == 1 && $ARGV[0] eq '--check';
    usage(2) if @ARGV && !$check_only;
    my $changed = 0;
    for my $relative (source_files()) {
        next if $relative !~ m{\Adocs/knowledge/};
        my ($text) = read_utf8($relative);
        my @lines = split /\n/, $text, -1;
        next if !@lines || $lines[0] !~ /\A---[ ]*\z/;
        my @out;
        my $in_front = 0;
        my $file_changed = 0;
        for my $line (@lines) {
            if ($line =~ /\A---[ ]*\z/) {
                $in_front = !$in_front;
                push @out, $line;
                next;
            }
            if ($in_front && $line =~ /\A(evidence|reverify|answer):[ ]+(.+)\z/
                    && length(encode('UTF-8', $line)) > $limits{card_line_bytes}) {
                my ($key, $value) = ($1, $2);
                my @wrapped = wrap_scalar($value, $limits{card_line_bytes} - 4);
                push @out, "$key: >-", map { "  $_" } @wrapped;
                $file_changed = 1;
            } else {
                push @out, $line;
            }
        }
        next if !$file_changed;
        ++$changed;
        next if $check_only;
        my $new_text = join("\n", @out);
        my $before = parse_fact($relative, $text);
        my $after = parse_fact($relative, $new_text);
        for my $key (qw(evidence reverify answer)) {
            die "knowledge-map: formatter changed $relative $key semantics\n"
                if ($before->{$key} // '') ne ($after->{$key} // '');
        }
        write_atomic(root_path($relative), $new_text);
    }
    if ($check_only && $changed) {
        print STDERR "knowledge-map: $changed card(s) still require metadata wrapping\n";
        return 1;
    }
    print STDERR "knowledge-map: " . ($check_only ? 'metadata wrapping is current'
        : "wrapped metadata in $changed card(s)") . "\n";
    return 0;
}

sub wrap_scalar {
    my ($value, $width) = @_;
    my @lines;
    while (length(encode('UTF-8', $value)) > $width) {
        my $break;
        for (my $i = 1; $i < length($value) - 1; ++$i) {
            next if substr($value, $i, 1) ne ' '
                || substr($value, $i - 1, 1) eq ' '
                || substr($value, $i + 1, 1) eq ' ';
            last if length(encode('UTF-8', substr($value, 0, $i))) > $width;
            $break = $i;
        }
        die "knowledge-map: scalar contains no safe fold boundary before $width bytes\n"
            if !defined $break;
        push @lines, substr($value, 0, $break);
        $value = substr($value, $break + 1);
    }
    push @lines, $value if $value ne '';
    return @lines;
}
