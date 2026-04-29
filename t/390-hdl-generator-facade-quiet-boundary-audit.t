#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::HDLGeneratorFacadeContract qw(
    build_hdl_generator_facade_contract
    hdl_generator_facade_compatibility_constructor_option_names
    hdl_generator_facade_core_constructor_option_names
    hdl_generator_facade_public_constructor_option_names
);

subtest 'facade contract classifies quiet as compatibility presentation state' => sub {
    my @facade_views = (
        {
            label => 'direct facade contract',
            facade => build_hdl_generator_facade_contract(),
        },
        {
            label => 'in-process capability manifest facade contract',
            facade => build_capability_manifest()->{embedding}{hdl_generator_facade},
        },
    );

    for my $view (@facade_views) {
        my $facade = $view->{facade};
        my $label = $view->{label};

        ok(
            contains_value(
                $facade->{public_constructor_option_names},
                'quiet',
            ),
            "$label keeps quiet accepted as a public constructor option",
        );
        ok(
            contains_value(
                hdl_generator_facade_public_constructor_option_names(),
                'quiet',
            ),
            "$label keeps quiet in the builder-owned public constructor list",
        );
        ok(
            contains_value(
                $facade->{compatibility_constructor_option_names},
                'quiet',
            ),
            "$label places quiet in the compatibility constructor family",
        );
        ok(
            contains_value(
                hdl_generator_facade_compatibility_constructor_option_names(),
                'quiet',
            ),
            "$label keeps quiet in the builder-owned compatibility list",
        );
        ok(
            !contains_value(
                $facade->{core_constructor_option_names},
                'quiet',
            ),
            "$label does not classify quiet as a core runtime constructor option",
        );
        ok(
            !contains_value(
                hdl_generator_facade_core_constructor_option_names(),
                'quiet',
            ),
            "$label keeps quiet out of the builder-owned core runtime list",
        );
        is_deeply(
            $facade->{constructor_option_family_map}{compatibility_constructor_option_names},
            $facade->{compatibility_constructor_option_names},
            "$label grouped constructor family map exposes the compatibility list",
        );
    }
};

subtest 'in-process facade generation stays presentation-silent regardless of quiet' => sub {
    my $source_path = make_direct_fixture();

    my ($loud_result, $loud_stdout, $loud_stderr) = run_facade_with_capture(
        quiet => 0,
        source_path => $source_path,
    );
    my ($quiet_result, $quiet_stdout, $quiet_stderr) = run_facade_with_capture(
        quiet => 1,
        source_path => $source_path,
    );

    is($loud_stdout, '', 'quiet => 0 does not make the in-process facade print progress to stdout');
    is($loud_stderr, '', 'quiet => 0 does not make the in-process facade print progress to stderr');
    is($quiet_stdout, '', 'quiet => 1 keeps the in-process facade stdout silent');
    is($quiet_stderr, '', 'quiet => 1 keeps the in-process facade stderr silent');
    is(
        $loud_result->{module_info}{module_name},
        'facade_quiet_boundary_root',
        'quiet => 0 still returns the expected module result',
    );
    is(
        $quiet_result->{module_info}{module_name},
        'facade_quiet_boundary_root',
        'quiet => 1 still returns the expected module result',
    );
    like(
        $loud_result->{hdl_code},
        qr/\bmodule\s+facade_quiet_boundary_root\b/s,
        'quiet => 0 still emits HDL through the returned result',
    );
    like(
        $quiet_result->{hdl_code},
        qr/\bmodule\s+facade_quiet_boundary_root\b/s,
        'quiet => 1 still emits HDL through the returned result',
    );
};

done_testing();

sub make_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $source_path = File::Spec->catfile($tempdir, 'facade_quiet_boundary_root.fsm');

    write_file(
        $source_path,
        <<'FSM'
(?fsm:facade_quiet_boundary_root
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
  )
)
FSM
    );

    return $source_path;
}

sub run_facade_with_capture {
    my (%args) = @_;
    my $result;
    my ($stdout, $stderr) = capture_streams(sub {
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            debug_level => 0,
            target_language => 'systemverilog',
            strict_mode => 1,
            quiet => $args{quiet},
        );
        $result = $pipeline->generate_hdl_from_file($args{source_path});
    });

    return ($result, $stdout, $stderr);
}

sub capture_streams {
    my ($code_ref) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $stdout_path = File::Spec->catfile($tempdir, 'stdout.txt');
    my $stderr_path = File::Spec->catfile($tempdir, 'stderr.txt');

    open my $saved_stdout, '>&', \*STDOUT or die "Cannot save STDOUT: $!";
    open my $saved_stderr, '>&', \*STDERR or die "Cannot save STDERR: $!";
    open STDOUT, '>', $stdout_path or die "Cannot redirect STDOUT: $!";
    open STDERR, '>', $stderr_path or die "Cannot redirect STDERR: $!";

    my $ok = eval {
        $code_ref->();
        1;
    };
    my $error = $@ unless $ok;

    open STDOUT, '>&', $saved_stdout or die "Cannot restore STDOUT: $!";
    open STDERR, '>&', $saved_stderr or die "Cannot restore STDERR: $!";

    die $error if !$ok;
    return (slurp_file($stdout_path), slurp_file($stderr_path));
}

sub contains_value {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && $value eq $wanted;
    }

    return 0;
}

sub slurp_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
