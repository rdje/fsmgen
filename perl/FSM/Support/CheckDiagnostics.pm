package FSM::Support::CheckDiagnostics;

use strict;
use warnings;

use Cwd qw(abs_path);
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use JSON::PP ();

use FSM::Support::DiagnosticCodes qw(diagnostic_code_metadata);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SerializableDiagnosticSummary qw(build_serializable_diagnostic_summary);

our @EXPORT_OK = qw(build_check_failure_report build_check_success_report);

sub build_check_success_report {
    my (%args) = @_;

    my $module_info = $args{module_info} || {};
    my $match = _matching_success_entry($args{source_file}, $args{strict_mode});

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
        diagnostic_summary => build_serializable_diagnostic_summary(
            report => {
                success => JSON::PP::true,
                diagnostics => [],
            },
        ),
        support_accounting => _success_support_accounting_contract($match),
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
    my $migration_hint_available =
        ($match && $match->{expected_hint_pattern}) ? JSON::PP::true : JSON::PP::false;

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
        support_accounting => _support_accounting_contract(
            $match,
            $diagnostic_code,
            $migration_hint_available,
        ),
    );

    if ($match) {
        $diagnostic{matched_corpus_entry_id} = $match->{id};
        $diagnostic{coverage} = $match->{coverage};
        $diagnostic{classification} = $match->{classification};
        $diagnostic{migration_hint_available} = $migration_hint_available;
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
        diagnostic_summary => build_serializable_diagnostic_summary(
            report => {
                success => JSON::PP::false,
                diagnostics => [\%diagnostic],
            },
        ),
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

    my @matches;
    for my $entry (grep { $_->{classification} eq 'expected_failure' } regression_corpus_entries()) {
        my $pattern = $entry->{expected_error_pattern};
        next unless ref($pattern) eq 'Regexp';
        push @matches, $entry if $message =~ $pattern;
    }

    return undef unless @matches;

    @matches = sort {
        length($b->{expected_error_pattern} . '') <=> length($a->{expected_error_pattern} . '')
            || $a->{id} cmp $b->{id}
    } @matches;

    return $matches[0];
}

sub _matching_success_entry {
    my ($source_file, $strict_mode) = @_;
    my $source_path = _canonical_path($source_file);
    return undef unless defined $source_path;

    my @matches;
    for my $entry (grep { $_->{classification} ne 'expected_failure' } regression_corpus_entries()) {
        my $entry_path = _corpus_entry_path($entry);
        next unless defined $entry_path && $entry_path eq $source_path;
        push @matches, $entry;
    }

    return undef unless @matches;

    if ($strict_mode) {
        my @strict_matches = grep { $_->{strict_supported} } @matches;
        @matches = @strict_matches if @strict_matches;
    }

    @matches = sort {
        _success_entry_rank($b) <=> _success_entry_rank($a)
            || $a->{id} cmp $b->{id}
    } @matches;

    return $matches[0];
}

sub _success_entry_rank {
    my ($entry) = @_;

    my $rank = 0;
    $rank += 100 if ($entry->{classification} || '') eq 'supported_smoke';
    $rank += 50 if $entry->{strict_supported};
    return $rank;
}

sub _success_support_accounting_contract {
    my ($match) = @_;

    return {
        matched => JSON::PP::false,
    } unless $match;

    return {
        matched => JSON::PP::true,
        entry_id => $match->{id},
        family => $match->{family},
        coverage => $match->{coverage},
        classification => $match->{classification},
        source_kind => $match->{source_kind},
        strict_supported => $match->{strict_supported} ? JSON::PP::true : JSON::PP::false,
    };
}

sub _support_accounting_contract {
    my ($match, $diagnostic_code, $migration_hint_available) = @_;

    return {
        matched => JSON::PP::false,
    } unless $match;

    return {
        matched => JSON::PP::true,
        entry_id => $match->{id},
        family => $match->{family},
        coverage => $match->{coverage},
        classification => $match->{classification},
        diagnostic_code => $diagnostic_code,
        migration_hint_available => $migration_hint_available,
    };
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

sub _corpus_entry_path {
    my ($entry) = @_;
    return undef unless ref($entry) eq 'HASH' && defined $entry->{relpath};

    return _canonical_path(
        File::Spec->catfile(_repo_root(), split m{/}, $entry->{relpath}),
    );
}

sub _repo_root {
    return _canonical_path(
        File::Spec->catdir(dirname(__FILE__), '..', '..', '..'),
    );
}

sub _canonical_path {
    my ($path) = @_;
    return undef unless defined $path && length $path;
    return abs_path($path) || File::Spec->rel2abs($path);
}

1;
