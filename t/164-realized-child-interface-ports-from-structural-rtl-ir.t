#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Composition::InterfacePortBuilder;
use FSM::Pipeline::HDLGenerator;

my $tempdir = tempdir(CLEANUP => 1);

subtest 'realized generated child interface ports now mirror structural_rtl_ir boundary ports' => sub {
    my $composition_path = write_fsm('realized_child_interface_ports_from_structural_ir_top.fsm', <<'FSM');
(?top:realized_child_interface_ports_from_structural_ir_top
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
    (asreset rstn)
  )
  (+size
    (select 1)
    (output_data 8)
  )
  (IDLE
    (<select==1'b0
      (output_data> <= 8'1)
    )
  )
  (ACTIVE
    (<select==1'b1
      (output_data> <= 8'2)
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
    (OUT = IN_A)
  )
  (-from_a
    (OUT = A)
  )
  (-from_b
    (OUT = B)
  )
)
FSM

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
        debug_level => 0,
        quiet => 1,
    );

    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my ($producer, $router) = @{$result->{composition_plan}->instances};

    is_deeply(
        normalize_interface_ports($producer->interface_ports),
        normalize_structural_ports($producer->module_info->{structural_rtl_ir}),
        'realized fsm child interface ports mirror structural_rtl_ir boundary ports',
    );
    is_deeply(
        normalize_interface_ports(
            FSM::Composition::InterfacePortBuilder->build_realized_child_interface_ports($producer->module_info)
        ),
        normalize_interface_ports($producer->interface_ports),
        'realized fsm child interface ports come from the extracted composition interface-port builder',
    );
    is_deeply(
        normalize_interface_ports($router->interface_ports),
        normalize_structural_ports($router->module_info->{structural_rtl_ir}),
        'realized dt child interface ports mirror structural_rtl_ir boundary ports',
    );
    is_deeply(
        normalize_interface_ports(
            FSM::Composition::InterfacePortBuilder->build_realized_child_interface_ports($router->module_info)
        ),
        normalize_interface_ports($router->interface_ports),
        'realized dt child interface ports come from the extracted composition interface-port builder',
    );
};

done_testing();

sub normalize_interface_ports {
    my ($ports) = @_;
    return [
        map {
            +{
                name => $_->name,
                direction => $_->direction,
                width => $_->width,
                type => $_->type,
            }
        } sort {
            $a->name cmp $b->name
        } @{$ports || []}
    ];
}

sub normalize_structural_ports {
    my ($structural_rtl_ir) = @_;
    return [
        map {
            my $type = $_->{type};
            $type = undef if defined($type) && ($type eq 'wire' || $type eq 'logic');
            +{
                name => $_->{name},
                direction => $_->{direction},
                width => $_->{width},
                type => $type,
            }
        } sort {
            $a->{name} cmp $b->{name}
        } @{$structural_rtl_ir->{ports} || []}
    ];
}

sub write_fsm {
    my ($filename, $content) = @_;
    my $path = File::Spec->catfile($tempdir, $filename);
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
    return $path;
}
