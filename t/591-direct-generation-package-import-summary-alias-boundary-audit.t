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

subtest 'direct generation separates source_info package summaries from raw fsm_module attributes' => sub {
    my $fsm_path = write_package_import_fixture();

    my $result = generate_result($fsm_path);
    is_deeply(
        $result->{source_info}{package_import_names},
        $result->{fsm_module}{attributes}{package_imports},
        'source_info package_import_names starts equivalent to fsm_module package_imports',
    );
    isnt(
        refaddr($result->{source_info}{package_import_names}),
        refaddr($result->{fsm_module}{attributes}{package_imports}),
        'source_info package_import_names does not reuse fsm_module package_imports array',
    );

    push @{$result->{source_info}{package_import_names}}, 'mutated_source_info_import';
    is_deeply(
        $result->{fsm_module}{attributes}{package_imports},
        [qw(shared_local)],
        'mutating source_info package_import_names does not contaminate fsm_module package_imports',
    );

    my $second_result = generate_result($fsm_path);
    push @{$second_result->{fsm_module}{attributes}{package_imports}}, 'mutated_fsm_module_import';
    is_deeply(
        $second_result->{source_info}{package_import_names},
        [qw(shared_local)],
        'mutating fsm_module package_imports does not contaminate source_info package_import_names',
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
    my $fsm_path = File::Spec->catfile($tempdir, 'direct_package_import_summary_alias_top.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:direct_package_import_summary_alias_top
  (+import shared_local)
  (+system
    (clock clk)
    (sreset reset)
  )
  (+size
    (OUT 8)
  )
  (idle
    (OUT = shared_local.RESET_BYTE)
  )
)

(?pkg:shared_local
  (+constants
    (RESET_BYTE 8'hA5)
  )
)
FSM
    );
    return $fsm_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
