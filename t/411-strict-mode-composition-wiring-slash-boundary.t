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
use FSM::Pipeline::SourceFrontend;

my $tempdir = tempdir(CLEANUP => 1);
my $legacy_path = File::Spec->catfile($tempdir, 'strict_composition_wiring_slash_legacy.fsm');
my $legacy_out_path = File::Spec->catfile($tempdir, 'strict_composition_wiring_slash_legacy.sv');
my $canonical_path = File::Spec->catfile($tempdir, 'strict_composition_wiring_canonical.fsm');
my $canonical_out_path = File::Spec->catfile($tempdir, 'strict_composition_wiring_canonical.sv');
my $verbose_path = File::Spec->catfile($tempdir, 'strict_composition_wiring_verbose.fsm');
my $verbose_out_path = File::Spec->catfile($tempdir, 'strict_composition_wiring_verbose.sv');

write_file(
    $legacy_path,
    composition_source(
        'strict_composition_wiring_slash_legacy',
        '/producer.output_data/consumer.input_data/',
        '/consumer.result_data/result_data/',
    ),
);
write_file(
    $canonical_path,
    composition_source(
        'strict_composition_wiring_canonical',
        '(producer.output_data consumer.input_data)',
        '(consumer.result_data result_data)',
    ),
);
write_file(
    $verbose_path,
    composition_source(
        'strict_composition_wiring_verbose',
        '(connect producer.output_data consumer.input_data)',
        '(connect consumer.result_data result_data)',
    ),
);

subtest 'default mode keeps legacy slash-link compatibility' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($legacy_path);

    is(
        $result->{composition_plan}->top_name,
        'strict_composition_wiring_slash_legacy',
        'default-mode pipeline keeps the slash-link composition top',
    );
    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_composition_wiring_slash_legacy\b/s,
        'default-mode pipeline still emits the top module for slash-link wiring',
    );
    like(
        $result->{hdl_code},
        qr/strict_composition_wiring_producer\s+producer\s*\([^;]*\.output_data\(comp_link_producer_output_data\)/s,
        'default-mode pipeline preserves the legacy slash-link producer route',
    );
    like(
        $result->{hdl_code},
        qr/strict_composition_wiring_consumer\s+consumer\s*\([^;]*\.input_data\(comp_link_producer_output_data\)[^;]*\.result_data\(result_data\)/s,
        'default-mode pipeline preserves the legacy slash-link consumer route',
    );
};

subtest 'strict mode accepts canonical and verbose list-form wiring' => sub {
    for my $case (
        [$canonical_path, $canonical_out_path, 'strict_composition_wiring_canonical', 'canonical list form'],
        [$verbose_path, $verbose_out_path, 'strict_composition_wiring_verbose', 'verbose connect form'],
    ) {
        my ($path, $out_path, $top_name, $label) = @$case;
        my $pipeline = FSM::Pipeline::HDLGenerator->new(
            target_language => 'systemverilog',
            debug_level => 0,
            quiet => 1,
            strict_mode => 1,
        );
        my $result = $pipeline->generate_hdl_from_file($path);

        is($result->{composition_plan}->top_name, $top_name, "strict-mode pipeline accepts $label");
        like($result->{hdl_code}, qr/\bmodule\s+\Q$top_name\E\b/s, "strict-mode pipeline emits HDL for $label");

        my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $out_path, $path],
        );

        ok($success, "CLI strict mode accepts $label");
        ok(-e $out_path, "CLI strict mode emits HDL for $label");
    }
};

subtest 'shared frontend strict boundary rejects legacy slash-link wiring' => sub {
    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file => $legacy_path,
        debug_level => 0,
    );

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $legacy_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects legacy '\?wiring' slash-link token '\/producer\.output_data\/consumer\.input_data\/' in source '\Q$legacy_path\E'.*Use the canonical '\(producer\.output_data consumer\.input_data\)' form or verbose '\(connect producer\.output_data consumer\.input_data\)' form.*'\/source\/target\/' compatibility/s,
        'shared frontend keeps an actionable slash-link migration hint',
    );
};

subtest 'strict pipeline and CLI reject legacy slash-link wiring before HDL emission' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($legacy_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$legacy_path\E'.*Strict mode rejects legacy '\?wiring' slash-link token '\/producer\.output_data\/consumer\.input_data\/'.*Use the canonical '\(producer\.output_data consumer\.input_data\)' form or verbose '\(connect producer\.output_data consumer\.input_data\)' form/s,
        'strict pipeline keeps source-file context around the slash-link boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $legacy_out_path, $legacy_path],
    );

    ok(!$success, 'CLI strict mode rejects legacy slash-link wiring');
    ok(!-e $legacy_out_path, 'CLI strict mode does not emit HDL for legacy slash-link wiring');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$legacy_path\E'.*Strict mode rejects legacy '\?wiring' slash-link token '\/producer\.output_data\/consumer\.input_data\/'.*Use the canonical '\(producer\.output_data consumer\.input_data\)' form or verbose '\(connect producer\.output_data consumer\.input_data\)' form/s,
        'CLI strict mode surfaces the same slash-link boundary',
    );
};

done_testing();

sub composition_source {
    my ($top_name, @wiring_entries) = @_;
    my $wiring_body = join "\n", map { "    $_" } @wiring_entries;
    return <<"FSM";
(?top:$top_name
  (?ports:public_io
    clk
    rst_n
    result_data>8
  )
  (?fsmc:producer strict_composition_wiring_producer)
  (?fsmc:consumer strict_composition_wiring_consumer)
  (?wiring:wiring
$wiring_body
  )
)

(?fsm:strict_composition_wiring_producer
  (+size
    (output_data 8)
  )

  (-drive_outputs
    (= (output_data> 8'hA5))
  )
)

(?fsm:strict_composition_wiring_consumer
  (+size
    (input_data 8)
    (result_data 8)
  )

  (-drive_outputs
    (= (result_data> input_data))
  )
)
FSM
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
