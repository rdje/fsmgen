package NativeProxyReleaseOmissionPlan;

use strict;
use warnings;

# Select from the current call forest. Archived labels, numeric call IDs and
# paths are never accepted as recipe fields. The preflight independently checks
# that each scope's first opening is also its first healthy close.
sub resolve {
    die "expected current flow, context and omission recipe\n"
        unless @_ == 3 && ref($_[0]) eq 'ARRAY' && ref($_[1]) eq 'HASH' && ref($_[2]) eq 'HASH';
    my ($calls, $context, $recipe) = @_;
    my %keys = map { $_ => 1 } qw(kind scope handle_kind);
    die "omission recipe fields differ from the pinned contract\n"
        unless keys(%$recipe) == keys(%keys) && !grep { !$keys{$_} } keys %$recipe;
    die "invalid omission recipe kind\n" unless defined($recipe->{kind}) && !ref($recipe->{kind});
    if ($recipe->{kind} eq 'healthy') {
        die "healthy omission recipe carries a target\n" if defined($recipe->{scope}) || defined($recipe->{handle_kind});
        return [];
    }
    die "unsupported omission recipe kind\n" unless $recipe->{kind} eq 'omit';
    die "invalid omission target\n" if grep { !defined($recipe->{$_}) || ref($recipe->{$_}) } qw(scope handle_kind);
    my (%ordinals, %first); my $directory = 0;
    for my $call (@$calls) {
        my $symbol = $call->{name}; my $occurrence = $ordinals{$symbol} // 0;
        $ordinals{$symbol} = $occurrence + 1;
        my ($kind, $label, $scope);
        if ($symbol eq 'NativeProxyImageCustody::_source') {
            ($kind, $label) = ('source', $call->{opens});
            $scope = $calls->[$call->{parent}]{name};
            $scope = 'NativeProxyObservationRelease::_close_owned'
                if $scope eq 'NativeProxyObservationRelease::_prepare'
                    || $scope eq 'NativeProxyObservationRelease::_retain_live_sources';
        } elsif ($symbol eq 'NativeProxyImageCoordination::_names'
                 || $symbol eq 'NativeProxyImageCustody::_members') {
            ($kind, $label, $scope) = ('directory', 'directory:'.$directory++, $symbol);
        } else { next; }
        next if exists($first{$scope});
        my $caller = $scope; $caller =~ s/::[^:]+\z//;
        $first{$scope} = {address => "$kind|$symbol#$occurrence", kind => $kind, symbol => $symbol,
            occurrence => $occurrence, label => $label, path => $call->{path},
            open_call_id => $call->{id}, close_scope => $scope, close_caller => $caller};
    }
    my $symbol = 'NativeProxyImageCoordination::_transaction';
    $first{$symbol} = {address => "lock|$symbol#0", kind => 'lock', symbol => $symbol, occurrence => 0,
        label => 'lock:0', path => $context->{acquired}{lock}{path}, open_call_id => undef,
        close_scope => $symbol, close_caller => 'NativeProxyImageCoordination'};
    my $target = $first{$recipe->{scope}};
    die "unknown omission scope or handle kind\n" unless $target && $target->{kind} eq $recipe->{handle_kind};
    return [{%$target}];
}

1;
