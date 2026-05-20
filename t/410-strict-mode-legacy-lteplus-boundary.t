#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(run);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use Lispish;
use FSM::Pipeline::HDLGenerator;
use FSM::Pipeline::SourceFrontend;

my $tempdir = tempdir(CLEANUP => 1);
my $libdir = File::Spec->catdir($tempdir, 'strict_lteplus_lib');
mkdir $libdir or die "Cannot create $libdir: $!";

my $legacy_pair_path = File::Spec->catfile($tempdir, 'strict_legacy_lteplus_pair.fsm');
my $legacy_pair_out_path = File::Spec->catfile($tempdir, 'strict_legacy_lteplus_pair.sv');
my $legacy_infix_path = File::Spec->catfile($tempdir, 'strict_legacy_lteplus_infix.fsm');
my $preferred_pair_path = File::Spec->catfile($tempdir, 'strict_preferred_lteminus_pair.fsm');
my $preferred_pair_out_path = File::Spec->catfile($tempdir, 'strict_preferred_lteminus_pair.sv');
my $child_top_path = File::Spec->catfile($tempdir, 'strict_lteplus_child_top.fsm');
my $child_out_path = File::Spec->catfile($tempdir, 'strict_lteplus_child_top.sv');
my $child_path = File::Spec->catfile($libdir, 'child_lteplus_dt.fsm');

write_file(
    $legacy_pair_path,
    <<'FSM'
(?fsm:strict_legacy_lteplus_pair
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (D_IN 8)
    (NEXT_VALUE 8)
  )
  (idle
    (<=+ (D_IN NEXT_VALUE))
  )
)
FSM
);

write_file(
    $legacy_infix_path,
    <<'FSM'
(?fsm:strict_legacy_lteplus_infix
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (D_IN 8)
    (NEXT_VALUE 8)
  )
  (idle
    (D_IN <=+ NEXT_VALUE)
  )
)
FSM
);

write_file(
    $preferred_pair_path,
    <<'FSM'
(?fsm:strict_preferred_lteminus_pair
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (D_IN 8)
    (NEXT_VALUE 8)
  )
  (idle
    (<=- (D_IN NEXT_VALUE))
  )
)
FSM
);

write_file(
    $child_top_path,
    <<'FSM'
(?top:strict_lteplus_child_top
  (?ports:public_io
    data_in<8
    result_data>8
  )
  (?dtc:router child_lteplus_dt)
)
FSM
);

write_file(
    $child_path,
    <<'FSM'
(?dt:child_lteplus_dt
  (+size
    (data_in 8)
    (result_data 8)
  )
  (-route
    (<=+ (result_data> data_in))
  )
)
FSM
);

subtest 'default mode keeps legacy <=+ compatibility' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($legacy_pair_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_legacy_lteplus_pair\b/s,
        'default-mode pipeline still compiles legacy <=+ pair syntax',
    );
};

subtest 'strict mode accepts preferred <=- pair form' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );
    my $result = $pipeline->generate_hdl_from_file($preferred_pair_path);

    like(
        $result->{hdl_code},
        qr/\bmodule\s+strict_preferred_lteminus_pair\b/s,
        'strict-mode pipeline compiles preferred <=- pair syntax',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $preferred_pair_out_path, $preferred_pair_path],
    );

    ok($success, 'CLI strict mode accepts preferred <=- pair syntax');
    ok(-e $preferred_pair_out_path, 'CLI strict mode emits HDL for preferred <=- pair syntax');
};

subtest 'shared frontend strict boundary rejects legacy <=+ pair assignments' => sub {
    my $raw_ast = Lispish::multi($legacy_pair_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $legacy_pair_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects legacy '<=\+' assignment '\(<\=\+ \(D_IN NEXT_VALUE\)\)' in source '\Q$legacy_pair_path\E'.*Use the preferred '<=-' pair form '\(<\=- \(D_IN NEXT_VALUE\)\)'.*'<=\+' compatibility/s,
        'shared frontend gives the preferred <=- migration hint for legacy pair syntax',
    );
};

subtest 'shared frontend strict boundary rejects legacy <=+ infix assignments specifically' => sub {
    my $raw_ast = Lispish::multi($legacy_infix_path);

    my $error = eval {
        FSM::Pipeline::SourceFrontend->enforce_strict_source_boundary(
            raw_ast => $raw_ast,
            strict_mode => 1,
            source_label => $legacy_infix_path,
        );
        undef;
    };
    $error = $@ if !$error;

    like(
        $error,
        qr/Strict mode rejects legacy '<=\+' assignment '\(D_IN <=\+ NEXT_VALUE\)' in source '\Q$legacy_infix_path\E'.*Use the preferred '<=-' pair form '\(<\=- \(D_IN NEXT_VALUE\)\)'/s,
        'legacy <=+ infix syntax gets the <=- support-tier diagnostic, not the generic infix diagnostic',
    );
};

subtest 'strict pipeline and CLI reject legacy <=+ before HDL emission' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($legacy_pair_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$legacy_pair_path\E'.*Strict mode rejects legacy '<=\+' assignment '\(<\=\+ \(D_IN NEXT_VALUE\)\)'.*Use the preferred '<=-' pair form '\(<\=- \(D_IN NEXT_VALUE\)\)'/s,
        'strict pipeline keeps source-file context around the legacy <=+ boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '-o', $legacy_pair_out_path, $legacy_pair_path],
    );

    ok(!$success, 'CLI strict mode rejects legacy <=+ assignments');
    ok(!-e $legacy_pair_out_path, 'CLI strict mode does not emit HDL for legacy <=+ assignments');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$legacy_pair_path\E'.*Strict mode rejects legacy '<=\+' assignment '\(<\=\+ \(D_IN NEXT_VALUE\)\)'.*Use the preferred '<=-' pair form '\(<\=- \(D_IN NEXT_VALUE\)\)'/s,
        'CLI strict mode surfaces the same legacy <=+ support-tier boundary',
    );
};

subtest 'strict mode also rejects external generated children that use legacy <=+' => sub {
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
        strict_mode => 1,
        source_search_paths => [$libdir],
    );

    my $pipeline_error = eval {
        $pipeline->generate_hdl_from_file($child_top_path);
        undef;
    };
    $pipeline_error = $@ if !$pipeline_error;

    like(
        $pipeline_error,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?dtc' 'child_lteplus_dt'.*Strict mode rejects legacy '<=\+' assignment '\(<\=\+ \(result_data> data_in\)\)'.*Use the preferred '<=-' pair form '\(<\=- \(result_data> data_in\)\)'/s,
        'strict pipeline keeps child-source context around the legacy <=+ boundary',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--quiet', '--path', $libdir, '-o', $child_out_path, $child_top_path],
    );

    ok(!$success, 'CLI strict mode rejects generated children that use legacy <=+');
    ok(!-e $child_out_path, 'CLI strict mode does not emit HDL for generated children that use legacy <=+');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Source file:\s+'\Q$child_path\E'.*Parent composition source:\s+'\Q$child_top_path\E'.*Generated child source:\s+'\?dtc' 'child_lteplus_dt'.*Strict mode rejects legacy '<=\+' assignment '\(<\=\+ \(result_data> data_in\)\)'.*Use the preferred '<=-' pair form '\(<\=- \(result_data> data_in\)\)'/s,
        'CLI strict mode surfaces the same child-source legacy <=+ boundary',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
