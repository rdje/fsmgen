package FSM::Test::HostedCorpusShard;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    hosted_corpus_list_only
    select_main_cli_corpus_entries
    select_hosted_corpus_entries
);

sub hosted_corpus_list_only {
    return $ENV{FSMGEN_HOSTED_CORPUS_LIST_ONLY} ? 1 : 0;
}

sub select_main_cli_corpus_entries {
    my (%args) = @_;
    my $entries = $args{entries};
    my $phase = $args{phase};

    die "main-CLI corpus entries must be an array reference\n"
        unless ref($entries) eq 'ARRAY';
    die "main-CLI corpus phase must be a non-empty string\n"
        unless defined($phase) && !ref($phase) && length($phase);

    my @phase_entries = grep {
        my $entry = $_;
        !exists($entry->{supported_phases})
            || grep { $_ eq $phase } @{$entry->{supported_phases}}
    } @{$entries};

    my %by_relpath;
    my @relpath_order;
    for my $entry (@phase_entries) {
        die "main-CLI corpus entry is missing relpath\n"
            unless defined($entry->{relpath}) && length($entry->{relpath});
        push @relpath_order, $entry->{relpath}
            unless exists $by_relpath{$entry->{relpath}};
        push @{$by_relpath{$entry->{relpath}}}, $entry;
    }

    my @canonical = map {
        my @ranked = sort {
            _success_entry_rank($b) <=> _success_entry_rank($a)
                || $a->{id} cmp $b->{id}
        } @{$by_relpath{$_}};
        $ranked[0];
    } @relpath_order;

    return \@canonical;
}

sub select_hosted_corpus_entries {
    my (%args) = @_;
    my $entries = $args{entries};

    die "hosted corpus entries must be an array reference\n"
        unless ref($entries) eq 'ARRAY';

    my $has_index = exists $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX};
    my $has_count = exists $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT};
    return [@{$entries}] unless $has_index || $has_count;

    die "hosted corpus sharding requires both FSMGEN_HOSTED_CORPUS_SHARD_INDEX and FSMGEN_HOSTED_CORPUS_SHARD_COUNT\n"
        unless $has_index && $has_count;

    my $index = $ENV{FSMGEN_HOSTED_CORPUS_SHARD_INDEX};
    my $count = $ENV{FSMGEN_HOSTED_CORPUS_SHARD_COUNT};
    die "FSMGEN_HOSTED_CORPUS_SHARD_INDEX must be a zero-based integer\n"
        unless defined($index) && $index =~ /\A(?:0|[1-9][0-9]*)\z/;
    die "FSMGEN_HOSTED_CORPUS_SHARD_COUNT must be a positive integer\n"
        unless defined($count) && $count =~ /\A[1-9][0-9]*\z/;
    die "hosted corpus shard index $index is outside shard count $count\n"
        if $index >= $count;

    my @selected_indices = grep { $_ % $count == $index } 0 .. $#{$entries};
    die "hosted corpus shard $index/$count selected no entries\n"
        unless @selected_indices;

    return [@{$entries}[@selected_indices]];
}

sub _success_entry_rank {
    my ($entry) = @_;

    my $rank = 0;
    $rank += 100 if ($entry->{classification} || '') eq 'supported_smoke';
    $rank += 50 if $entry->{strict_supported};
    return $rank;
}

1;
