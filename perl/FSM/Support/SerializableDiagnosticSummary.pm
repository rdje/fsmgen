package FSM::Support::SerializableDiagnosticSummary;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

our @EXPORT_OK = qw(
    build_serializable_diagnostic_summary
    build_serializable_diagnostic_summary_contract
    serializable_diagnostic_summary_contract_source
    serializable_diagnostic_summary_public_top_level_keys
    serializable_diagnostic_summary_summary_keys
);

sub serializable_diagnostic_summary_contract_source {
    return 'FSM::Support::SerializableDiagnosticSummary';
}

sub build_serializable_diagnostic_summary_contract {
    return {
        schema_version => 1,
        status => 'bounded_public',
        contract_source => serializable_diagnostic_summary_contract_source(),
        object_name => 'diagnostic_summary',
        report_source => serializable_diagnostic_summary_contract_source(),
        entrypoints => {
            in_process => [
                'FSM::Support::SerializableDiagnosticSummary::build_serializable_diagnostic_summary(report => $public_json_report)',
                'FSM::Support::SerializableDiagnosticSummary::build_serializable_diagnostic_summary(diagnostics => $diagnostics)',
            ],
        },
        public_top_level_presence_keys => serializable_diagnostic_summary_public_top_level_keys(),
        summary_keys => serializable_diagnostic_summary_summary_keys(),
        json_safe_as_whole => JSON::PP::true,
        guidance => [
            'Use this summary for bounded diagnostic inspection across public JSON reports.',
            'The summary records diagnostic counts, stable codes, severity counts, and support-accounting match hints without copying whole diagnostic payloads.',
            'Full diagnostic objects remain owned by their existing check/semantic diagnostic contracts.',
        ],
    };
}

sub build_serializable_diagnostic_summary {
    my (%args) = @_;
    my $report = ref($args{report}) eq 'HASH' ? $args{report} : {};
    my $diagnostics = ref($args{diagnostics}) eq 'ARRAY'
        ? $args{diagnostics}
        : (ref($report->{diagnostics}) eq 'ARRAY' ? $report->{diagnostics} : []);

    my @codes;
    my %severity_counts;
    my %code_counts;
    my $matched_support_accounting = 0;

    for my $diagnostic (@$diagnostics) {
        next unless ref($diagnostic) eq 'HASH';
        my $code = $diagnostic->{code};
        if (defined($code) && length($code)) {
            push @codes, $code;
            $code_counts{$code}++;
        }
        my $severity = $diagnostic->{severity} || 'unknown';
        $severity_counts{$severity}++;
        my $support = ref($diagnostic->{support_accounting}) eq 'HASH'
            ? $diagnostic->{support_accounting}
            : {};
        $matched_support_accounting ||= $support->{matched} ? 1 : 0;
    }

    return {
        diagnostic_summary_schema_version => 1,
        report_source => serializable_diagnostic_summary_contract_source(),
        contract_source => serializable_diagnostic_summary_contract_source(),
        success => exists($report->{success}) ? _bool($report->{success}) : undef,
        diagnostic_count => scalar(@$diagnostics),
        codes => \@codes,
        unique_codes => [sort keys %code_counts],
        code_counts => \%code_counts,
        severity_counts => \%severity_counts,
        has_diagnostics => _bool(scalar(@$diagnostics)),
        has_stable_codes => _bool(scalar(@codes)),
        matched_support_accounting => _bool($matched_support_accounting),
    };
}

sub serializable_diagnostic_summary_public_top_level_keys {
    return [
        qw(
            diagnostic_summary_schema_version
            report_source
            contract_source
            success
            diagnostic_count
            codes
            unique_codes
            code_counts
            severity_counts
            has_diagnostics
            has_stable_codes
            matched_support_accounting
        ),
    ];
}

sub serializable_diagnostic_summary_summary_keys {
    return [
        qw(
            success
            diagnostic_count
            has_diagnostics
            has_stable_codes
            matched_support_accounting
        ),
    ];
}

sub _bool {
    my ($value) = @_;
    return $value ? JSON::PP::true : JSON::PP::false;
}

1;
