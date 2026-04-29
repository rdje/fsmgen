#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorResultContract qw(build_hdl_generator_result_contract);

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');

subtest 'contracts and manifests keep the raw HDLGenerator result out of the JSON-safe promise' => sub {
    my @views = (
        {
            label => 'direct HDLGenerator result contract',
            result_contract => build_hdl_generator_result_contract(),
            facade_contract => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'in-process capability manifest',
            result_contract => build_capability_manifest()->{embedding}{hdl_generator_result},
            facade_contract => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI capability manifest',
            result_contract => run_capability_manifest('--capability-manifest')->{embedding}{hdl_generator_result},
            facade_contract => run_capability_manifest('--capability-manifest')->{embedding}{hdl_generator_facade},
        },
        {
            label => 'CLI alias capability manifest',
            result_contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{hdl_generator_result},
            facade_contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        ok(
            !$view->{result_contract}{full_result_json_safe},
            "$label says the whole raw result is not JSON-safe",
        );
        is(
            $view->{result_contract}{json_safe_export_surface},
            'semantic_exports.normalized_semantic_json',
            "$label points JSON consumers at normalized semantic JSON",
        );
        ok(
            !$view->{facade_contract}{result_surface_json_safe_as_a_whole},
            "$label facade does not advertise the raw result as JSON-safe",
        );
    }
};

subtest 'real direct and composition results are not JSON-safe as whole raw hashes' => sub {
    my ($direct_path, $composition_path) = make_fixtures();

    my $direct_result = generate_result($direct_path);
    ok(
        contains_blessed($direct_result),
        'direct raw result contains live Perl objects',
    );
    ok(
        !strict_json_encode_ok($direct_result),
        'direct raw result is not strict JSON-encodable as a whole',
    );

    my $composition_result = generate_result($composition_path);
    ok(
        contains_blessed($composition_result),
        'composition raw result contains live Perl objects',
    );
    ok(
        !strict_json_encode_ok($composition_result),
        'composition raw result is not strict JSON-encodable as a whole',
    );
};

subtest 'normalized semantic JSON remains the JSON-safe interchange path' => sub {
    my ($direct_path, $composition_path) = make_fixtures();

    for my $case (
        [direct => $direct_path],
        [composition => $composition_path],
    ) {
        my ($label, $path) = @{$case};
        my $decoded = run_semantic_json($path);

        ok(
            !contains_blessed($decoded),
            "$label semantic JSON has no live Perl objects after decode",
        );
        ok(
            strict_json_encode_ok($decoded),
            "$label semantic JSON decodes and re-encodes as JSON",
        );
        ok(
            exists $decoded->{semantic},
            "$label semantic JSON keeps the public semantic payload",
        );
        ok(
            !exists $decoded->{raw_ast},
            "$label semantic JSON does not expose raw_ast",
        );
        ok(
            !exists $decoded->{fsm_module},
            "$label semantic JSON does not expose fsm_module",
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
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub run_semantic_json {
    my ($path) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
    );

    ok($success, "semantic JSON export succeeds for $path");
    is(join('', @{$stderr_buf || []}), '', "semantic JSON export keeps stderr clean for $path");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub strict_json_encode_ok {
    my ($value) = @_;
    return eval {
        encode_json($value);
        1;
    } ? 1 : 0;
}

sub contains_blessed {
    my ($value) = @_;
    return 0 unless ref($value);
    return 1 if blessed($value) && !JSON::PP::is_bool($value);
    if (ref($value) eq 'HASH') {
        for my $child (values %$value) {
            return 1 if contains_blessed($child);
        }
        return 0;
    }
    if (ref($value) eq 'ARRAY') {
        for my $child (@$value) {
            return 1 if contains_blessed($child);
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
