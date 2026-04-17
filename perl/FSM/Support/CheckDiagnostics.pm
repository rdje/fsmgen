package FSM::Support::CheckDiagnostics;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use FSM::Support::DiagnosticCodes qw(diagnostic_code_metadata);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);

our @EXPORT_OK = qw(build_check_failure_report build_check_success_report);

sub build_check_success_report {
    my (%args) = @_;

    my $module_info = $args{module_info} || {};

    return {
        check_schema_version => 1,
        producer => {
            name => 'FSMGen',
            report_source => 'FSM::Support::CheckDiagnostics',
        },
        command => _command_contract(%args),
        source => _source_contract(%args),
        success => JSON::PP::true,
        diagnostics => [],
        result => {
            module_name => $module_info->{module_name},
            state_count => $module_info->{state_count},
            signal_count => $module_info->{signal_count},
            composition_child_count => $module_info->{composition_child_count},
        },
        generated_output => {
            emitted => JSON::PP::false,
        },
    };
}

sub build_check_failure_report {
    my (%args) = @_;

    my $message = _clean_message($args{message} // $args{error} // '');
    my $match = _matching_expected_failure($message);
    my $diagnostic_code = $match ? $match->{diagnostic_code} : undef;
    my $metadata = $diagnostic_code
        ? diagnostic_code_metadata($diagnostic_code)
        : undef;

    my %diagnostic = (
        code => $diagnostic_code,
        severity => ($metadata && $metadata->{severity}) || 'error',
        stability => ($metadata && $metadata->{stability}) || 'unclassified',
        family => ($metadata && $metadata->{family}) || 'unclassified',
        summary => ($metadata && $metadata->{summary}) || 'Unclassified FSMGen failure.',
        message => $message,
        source_file => _extract_artifact($message, 'Source file') // $args{source_file},
        parent_composition_source => _extract_artifact($message, 'Parent composition source'),
        generated_child_source => _extract_artifact($message, 'Generated child source'),
        expected_rtl_metadata_file => _extract_artifact($message, 'Expected RTL metadata file'),
        expected_child_source_file => _extract_artifact($message, 'Expected child source file'),
        rtl_metadata_file => _extract_artifact($message, 'RTL metadata file'),
    );

    if ($match) {
        $diagnostic{matched_corpus_entry_id} = $match->{id};
        $diagnostic{coverage} = $match->{coverage};
        $diagnostic{classification} = $match->{classification};
        $diagnostic{migration_hint_available} = $match->{expected_hint_pattern}
            ? JSON::PP::true
            : JSON::PP::false;
    }
    else {
        $diagnostic{migration_hint_available} = JSON::PP::false;
    }

    return {
        check_schema_version => 1,
        producer => {
            name => 'FSMGen',
            report_source => 'FSM::Support::CheckDiagnostics',
        },
        command => _command_contract(%args),
        source => _source_contract(%args),
        success => JSON::PP::false,
        diagnostics => [\%diagnostic],
        generated_output => {
            emitted => JSON::PP::false,
        },
    };
}

sub _command_contract {
    my (%args) = @_;

    return {
        mode => 'check',
        json => JSON::PP::true,
        strict_mode => $args{strict_mode} ? JSON::PP::true : JSON::PP::false,
        target_language => $args{target_language} || 'systemverilog',
    };
}

sub _source_contract {
    my (%args) = @_;

    return {
        input => $args{input},
        resolved_path => $args{source_file},
    };
}

sub _matching_expected_failure {
    my ($message) = @_;

    for my $entry (
        grep { $_->{classification} eq 'expected_failure' } regression_corpus_entries()
    ) {
        my $pattern = $entry->{expected_error_pattern};
        next unless ref($pattern) eq 'Regexp';
        return $entry if $message =~ $pattern;
    }

    return undef;
}

sub _extract_artifact {
    my ($message, $label) = @_;
    return undef unless defined $message && defined $label && length $label;

    my $quoted_label = quotemeta($label);
    return $1 if $message =~ /^$quoted_label:\s+'([^']+)'/m;
    return undef;
}

sub _clean_message {
    my ($message) = @_;
    $message = '' unless defined $message;
    $message =~ s/\s+\z//s;
    return $message;
}

1;
