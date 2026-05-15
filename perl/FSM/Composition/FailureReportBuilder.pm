package FSM::Composition::FailureReportBuilder;

=head1 NAME

FSM::Composition::FailureReportBuilder - Builder for blocked composition failure summaries

=head1 DESCRIPTION

Builds the bounded failed-run composition summary family used by the pipeline
and CLI. This package owns blocked-boundary extraction plus the construct,
artifact, context, and concise-reason summary rules derived from raised
composition diagnostics.

=cut

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub build_report ($class, $error_text) {
    return undef unless defined $error_text && length $error_text;

    my $summary_text = $error_text;
    $summary_text =~ s/\n\s*at\s+\S.*\z//s;

    my %report;

    if ($summary_text =~ /Composition top '([^']+)'/s) {
        $report{top_name} = $1;
    }
    elsif ($summary_text =~ /Composition source '\?top:([^']+)'/s) {
        $report{top_name} = $1;
    }

    if ($summary_text =~ /Composition references external RTL module '([^']+)'/s) {
        $report{rtl_module_name} = $1;
    }

    if ($summary_text =~ /\b(?:the\s+)?(?:current\s+)?active\s+(C[1-4])\s+lane\b/is) {
        $report{lane} = uc($1);
    }

    my $construct = $class->construct_excerpt($summary_text);
    if ($construct) {
        $report{construct} = $construct->{token};
        $report{construct_summary} = $construct->{summary};
    }

    my $artifact = $class->artifact_excerpt($summary_text);
    if ($artifact) {
        $report{artifact_label} = $artifact->{label};
        $report{artifact_value} = $artifact->{value};
        $report{artifact_summary} = $artifact->{summary};
    }

    my $search_roots = $class->search_roots_excerpt($summary_text);
    if ($search_roots) {
        $report{search_roots_label} = $search_roots->{label};
        $report{search_roots_value} = $search_roots->{value};
        $report{search_roots_summary} = $search_roots->{summary};
    }

    my $context = $class->context_excerpt($summary_text);
    if ($context) {
        unless (
            defined($report{artifact_value})
            && length($report{artifact_value})
            && $context->{label} eq 'Metadata'
            && $context->{value} eq $report{artifact_value}
        ) {
            $report{context_label} = $context->{label};
            $report{context_value} = $context->{value};
            $report{context_summary} = $context->{summary};
        }
    }

    if ($summary_text =~ /\b(?:but )?([A-Za-z0-9?'\-\/][A-Za-z0-9?'\-\/ ]+?) is blocked because\b/s) {
        my $blocked_boundary = $1;
        $blocked_boundary =~ s/\s+/ /g;
        $blocked_boundary =~ s/^\s+|\s+$//g;
        $report{blocked_boundary} = $blocked_boundary;
        $report{blocked_boundary_label} = $class->boundary_label($blocked_boundary);
    }

    if ($summary_text =~ /\bis blocked because\s+(.+)\z/s) {
        my $reason = $class->reason_excerpt($1);
        $report{blocked_reason} = $reason if defined $reason && length $reason;
    }

    return undef unless $report{blocked_boundary};
    return \%report;
}

sub boundary_label ($class, $blocked_boundary) {
    return '' unless defined $blocked_boundary && length $blocked_boundary;

    my $label = $blocked_boundary;
    $label =~ s/^\s+|\s+$//g;
    $label =~ s/^composition //i;
    return $label;
}

sub reason_excerpt ($class, $reason_text) {
    return '' unless defined $reason_text && length $reason_text;

    my $reason = $reason_text;
    $reason =~ s/\s+/ /g;
    $reason =~ s/^\s+|\s+$//g;
    $reason =~ s/^declared interface metadata '[^']+'\s+//;
    $reason =~ s/\s+in declared interface metadata '[^']+'//g;
    $reason =~ s/\s*See docs\/.*\z//i;
    $reason =~ s/,\s+except that the single-child passthrough C1 lane and the explicit-link C2\/C3 lanes may now infer the top interface when '\?ports' is omitted or empty//g;

    if (
        $reason =~ /\A(.+?)\.\s+Seen same-name child endpoints:\s+(.+?)\.\s+(?:The active|The current|Use '\?wiring'|Use '\?ports'|Use '\?fsmc'|Use '\?dtc'|Standalone '\?dt:name' roots|FSM child roots are shipped as composition children).*\z/s
    ) {
        my ($headline, $seen) = ($1, $2);
        $headline =~ s/^\s+|\s+$//g;
        $seen =~ s/^\s+|\s+$//g;
        return "$headline. Seen same-name child endpoints: $seen";
    }

    $reason =~ s/\.\s+(?:Search roots:|Seen |The active |The current |Use '\?wiring'|Use '\?ports'|Use '\?fsmc'|Use '\?dtc'|Standalone '\?dt:name' roots|FSM child roots are shipped as composition children).*\z//;
    $reason =~ s/\.\z//;
    $reason =~ s/^\s+|\s+$//g;
    return $reason;
}

sub construct_excerpt ($class, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    my @patterns = (
        [ qr/declared connect-by-name|=port/s, '=port', '=port' ],
        [ qr/requests declared connect-by-name/s, '=port', '=port' ],
        [ qr/Composition references external RTL module|RTL interface metadata|contains embedded '\?rtlif:/s, '?rtl', '?rtl' ],
        [ qr/explicit '\?ports' block|'\?ports' to declare at least one explicit top port/s, '?ports', '?ports' ],
        [ qr/explicit link|explicit-link|nested '\?wiring' item|contains '\?wiring' token|contains '\?wiring' link form/s, '?wiring', '?wiring' ],
        [ qr/contains child '\?wiring(?::[^']+)?'/s, '?wiring', '?wiring' ],
        [ qr/omits top port|declares top port|declares duplicate top port|marks top port|uses top port|nested '\?ports' item|contains '\?ports' token|contains '\?ports' mapping directive|contains '\?ports' verbose declaration/s, '?ports', '?ports' ],
        [ qr/contains child '\?ports(?::[^']+)?'/s, '?ports', '?ports' ],
        [ qr/contains child '\?rtl:[^']+'/s, '?rtl', '?rtl' ],
        [ qr/contains child '\?fsmc(?::[^']+)?'/s, '?fsmc', '?fsmc' ],
        [ qr/\?fsmc' child|active FSM child source/s, '?fsmc', '?fsmc' ],
        [ qr/contains child '\?dtc(?::[^']+)?'/s, '?dtc', '?dtc' ],
        [ qr/\?dtc' child|standalone-DT child source/s, '?dtc', '?dtc' ],
    );

    for my $entry (@patterns) {
        my ($pattern, $token, $summary) = @$entry;
        next unless $summary_text =~ $pattern;
        return {
            token => $token,
            summary => $summary,
        };
    }

    return undef;
}

sub artifact_excerpt ($class, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    my @patterns = (
        [ qr/Expected child source file:\s+'([^']+)'/s, sub { return ('Expected child source file', "'$_[0]'"); } ],
        [ qr/resolves '\?(?:fsmc|dtc)' child '[^']+' to '([^']+)'/s, sub { return ('Child source file', "'$_[0]'"); } ],
        [ qr/Expected RTL metadata file:\s+'([^']+)'/s, sub { return ('Expected RTL metadata file', "'$_[0]'"); } ],
        [ qr/no declared interface metadata file '([^']+)' was found/s, sub { return ('Expected RTL metadata file', "'$_[0]'"); } ],
        [ qr/declared interface metadata '([^']+)'/s, sub { return ('RTL metadata file', "'$_[0]'"); } ],
    );

    for my $entry (@patterns) {
        my ($pattern, $builder) = @$entry;
        next unless $summary_text =~ $pattern;
        my ($label, $value) = $builder->($1);
        return {
            label => $label,
            value => $value,
            summary => "$label $value",
        };
    }

    return undef;
}

sub search_roots_excerpt ($class, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    if ($summary_text =~ /(?:^|\n)Search roots:\s*([^\n]+)/s) {
        my $value = $1;
        $value =~ s/\s+\z//;
        return {
            label => 'Search roots',
            value => $value,
            summary => $value,
        };
    }

    return undef;
}

sub context_excerpt ($class, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    my @patterns = (
        [ qr/contains a child entry that is empty or missing its header/s, sub { return ('Child entry', "'missing header'"); } ],
        [ qr/contains a child entry that does not begin with a string header/s, sub { return ('Child entry', "'non-string header'"); } ],
        [ qr/contains a nested '(\?(?:ports|wiring))' item/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/contains child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/contains '(\?(?:fsmc|dtc))' child without a name/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/contains '\?(?:fsmc|dtc|rtl)' child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/declares duplicate child instance name '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/declares '\?(?:fsmc|dtc|rtl)' child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/resolves '\?(?:fsmc|dtc)' child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/mapping directive '([^']+)'/s, sub { return ('Mapping directive', "'$_[0]'"); } ],
        [ qr/link form '([^']+)'/s, sub { return ('Link form', "'$_[0]'"); } ],
        [ qr/verbose declaration '([^']+)'/s, sub { return ('Declaration', "'$_[0]'"); } ],
        [ qr/contains multiple embedded '(\?rtlif:[^']+)' roots/s, sub { return ('RTL root', "'$_[0]'"); } ],
        [ qr/does not contain a '(\?rtlif:[^']+)' root/s, sub { return ('RTL root', "'$_[0]'"); } ],
        [ qr/under '(\?rtlif:[^']+)'/s, sub { return ('RTL root', "'$_[0]'"); } ],
        [ qr/references child expression '([^']+)'/s, sub { return ('Child expression', "'$_[0]'"); } ],
        [ qr/uses child expression '([^']+)'/s, sub { return ('Child expression', "'$_[0]'"); } ],
        [ qr/references child endpoint '([^']+)'/s, sub { return ('Child endpoint', "'$_[0]'"); } ],
        [ qr/uses child endpoint '([^']+)'/s, sub { return ('Child endpoint', "'$_[0]'"); } ],
        [ qr/(?:uses )?top expression '([^']+)'/s, sub { return ('Top expression', "'$_[0]'"); } ],
        [ qr/uses actual source '([^']+)'/s, sub { return ('Actual source', "'$_[0]'"); } ],
        [ qr/uses actual endpoint '([^']+)'/s, sub { return ('Actual endpoint', "'$_[0]'"); } ],
        [ qr/links top input '([^']+)' directly to top output '([^']+)'/s, sub {
            return ('Top port', "'$_[0]'");
        } ],
        [ qr/drives multiple top outputs from '([^']+)'/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/links '[^']+' to '([^']+)', .*incompatible declared type contracts/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/links '[^']+' \(width \d+\) to '([^']+)' \(width \d+\)/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/assigns explicit link driver '[^']+' to target '([^']+)'/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/references top-level endpoint '([^']+)'/s, sub { return ('Top endpoint', "'$_[0]'"); } ],
        [ qr/uses explicit endpoint '([^']+)'/s, sub { return ('Endpoint', "'$_[0]'"); } ],
        [ qr/declares duplicate top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/omits top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/declares top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/marks top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/uses top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/leaves child port '([^']+)'/s, sub { return ('Child port', "'$_[0]'"); } ],
        [ qr/child port '([^']+)'/s, sub { return ('Child port', "'$_[0]'"); } ],
        [ qr/repeats port '([^']+)'/s, sub { return ('RTL port', "'$_[0]'"); } ],
        [ qr/instance '([^']+)' has no port named '([^']+)'/s, sub { return ('Child endpoint', "'$_[0].$_[1]'"); } ],
        [ qr/token '([^']+)'/s, sub { return ('Token', "'$_[0]'"); } ],
        [ qr/declared interface metadata '([^']+)'/s, sub { return ('Metadata', "'$_[0]'"); } ],
        [ qr/RTL interface metadata '([^']+)'/s, sub { return ('Metadata', "'$_[0]'"); } ],
    );

    for my $entry (@patterns) {
        my ($pattern, $formatter) = @$entry;
        next unless my @captures = ($summary_text =~ $pattern);
        my ($label, $value) = $formatter->(@captures);
        next unless defined $label && defined $value;
        return {
            label => $label,
            value => $value,
            summary => "$label $value",
        };
    }

    return undef;
}

1;

__END__

=head1 METHODS

=head2 build_report

Builds the blocked composition failure summary payload from one raised
diagnostic string.

=head2 boundary_label

Normalizes a blocked-boundary label into the concise CLI-facing form.

=head2 reason_excerpt

Builds the concise blocked-reason summary from the tail of one raised
diagnostic.

=head2 construct_excerpt

Extracts the best current construct token summary from one raised diagnostic.

=head2 artifact_excerpt

Extracts the artifact summary, such as a child source file or `.rtlif`
metadata file, from one raised diagnostic.

=head2 context_excerpt

Extracts the most specific context summary available from one raised
diagnostic, such as a child, top port, token, or child endpoint.

=cut
