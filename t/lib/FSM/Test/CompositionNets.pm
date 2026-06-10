package FSM::Test::CompositionNets;

use strict;
use warnings;

use Exporter 'import';
use Test::More ();

our @EXPORT_OK = qw(
    assert_only_carrier_and_shared_dp_sink_nets
    carrier_nets
    net_name
    net_width
    shared_dp_sink_nets
);

sub net_name {
    my ($net) = @_;
    return undef unless defined $net;
    return $net->{name} if ref($net) eq 'HASH';
    return $net->name if ref($net) && $net->can('name');
    return undef;
}

sub net_width {
    my ($net) = @_;
    return undef unless defined $net;
    return $net->{width} if ref($net) eq 'HASH';
    return $net->width if ref($net) && $net->can('width');
    return undef;
}

sub carrier_nets {
    return [
        grep {
            my $name = net_name($_) // '';
            $name !~ /\Ashared_dp_unused_/
        } @_
    ];
}

sub shared_dp_sink_nets {
    return [
        grep {
            my $name = net_name($_) // '';
            $name =~ /\Ashared_dp_unused_/
        } @_
    ];
}

sub assert_only_carrier_and_shared_dp_sink_nets {
    my ($nets, $expected_carrier_names, $label) = @_;
    $nets ||= [];
    $expected_carrier_names ||= [];

    my $carriers = carrier_nets(@$nets);
    my $sinks = shared_dp_sink_nets(@$nets);
    my @foreign = grep {
        my $name = net_name($_) // '';
        $name =~ /\Ashared_dp_/ && $name !~ /\Ashared_dp_unused_/
    } @$nets;

    Test::More::is_deeply(
        [map { net_name($_) } @$carriers],
        $expected_carrier_names,
        "$label carrier net names",
    );
    Test::More::is(
        scalar(@$nets),
        scalar(@$carriers) + scalar(@$sinks),
        "$label has only carrier nets plus shared-datapath unused sink nets",
    );
    Test::More::is(
        scalar(@foreign),
        0,
        "$label does not expose unexpected shared-datapath helper nets",
    );

    return ($carriers, $sinks);
}

1;
