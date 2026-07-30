package FSM::IR::SourceHIRPPIFRenderer;

=head1 NAME

FSM::IR::SourceHIRPPIFRenderer - Canonical private SourceHIR-to-PPIF handoff

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::SourceHIR;

my @RENDER_RESULT_KEYS = qw(format schema_version source_label source_map text);

sub render_ppif ($class, @args) {
    _validate_class_call($class, 'render_ppif', \@args, 1);
    my ($source_hir) = @args;
    confess "FSM::IR::SourceHIRPPIFRenderer->render_ppif expects one FSM::IR::SourceHIR object\n"
        unless blessed($source_hir) && $source_hir->isa('FSM::IR::SourceHIR');

    my $source = $source_hir->source_object;
    my $channel = $source_hir->valid_ready_channel;
    my @lines;
    my @source_map;

    _append_line(\@lines, \@source_map,
        "(protocol-platform-intent " . $source_hir->intent_name,
        '/intent_name', $source_hir);
    _append_line(\@lines, \@source_map,
        "  (profile " . $source_hir->profile . ")",
        '/profile', $source_hir);
    _append_line(\@lines, \@source_map, '  (source', '/source_object', $source_hir);
    _append_line(\@lines, \@source_map,
        "    (object $source->{id})", '/source_object/id', $source_hir);

    for my $index (0 .. $#{$source->{anchors}}) {
        my $anchor = $source->{anchors}[$index];
        my $close_source = $index == $#{$source->{anchors}} ? ')' : '';
        _append_line(
            \@lines,
            \@source_map,
            "    (anchor (document $anchor->{document}) (section $anchor->{section}) (page $anchor->{page}))$close_source",
            "/source_object/anchors/$index",
            $source_hir,
        );
    }

    _append_line(\@lines, \@source_map,
        "  (valid-ready-channel $channel->{name}",
        '/valid_ready_channel/name', $source_hir);
    _append_line(\@lines, \@source_map,
        "    (channel $channel->{channel})",
        '/valid_ready_channel/channel', $source_hir);
    _append_line(\@lines, \@source_map,
        "    (role $channel->{role})",
        '/valid_ready_channel/role', $source_hir);
    _append_line(\@lines, \@source_map,
        "    (clock $channel->{clock})",
        '/valid_ready_channel/clock', $source_hir);

    my $reset = $channel->{reset};
    my $polarity = $reset->{active_level} == 0 ? 'active_low' : 'active_high';
    _append_line(\@lines, \@source_map,
        "    (reset ($reset->{signal} $polarity $reset->{kind}))",
        '/valid_ready_channel/reset', $source_hir);
    _append_line(\@lines, \@source_map,
        "    (valid $channel->{valid})",
        '/valid_ready_channel/valid', $source_hir);
    _append_line(\@lines, \@source_map,
        "    (ready $channel->{ready})",
        '/valid_ready_channel/ready', $source_hir);
    _append_line(\@lines, \@source_map,
        '    (payload', '/valid_ready_channel/payload', $source_hir);

    for my $index (0 .. $#{$channel->{payload}}) {
        my $payload = $channel->{payload}[$index];
        my $close_root = $index == $#{$channel->{payload}} ? ')))' : '';
        _append_line(
            \@lines,
            \@source_map,
            "      ($payload->{name} width $payload->{width})$close_root",
            "/valid_ready_channel/payload/$index",
            $source_hir,
        );
    }

    my $text = join("\n", @lines) . "\n";
    push @source_map, {
        semantic_path => '/',
        generated_span => {
            start_line => 1,
            start_column => 1,
            end_line => scalar(@lines),
            end_column => length($lines[-1]),
        },
        source_location => $source_hir->source_location_for('/'),
    };

    @source_map = sort {
        $a->{generated_span}{start_line} <=> $b->{generated_span}{start_line}
            || $a->{generated_span}{start_column} <=> $b->{generated_span}{start_column}
            || _line_measure($a->{generated_span}) <=> _line_measure($b->{generated_span})
            || _column_measure($a->{generated_span}) <=> _column_measure($b->{generated_span})
            || $a->{semantic_path} cmp $b->{semantic_path}
    } @source_map;

    return {
        schema_version => 1,
        format => 'ppif',
        source_label => 'source-hir-generated/' . $source_hir->intent_name . '.ppif',
        text => $text,
        source_map => _clone(\@source_map),
    };
}

sub diagnostic_from_ppif_error ($class, @args) {
    _validate_class_call($class, 'diagnostic_from_ppif_error', \@args, 2);
    my ($rendered, $error_text) = @args;
    _validate_render_result($rendered);
    confess "FSM::IR::SourceHIRPPIFRenderer->diagnostic_from_ppif_error argument 2 must be a defined scalar\n"
        if !defined($error_text) || ref($error_text);

    my ($first_line) = grep { /\S/ } split /\R/, $error_text;
    $first_line //= 'existing PPIF adapter rejected generated source';
    $first_line =~ s/\A\s+//;
    $first_line =~ s/\s+\z//;
    $first_line =~ s/\s+at\s+\S+\s+line\s+[0-9]+.*\z//;

    my ($line, $column);
    my $label = $rendered->{source_label};
    if ($first_line =~ /\Q$label\E:([1-9][0-9]*)(?::([1-9][0-9]*))?/) {
        ($line, $column) = ($1, $2);
    } elsif ($first_line =~ /\bline\s+([1-9][0-9]*)(?:[,: ]+\s*column\s+([1-9][0-9]*))?/i) {
        ($line, $column) = ($1, $2);
    }

    my @matches = defined($line)
        ? grep { _span_contains($_->{generated_span}, $line, $column) } @{$rendered->{source_map}}
        : ();
    @matches = sort {
        _line_measure($a->{generated_span}) <=> _line_measure($b->{generated_span})
            || _column_measure($a->{generated_span}) <=> _column_measure($b->{generated_span})
            || $a->{semantic_path} cmp $b->{semantic_path}
    } @matches;

    my $selected = $matches[0]
        // (grep { $_->{semantic_path} eq '/' } @{$rendered->{source_map}})[0];
    confess "FSM::IR::SourceHIRPPIFRenderer renderer result lacks root source-map entry\n"
        unless ref($selected) eq 'HASH';

    my $generated_location = {source_label => $label};
    $generated_location->{line} = int($line) if defined $line;
    $generated_location->{column} = int($column) if defined $column;

    return {
        schema_version => 1,
        severity => 'error',
        code => 'FSMGEN_SOURCE_HIR_PPIF_REJECTED',
        phase => 'ppif_handoff',
        message => 'generated PPIF was rejected by the existing adapter',
        semantic_path => $selected->{semantic_path},
        source_location => _clone($selected->{source_location}),
        downstream_message => $first_line,
        generated_location => $generated_location,
    };
}

sub _validate_class_call ($class, $method, $args, $expected) {
    confess "FSM::IR::SourceHIRPPIFRenderer->$method must be called with the FSM::IR::SourceHIRPPIFRenderer class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess "FSM::IR::SourceHIRPPIFRenderer->$method expects exactly $expected argument(s)\n"
        unless @$args == $expected;
}

sub _validate_render_result ($rendered) {
    confess "FSM::IR::SourceHIRPPIFRenderer->diagnostic_from_ppif_error argument 1 must be a renderer-result hash reference\n"
        unless ref($rendered) eq 'HASH';
    my %allowed = map { $_ => 1 } @RENDER_RESULT_KEYS;
    my @unknown = sort grep { !$allowed{$_} } keys %$rendered;
    confess "FSM::IR::SourceHIRPPIFRenderer renderer result has unsupported field '$unknown[0]'\n"
        if @unknown;
    confess "FSM::IR::SourceHIRPPIFRenderer renderer result has invalid schema or format\n"
        unless ($rendered->{schema_version} // '') eq '1'
            && ($rendered->{format} // '') eq 'ppif'
            && defined($rendered->{source_label}) && !ref($rendered->{source_label})
            && defined($rendered->{text}) && !ref($rendered->{text})
            && ref($rendered->{source_map}) eq 'ARRAY';
}

sub _append_line ($lines, $source_map, $text, $path, $source_hir) {
    push @$lines, $text;
    push @$source_map, {
        semantic_path => $path,
        generated_span => {
            start_line => scalar(@$lines),
            start_column => 1,
            end_line => scalar(@$lines),
            end_column => length($text),
        },
        source_location => $source_hir->source_location_for($path),
    };
}

sub _span_contains ($span, $line, $column) {
    return 0 unless ref($span) eq 'HASH';
    return 0 if $line < $span->{start_line} || $line > $span->{end_line};
    return 1 unless defined $column;
    return 0 if $line == $span->{start_line} && $column < $span->{start_column};
    return 0 if $line == $span->{end_line} && $column > $span->{end_column};
    return 1;
}

sub _line_measure ($span) {
    return $span->{end_line} - $span->{start_line};
}

sub _column_measure ($span) {
    return $span->{end_line} == $span->{start_line}
        ? $span->{end_column} - $span->{start_column}
        : 1_000_000_000;
}

sub _clone ($value) {
    return undef unless defined $value;
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;

__END__

=head1 METHODS

=head2 render_ppif

Returns canonical PPIF text and a private generated-to-original source map.

=head2 diagnostic_from_ppif_error

Maps a caught PPIF error to a private SourceHIR diagnostic, using generated
position evidence when present and root provenance otherwise.

=cut
