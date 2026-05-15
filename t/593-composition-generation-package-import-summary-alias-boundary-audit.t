#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'composition generation separates source_info package summaries from raw composition_spec imports' => sub {
    my $composition_path = write_package_import_fixture();

    my $result = generate_result($composition_path);
    my $top = $result->{composition_spec}->top;
    is_deeply(
        $result->{source_info}{package_import_names},
        $top->package_imports,
        'source_info package_import_names starts equivalent to composition top package_imports',
    );
    isnt(
        refaddr($result->{source_info}{package_import_names}),
        refaddr($top->{package_imports}),
        'source_info package_import_names does not reuse raw composition top package_imports array',
    );

    push @{$result->{source_info}{package_import_names}}, 'mutated_source_info_import';
    is_deeply(
        $top->package_imports,
        [qw(shared_local)],
        'mutating source_info package_import_names does not contaminate composition top package_imports',
    );

    my $second_result = generate_result($composition_path);
    my $second_top = $second_result->{composition_spec}->top;
    push @{$second_top->{package_imports}}, 'mutated_composition_spec_import';
    is_deeply(
        $second_result->{source_info}{package_import_names},
        [qw(shared_local)],
        'mutating raw composition top package_imports does not contaminate source_info package_import_names',
    );
};

done_testing();

sub generate_result {
    my ($path) = @_;
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        quiet => 1,
    );
    return $pipeline->generate_hdl_from_file($path);
}

sub write_package_import_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_package_import_summary_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_package_import_summary_alias_top
  (+import shared_local)
  (?ports:public_io
    shared_out>8
  )
  (?rtl:uart_tx)
  (?wiring:wiring
    /=shared_local.RESET_BYTE/shared_out/
    /=shared_local.RESET_BYTE/uart_tx.data_in/
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
)

(?rtlif:uart_tx
  data_in<8:data
)
FSM
    );
    return $composition_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
