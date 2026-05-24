package FSM::Support::ISFResourceCatalog;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    isf_backlog_resource_kind_values
    isf_enforced_resource_kind_values
    isf_resource_arbiter_values
    isf_resource_kind_meaning_map
    isf_resource_kind_status_map
    isf_resource_kind_values
);

my @RESOURCE_ARBITERS = qw(priority round_robin);

my @RESOURCE_KINDS = qw(
    rule_slot
    output_bundle
    interface_bundle
    named_drive
    transaction_start
    child_instance
    storage_port
);

my %RESOURCE_KIND_STATUS = (
    rule_slot         => 'shipped_for_priority_and_round_robin_arbitration',
    output_bundle     => 'shipped_for_priority_and_round_robin_arbitration',
    transaction_start => 'shipped_for_priority_and_round_robin_arbitration',
    storage_port      => 'shipped_for_priority_and_round_robin_arbitration',
    interface_bundle  => 'backlog',
    named_drive       => 'backlog',
    child_instance    => 'backlog',
);

my %RESOURCE_KIND_MEANING = (
    rule_slot         => 'one-cycle mutual-exclusion slot for rule users, with priority or bounded round-robin arbitration',
    output_bundle     => 'one-cycle ownership of a group of actor outputs or LHS targets, with priority or bounded round-robin arbitration',
    interface_bundle  => 'ownership of a protocol-facing interface or bus bundle',
    named_drive       => 'ownership of a reusable actor drive body or drive-call path',
    transaction_start => 'arbitration for start/request fan-in into one transaction, with priority or bounded round-robin arbitration',
    child_instance    => 're-entry control for a spawned child instance',
    storage_port      => 'arbitration for shared state, register, memory, or storage-port access, with priority or bounded round-robin arbitration',
);

sub isf_resource_arbiter_values {
    return [@RESOURCE_ARBITERS];
}

sub isf_resource_kind_values {
    return [@RESOURCE_KINDS];
}

sub isf_enforced_resource_kind_values {
    return [
        grep { $RESOURCE_KIND_STATUS{$_} ne 'backlog' } @RESOURCE_KINDS
    ];
}

sub isf_backlog_resource_kind_values {
    return [
        grep { $RESOURCE_KIND_STATUS{$_} eq 'backlog' } @RESOURCE_KINDS
    ];
}

sub isf_resource_kind_status_map {
    return { %RESOURCE_KIND_STATUS };
}

sub isf_resource_kind_meaning_map {
    return { %RESOURCE_KIND_MEANING };
}

1;
