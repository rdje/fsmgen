package FSM::Scheduler::ISF::SourceWriterOwners;

use strict;
use warnings;
use Carp qw(confess);

# Private source identity only. In particular a transaction-created DT is not
# a state-exclusive writer: activation belongs to the actual guards/grants.
my %DT_OWNER_KIND = (
    latency_counter => 'transaction', temporal_contract_monitor => 'transaction',
    rule => 'rule', drive => 'drive',
);
sub resolve {
    my ($class, $ir, $actor, $container_kind, $container) = @_;
    confess "Source writer ownership requires a module, actor and named container\n"
        unless ref($ir) eq 'HASH' && _name($ir->{actor_name})
            && ref($actor) eq 'HASH' && ref($container) eq 'HASH' && _name($container->{name});
    confess "Source writer ownership requires an actual clock-domain module\n"
        if (($ir->{domain_partition} || {})->{kind} // '') eq 'multi_domain';
    my ($kind, $name);
    if (defined($container_kind) && $container_kind eq 'state') {
        ($kind, $name) = ('transaction', $container->{transaction});
    } elsif (defined($container_kind) && $container_kind eq 'dt') {
        my $expected = $DT_OWNER_KIND{$container->{kind} // ''};
        confess "Source writer ownership has an unsupported DT family\n" unless $expected;
        my $owner = $container->{source_owner};
        confess "Source writer ownership requires an explicit DT source owner\n"
            unless ref($owner) eq 'HASH' && keys(%$owner) == 2
                && _name($owner->{kind}) && $owner->{kind} eq $expected && _name($owner->{name});
        ($kind, $name) = @{$owner}{qw(kind name)};
    } else {
        confess "Source writer ownership requires a state or DT container\n";
    }
    confess "Source writer ownership requires an explicit source identity\n" unless _name($name);
    my $source;
    if ($kind eq 'drive') {
        my $drives = $actor->{drives} || {};
        confess "Source writer ownership requires declared drive records\n" unless ref($drives) eq 'HASH';
        $source = $drives->{$name};
    } else {
        my $records = $actor->{$kind eq 'transaction' ? 'transactions' : 'rules'} || [];
        confess "Source writer ownership requires declared source records\n"
            unless ref($records) eq 'ARRAY' && !grep {ref($_) ne 'HASH'} @$records;
        my @matches = grep {defined($_->{name}) && $_->{name} eq $name} @$records;
        confess "Source writer ownership has duplicate source '$name'\n" if @matches > 1;
        $source = $matches[0];
    }
    confess "Source writer ownership has no declared $kind '$name'\n" unless ref($source) eq 'HASH';
    my $scheduled = $actor->{_scheduled_domain_name};
    my $domain = $source->{domain} // $scheduled // ($actor->{clock_domains} || {})->{default};
    confess "Source writer ownership requires scalar domain identities\n"
        if (defined($domain) && !_name($domain)) || (defined($scheduled) && !_name($scheduled));
    confess "Source writer ownership crosses the actual clock-domain module\n"
        if defined($scheduled) && defined($domain) && $scheduled ne $domain;
    return {module => $ir->{actor_name}, domain => $domain,
        source_kind => $kind, source_name => $name,
        container_kind => $container_kind, container_name => $container->{name}};
}
sub _name {defined($_[0]) && !ref($_[0]) && length($_[0])}

1;
