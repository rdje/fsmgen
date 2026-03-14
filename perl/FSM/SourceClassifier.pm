package FSM::SourceClassifier;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub classify_source_ast ($raw_ast) {
    my $header = detect_top_level_source_header($raw_ast);
    my $kind = 'unknown';

    if (defined $header) {
        if ($header eq '+fsm' || $header =~ /^\?fsm:/) {
            $kind = 'fsm';
        } elsif ($header =~ /^\?top:/) {
            $kind = 'composition';
        }
    }

    return {
        kind => $kind,
        header => $header,
    };
}

sub detect_top_level_source_header ($raw_ast) {
    return undef unless ref($raw_ast) eq 'ARRAY';

    my @header_candidates;

    if (@$raw_ast > 0 && !ref($raw_ast->[0])) {
        push @header_candidates, $raw_ast->[0];
    }

    if (@$raw_ast > 0 && ref($raw_ast->[0]) eq 'ARRAY' && @{$raw_ast->[0]} > 0 && !ref($raw_ast->[0][0])) {
        push @header_candidates, $raw_ast->[0][0];
    }

    for my $ast_node (@$raw_ast) {
        next unless ref($ast_node) eq 'ARRAY' && @$ast_node > 0;
        next if ref($ast_node->[0]);
        push @header_candidates, $ast_node->[0];
    }

    for my $candidate (@header_candidates) {
        next unless defined $candidate;
        return $candidate if $candidate eq '+fsm';
        return $candidate if $candidate =~ /^\?[A-Za-z_][\w-]*:/;
    }

    return undef;
}

1;
