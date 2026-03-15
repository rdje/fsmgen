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
use FSM::Adapter::FSMGenFull;
use FSM::Composition::Parser;
use FSM::Pipeline::HDLGenerator;
use FSM::SourceClassifier;

my $tempdir = tempdir(CLEANUP => 1);
my $bad_fsm_path = File::Spec->catfile($tempdir, 'bad_fsm_name.fsm');
my $bad_fsm_out_path = File::Spec->catfile($tempdir, 'bad_fsm_name.sv');
my $bad_top_path = File::Spec->catfile($tempdir, 'bad_top_name.fsm');
my $bad_top_out_path = File::Spec->catfile($tempdir, 'bad_top_name.sv');
my $bad_embedded_path = File::Spec->catfile($tempdir, 'bad_embedded_fsm_name.fsm');
my $bad_embedded_out_path = File::Spec->catfile($tempdir, 'bad_embedded_fsm_name.sv');

write_file(
    $bad_fsm_path,
    <<'FSM'
(?fsm:bad-name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
FSM
);

write_file(
    $bad_top_path,
    <<'TOP'
(?top:bad-name
  (?ports)
)
TOP
);

write_file(
    $bad_embedded_path,
    <<'TOP'
(?top:good_top
  (?ports)
  (?fsmc:child bad-name)
)
(?fsm:bad-name
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-dt
    (A = 1)
  )
)
TOP
);

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    quiet => 1,
);

subtest 'malformed ?fsm root names are rejected explicitly instead of truncating' => sub {
    my $raw_ast = Lispish::multi($bad_fsm_path);
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    is($source_info->{kind}, 'fsm', 'classifier still recognizes the malformed tagged header as an FSM source kind');
    is($source_info->{header}, '?fsm:bad-name', 'classifier preserves the malformed FSM header verbatim');

    my $adapter = FSM::Adapter::FSMGenFull->new(debug => 0);
    my $adapter_exception = eval {
        $adapter->parse_fsm($raw_ast);
        undef;
    };
    $adapter_exception = $@;

    like(
        $adapter_exception,
        qr/Malformed top-level FSM source '\?fsm:bad-name'/,
        'FSM-only parser rejects malformed ?fsm root names explicitly',
    );
    unlike(
        $adapter_exception,
        qr/\bbad\b.*Parsing FSM module/s,
        'FSM-only parser no longer truncates the malformed ?fsm source name to the valid prefix',
    );

    my $pipeline_exception = eval {
        $pipeline->generate_hdl_from_file($bad_fsm_path);
        undef;
    };
    $pipeline_exception = $@;

    like(
        $pipeline_exception,
        qr/Malformed top-level FSM source '\?fsm:bad-name'/,
        'pipeline surfaces the malformed ?fsm root-name boundary clearly',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $bad_fsm_out_path, '--quiet', $bad_fsm_path],
    );

    ok(!$success, 'CLI rejects malformed ?fsm root names');
    ok(!-e $bad_fsm_out_path, 'CLI does not emit HDL output for malformed ?fsm root names');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Malformed top-level FSM source '\?fsm:bad-name'/,
        'CLI surfaces the malformed ?fsm root-name boundary clearly',
    );
};

subtest 'malformed ?top root names are rejected explicitly instead of truncating' => sub {
    my $raw_ast = Lispish::multi($bad_top_path);
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    is($source_info->{kind}, 'composition', 'classifier still recognizes the malformed tagged header as a composition source kind');
    is($source_info->{header}, '?top:bad-name', 'classifier preserves the malformed composition header verbatim');

    my $parser = FSM::Composition::Parser->new;
    my $parser_exception = eval {
        $parser->parse_source($raw_ast);
        undef;
    };
    $parser_exception = $@;

    like(
        $parser_exception,
        qr/Malformed composition top root '\?top:bad-name'/,
        'composition parser rejects malformed ?top root names explicitly',
    );

    my $pipeline_exception = eval {
        $pipeline->generate_hdl_from_file($bad_top_path);
        undef;
    };
    $pipeline_exception = $@;

    like(
        $pipeline_exception,
        qr/Malformed composition top root '\?top:bad-name'/,
        'pipeline surfaces the malformed ?top root-name boundary clearly',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $bad_top_out_path, '--quiet', $bad_top_path],
    );

    ok(!$success, 'CLI rejects malformed ?top root names');
    ok(!-e $bad_top_out_path, 'CLI does not emit HDL output for malformed ?top root names');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Malformed composition top root '\?top:bad-name'/,
        'CLI surfaces the malformed ?top root-name boundary clearly',
    );
};

subtest 'malformed embedded ?fsm child source names are rejected explicitly' => sub {
    my $raw_ast = Lispish::multi($bad_embedded_path);
    my $source_info = FSM::SourceClassifier::classify_source_ast($raw_ast);
    is($source_info->{kind}, 'composition', 'classifier still treats the malformed embedded-child fixture as a composition source');
    is($source_info->{header}, '?top:good_top', 'classifier preserves the valid outer top header');

    my $parser = FSM::Composition::Parser->new;
    my $parser_exception = eval {
        $parser->parse_source($raw_ast);
        undef;
    };
    $parser_exception = $@;

    like(
        $parser_exception,
        qr/Malformed embedded FSM source '\?fsm:bad-name'/,
        'composition parser rejects malformed embedded ?fsm child source names explicitly',
    );

    my $pipeline_exception = eval {
        $pipeline->generate_hdl_from_file($bad_embedded_path);
        undef;
    };
    $pipeline_exception = $@;

    like(
        $pipeline_exception,
        qr/Malformed embedded FSM source '\?fsm:bad-name'/,
        'pipeline surfaces the malformed embedded ?fsm child-source boundary clearly',
    );

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '-o', $bad_embedded_out_path, '--quiet', $bad_embedded_path],
    );

    ok(!$success, 'CLI rejects malformed embedded ?fsm child source names');
    ok(!-e $bad_embedded_out_path, 'CLI does not emit output for malformed embedded ?fsm child source names');

    my $combined_output = join(
        '',
        @{ $stdout_buf || [] },
        @{ $stderr_buf || [] },
        ($error_message || ''),
    );

    like(
        $combined_output,
        qr/Malformed embedded FSM source '\?fsm:bad-name'/,
        'CLI surfaces the malformed embedded ?fsm child-source boundary clearly',
    );
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
