package FSM::Scheduler::ISF::LibraryPortOwnership;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Exporter qw(import);

our @EXPORT_OK = qw(connect_library_output_readbacks);

# A library binding owns the public output. The importing FSM can observe the
# value through an input, but cannot create a second writer or reset register.
sub connect_library_output_readbacks {
    my ($parent, $uses) = @_;
    my %owners;
    for my $use (@$uses) {
        for my $binding (@{$use->{bindings} || []}) {
            next unless ($binding->{role} // '') eq 'output';
            my $name = $binding->{parent_name};
            confess "Library output '$name' is driven by both '$owners{$name}' and '$use->{instance}'\n"
                if exists $owners{$name};
            $owners{$name} = $use->{instance};
        }
    }
    for my $name (sort keys %owners) {
        for my $block (@{$parent->{states} || []}, @{$parent->{dt_blocks} || []}) {
            my @targets = (map { $_->{lhs} } @{$block->{assignments} || []});
            push @targets, @{$block->{fields} || []};
            confess "Library-owned output '$name' also has a parent writer in '$block->{name}'\n"
                if grep { defined($_) && /\A\Q$name\E(?:[.\[]|\z)/ } @targets;
        }
        confess "Library-owned output '$name' cannot have a parent reset or default; declare it on the library actor\n"
            if exists($parent->{reset_values}{$name}) || exists($parent->{output_defaults}{$name});
        # ports remains the actor-facing schedule/top contract. Only the
        # emitted importing FSM sees a readback input at this boundary.
        my ($port) = grep { $_->{name} eq $name } @{$parent->{explicit_interface_ports} || []};
        confess "Library output '$name' has no authored parent output interface\n"
            unless $port && $port->{direction} eq 'output';
        $port->{direction} = 'input';
        $parent->{storage_roles}{$name} = 'library_output_readback';
    }
    return scalar keys %owners;
}

1;
