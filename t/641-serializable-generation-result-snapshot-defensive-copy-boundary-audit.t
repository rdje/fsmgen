#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::SerializableGenerationResultSnapshot qw(
    build_serializable_generation_result_snapshot
    build_serializable_generation_result_snapshot_contract
    serializable_generation_result_snapshot_public_top_level_keys
);

my $sentinel = '__mutated_by_t641__';

subtest 'generation result snapshot contract returns fresh nested containers' => sub {
    my $first = build_serializable_generation_result_snapshot_contract();
    $first->{public_top_level_presence_keys}[0] = $sentinel;
    $first->{summary_keys}[0] = $sentinel;
    push @{$first->{guidance}}, $sentinel;

    my $second = build_serializable_generation_result_snapshot_contract();
    ok(!contains_sentinel($second), 'fresh contract is not polluted by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        serializable_generation_result_snapshot_public_top_level_keys(),
        'fresh contract still advertises the public key list',
    );
};

subtest 'generation result snapshot returns fresh report containers' => sub {
    my $result = generate_direct_result();
    my $first = build_serializable_generation_result_snapshot(result => $result);

    $first->{summary}{module_name} = $sentinel;
    $first->{top_level_keys}[0] = $sentinel;
    $first->{source_summary}{package_import_names}[0] = $sentinel;
    $first->{raw_shell_presence}{raw_ast}{value_ref} = $sentinel;

    my $second = build_serializable_generation_result_snapshot(result => $result);
    ok(!contains_sentinel($second), 'fresh snapshot is not polluted by prior caller mutation');
    is(
        $second->{summary}{module_name},
        'serializable_generation_snapshot_alias_direct',
        'fresh snapshot keeps original module name',
    );
    ok(
        grep { $_ eq 'module_info' } @{$second->{top_level_keys}},
        'fresh snapshot keeps original top-level key list',
    );
    is(
        $second->{raw_shell_presence}{raw_ast}{value_ref},
        'ARRAY',
        'fresh snapshot keeps original raw_ast ref metadata',
    );
};

done_testing();

sub generate_direct_result {
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, 'serializable_generation_snapshot_alias_direct.fsm');
    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:serializable_generation_snapshot_alias_direct
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (<= (output_data> 8'1))
    )
  )
)
FSM
    );

    return FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fsm_path);
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_sentinel($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists $value->{$sentinel};
        return 1 if grep { contains_sentinel($_) } values %$value;
        return 0;
    }

    return 0;
}
