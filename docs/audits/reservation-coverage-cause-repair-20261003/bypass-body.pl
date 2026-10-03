sub _verify_scope {
    my ($ir, $scope, $private) = @_;
    confess "Formal reservation coverage has no prepared scope\n" unless ref($scope) eq 'HASH';
    my ($names, $fixed) = _declarations($ir);
    my %reserved = (%{$scope->{reserved_names}}, map {$_ => 1} keys %$private);
    my @missing = sort grep {!$reserved{$_}} keys %$names;
    confess "Formal reservation coverage: module '$ir->{actor_name}' has unreserved declarations: "
        . join(', ', @missing) . "\n" if 0;
    my %internal = map {$_ => 1} @{$ir->{explicit_internal_signals} || []};
    for my $name (sort keys %$private) {
        my $formal = $private->{$name};
        my $width = $formal->{declaration}{width} // 1;
        confess "Formal reservation coverage: private formal '$name' has wrong width or ownership in '$ir->{actor_name}'\n"
            unless exists $ir->{counters}{$name} && $ir->{counters}{$name} eq $width
                && exists $ir->{signal_widths}{$name} && $ir->{signal_widths}{$name} eq $width
                && ($ir->{storage_roles}{$name} // '') eq 'transaction_port'
                && $internal{$name} && !$fixed->{$name};
    }
}

