#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

subtest 'direct structural_rtl_ir preserves declared type identity on typed +size signals' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $libdir = File::Spec->catdir($tempdir, 'pkg_lib');
    mkdir $libdir or die "Cannot create $libdir: $!";

    my $package_path = File::Spec->catfile($libdir, 'shared_types.fsm');
    my $fsm_path = File::Spec->catfile($tempdir, 'typed_direct_structural_ir.fsm');

    write_file(
        $package_path,
        <<'FSM'
(?pkg:shared_types
  (+types
    (type payload_t (four_state (signed (bits 8))))
  )
)
FSM
    );

    write_file(
        $fsm_path,
        <<'FSM'
(?fsm:typed_direct_structural_ir
  (+import shared_types)
  (+system
    (clock clk)
    (sreset rstn)
  )
  (+types
    (type bit_t bit)
    (type byte_t shared_types.payload_t)
  )
  (+size
    (IN byte_t)
    (OUT byte_t)
    (CTRL bit_t)
  )
  (idle
    (<CTRL
      (OUT = IN)
    )
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
        source_search_paths => [$libdir],
    );
    my $result = $pipeline->generate_hdl_from_file($fsm_path);
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my %ports_by_name = map { $_->{name} => $_ } @{ $structural_rtl_ir->{ports} || [] };

    is($ports_by_name{IN}{declared_type_name}, 'byte_t', 'direct structural port preserves authored local alias name');
    is($ports_by_name{IN}{declared_type_spec}{width}, 8, 'direct structural port preserves resolved declared type width');
    is($ports_by_name{IN}{declared_type_spec}{signed}, 1, 'direct structural port preserves resolved declared type signedness');
    is($ports_by_name{IN}{declared_type_spec}{state_model}, 'four_state', 'direct structural port preserves resolved declared type state model');
    is($ports_by_name{CTRL}{declared_type_name}, 'bit_t', 'direct structural port preserves local bit alias name');
    is($ports_by_name{CTRL}{declared_type_spec}{kind}, 'bit', 'direct structural port preserves local bit alias spec');
    ok(!exists $ports_by_name{clk}{declared_type_name}, 'implicit system ports stay untyped in structural metadata');
};

subtest 'composition structural_rtl_ir preserves declared type identity on top ports and realized child interface ports' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $composition_path = File::Spec->catfile($tempdir, 'typed_composition_structural_ir.fsm');

    write_file(
        $composition_path,
        <<'FSM'
(?top:typed_composition_structural_ir
  (+import shared_types)
  (+types
    (type frame_t (record (tag bit) (payload shared_types.byte_t)))
  )
  (?ports:public_io
    in_byte<shared_types.byte_t
    out_byte>shared_types.byte_t
    in_frame<frame_t
    out_frame>frame_t
  )
  (?dtc:typed_byte typed_byte_src)
  (?dtc:typed_frame typed_frame_src)
  (?toplink:wiring
    /in_byte/typed_byte.IN_BYTE/
    /typed_byte.OUT_BYTE/out_byte/
    /in_frame/typed_frame.IN_FRAME/
    /typed_frame.OUT_FRAME/out_frame/
  )
)

(?dt:typed_byte_src
  (+types
    (type byte_t (four_state (signed (bits 8))))
  )
  (+size
    (IN_BYTE byte_t)
    (OUT_BYTE byte_t)
  )
  (-pass
    (OUT_BYTE = IN_BYTE)
  )
)

(?dt:typed_frame_src
  (+types
    (type byte_t (four_state (signed (bits 8))))
    (type frame_t (record (tag bit) (payload byte_t)))
  )
  (+size
    (IN_FRAME frame_t)
    (OUT_FRAME frame_t)
  )
  (-pass
    (OUT_FRAME = IN_FRAME)
  )
)

(?pkg:shared_types
  (+types
    (type byte_t (four_state (signed (bits 8))))
  )
)
FSM
    );

    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        quiet => 1,
        target_language => 'systemverilog',
    );
    my $result = $pipeline->generate_hdl_from_file($composition_path);
    my $structural_rtl_ir = $result->{structural_rtl_ir};
    my %top_ports_by_name = map { $_->{name} => $_ } @{ $structural_rtl_ir->{ports} || [] };
    my ($byte_instance) = grep { $_->{instance_name} eq 'typed_byte' } @{ $structural_rtl_ir->{instances} || [] };
    my ($frame_instance) = grep { $_->{instance_name} eq 'typed_frame' } @{ $structural_rtl_ir->{instances} || [] };
    my %byte_child_ports_by_name = map { $_->{name} => $_ } @{ $byte_instance->{interface_ports} || [] };
    my %frame_child_ports_by_name = map { $_->{name} => $_ } @{ $frame_instance->{interface_ports} || [] };
    my ($realized_byte_instance) = grep { $_->instance_name eq 'typed_byte' } @{ $result->{composition_plan}->instances || [] };
    my ($realized_frame_instance) = grep { $_->instance_name eq 'typed_frame' } @{ $result->{composition_plan}->instances || [] };
    my %realized_byte_child_ports_by_name = map { $_->name => $_ } @{ $realized_byte_instance->interface_ports || [] };
    my %realized_frame_child_ports_by_name = map { $_->name => $_ } @{ $realized_frame_instance->interface_ports || [] };

    is($top_ports_by_name{in_byte}{declared_type_name}, 'shared_types.byte_t', 'composition top input preserves imported declared type name');
    is($top_ports_by_name{in_byte}{declared_type_spec}{width}, 8, 'composition top input preserves imported declared type width');
    is($top_ports_by_name{in_byte}{declared_type_spec}{signed}, 1, 'composition top input preserves imported declared type signedness');
    is($top_ports_by_name{out_frame}{declared_type_name}, 'frame_t', 'composition top output preserves local aggregate alias name');
    is($top_ports_by_name{out_frame}{declared_type_spec}{kind}, 'record', 'composition top output preserves aggregate declared type kind');
    is_deeply(
        $top_ports_by_name{out_frame}{declared_type_spec}{member_order},
        ['tag', 'payload'],
        'composition top output preserves aggregate declared type member order',
    );

    is($byte_child_ports_by_name{IN_BYTE}{declared_type_name}, 'byte_t', 'realized byte child interface input preserves local declared type name');
    is($byte_child_ports_by_name{IN_BYTE}{declared_type_spec}{signed}, 1, 'realized byte child interface input preserves local declared type signedness');
    is($frame_child_ports_by_name{OUT_FRAME}{declared_type_name}, 'frame_t', 'realized frame child interface output preserves local aggregate declared type name');
    is($frame_child_ports_by_name{OUT_FRAME}{declared_type_spec}{kind}, 'record', 'realized frame child interface output preserves local aggregate declared type spec');

    is($realized_byte_child_ports_by_name{IN_BYTE}->declared_type_name, 'byte_t', 'realized byte child interface port objects mirror declared type identity');
    is($realized_frame_child_ports_by_name{OUT_FRAME}->declared_type_spec->{width}, 9, 'realized frame child interface port objects mirror declared aggregate width');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
