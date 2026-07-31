package FSM::VIAL::Parity::AHBBaseOutput;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

my $JSON = JSON::PP->new->canonical(1);
my $ORACLE_SCHEMA = 'fsmgen.vial_ahb_base_output_oracle.v1';
my $REPORT_SCHEMA = 'fsmgen.vial_parity_report.v1';
my $CAPABILITY = 'vial.parity.ahb_base_output_arbitration.v1';
my @RESULT_KEYS = qw(
    ok status report baseline_projection candidate_projection diagnostics
);
my @REPORT_KEYS = qw(
    schema schema_version plan_id baseline_result_id candidate_result_id
    eligible equivalent compared_paths exclusions mismatches diagnostics
);
my @OUTCOME_KEYS = qw(
    scenario_id status bus_accepts ready_low_cycles response_error_cycles
    nonzero_read_data_cycles final_ready final_response final_read_data_hex
    storage_hex
);
my @EXCLUSION_KEYS = qw(semantic_id reason portable_class capability_id);
my @MISMATCH_KEYS = qw(path baseline candidate semantic_id logical_time);

sub result_keys($class) {
    confess __PACKAGE__ . "->result_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@RESULT_KEYS];
}

sub report_keys($class) {
    confess __PACKAGE__ . "->report_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@REPORT_KEYS];
}

sub compare($class, @args) {
    return _failure('VIAL_PARITY_INVOCATION_ERROR', 'compare requires the exact AHBBaseOutput class invocant', '/')
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return _failure('VIAL_PARITY_INVOCATION_ERROR', 'compare expects one closed argument hash', '/')
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $result = eval { _compare($args[0]) };
    return $result if defined $result;
    my $error = $@;
    return _failure($error->{code}, $error->{message}, $error->{path})
        if blessed($error) && $error->isa('FSM::VIAL::Parity::AHBBaseOutput::Failure');
    return _failure('VIAL_PARITY_HOST_ERROR', _sanitize_exception($error), '/');
}

sub _compare($raw) {
    _require_exact_keys($raw, [qw(
        candidate_result baseline_exit_code baseline_stdout
        baseline_source_sha256 baseline_dut_sha256 candidate_dut_sha256
    )], 'AHB parity comparison');
    _require_digest($raw->{baseline_source_sha256}, '/baseline_source_sha256');
    _require_digest($raw->{baseline_dut_sha256}, '/baseline_dut_sha256');
    _require_digest($raw->{candidate_dut_sha256}, '/candidate_dut_sha256');
    _throw('VIAL_PARITY_DUT_IDENTITY_ERROR', 'handwritten and generated VIAL runs did not use the same generated DUT bytes', '/baseline_dut_sha256')
        unless $raw->{baseline_dut_sha256} eq $raw->{candidate_dut_sha256};
    _throw('VIAL_PARITY_BASELINE_ERROR', 'baseline_exit_code must be integer zero', '/baseline_exit_code')
        unless defined($raw->{baseline_exit_code}) && !ref($raw->{baseline_exit_code})
            && "$raw->{baseline_exit_code}" =~ /\A[0-9]+\z/
            && $raw->{baseline_exit_code} == 0;
    _throw('VIAL_PARITY_BASELINE_ERROR', 'baseline_stdout must be a bounded scalar', '/baseline_stdout')
        unless defined($raw->{baseline_stdout}) && !ref($raw->{baseline_stdout})
            && bytes::length($raw->{baseline_stdout}) <= 65_536;

    my $candidate = $raw->{candidate_result};
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate_result must be one unblessed result manifest', '/candidate_result')
        unless ref($candidate) eq 'HASH' && !blessed($candidate);
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate result schema is not exact', '/candidate_result/schema')
        unless ($candidate->{schema} // '') eq 'fsmgen.verification_result_manifest.v1'
            && ($candidate->{schema_version} // 0) == 1;
    for my $key (qw(plan_id fixture_id result_id)) {
        _throw('VIAL_PARITY_CANDIDATE_ERROR', "candidate result $key is invalid", "/candidate_result/$key")
            unless defined($candidate->{$key}) && !ref($candidate->{$key}) && length($candidate->{$key});
    }
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate fixture identity is not the selected AHB base-output oracle', '/candidate_result/fixture_id')
        unless $candidate->{fixture_id} eq 'ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration';
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate plan identity is malformed', '/candidate_result/plan_id')
        unless $candidate->{plan_id} =~ m{\Aplan/[0-9a-f]{64}\z};
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate result identity is malformed', '/candidate_result/result_id')
        unless $candidate->{result_id} =~ m{\Aresult/[0-9a-f]{64}\z};
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate result is not parity eligible', '/candidate_result/portable_parity_eligible')
        unless $candidate->{portable_parity_eligible};
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate result did not pass', '/candidate_result/status')
        unless ($candidate->{status} // '') eq 'pass';
    for my $family (qw(scenario_results events samples transactions)) {
        _throw('VIAL_PARITY_CANDIDATE_ERROR', "candidate result $family must be an array", "/candidate_result/$family")
            unless ref($candidate->{$family}) eq 'ARRAY';
    }
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate must contain exactly the selected two scenarios', '/candidate_result/scenario_results')
        unless @{$candidate->{scenario_results}} == 2;

    my $baseline = _baseline_projection($raw);
    my $projected = _candidate_projection($candidate, $raw->{candidate_dut_sha256});
    my @paths = _compared_paths();
    my @mismatches;
    for my $path (@paths) {
        my $baseline_value = _pointer($baseline->{outcomes}, $path);
        my $candidate_value = _pointer($projected->{outcomes}, $path);
        next if $JSON->encode($baseline_value) eq $JSON->encode($candidate_value);
        my $mismatch = {
            path => "/outcomes$path",
            baseline => _clone($baseline_value),
            candidate => _clone($candidate_value),
            semantic_id => _semantic_id_for_path($path),
            logical_time => _logical_time_for_path($projected, $path),
        };
        _require_exact_keys($mismatch, \@MISMATCH_KEYS, 'parity mismatch');
        push @mismatches, $mismatch;
    }
    my @exclusions = map {
        my $entry = {
            semantic_id => "handwritten-ahb/$_/internal-capture-hold-completion",
            reason => 'internal capture/hold/completion signals are not declared typed VIAL probes and are excluded from the portable oracle',
            portable_class => 'native_only',
            capability_id => $CAPABILITY,
        };
        _require_exact_keys($entry, \@EXCLUSION_KEYS, 'parity exclusion');
        $entry;
    } qw(success unsupported_size);
    my $equivalent = @mismatches ? JSON::PP::false : JSON::PP::true;
    my $report = {
        schema => $REPORT_SCHEMA,
        schema_version => 1,
        plan_id => $candidate->{plan_id},
        baseline_result_id => 'handwritten-ahb-oracle/' . sha256_hex($JSON->encode($baseline)),
        candidate_result_id => $candidate->{result_id},
        eligible => JSON::PP::true,
        equivalent => $equivalent,
        compared_paths => [map { "/outcomes$_" } @paths],
        exclusions => \@exclusions,
        mismatches => \@mismatches,
        diagnostics => [],
    };
    _require_exact_keys($report, \@REPORT_KEYS, 'parity report');
    return _result({
        ok => JSON::PP::true,
        status => @mismatches ? 'mismatch' : 'equivalent',
        report => $report,
        baseline_projection => $baseline,
        candidate_projection => $projected,
        diagnostics => [],
    });
}

sub _baseline_projection($raw) {
    my %parsed;
    my %pattern = (
        success => qr/\ABASE_ASSERT_SUCCESS accepts=([0-9]+) captures=([0-9]+) holds=([0-9]+) completions=([0-9]+) ready_low=([0-9]+) storage=([0-9a-fA-F]{8})\z/,
        unsupported_size => qr/\ABASE_ASSERT_ERROR accepts=([0-9]+) captures=([0-9]+) holds=([0-9]+) completions=([0-9]+) error_cycles=([0-9]+) storage=([0-9a-fA-F]{8})\z/,
    );
    for my $line (split /\r?\n/, $raw->{baseline_stdout}) {
        next unless index($line, 'BASE_ASSERT_') == 0;
        my $name = index($line, 'BASE_ASSERT_SUCCESS ') == 0 ? 'success'
            : index($line, 'BASE_ASSERT_ERROR ') == 0 ? 'unsupported_size' : undef;
        _throw('VIAL_PARITY_BASELINE_ERROR', 'baseline contains an unknown oracle record', '/baseline_stdout')
            unless defined $name;
        _throw('VIAL_PARITY_BASELINE_ERROR', "baseline contains duplicate $name oracle records", '/baseline_stdout')
            if exists $parsed{$name};
        my @value = $line =~ $pattern{$name};
        _throw('VIAL_PARITY_BASELINE_ERROR', "baseline $name oracle record is malformed", '/baseline_stdout')
            unless @value == 6;
        $parsed{$name} = {
            accepts => 0 + $value[0], captures => 0 + $value[1],
            holds => 0 + $value[2], completions => 0 + $value[3],
            fifth => 0 + $value[4], storage => lc($value[5]),
        };
    }
    _throw('VIAL_PARITY_BASELINE_ERROR', 'baseline is missing one exact success or ERROR oracle record', '/baseline_stdout')
        unless keys(%parsed) == 2 && $parsed{success} && $parsed{unsupported_size};
    return {
        schema => $ORACLE_SCHEMA,
        schema_version => 1,
        source => 'handwritten_ahb_harness',
        dut_sha256 => $raw->{baseline_dut_sha256},
        harness_sha256 => $raw->{baseline_source_sha256},
        status => 'pass',
        outcomes => [
            _outcome(
                scenario_id => 'success', bus_accepts => $parsed{success}{accepts},
                ready_low_cycles => $parsed{success}{fifth}, response_error_cycles => 0,
                nonzero_read_data_cycles => 0, storage_hex => $parsed{success}{storage},
            ),
            _outcome(
                scenario_id => 'unsupported_size', bus_accepts => $parsed{unsupported_size}{accepts},
                ready_low_cycles => undef, response_error_cycles => $parsed{unsupported_size}{fifth},
                nonzero_read_data_cycles => 0, storage_hex => $parsed{unsupported_size}{storage},
            ),
        ],
        excluded_internal_observations => [
            {scenario_id => 'success', map { $_ => $parsed{success}{$_} } qw(captures holds completions)},
            {scenario_id => 'unsupported_size', map { $_ => $parsed{unsupported_size}{$_} } qw(captures holds completions)},
        ],
    };
}

sub _candidate_projection($candidate, $dut_sha256) {
    my %scenario;
    for my $entry (@{$candidate->{scenario_results}}) {
        my ($short) = ($entry->{scenario_id} // '') =~ /::scenario::(success|unsupported_size)\z/;
        next unless defined $short;
        _throw('VIAL_PARITY_CANDIDATE_ERROR', "candidate contains duplicate $short scenario results", '/candidate_result/scenario_results')
            if $scenario{$short};
        $scenario{$short} = $entry;
    }
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate is missing the success or unsupported_size scenario', '/candidate_result/scenario_results')
        unless $scenario{success} && $scenario{unsupported_size};
    my @outcomes;
    my %times;
    for my $short (qw(success unsupported_size)) {
        my $entry = $scenario{$short};
        _throw('VIAL_PARITY_CANDIDATE_ERROR', "candidate $short scenario did not pass", '/candidate_result/scenario_results')
            unless ($entry->{status} // '') eq 'pass';
        my $run_id = $entry->{run_id};
        my %event;
        $event{$_->{event_id}}++
            for grep { ($_->{run_id} // '') eq $run_id } @{$candidate->{events}};
        my %sample;
        for my $id (qw(endpoint/HREADYOUT endpoint/HRESP endpoint/HRDATA probe/reg_data_q)) {
            my @records = grep {
                ($_->{run_id} // '') eq $run_id && ($_->{sample_id} // '') eq $id
            } @{$candidate->{samples}};
            _throw('VIAL_PARITY_CANDIDATE_ERROR', "candidate $short has no $id samples", '/candidate_result/samples')
                unless @records;
            for my $record (@records) {
                _normalized_hex($record->{value}, "/candidate_result/samples/$id");
            }
            $sample{$id} = \@records;
        }
        my $outcome = _outcome(
            scenario_id => $short,
            bus_accepts => $event{'event/ahb_write/accepted'} // 0,
            ready_low_cycles => $short eq 'success'
                ? scalar(grep { _normalized_hex($_->{value}, '/candidate_result/samples/endpoint/HREADYOUT') eq '0' } @{$sample{'endpoint/HREADYOUT'}})
                : undef,
            response_error_cycles => scalar(grep { _normalized_hex($_->{value}, '/candidate_result/samples/endpoint/HRESP') ne '0' } @{$sample{'endpoint/HRESP'}}),
            nonzero_read_data_cycles => scalar(grep { _normalized_hex($_->{value}, '/candidate_result/samples/endpoint/HRDATA') ne '0' } @{$sample{'endpoint/HRDATA'}}),
            final_ready => 0 + hex(_normalized_hex($sample{'endpoint/HREADYOUT'}[-1]{value}, '/candidate_result/samples/endpoint/HREADYOUT')),
            final_response => 0 + hex(_normalized_hex($sample{'endpoint/HRESP'}[-1]{value}, '/candidate_result/samples/endpoint/HRESP')),
            final_read_data_hex => sprintf('%08s', _normalized_hex($sample{'endpoint/HRDATA'}[-1]{value}, '/candidate_result/samples/endpoint/HRDATA')),
            storage_hex => sprintf('%08s', _normalized_hex($sample{'probe/reg_data_q'}[-1]{value}, '/candidate_result/samples/probe/reg_data_q')),
        );
        $outcome->{final_read_data_hex} =~ tr/ /0/;
        $outcome->{storage_hex} =~ tr/ /0/;
        push @outcomes, $outcome;
        $times{$short} = {
            ready => _clone($sample{'endpoint/HREADYOUT'}[-1]{logical_time}),
            response => _clone($sample{'endpoint/HRESP'}[-1]{logical_time}),
            read_data => _clone($sample{'endpoint/HRDATA'}[-1]{logical_time}),
            storage => _clone($sample{'probe/reg_data_q'}[-1]{logical_time}),
            scenario => _clone($entry->{end_time}),
        };
    }
    return {
        schema => $ORACLE_SCHEMA,
        schema_version => 1,
        source => 'generated_vial_result',
        plan_id => $candidate->{plan_id},
        fixture_id => $candidate->{fixture_id},
        result_id => $candidate->{result_id},
        dut_sha256 => $dut_sha256,
        status => 'pass',
        outcomes => \@outcomes,
        logical_times => \%times,
    };
}

sub _outcome(%raw) {
    my $entry = {
        scenario_id => $raw{scenario_id},
        status => 'pass',
        bus_accepts => 0 + $raw{bus_accepts},
        ready_low_cycles => defined($raw{ready_low_cycles}) ? 0 + $raw{ready_low_cycles} : undef,
        response_error_cycles => 0 + $raw{response_error_cycles},
        nonzero_read_data_cycles => 0 + $raw{nonzero_read_data_cycles},
        final_ready => defined($raw{final_ready}) ? 0 + $raw{final_ready} : 1,
        final_response => defined($raw{final_response}) ? 0 + $raw{final_response} : 0,
        final_read_data_hex => $raw{final_read_data_hex} // '00000000',
        storage_hex => lc($raw{storage_hex}),
    };
    _require_exact_keys($entry, \@OUTCOME_KEYS, 'AHB outcome');
    return $entry;
}

sub _compared_paths() {
    my @field = qw(
        scenario_id status bus_accepts ready_low_cycles response_error_cycles
        nonzero_read_data_cycles final_ready final_response final_read_data_hex
        storage_hex
    );
    my @path = map { "/0/$_" } @field;
    push @path, map { "/1/$_" } grep { $_ ne 'ready_low_cycles' } @field;
    return @path;
}

sub _pointer($root, $path) {
    my @part = grep { length } split m{/}, $path;
    my $value = $root;
    for my $part (@part) {
        $value = ref($value) eq 'ARRAY' ? $value->[$part] : $value->{$part};
    }
    return $value;
}

sub _semantic_id_for_path($path) {
    return 'event/ahb_write/accepted' if $path =~ /\/bus_accepts\z/;
    return 'endpoint/HREADYOUT' if $path =~ /\/(?:ready_low_cycles|final_ready)\z/;
    return 'endpoint/HRESP' if $path =~ /\/(?:response_error_cycles|final_response)\z/;
    return 'endpoint/HRDATA' if $path =~ /\/(?:nonzero_read_data_cycles|final_read_data_hex)\z/;
    return 'probe/reg_data_q' if $path =~ /\/storage_hex\z/;
    return $path =~ m{\A/0/} ? 'scenario/success' : 'scenario/unsupported_size';
}

sub _logical_time_for_path($projection, $path) {
    my $scenario = $path =~ m{\A/0/} ? 'success' : 'unsupported_size';
    return _clone($projection->{logical_times}{$scenario}{ready})
        if $path =~ /\/(?:ready_low_cycles|final_ready)\z/;
    return _clone($projection->{logical_times}{$scenario}{response})
        if $path =~ /\/(?:response_error_cycles|final_response)\z/;
    return _clone($projection->{logical_times}{$scenario}{read_data})
        if $path =~ /\/(?:nonzero_read_data_cycles|final_read_data_hex)\z/;
    return _clone($projection->{logical_times}{$scenario}{storage})
        if $path =~ /\/storage_hex\z/;
    return _clone($projection->{logical_times}{$scenario}{scenario});
}

sub _normalized_hex($value, $path) {
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate sample value is not a normalized scalar', $path)
        unless ref($value) eq 'HASH' && !blessed($value)
            && ($value->{kind} // '') eq 'scalar'
            && ($value->{value_hex} // '') =~ /\A[0-9a-f]+\z/
            && defined($value->{width}) && !ref($value->{width})
            && "$value->{width}" =~ /\A[1-9][0-9]*\z/
            && ($value->{known_hex} // '') =~ /\A[0-9a-f]+\z/
            && ($value->{z_hex} // '') =~ /\A0+\z/;
    my $nibbles = int(($value->{width} + 3) / 4);
    my $leading_bits = $value->{width} % 4 || 4;
    my $known = $value->{known_hex};
    my $expected_lead = sprintf('%x', (1 << $leading_bits) - 1);
    _throw('VIAL_PARITY_CANDIDATE_ERROR', 'candidate sample contains an unknown bit', $path)
        unless length($known) == $nibbles
            && substr($known, 0, 1) eq $expected_lead
            && substr($known, 1) =~ /\Af*\z/;
    my $hex = lc($value->{value_hex});
    $hex =~ s/\A0+(?=[0-9a-f])//;
    return $hex;
}

sub _require_digest($value, $path) {
    _throw('VIAL_PARITY_INVOCATION_ERROR', 'digest must be lowercase SHA-256', $path)
        unless defined($value) && !ref($value) && $value =~ /\A[0-9a-f]{64}\z/;
}

sub _require_exact_keys($hash, $keys, $label) {
    _throw('VIAL_PARITY_INVOCATION_ERROR', "$label must be one unblessed hash", '/')
        unless ref($hash) eq 'HASH' && !blessed($hash);
    my %expected = map { $_ => 1 } @$keys;
    my @actual = sort keys %$hash;
    my @expected = sort @$keys;
    _throw('VIAL_PARITY_SCHEMA_ERROR', "$label keys are not exact", '/')
        unless $JSON->encode(\@actual) eq $JSON->encode(\@expected)
            && !grep { !$expected{$_} } @actual;
}

sub _result($value) {
    _require_exact_keys($value, \@RESULT_KEYS, 'AHB parity result');
    return _clone($value);
}

sub _failure($code, $message, $path) {
    return _result({
        ok => JSON::PP::false,
        status => 'error',
        report => undef,
        baseline_projection => undef,
        candidate_projection => undef,
        diagnostics => [{code => $code, message => $message, path => $path}],
    });
}

sub _clone($value) {
    return $value unless ref($value);
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'parity data contains a non-JSON reference';
}

sub _sanitize_exception($error) {
    my $text = defined($error) ? "$error" : 'unknown host error';
    $text =~ s/[\r\n]+/ /g;
    $text =~ s/\s+at\s+\S+\s+line\s+\d+.*\z//;
    $text =~ s/\s+/ /g;
    $text =~ s/\A\s+|\s+\z//g;
    return length($text) ? $text : 'unknown host error';
}

sub _throw($code, $message, $path) {
    die bless({code => $code, message => $message, path => $path},
        'FSM::VIAL::Parity::AHBBaseOutput::Failure');
}

package FSM::VIAL::Parity::AHBBaseOutput::Failure;

use overload q{""} => sub { $_[0]{message} }, fallback => 1;

1;
