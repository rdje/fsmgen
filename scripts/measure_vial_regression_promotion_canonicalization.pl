#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use bytes ();
use Cwd qw(realpath);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(dirname);
use File::Spec;
use FindBin;
use IPC::Open3 qw(open3);
use JSON::PP ();
use POSIX ();
use Sub::Util qw(set_prototype);
use Symbol qw(gensym);
use Time::HiRes qw(clock_gettime sleep CLOCK_MONOTONIC);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement;
use FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore;
use FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore;

my $SCHEMA =
    'fsmgen.vial_regression_promotion_canonicalization_measurement.v1';
my $SELF_TEST_SCHEMA =
    'fsmgen.vial_regression_promotion_canonicalization_instrumentation_self_test.v1';
my $RESULT_MAX_BYTES = 262_144;
my $SAMPLE_MAX_BYTES = 8_388_608;
my $SAMPLE_BASE = '.artifacts/diagnostics/vial-scale';
my $BALANCED_ORDINAL = 11;
my $JSON = JSON::PP->new->canonical(1)->utf8(1);
my $ROOT = realpath(File::Spec->catdir($FindBin::Bin, '..'))
    // die "cannot resolve repository root\n";
my $VERIFIER = File::Spec->catfile(
    $ROOT, 'scripts',
    'verify_vial_regression_promotion_current_corpus.pl',
);

my (@canonical_context, @clone_context);
my (%metrics, %clone_depth, $whole_graph_threshold);

exit main(@ARGV);

sub main {
    my (@arguments) = @_;
    if (@arguments == 1 && $arguments[0] eq '--help') {
        print usage();
        return 0;
    }
    if (@arguments == 1 && $arguments[0] eq '--self-test') {
        emit_result(run_self_test());
        return 0;
    }

    my $options = parse_real_options(@arguments);
    require_active_guard();
    my $sample = prepare_sample_path($options->{sample_relative});
    my $before = run_independent_verifier();
    my $input = phase_input($options->{phase}, $before);
    $whole_graph_threshold = int(($input->{bytes} + 1) / 2);
    $whole_graph_threshold = 1_048_576
        if $whole_graph_threshold > 1_048_576;

    my $balanced_report;
    if ($options->{phase} eq 'balanced-validation') {
        my $loaded =
            FSM::VIAL::ArchitectureScaleRegressionPromotionProfileStore->load({
                repository_root => $ROOT,
                ordinal => $BALANCED_ORDINAL,
            });
        $balanced_report = $loaded->{publication}{report};
    }

    my $packages = instrumentable_fsm_packages();
    my $sampler_pid = start_sample(
        $sample->{absolute_path}, $options->{sample_seconds},
    );
    sleep 0.25;

    my @cpu_before = times;
    my $wall_started = clock_gettime(CLOCK_MONOTONIC);
    my ($phase_ok, $phase_value, $phase_error);
    {
        local $@;
        $phase_ok = eval {
            $phase_value = with_instrumentation($packages, sub {
                return FSM::VIAL::ArchitectureScaleBalancedPortableMeasurement
                    ->validate_report({
                        repository_root => $ROOT,
                        report => $balanced_report,
                    }) if $options->{phase} eq 'balanced-validation';
                return FSM::VIAL::ArchitectureScaleRegressionPromotionCorpusStore
                    ->load({repository_root => $ROOT});
            });
            1;
        };
        $phase_error = $@;
    }
    my $wall_finished = clock_gettime(CLOCK_MONOTONIC);
    my @cpu_after = times;
    my $sample_status = finish_sample($sampler_pid, $sample->{absolute_path});
    die $phase_error unless $phase_ok;

    my $after = run_independent_verifier();
    die "current corpus changed during canonicalization measurement\n"
        unless $JSON->encode($after) eq $JSON->encode($before);

    my $output_bytes = $JSON->encode($phase_value);
    if ($options->{phase} eq 'balanced-validation') {
        my $expected = $JSON->encode($balanced_report);
        die "balanced validation instrumentation changed the returned report\n"
            unless $output_bytes eq $expected;
    }

    my $result = {
        schema => $SCHEMA,
        schema_version => 1,
        phase => $options->{phase},
        instrumentation_revision =>
            'top_level_clone_timing_and_json_pp_underlay_v3',
        repository_relative_only => JSON::PP::true,
        resource_guard => {
            active => JSON::PP::true,
            host_max_percent => 0 +
                $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT},
            process_max_rss_mib => 0 +
                $ENV{FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB},
        },
        corpus_before_after => {
            unchanged => JSON::PP::true,
            inventory_sha256 => $before->{inventory_sha256},
            corpus_identity => $before->{corpus_identity},
            publication_identity => $before->{publication_identity},
            file_count => $before->{summary}{file_count},
            total_bytes => $before->{summary}{total_bytes},
            profile_staging_empty => JSON::PP::true,
            corpus_staging_empty => JSON::PP::true,
        },
        input_artifacts => $input,
        output_value => {
            canonical_bytes => bytes::length($output_bytes),
            canonical_sha256 => sha256_hex($output_bytes),
            exact_value_preserved => JSON::PP::true,
        },
        phase_timing => {
            monotonic_wall_ns => nanoseconds($wall_finished - $wall_started),
            process_user_cpu_ns => nanoseconds($cpu_after[0] - $cpu_before[0]),
            process_system_cpu_ns => nanoseconds($cpu_after[1] - $cpu_before[1]),
        },
        instrumentation => {
            whole_graph_threshold_bytes => $whole_graph_threshold,
            modules => finalized_metrics(),
            timing_is_nested => JSON::PP::true,
            recursive_clone_nodes_are_counted_but_not_individually_timed =>
                JSON::PP::true,
            encoded_bytes_are_exact_new_json_string_bytes => JSON::PP::true,
            heap_allocation_count_available => JSON::PP::false,
        },
        sample => $sample_status,
        interpretation_limits => [
            'wrapper wall times overlap where clone calls canonical encoding',
            'encoded byte totals count newly materialized JSON strings, not heap allocator events',
            'macOS sample footprint values are sampler-reported rounded observations',
            'this characterization does not promote a performance budget, support tier, or capacity limit',
        ],
    };
    emit_result($result);
    return 0;
}

sub usage {
    return <<'USAGE';
Usage:
  scripts/measure_vial_regression_promotion_canonicalization.pl \
    --phase balanced-validation|corpus-load \
    --sample-relative .artifacts/diagnostics/vial-scale/NAME.sample.txt \
    [--sample-seconds 3]
  scripts/measure_vial_regression_promotion_canonicalization.pl --self-test
  scripts/measure_vial_regression_promotion_canonicalization.pl --help

Real phases must run through scripts/run_with_ram_guard.sh. They are read-only,
sample the measured Perl process directly into the repository, and emit one
bounded canonical newline-terminated JSON result on success.
USAGE
}

sub parse_real_options {
    my (@arguments) = @_;
    my %options;
    while (@arguments) {
        my $name = shift @arguments;
        die usage() unless $name eq '--phase'
            || $name eq '--sample-relative'
            || $name eq '--sample-seconds';
        die usage() unless @arguments;
        my $value = shift @arguments;
        die usage() if exists $options{substr($name, 2) =~ s/-/_/gr};
        $options{substr($name, 2) =~ s/-/_/gr} = $value;
    }
    die usage() unless defined($options{phase})
        && defined($options{sample_relative});
    die usage() unless $options{phase} eq 'balanced-validation'
        || $options{phase} eq 'corpus-load';
    $options{sample_seconds} //= 3;
    die usage() unless $options{sample_seconds} =~ /\A[1-9][0-9]*\z/
        && $options{sample_seconds} <= 10;
    return \%options;
}

sub require_active_guard {
    die "canonicalization measurement requires the repository RAM guard\n"
        unless ($ENV{FSMGEN_RAM_GUARD_ACTIVE} // '') eq '1';
    for my $name (qw(
        FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT
        FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB
    )) {
        die "canonicalization measurement has an invalid RAM guard\n"
            unless ($ENV{$name} // '') =~ /\A[0-9]+(?:[.][0-9]+)?\z/;
    }
}

sub prepare_sample_path {
    my ($relative) = @_;
    die "sample path must be repository-relative and closed\n"
        unless defined($relative)
            && $relative =~ m{\A\Q$SAMPLE_BASE\E/[A-Za-z0-9][A-Za-z0-9._-]*[.]sample[.]txt\z};
    my $absolute = File::Spec->catfile($ROOT, split m{/}, $relative);
    die "sample destination already exists\n" if -e $absolute || -l $absolute;
    my $parent = dirname($absolute);
    my $expected_parent = File::Spec->catdir($ROOT, split m{/}, $SAMPLE_BASE);
    die "sample destination parent is unavailable\n"
        unless -d $parent && !-l $parent
            && realpath($parent) eq realpath($expected_parent);
    my @root_stat = stat($ROOT);
    my @parent_stat = stat($parent);
    die "sample destination is not on the repository volume\n"
        unless @root_stat && @parent_stat && $root_stat[0] == $parent_stat[0];
    die "sample destination has a foreign owner\n"
        unless $root_stat[4] == $parent_stat[4] && $parent_stat[4] == $<;
    return {relative_path => $relative, absolute_path => $absolute};
}

sub run_independent_verifier {
    my ($input, $output);
    my $error = gensym;
    my $pid = open3($input, $output, $error, $^X, $VERIFIER);
    close $input or die "cannot close verifier input\n";
    local $/;
    my $stdout = <$output> // '';
    my $stderr = <$error> // '';
    close $output or die "cannot close verifier output\n";
    close $error or die "cannot close verifier diagnostic pipe\n";
    waitpid($pid, 0) == $pid or die "cannot wait for corpus verifier\n";
    die "independent corpus verifier failed: $stderr"
        unless $? == 0 && $stderr eq '';
    die "independent corpus verifier result is unbounded\n"
        unless bytes::length($stdout) <= 65_536;
    my $decoded = eval { $JSON->decode($stdout) };
    die "independent corpus verifier result is invalid\n"
        if $@ || ref($decoded) ne 'HASH'
            || $stdout ne $JSON->encode($decoded) . "\n";
    return $decoded;
}

sub phase_input {
    my ($phase, $census) = @_;
    if ($phase eq 'corpus-load') {
        return {
            artifact_count => $census->{summary}{file_count},
            bytes => $census->{summary}{total_bytes},
            identity_kind => 'complete_inventory_sha256',
            identity => $census->{inventory_sha256},
        };
    }
    my @balanced = grep {
        $_->{relative_path} =~ m{\Aprofiles/11-[^/]+/measurement-report[.]json\z}
    } @{$census->{files}};
    die "independent census has no unique balanced profile artifact\n"
        unless @balanced == 1;
    return {
        artifact_count => 1,
        bytes => $balanced[0]{bytes},
        identity_kind => 'artifact_sha256',
        identity => $balanced[0]{sha256},
        relative_path => $balanced[0]{relative_path},
    };
}

sub start_sample {
    my ($path, $seconds) = @_;
    my $target_pid = $$;
    my $pid = fork();
    die "cannot fork macOS sample process\n" unless defined $pid;
    return $pid if $pid;
    open STDOUT, '>', File::Spec->devnull
        or POSIX::_exit(126);
    open STDERR, '>', File::Spec->devnull
        or POSIX::_exit(126);
    if (!exec '/usr/bin/sample', $target_pid, $seconds, 1, '-file', $path) {
        POSIX::_exit(127);
    }
}

sub finish_sample {
    my ($pid, $path) = @_;
    waitpid($pid, 0) == $pid or die "cannot wait for macOS sample process\n";
    die "macOS sample process failed\n" unless $? == 0;
    my @stat = lstat($path);
    die "macOS sample output is not one owned regular file\n"
        unless @stat && -f _ && !-l _ && $stat[3] == 1 && $stat[4] == $<;
    my @root_stat = stat($ROOT);
    die "macOS sample output left the repository volume\n"
        unless @root_stat && $stat[0] == $root_stat[0];
    die "macOS sample output is empty or unbounded\n"
        unless $stat[7] > 0 && $stat[7] <= $SAMPLE_MAX_BYTES;
    my $bytes = read_bounded($path, $SAMPLE_MAX_BYTES);
    my ($footprint) = $bytes =~ /^Physical footprint:\s*(.+)$/m;
    my ($peak) = $bytes =~ /^Physical footprint \(peak\):\s*(.+)$/m;
    return {
        relative_path => File::Spec->abs2rel($path, $ROOT),
        bytes => bytes::length($bytes),
        sha256 => sha256_hex($bytes),
        physical_footprint_reported => $footprint,
        physical_footprint_peak_reported => $peak,
        maximum_bytes => $SAMPLE_MAX_BYTES,
    };
}

sub read_bounded {
    my ($path, $maximum) = @_;
    open my $handle, '<:raw', $path or die "cannot open bounded artifact\n";
    my $content = '';
    while (1) {
        my $read = read($handle, my $chunk, 65_536);
        die "cannot read bounded artifact\n" unless defined $read;
        last if $read == 0;
        $content .= $chunk;
        die "bounded artifact exceeded its ceiling\n"
            if bytes::length($content) > $maximum;
    }
    close $handle or die "cannot close bounded artifact\n";
    return $content;
}

sub instrumentable_fsm_packages {
    my %packages;
    for my $inc (keys %INC) {
        next unless $inc =~ m{\AFSM/(.+)[.]pm\z};
        my $package = "FSM::$1";
        $package =~ s{/}{::}g;
        $packages{$package} = 1;
    }
    return [sort keys %packages];
}

sub with_instrumentation {
    my ($packages, $callback) = @_;
    %metrics = ();
    %clone_depth = ();
    @canonical_context = ();
    @clone_context = ();
    my @bindings;
    no strict 'refs';
    for my $package (@{$packages}) {
        for my $operation (qw(_canonical_json _clone sha256_hex)) {
            my $symbol = "${package}::${operation}";
            my $original = *{$symbol}{CODE};
            next unless $original;
            my $replacement =
                instrumented_wrapper($package, $operation, $original);
            my $prototype = prototype($original);
            set_prototype($prototype, $replacement) if defined $prototype;
            push @bindings, [
                $symbol, $replacement,
            ];
        }
    }
    my $json_original = *{'JSON::PP::encode'}{CODE}
        // die "JSON::PP::encode is unavailable\n";
    my $json_replacement = instrumented_json_encoder($json_original);
    my $json_prototype = prototype($json_original);
    set_prototype($json_prototype, $json_replacement)
        if defined $json_prototype;
    push @bindings, [
        'JSON::PP::encode', $json_replacement,
    ];
    return install_bindings(\@bindings, $callback);
}

sub install_bindings {
    my ($bindings, $callback) = @_;
    my @originals;
    no strict 'refs';
    no warnings 'redefine';
    for my $binding (@{$bindings}) {
        my ($symbol, $replacement) = @{$binding};
        my $original = *{$symbol}{CODE}
            // die "instrumentation target disappeared: $symbol\n";
        push @originals, [$symbol, $original];
        *{$symbol} = $replacement;
    }
    my ($ok, $value, $error);
    {
        local $@;
        $ok = eval {
            $value = $callback->();
            1;
        };
        $error = $@;
    }
    for my $binding (reverse @originals) {
        my ($symbol, $original) = @{$binding};
        *{$symbol} = $original;
    }
    die $error unless $ok;
    return $value;
}

sub instrumented_wrapper {
    my ($package, $operation, $original) = @_;
    return sub {
        my @arguments = @_;
        if ($operation eq '_clone' && ($clone_depth{$package} // 0) > 0) {
            my $entry = metric_entry($package, 'clone');
            $entry->{calls}++;
            $entry->{recursive_node_calls}++;
            return $original->(@arguments);
        }
        my $started = clock_gettime(CLOCK_MONOTONIC);
        my ($ok, $value, $error);
        if ($operation eq '_canonical_json') {
            push @canonical_context, $package;
        } elsif ($operation eq '_clone') {
            push @clone_context, $package;
            $clone_depth{$package}++;
        }
        {
            local $@;
            $ok = eval {
                $value = $original->(@arguments);
                1;
            };
            $error = $@;
        }
        pop @canonical_context if $operation eq '_canonical_json';
        if ($operation eq '_clone') {
            $clone_depth{$package}--;
            pop @clone_context;
        }
        my $entry = metric_entry($package, operation_name($operation));
        my $elapsed_ns = nanoseconds(
            clock_gettime(CLOCK_MONOTONIC) - $started,
        );
        $entry->{calls}++;
        $entry->{wall_ns} += $elapsed_ns;
        $entry->{failures}++ unless $ok;
        if ($operation eq '_clone') {
            $entry->{top_level_calls}++;
            $entry->{top_level_wall_ns} += $elapsed_ns;
            $entry->{recursive_node_calls} //= 0;
        }
        if ($operation eq 'sha256_hex') {
            my $measured = 0;
            my $unavailable = 0;
            for my $argument (@arguments) {
                if (defined($argument) && !ref($argument)) {
                    $measured += bytes::length($argument);
                } else {
                    $unavailable = 1;
                }
            }
            $entry->{input_bytes} += $measured;
            $entry->{input_byte_measurement_unavailable_calls}++
                if $unavailable;
        }
        die $error unless $ok;
        return $value;
    };
}

sub instrumented_json_encoder {
    my ($original) = @_;
    return sub {
        my @arguments = @_;
        my $value = $original->(@arguments);
        my $length = bytes::length($value);
        if (@canonical_context) {
            record_encoded_bytes(
                metric_entry($canonical_context[-1], 'canonical_encode'),
                $length,
            );
        }
        if (@clone_context) {
            record_encoded_bytes(
                metric_entry($clone_context[-1], 'clone'), $length,
            );
        }
        return $value;
    };
}

sub operation_name {
    my ($operation) = @_;
    return 'canonical_encode' if $operation eq '_canonical_json';
    return 'clone' if $operation eq '_clone';
    return 'sha256_hex';
}

sub metric_entry {
    my ($package, $operation) = @_;
    return $metrics{$package}{$operation} //= {
        calls => 0,
        failures => 0,
        wall_ns => 0,
    };
}

sub record_encoded_bytes {
    my ($entry, $length) = @_;
    $entry->{json_encode_calls}++;
    $entry->{encoded_bytes} += $length;
    $entry->{maximum_encoded_bytes} = $length
        if !defined($entry->{maximum_encoded_bytes})
            || $length > $entry->{maximum_encoded_bytes};
    my $bucket = $length < 1_024 ? 'lt_1_kib'
        : $length < 65_536 ? '1_kib_to_lt_64_kib'
        : $length < 1_048_576 ? '64_kib_to_lt_1_mib'
        : 'ge_1_mib';
    $entry->{encoded_size_buckets}{$bucket}{calls}++;
    $entry->{encoded_size_buckets}{$bucket}{bytes} += $length;
    if ($length >= $whole_graph_threshold) {
        $entry->{whole_graph_encode_calls}++;
        $entry->{whole_graph_encoded_bytes} += $length;
    }
}

sub finalized_metrics {
    my @result;
    for my $package (sort keys %metrics) {
        my %operations;
        for my $operation (sort keys %{$metrics{$package}}) {
            my %entry = %{$metrics{$package}{$operation}};
            next unless $entry{calls} || ($entry{json_encode_calls} // 0);
            $entry{json_encode_calls} //= 0
                if $operation ne 'sha256_hex';
            $entry{encoded_bytes} //= 0
                if $operation ne 'sha256_hex';
            $entry{maximum_encoded_bytes} //= 0
                if $operation ne 'sha256_hex';
            $entry{whole_graph_encode_calls} //= 0
                if $operation ne 'sha256_hex';
            $entry{whole_graph_encoded_bytes} //= 0
                if $operation ne 'sha256_hex';
            $entry{encoded_size_buckets} //= {}
                if $operation ne 'sha256_hex';
            $operations{$operation} = \%entry;
        }
        push @result, {module => $package, operations => \%operations}
            if keys %operations;
    }
    return \@result;
}

sub nanoseconds {
    my ($seconds) = @_;
    return int($seconds * 1_000_000_000 + 0.5);
}

sub run_self_test {
    $whole_graph_threshold = 8;
    my $input = {alpha => [1, 2, 3], beta => 'payload'};
    my $expected = $JSON->encode($input);
    my $prototype_before = prototype(
        \&FSM::VIAL::CanonicalizationInstrumentationSelfTest::sha256_hex,
    );
    my ($clone, $canonical, $digest);
    with_instrumentation(
        ['FSM::VIAL::CanonicalizationInstrumentationSelfTest'],
        sub {
            $clone = FSM::VIAL::CanonicalizationInstrumentationSelfTest::_clone(
                $input,
            );
            $canonical =
                FSM::VIAL::CanonicalizationInstrumentationSelfTest::_canonical_json(
                    $input,
                );
            $digest =
                FSM::VIAL::CanonicalizationInstrumentationSelfTest::sha256_hex(
                    $canonical,
                );
            return 1;
        },
    );
    die "instrumentation self-test changed a clone\n"
        unless $JSON->encode($clone) eq $expected;
    die "instrumentation self-test changed canonical bytes\n"
        unless $canonical eq $expected;
    die "instrumentation self-test changed SHA-256\n"
        unless $digest eq sha256_hex($expected);
    my $prototype_after = prototype(
        \&FSM::VIAL::CanonicalizationInstrumentationSelfTest::sha256_hex,
    );
    die "instrumentation self-test changed a prototype\n"
        unless ($prototype_before // '') eq ($prototype_after // '')
            && ($prototype_after // '') eq ';@';
    return {
        schema => $SELF_TEST_SCHEMA,
        schema_version => 1,
        exact_values_preserved => JSON::PP::true,
        prototypes_preserved => JSON::PP::true,
        canonical_bytes => bytes::length($expected),
        canonical_sha256 => sha256_hex($expected),
        modules => finalized_metrics(),
        result_ceiling_bytes => $RESULT_MAX_BYTES,
    };
}

sub emit_result {
    my ($result) = @_;
    my $bytes = $JSON->encode($result) . "\n";
    die "canonicalization measurement result exceeded its ceiling\n"
        if bytes::length($bytes) > $RESULT_MAX_BYTES;
    print $bytes;
}

package FSM::VIAL::CanonicalizationInstrumentationSelfTest;

my $SELF_TEST_JSON;
BEGIN { $SELF_TEST_JSON = JSON::PP->new->canonical(1)->utf8(1) }

sub _canonical_json {
    return $SELF_TEST_JSON->encode($_[0]);
}

sub _clone {
    return $SELF_TEST_JSON->decode($SELF_TEST_JSON->encode($_[0]));
}

sub sha256_hex (;@) {
    return Digest::SHA::sha256_hex(@_);
}

1;
