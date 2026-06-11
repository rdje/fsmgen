package FSM::Scheduler::ISF::ATLGeneratedTop;

use v5.20;
use strict;
use warnings;
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use Exporter 'import';

our @EXPORT_OK = qw(
    atl_generated_top_report_entry
    mark_atl_data_link_child_interface_ports
);

sub atl_generated_top_report_entry($top) {
    my $entry = {
        kind                 => $top->{kind},
        top_module           => $top->{top_module},
        top_fsm              => $top->{top_fsm},
        parent_module        => $top->{parent_module},
        parent_scheduled_fsm => $top->{parent_scheduled_fsm},
        clock                => $top->{clock},
        reset                => $top->{reset},
    };

    if (ref($top->{children}) eq 'ARRAY' && @{$top->{children}}) {
        $entry->{children} = [
            map {
                {
                    instance             => $_->{instance},
                    child_module         => $_->{child_module},
                    child_scheduled_fsm  => $_->{child_scheduled_fsm},
                    target_transaction   => $_->{target_transaction},
                    trigger_parent_port  => $_->{trigger_parent_port},
                    trigger_child_port   => $_->{trigger_child_port},
                    event                => $_->{event},
                    event_parent_port    => $_->{event_parent_port},
                    event_child_port     => $_->{event_child_port},
                }
            } @{$top->{children}}
        ];
        return $entry;
    }

    return {
        %$entry,
        instance             => $top->{instance},
        child_module         => $top->{child_module},
        child_scheduled_fsm  => $top->{child_scheduled_fsm},
        target_transaction   => $top->{target_transaction},
        trigger_parent_port  => $top->{trigger_parent_port},
        trigger_child_port   => $top->{trigger_child_port},
        event                => $top->{event},
        event_parent_port    => $top->{event_parent_port},
        event_child_port     => $top->{event_child_port},
    };
}

sub mark_atl_data_link_child_interface_ports($child_irs, $atl_top_instances) {
    return unless ref($child_irs) eq 'HASH' && ref($atl_top_instances) eq 'ARRAY';

    for my $top (@$atl_top_instances) {
        next unless ref($top) eq 'HASH';
        my @children = ref($top->{children}) eq 'ARRAY' && @{$top->{children}}
            ? @{$top->{children}}
            : ($top);

        for my $child (@children) {
            my $child_module = $child->{child_module};
            my $child_ir = $child_irs->{$child_module};
            next unless ref($child_ir) eq 'HASH';

            my %port_by_name = map { $_->{name} => $_ } @{$child_ir->{ports} || []};
            my %already = map { $_->{name} => 1 } @{$child_ir->{explicit_interface_ports} || []};
            for my $data_link (@{$child->{data_links} || []}) {
                for my $child_endpoint (qw(child_sink_port child_source_port)) {
                    my $child_port = $data_link->{$child_endpoint};
                    next unless defined($child_port) && !ref($child_port) && length($child_port);
                    next if $already{$child_port}++;

                    my $port = $port_by_name{$child_port};
                    next unless ref($port) eq 'HASH';
                    push @{$child_ir->{explicit_interface_ports}}, {
                        name      => $port->{name},
                        direction => $port->{direction},
                        width     => $port->{width} || 1,
                    };
                }
            }
        }
    }
}

1;
