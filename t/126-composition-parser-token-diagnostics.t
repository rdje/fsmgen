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

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
);

subtest 'malformed verbose ?ports declarations now say port-declaration shape is blocked' => sub {
    expect_failure(
        name => 'nested_ports_item_top',
        body => <<'FSM',
(?top:nested_ports_item_top
  (?ports:public_io
    (group
      clk
    )
    result_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
        pipeline_regex => qr/Composition top 'nested_ports_item_top' contains '\?ports' verbose declaration '\(group clk\)', .*composition port declaration shape is blocked because verbose declarations must start with the literal keyword 'input' or 'output'/s,
        cli_regex => qr/composition port declaration shape is blocked because verbose declarations must start with the literal keyword 'input' or 'output'/s,
        cli_failure_name => 'malformed verbose ?ports declarations',
    );
};

subtest 'invalid ?ports tokens now say port token shape is blocked' => sub {
    expect_failure(
        name => 'invalid_ports_token_top',
        body => <<'FSM',
(?top:invalid_ports_token_top
  (?ports:public_io
    bad-name>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
        pipeline_regex => qr/Composition top 'invalid_ports_token_top' contains '\?ports' token 'bad-name>8', .*composition port token shape is blocked because it is not a valid explicit top-port token/s,
        cli_regex => qr/composition port token shape is blocked because it is not a valid explicit top-port token/s,
        cli_failure_name => 'invalid ?ports tokens',
    );
};

subtest 'non-positive ?ports widths now say port sizing is blocked' => sub {
    expect_failure(
        name => 'nonpositive_ports_width_top',
        body => <<'FSM',
(?top:nonpositive_ports_width_top
  (?ports:public_io
    data_in<0
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
        pipeline_regex => qr/Composition top 'nonpositive_ports_width_top' contains '\?ports' token 'data_in<0', .*composition port sizing is blocked because it declares non-positive width '0'/s,
        cli_regex => qr/composition port sizing is blocked because it declares non-positive width '0'/s,
        cli_failure_name => 'non-positive ?ports widths',
    );
};

subtest 'nested ?toplink items now say top-link token flatness is blocked' => sub {
    expect_failure(
        name => 'nested_toplink_item_top',
        body => <<'FSM',
(?top:nested_toplink_item_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:child child_src)
  (?toplink:wiring
    (group
      /child.result_data/result_data/
    )
  )
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
        pipeline_regex => qr/Composition top 'nested_toplink_item_top' contains a nested '\?toplink' item, .*explicit top-link token flatness is blocked because the active composition parser only supports flat '\/source\/target\/' link tokens/s,
        cli_regex => qr/explicit top-link token flatness is blocked because the active composition parser only supports flat '\/source\/target\/' link tokens/s,
        cli_failure_name => 'nested ?toplink items',
    );
};

subtest 'unsupported ?toplink tokens now say top-link token shape is blocked' => sub {
    expect_failure(
        name => 'unsupported_toplink_token_top',
        body => <<'FSM',
(?top:unsupported_toplink_token_top
  (?ports:public_io
    clk
    rstn
    result_data>8
  )
  (?fsmc:child child_src)
  (?toplink:wiring
    child.result_data->result_data
  )
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (result_data> <= 8'1)
  )
  (+size
    (result_data 8)
  )
)
FSM
        pipeline_regex => qr/Composition top 'unsupported_toplink_token_top' contains '\?toplink' token 'child\.result_data->result_data', .*explicit top-link token shape is blocked because the current parser only accepts simple '\/source\/target\/' link forms/s,
        cli_regex => qr/explicit top-link token shape is blocked because the current parser only accepts simple '\/source\/target\/' link forms/s,
        cli_failure_name => 'unsupported ?toplink tokens',
    );
};

subtest 'malformed composition-root +constants entries now say top symbol token shape is blocked' => sub {
    expect_failure(
        name => 'bad_top_constants_top',
        body => <<'FSM',
(?top:bad_top_constants_top
  (+constants
    (bad-name 8'165)
  )
  (?rtl:uart_tx)
)

(?rtlif:uart_tx
  data_in<8:data
)
FSM
        pipeline_regex => qr/Composition top 'bad_top_constants_top' contains malformed '\+constants' entry for constant 'bad-name', .*composition top symbol token shape is blocked because each '\+constants' entry must use an HDL-identifier-compatible name/s,
        cli_regex => qr/composition top symbol token shape is blocked because each '\+constants' entry must use an HDL-identifier-compatible name/s,
        cli_failure_name => 'malformed composition-root +constants entries',
    );
};

subtest 'non-literal composition-root +enums values now say top symbol literal support is blocked' => sub {
    expect_failure(
        name => 'nonscalar_top_enums_top',
        body => <<'FSM',
(?top:nonscalar_top_enums_top
  (+enums
    (mode
      (BUSY unresolved_name)
    )
  )
  (?rtl:uart_tx)
)

(?rtlif:uart_tx
  data_in<8:data
)
FSM
        pipeline_regex => qr/Composition top 'nonscalar_top_enums_top' contains '\+enums' entry for enum member 'mode\.BUSY' with value token 'unresolved_name', .*composition top symbol literal support is blocked because top symbol values currently must resolve to literal scalar values/s,
        cli_regex => qr/composition top symbol literal support is blocked because top symbol values currently must resolve to literal scalar values/s,
        cli_failure_name => 'non-literal composition-root +enums values',
    );
};

done_testing();

sub expect_failure {
    my (%args) = @_;
    my $composition_path = File::Spec->catfile($tempdir, "$args{name}.fsm");
    my $output_path = File::Spec->catfile($tempdir, "$args{name}.sv");

    write_file($composition_path, $args{body});

    my $exception = eval {
        $pipeline->generate_hdl_from_file($composition_path);
        undef;
    };
    $exception = $@;

    like($exception, $args{pipeline_regex}, "pipeline now says $args{cli_failure_name} are blocked explicitly");
    like($exception, qr/docs\/COMPOSITION_SCOPE\.md/s, "pipeline diagnostic for $args{cli_failure_name} points to the scoped composition doc");
    like($exception, qr/docs\/COMPOSITION_LEGACY_MAPPING\.md/s, "pipeline diagnostic for $args{cli_failure_name} points to the legacy mapping note");

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '-o', $output_path, $composition_path],
    );

    ok(!$success, "CLI rejects $args{cli_failure_name}");
    ok(!-e $output_path, "CLI does not emit output for $args{cli_failure_name}");

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like($combined_output, $args{cli_regex}, "CLI surfaces the blocked diagnostic for $args{cli_failure_name}");
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
