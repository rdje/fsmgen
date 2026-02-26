package FSM::HDL::FlattenedDT::Backend::Verilog;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Debug;

sub new ($class, %args) {
    my $flattened_dt = $args{flattened_dt}
      or die "[Verilog.pm][new()] Missing required 'flattened_dt' argument";

    return bless {
        flattened_dt => $flattened_dt,
    }, $class;
}

sub generate_verilog ($self, $fsm_module) {
    my $ctx = $self->{flattened_dt};
    fsm_debug("[Verilog.pm][generate_verilog()] Starting flattened DT Verilog generation for " . $fsm_module->name, 3);
    my $sv_hdl = $ctx->generate_systemverilog($fsm_module);
    return $self->convert_systemverilog_to_verilog($sv_hdl);
}

sub convert_systemverilog_to_verilog ($self, $sv_hdl) {
    my $verilog_hdl = $sv_hdl;
    
    # SystemVerilog procedural blocks -> Verilog-2001 compatible forms.
    $verilog_hdl =~ s/\balways_comb\b/always @*/g;
    $verilog_hdl =~ s/\balways_ff\s*@\s*\(/always @(/g;
    
    return $verilog_hdl;
}

1;
