package NativeProxyReleaseClosePlan;

use strict;
use warnings;
use JSON::PP ();

# Pure current-flow binding. Baseline handle numbers and paths never select a
# live descriptor. The independent Python oracle derives ownership separately.
sub resolve {
    die "expected prospective flow, context and single close reports\n"
        unless @_ == 3 && ref($_[0]) eq 'ARRAY' && ref($_[1]) eq 'HASH'
            && ref($_[2]) eq 'ARRAY' && @{$_[2]} <= 1;
    my ($calls, $context, $reports) = @_;
    my (%ordinals, %available); my $directory = 0;
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
        my $address = "$kind|$symbol#$occurrence";
        my $caller = $scope; $caller =~ s/::[^:]+\z//;
        die "duplicate current close address\n" if exists($available{$address});
        $available{$address} = {address => $address, kind => $kind, symbol => $symbol,
            occurrence => $occurrence, label => $label, path => $call->{path},
            open_call_id => $call->{id}, close_scope => $scope, close_caller => $caller};
    }
    my $symbol = 'NativeProxyImageCoordination::_transaction'; my $address = "lock|$symbol#0";
    $available{$address} = {address => $address, kind => 'lock', symbol => $symbol, occurrence => 0,
        label => 'lock:0', path => $context->{acquired}{lock}{path}, open_call_id => undef,
        close_scope => $symbol, close_caller => 'NativeProxyImageCoordination'};
    my (@bound, %seen);
    for my $report (@$reports) {
        my %keys = map { $_ => 1 } qw(address kind symbol occurrence errno);
        die "close-report fields differ from the pinned contract\n"
            unless ref($report) eq 'HASH' && keys(%$report) == keys(%keys)
                && !grep { !$keys{$_} } keys %$report;
        for my $key (qw(address kind symbol errno)) {
            die "close-report text is missing or structured\n"
                unless defined($report->{$key}) && !ref($report->{$key});
        }
        die "unsupported close-report errno\n" unless $report->{errno} eq 'EIO';
        my $occurrence = $report->{occurrence};
        die "invalid close-report occurrence\n" unless defined($occurrence) && !ref($occurrence)
            && JSON::PP->new->encode($occurrence) =~ /\A(?:0|[1-9][0-9]*)\z/;
        my $key = "$report->{kind}|$report->{symbol}#$occurrence";
        die "close-report address differs from its fields\n" unless $key eq $report->{address};
        die "duplicate or unknown close report\n" if $seen{$key}++ || !exists($available{$key});
        push @bound, {%{$available{$key}}};
    }
    return \@bound;
}

1;
