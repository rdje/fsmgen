#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::NormalizedSemanticReport qw(
    build_normalized_semantic_success_report
);

{
    package Test::ResultJsonBoundaryExtension;

    use strict;
    use warnings;

    sub new {
        my ($class) = @_;
        return bless {
            last_parse_kind => undef,
            result_calls => [],
        }, $class;
    }

    sub after_parse_source {
        my ($self, $context) = @_;
        $self->{last_parse_kind} = $context->source_info->{kind};
    }

    sub after_generate_result {
        my ($self, $context) = @_;

        push @{$self->{result_calls}}, {
            stage => $context->stage,
            source_kind => $context->source_info->{kind},
            module_name => $context->result->{module_info}{module_name},
        };

        $context->result->{extension_marker} = {
            marker => 'result_json_boundary_extension',
            source_kind => $context->source_info->{kind},
            parsed_kind => $self->{last_parse_kind},
            target_language => $context->target_language,
        };

        $context->result->{hdl_code} .= "\n// result-json-boundary-extension marker\n"
            if defined $context->result->{hdl_code};
    }

    sub result_calls {
        my ($self) = @_;
        return $self->{result_calls};
    }
}

my $test_lib = File::Spec->catdir($FindBin::Bin, 'lib');
my ($direct_path, $composition_path) = make_fixtures();

subtest 'in-process extension result augmentation stays available on the raw result only' => sub {
    for my $case (
        [direct => $direct_path, 'fsm'],
        [composition => $composition_path, 'composition'],
    ) {
        my ($label, $path, $expected_kind) = @{$case};
        my $extension = Test::ResultJsonBoundaryExtension->new;
        my $result = generate_result($path, $extension);

        is(
            $result->{extension_marker}{marker},
            'result_json_boundary_extension',
            "$label raw result keeps extension-added marker",
        );
        is(
            $result->{extension_marker}{source_kind},
            $expected_kind,
            "$label raw result marker sees the source kind",
        );
        like(
            $result->{hdl_code},
            qr{// result-json-boundary-extension marker}s,
            "$label raw HDL result keeps extension-added HDL text",
        );
        is(
            scalar(@{$extension->result_calls}),
            1,
            "$label extension result hook ran once",
        );
        is(
            $extension->result_calls->[0]{stage},
            'after_generate_result',
            "$label extension result hook keeps its typed stage",
        );

        my $report = build_semantic_report($path, $result);
        ok(
            strict_json_encode_ok($report),
            "$label normalized semantic report remains strict JSON-encodable",
        );
        ok(
            exists $report->{semantic},
            "$label normalized semantic report keeps the public semantic payload",
        );
        assert_no_extension_leak(
            $report,
            "$label normalized semantic report",
            [qw(result_json_boundary_extension result-json-boundary-extension)],
        );
    }
};

subtest 'CLI extension modules do not leak raw result augmentation into semantic JSON' => sub {
    for my $case (
        [direct => $direct_path],
        [composition => $composition_path],
    ) {
        my ($label, $path) = @{$case};
        my $decoded = run_cli_semantic_json($path);

        ok($decoded->{success}, "$label semantic JSON export succeeds");
        ok(
            strict_json_encode_ok($decoded),
            "$label semantic JSON decodes and re-encodes as strict JSON",
        );
        ok(
            exists $decoded->{semantic},
            "$label semantic JSON keeps the public semantic payload",
        );
        ok(
            !exists $decoded->{raw_ast},
            "$label semantic JSON does not expose raw parse data",
        );
        assert_no_extension_leak(
            $decoded,
            "$label CLI semantic JSON",
            ['FSM::TestExtension::Marker', 'extension marker: FSM::TestExtension::Marker'],
        );
    }
};

done_testing();

sub make_fixtures {
    my $tempdir = tempdir(CLEANUP => 1);
    my $direct_path = File::Spec->catfile($tempdir, 'json_boundary_direct.fsm');
    my $composition_path = File::Spec->catfile($tempdir, 'json_boundary_top.fsm');

    write_file(
        $direct_path,
        <<'FSM'
(?fsm:json_boundary_direct
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (OUT 1))
  )
  (+size
    (OUT 1)
  )
)
FSM
    );

    write_file(
        $composition_path,
        <<'FSM'
(?top:json_boundary_top
  (?ports:public_io
    clk
    reset
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset reset)
  )
  (-state0
    (<= (output_data> 8'1))
  )
  (+size
    (output_data 8)
  )
)
FSM
    );

    return ($direct_path, $composition_path);
}

sub generate_result {
    my ($path, $extension) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extensions => [$extension],
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub build_semantic_report {
    my ($path, $result) = @_;
    return build_normalized_semantic_success_report(
        input => $path,
        source_file => $path,
        target_language => 'systemverilog',
        strict_mode => 1,
        result => $result,
        module_info => $result->{module_info},
    );
}

sub run_cli_semantic_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            $^X,
            '-I', $test_lib,
            './bin/fsmgen',
            '--strict',
            '--emit-semantic-json',
            '--extension-module', 'FSM::TestExtension::Marker',
            $path,
        ],
    );

    ok($success, "semantic JSON export succeeds for $path");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON export keeps stderr clean for $path");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub assert_no_extension_leak {
    my ($payload, $label, $forbidden_strings) = @_;

    ok(
        !contains_key_recursive($payload, 'extension_marker'),
        "$label does not expose extension_marker as a public key",
    );

    for my $needle (@{$forbidden_strings || []}) {
        ok(
            !contains_string_recursive($payload, $needle),
            "$label does not expose '$needle'",
        );
    }
}

sub strict_json_encode_ok {
    my ($value) = @_;
    return eval {
        encode_json($value);
        1;
    } ? 1 : 0;
}

sub contains_key_recursive {
    my ($value, $target_key) = @_;
    return 0 unless ref($value);

    if (ref($value) eq 'HASH') {
        for my $key (keys %$value) {
            return 1 if $key eq $target_key;
            return 1 if contains_key_recursive($value->{$key}, $target_key);
        }
        return 0;
    }

    if (ref($value) eq 'ARRAY') {
        for my $child (@$value) {
            return 1 if contains_key_recursive($child, $target_key);
        }
        return 0;
    }

    return 0;
}

sub contains_string_recursive {
    my ($value, $needle) = @_;
    return 0 unless defined $value;

    if (!ref($value)) {
        return index($value, $needle) >= 0 ? 1 : 0;
    }

    if (ref($value) eq 'HASH') {
        for my $key (keys %$value) {
            return 1 if index($key, $needle) >= 0;
            return 1 if contains_string_recursive($value->{$key}, $needle);
        }
        return 0;
    }

    if (ref($value) eq 'ARRAY') {
        for my $child (@$value) {
            return 1 if contains_string_recursive($child, $needle);
        }
        return 0;
    }

    return 0;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
