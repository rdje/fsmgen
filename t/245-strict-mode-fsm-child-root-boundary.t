#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);
my $libdir = File::Spec->catdir($tempdir, 'strict_fsm_child_lib');
mkdir $libdir or die "Cannot create $libdir: $!";

my $flat_top_path = File::Spec->catfile($tempdir, 'strict_external_flat_legacy_fsm_child_top.fsm');
my $flat_out_path = File::Spec->catfile($tempdir, 'strict_external_flat_legacy_fsm_child_top.sv');
my $flat_child_path = File::Spec->catfile($libdir, 'flat_child_src.fsm');

my $nested_top_path = File::Spec->catfile($tempdir, 'strict_external_nested_legacy_fsm_child_top.fsm');
my $nested_out_path = File::Spec->catfile($tempdir, 'strict_external_nested_legacy_fsm_child_top.sv');
my $nested_child_path = File::Spec->catfile($libdir, 'nested_child_src.fsm');

write_file(
    $flat_top_path,
    <<'FSM'
(?top:strict_external_flat_legacy_fsm_child_top
  (?ports:public_io
    data_in<1
    data_out>1
  )
  (?fsmc:child flat_child_src)
)
FSM
);

write_file(
    $flat_child_path,
    <<'FSM'
(+fsm flat_child_src)
(+size
  (data_in 1)
  (data_out 1)
)
(idle
  (data_out = data_in)
)
FSM
);

write_file(
    $nested_top_path,
    <<'FSM'
(?top:strict_external_nested_legacy_fsm_child_top
  (?ports:public_io
    data_in<1
    data_out>1
  )
  (?fsmc:child nested_child_src)
)
FSM
);

write_file(
    $nested_child_path,
    <<'FSM'
(+fsm nested_child_src
  (+size
    (data_in 1)
    (data_out 1)
  )
  (idle
    (data_out = data_in)
  )
)
FSM
);

subtest 'strict mode rejects external ?fsmc children rooted at legacy +fsm' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    for my $case (
        [$flat_top_path, $flat_child_path, 'flat_child_src', 'flattened legacy +fsm child root'],
        [$nested_top_path, $nested_child_path, 'nested_child_src', 'nested legacy +fsm child root'],
    ) {
        my ($top_path, $child_path, $source_name, $label) = @$case;

        my $exception = eval {
            $pipeline->generate_hdl_from_file($top_path);
            undef;
        };
        $exception = $@;

        like(
            $exception,
            qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$top_path\E'.*Generated child source:\s+'\?fsmc' '\Q$source_name\E'.*Strict mode rejects the legacy '\+fsm' root family as the root of '\?fsmc' source '\Q$source_name\E'.*Use the canonical '\?fsm:source_name' root form/s,
            "strict mode rejects $label with full child-source context and the canonical ?fsm migration hint",
        );
    }
};

subtest 'CLI strict mode also rejects external ?fsmc children rooted at legacy +fsm' => sub {
    for my $case (
        [$flat_top_path, $flat_out_path, $flat_child_path, 'flat_child_src', 'flattened legacy +fsm child root'],
        [$nested_top_path, $nested_out_path, $nested_child_path, 'nested_child_src', 'nested legacy +fsm child root'],
    ) {
        my ($top_path, $out_path, $child_path, $source_name, $label) = @$case;

        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', '--path', $libdir, '-o', $out_path, $top_path],
        );

        ok(!$success, "CLI strict mode rejects $label");
        ok(!-e $out_path, "CLI strict mode does not emit HDL for $label");

        my $combined_output = join(
            '',
            @{ $stdout_buf || [] },
            @{ $stderr_buf || [] },
            ($error_message || ''),
        );

        like(
            $combined_output,
            qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$top_path\E'.*Generated child source:\s+'\?fsmc' '\Q$source_name\E'.*Strict mode rejects the legacy '\+fsm' root family as the root of '\?fsmc' source '\Q$source_name\E'.*Use the canonical '\?fsm:source_name' root form/s,
            "CLI strict mode surfaces the canonical ?fsm migration hint for $label",
        );
    }
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
