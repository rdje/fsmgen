#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Pipeline::HDLGenerator;
use FSM::Test::CompositionNets qw(carrier_nets net_name);

subtest 'composition generation separates module_info lowered summaries from embedded lowered_rtl_ir mirrors' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'composition_module_info_lowered_ir_alias_top.fsm');
    write_file(
        $composition_path,
        <<'FSM'
(?top:composition_module_info_lowered_ir_alias_top
  (?ports:public_io
    clk
    rstn
    select
    data_a<8
    data_b<8
    result_data>8
  )
  (?fsmc:producer producer_src)
  (?dtc:router route_src)
  (?wiring:wiring
    /select/producer.select/
    /producer.output_data/router.IN_A/
    /data_a/router.A/
    /data_b/router.B/
    /router.OUT/result_data/
  )
)

(?fsm:producer_src
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

(?dt:route_src
  (+size
    (IN_A 8)
    (A 8)
    (B 8)
    (OUT 8)
  )
  (-from_in_a
    (= (OUT IN_A))
  )
  (-from_a
    (= (OUT A))
  )
  (-from_b
    (= (OUT B))
  )
)
FSM
    );

    my $result = generate_result($composition_path);
    my $module_info = $result->{module_info};

    for my $key (qw(internal_net_names instance_names)) {
        is_deeply(
            $module_info->{$key},
            $module_info->{lowered_rtl_ir}{$key},
            "$key starts equivalent to its embedded lowered_rtl_ir mirror",
        );
        isnt(
            refaddr($module_info->{$key}),
            refaddr($module_info->{lowered_rtl_ir}{$key}),
            "$key does not reuse its embedded lowered_rtl_ir container",
        );
    }

    $module_info->{internal_net_names}[0] = 'mutated_summary_net';
    $module_info->{instance_names}[0] = 'mutated_summary_instance';

    is_deeply(
        [map { net_name($_) } @{carrier_nets(map { +{ name => $_ } } @{$module_info->{lowered_rtl_ir}{internal_net_names}})}],
        ['comp_link_producer_output_data'],
        'mutating module_info internal_net_names summary does not contaminate embedded lowered_rtl_ir internal_net_names',
    );
    is_deeply(
        $module_info->{lowered_rtl_ir}{instance_names},
        ['producer', 'router'],
        'mutating module_info instance_names summary does not contaminate embedded lowered_rtl_ir instance_names',
    );

    my $second_result = generate_result($composition_path);
    my $second_module_info = $second_result->{module_info};
    $second_module_info->{lowered_rtl_ir}{internal_net_names}[0] = 'mutated_embedded_net';
    $second_module_info->{lowered_rtl_ir}{instance_names}[0] = 'mutated_embedded_instance';

    is_deeply(
        [map { net_name($_) } @{carrier_nets(map { +{ name => $_ } } @{$second_module_info->{internal_net_names}})}],
        ['comp_link_producer_output_data'],
        'mutating embedded lowered_rtl_ir internal_net_names does not contaminate module_info internal_net_names summary',
    );
    is_deeply(
        $second_module_info->{instance_names},
        ['producer', 'router'],
        'mutating embedded lowered_rtl_ir instance_names does not contaminate module_info instance_names summary',
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

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
