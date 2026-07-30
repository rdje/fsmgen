package FSM::Support::HDLInstanceIdentifierPolicy;

=head1 NAME

FSM::Support::HDLInstanceIdentifierPolicy - Portable child-instance identifier policy

=head1 DESCRIPTION

Defines the backend-neutral identifier contract for structural child-instance
labels. Authored labels must be simple identifiers that are not reserved by any
shipped HDL target. Generated labels use the same keyword registry plus a
deterministic, VHDL-safe collision allocator.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

my %SYSTEMVERILOG_KEYWORD = map { $_ => 1 } qw(
    accept_on alias always always_comb always_ff always_latch and assert assign
    assume automatic before begin bind bins binsof bit break buf bufif0 bufif1
    byte case casex casez cell chandle checker class clocking cmos config const
    constraint context continue cover covergroup coverpoint cross deassign
    default defparam design disable dist do edge else end endcase endchecker
    endclass endclocking endconfig endfunction endgenerate endgroup endinterface
    endmodule endpackage endprimitive endprogram endproperty endspecify
    endsequence endtable endtask enum event eventually expect export extends
    extern final first_match for force foreach forever fork forkjoin function
    generate genvar global highz0 highz1 if iff ifnone ignore_bins illegal_bins
    implements implies import incdir include initial inout input inside instance
    int integer interconnect interface intersect join join_any join_none large
    let liblist library local localparam logic longint macromodule matches medium
    modport module nand negedge nettype new nexttime nmos nor noshowcancelled not
    notif0 notif1 null or output package packed parameter pmos posedge primitive
    priority program property protected pull0 pull1 pulldown pullup
    pulsestyle_ondetect pulsestyle_onevent pure rand randc randcase randsequence
    rcmos real realtime ref reg reject_on release repeat restrict return rnmos
    rpmos rtran rtranif0 rtranif1 s_always s_eventually s_nexttime s_until
    s_until_with scalared sequence shortint shortreal showcancelled signed small
    soft solve specify specparam static string strong strong0 strong1 struct
    super supply0 supply1 sync_accept_on sync_reject_on table tagged task this
    throughout time timeprecision timeunit tran tranif0 tranif1 tri tri0 tri1
    triand trior trireg type typedef union unique unique0 unsigned until
    until_with untyped use uwire var vectored virtual void wait wait_order wand
    weak weak0 weak1 while wildcard wire with within wor xnor xor
);

my %VHDL_2008_KEYWORD = map { $_ => 1 } qw(
    abs access after alias all and architecture array assert assume
    assume_guarantee attribute begin block body buffer bus case component
    configuration constant context cover default disconnect downto else elsif
    end entity exit fairness file for force function generate generic group
    guarded if impure in inertial inout is label library linkage literal loop
    map new next nor not null of on open or others out package parameter port
    postponed procedure process property protected pure range record register
    reject release rem report restrict restrict_guarantee return rol ror select
    sequence severity shared signal sla sll sra srl strong subtype then to
    transport type unaffected units until use variable wait when while with
    xnor xor
);

sub is_simple_identifier ($class, $value) {
    return defined($value)
        && !ref($value)
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}

sub reserved_target_languages ($class, $value) {
    return [] unless $class->is_simple_identifier($value);

    my @targets;
    push @targets, 'SystemVerilog' if $SYSTEMVERILOG_KEYWORD{$value};
    push @targets, 'VHDL' if $VHDL_2008_KEYWORD{lc($value)};
    return \@targets;
}

sub is_portable_instance_identifier ($class, $value) {
    return 0 unless $class->is_simple_identifier($value);
    return @{$class->reserved_target_languages($value)} ? 0 : 1;
}

sub assert_authored_instance_identifier ($class, $value, %args) {
    my $origin = $args{origin} // 'Authored child instance';

    confess "$origin must use a simple HDL child-instance identifier matching [A-Za-z_][A-Za-z0-9_]*\n"
        unless $class->is_simple_identifier($value);

    my $targets = $class->reserved_target_languages($value);
    if (@$targets) {
        confess "$origin '$value' is not a portable HDL child-instance identifier because it is reserved in "
            . join(' and ', @$targets)
            . "; choose a non-keyword simple identifier\n";
    }

    return $value;
}

sub allocate_generated_instance_identifier ($class, %args) {
    my $desired = $args{desired};
    my $role = $args{role};
    my $reserved = $args{reserved};

    confess "Generated child-instance desired name must match [A-Za-z_][A-Za-z0-9_]*\n"
        unless $class->is_simple_identifier($desired);
    confess "Generated child-instance role must match [A-Za-z_][A-Za-z0-9_]*\n"
        unless $class->is_simple_identifier($role);
    confess "Generated child-instance allocator requires a reserved-name hash reference\n"
        unless ref($reserved) eq 'HASH';

    my $keyword_seed = @{$class->reserved_target_languages($desired)} ? 1 : 0;
    my $base = $keyword_seed
        ? "${desired}_instance"
        : _reserved_name_exists($reserved, $desired)
            ? "${desired}_$role"
            : $desired;
    my $candidate = $base;
    my $suffix = 2;
    while (
        _reserved_name_exists($reserved, $candidate)
        || @{$class->reserved_target_languages($candidate)}
    ) {
        $candidate = "${base}_$suffix";
        ++$suffix;
    }

    $reserved->{$candidate} = 1;
    return $candidate;
}

sub _reserved_name_exists ($reserved, $candidate) {
    my $folded_candidate = lc($candidate);
    return scalar grep { lc($_) eq $folded_candidate } keys %$reserved;
}

1;

__END__

=head1 METHODS

=head2 is_simple_identifier($value)

Returns true when C<$value> uses the unescaped simple-identifier spelling.

=head2 reserved_target_languages($value)

Returns an array reference naming the shipped HDL targets for which C<$value>
is reserved. SystemVerilog lookup is case-sensitive; VHDL-2008 lookup is
case-insensitive.

=head2 is_portable_instance_identifier($value)

Returns true when C<$value> is both simple and non-reserved across the shipped
HDL targets.

=head2 assert_authored_instance_identifier($value, %args)

Returns C<$value> when it is portable, otherwise throws an origin-aware
diagnostic. Callers may pass C<origin> to identify the nearest source boundary.

=head2 allocate_generated_instance_identifier(%args)

Allocates and records one deterministic generated label. C<desired>, C<role>,
and C<reserved> are required. Keyword seeds gain C<_instance>; ordinary
collisions gain C<_ROLE>; further collisions gain a numeric suffix. Collision
lookup is case-insensitive so the result remains unique in VHDL as well as the
Verilog family.

=cut
