package NativeProxyReleaseCompositionPlan;

use strict;
use warnings;
use JSON::PP ();

my $RELEASE = 'NativeProxyObservationRelease';
my $COORD = 'NativeProxyImageCoordination';
my $CUSTODY = 'NativeProxyImageCustody';
my $ARCHIVE = 'NativeProxyObservationArchive';
my $CENSUS = 'NativeProxyReferenceCensus';
my %SOURCE_SCOPE = map { $_ => 1 } (
    "${RELEASE}::_close_owned", "${ARCHIVE}::_source_closure", "${COORD}::_census",
    "${CENSUS}::_closure", "${CENSUS}::_image", "${CENSUS}::_inspect_locked", "${CUSTODY}::read_entry");
my %DIRECTORY_SCOPE = map { $_ => 1 } ("${COORD}::_names", "${CUSTODY}::_members");
my %ERROR = (
    "${RELEASE}::_close_owned" => 'cannot close retained release descriptor',
    "${ARCHIVE}::_source_closure" => 'cannot close archive reread descriptor',
    "${COORD}::_census" => 'cannot close census reference',
    "${CENSUS}::_closure" => 'cannot close fresh reference',
    "${CENSUS}::_image" => 'cannot close image input',
    "${CENSUS}::_inspect_locked" => 'cannot close reference',
    "${CUSTODY}::read_entry" => 'cannot close image descriptor',
    "${COORD}::_names" => 'cannot close bounded namespace',
    "${CUSTODY}::_members" => 'cannot close image directory',
    "${COORD}::_transaction" => 'cannot close permanent lock',
);

sub _recipe {
    my ($recipe) = @_;
    die "composition recipe fields differ\n" unless ref($recipe) eq 'HASH'
        && join(',', sort keys %$recipe) eq 'kind,order,scope';
    for my $key (qw(kind order)) {
        die "composition recipe text is missing or structured\n"
            unless defined($recipe->{$key}) && !ref($recipe->{$key});
    }
    my ($kind, $scope, $order) = @$recipe{qw(kind scope order)};
    if ($kind eq 'healthy') {
        die "healthy composition carries a scope or order\n" if defined($scope) || $order ne 'none';
        return;
    }
    die "composition scope is missing or structured\n" unless defined($scope) && !ref($scope);
    die "unknown composition declaration order\n" unless $order eq 'observed' || $order eq 'reversed';
    my $valid = $kind eq 'group' ? exists($ERROR{$scope})
        : $kind eq 'source-primary' ? exists($SOURCE_SCOPE{$scope})
        : $kind eq 'directory-primary' ? exists($DIRECTORY_SCOPE{$scope})
        : $kind eq 'milestone-primary' ? scalar(grep { $scope eq $_ }
            qw(before-unlink after-unlink-unknown final-lock-identity)) : 0;
    die "unknown composition kind or scope\n" unless $valid;
}

sub _flow {
    my ($calls, $context) = @_;
    my (%children, %ordinals, %occurrence, %binding, %call_label);
    my (@roots, @events, @closed, %live, %after, %position);
    my $directory = 0;
    for my $index (0 .. $#$calls) {
        my $call = $calls->[$index];
        die "composition call forest is not contiguous\n" unless ref($call) eq 'HASH'
            && $call->{id} == $index && (!defined($call->{parent}) || $call->{parent} < $index);
        if (defined($call->{parent})) { push @{$children{$call->{parent}}}, $index; }
        else { push @roots, $index; }
        my $symbol = $call->{name}; my $ordinal = $ordinals{$symbol} // 0;
        $ordinals{$symbol} = $ordinal + 1; $occurrence{$index} = $ordinal;
        my ($kind, $label, $scope);
        if ($symbol eq "${CUSTODY}::_source") {
            ($kind, $label) = ('source', $call->{opens});
            $scope = $calls->[$call->{parent}]{name};
            $scope = "${RELEASE}::_close_owned" if $scope eq "${RELEASE}::_prepare"
                || $scope eq "${RELEASE}::_retain_live_sources";
            die "unknown composition source owner\n" unless $SOURCE_SCOPE{$scope};
        } elsif ($DIRECTORY_SCOPE{$symbol}) {
            ($kind, $label, $scope) = ('directory', 'directory:'.$directory++, $symbol);
        } else { next; }
        die "duplicate composition handle label\n" if exists($binding{$label});
        my $caller = $scope; $caller =~ s/::[^:]+\z//;
        $binding{$label} = {address => "$kind|$symbol#$ordinal", kind => $kind, symbol => $symbol,
            occurrence => $ordinal, label => $label, path => $call->{path}, open_call_id => $index,
            close_scope => $scope, close_caller => $caller};
        $call_label{$index} = $label;
    }
    die "composition transaction roots differ\n" unless @roots == 23
        && $calls->[$roots[2]]{name} eq "${CUSTODY}::_directory"
        && $calls->[$roots[2]]{path} eq $context->{store}{path};
    $binding{'lock:0'} = {address => "lock|${COORD}::_transaction#0", kind => 'lock',
        symbol => "${COORD}::_transaction", occurrence => 0, label => 'lock:0',
        path => $context->{acquired}{lock}{path}, open_call_id => undef,
        close_scope => "${COORD}::_transaction", close_caller => $COORD};
    my $event = sub {
        my ($name) = @_;
        die "duplicate composition timeline event\n" if exists($position{$name});
        $position{$name} = scalar(@events); push @events, $name;
        $after{$name} = {%live};
    };
    my $open = sub {
        my ($label) = @_;
        die "composition opens an unknown or live owner\n" unless exists($binding{$label}) && !$live{$label};
        $live{$label} = 1; $event->("opened:$label");
    };
    my $close = sub {
        my ($label) = @_;
        die "composition closes an absent owner\n" unless delete($live{$label});
        push @closed, $label; $event->("close:$label:after");
    };
    my (%owned, @release_owned);
    my $visit;
    $visit = sub {
        my ($ident) = @_; my $call = $calls->[$ident];
        $event->("call:$ident:before");
        if (exists($call_label{$ident})) {
            my $label = $call_label{$ident}; my $bound = $binding{$label};
            $open->($label);
            if ($bound->{kind} eq 'directory') { $close->($label); }
            elsif ($bound->{close_scope} eq "${RELEASE}::_close_owned") { push @release_owned, $label; }
            else { push @{$owned{$call->{parent}}}, $label; }
        }
        $event->('unlink:0:after') if $call->{name} eq "${RELEASE}::_unlink_exact";
        for my $child (@{$children{$ident} // []}) {
            $visit->($child);
            # Fresh single-source scopes close immediately after their recheck.
            if ($call->{name} eq "${ARCHIVE}::_source_closure" || $call->{name} eq "${COORD}::_census"
                    || $call->{name} eq "${CENSUS}::_closure") {
                my $c = $calls->[$child];
                if ($c->{name} eq "${CUSTODY}::_recheck_source") {
                    my $label = $c->{source_handle};
                    $close->($label) if $live{$label} && grep { $_ eq $label } @{$owned{$ident} // []};
                }
            }
        }
        $close->($_) for grep { $live{$_} } @{$owned{$ident} // []};
        $event->("call:$ident:after");
    };
    for my $ident (@roots) {
        $visit->($ident); $open->('lock:0') if $ident == $roots[2];
    }
    undef $visit;
    $close->('lock:0'); $close->($_) for @release_owned;
    die "composition timeline lost an owner\n" if keys(%live) || @closed != keys(%binding);
    return {events => \@events, position => \%position, after => \%after, closed => \@closed,
        bindings => \%binding, occurrence => \%occurrence};
}

sub resolve {
    die "expected composition flow, context and recipe\n" unless @_ == 3
        && ref($_[0]) eq 'ARRAY' && @{$_[0]} && ref($_[1]) eq 'HASH';
    my ($calls, $context, $recipe) = @_;
    _recipe($recipe);
    my $flow = _flow($calls, $context);
    my ($kind, $scope) = @$recipe{qw(kind scope)};
    my $bindings = $flow->{bindings}; my $after = $flow->{after};
    my ($first, $primary, $resolved_primary);
    my $cut = $flow->{events}[-1];
    if ($kind eq 'group') {
        ($first) = grep { $bindings->{$_}{close_scope} eq $scope
            && keys(%{$after->{"close:$_:after"}}) } @{$flow->{closed}};
        die "composition group has no remaining owner\n" unless defined($first);
        $cut = "close:$first:after";
    } elsif ($kind eq 'directory-primary') {
        my ($label) = grep { $bindings->{$_}{close_scope} eq $scope } @{$flow->{closed}};
        die "composition directory primary is absent\n" unless defined($label);
        my $bound = $bindings->{$label}; $cut = "opened:$label";
        $primary = {kind => 'directory-read', address => $bound->{address}, errno => 'EIO',
            error_prefix => $scope eq "${COORD}::_names" ? 'cannot read bounded namespace' : 'cannot read image members'};
        $resolved_primary = {%$primary, binding => {%$bound}};
    } elsif ($kind ne 'healthy') {
        my @eligible;
        if ($kind eq 'source-primary') {
            @eligible = grep { $_->{name} eq "${CUSTODY}::_recheck_source"
                && $bindings->{$_->{source_handle}}{close_scope} eq $scope
                && keys(%{$after->{"call:$_->{id}:before"}}) >= 2 } @$calls;
        } elsif ($scope eq 'before-unlink') {
            @eligible = grep { $_->{name} eq "${RELEASE}::_unlink_exact" } @$calls;
        } elsif ($scope eq 'after-unlink-unknown') {
            @eligible = grep { $_->{name} eq 'NativeProxyPrivateWorkspace::_absent'
                && $calls->[$_->{parent}]{name} eq "${RELEASE}::_assert_absent"
                && $calls->[$_->{parent}]{phase} eq 'after_unlink' } @$calls;
        } else { @eligible = reverse grep { $_->{name} eq "${COORD}::_lock_identity" } @$calls; }
        die "composition primary call is absent\n" unless @eligible;
        my $call = $eligible[0]; my $ordinal = $flow->{occurrence}{$call->{id}};
        $cut = "call:$call->{id}:before";
        $primary = {kind => 'call', symbol => $call->{name}, occurrence => $ordinal,
            phase => 'before', address => "$call->{name}#$ordinal:before"};
        $resolved_primary = {%$primary, call_id => $call->{id}};
    }
    my @suffix = ((defined($first) ? ($first) : ()), grep { $after->{$cut}{$_} } @{$flow->{closed}});
    die "composition primary has no cleanup report\n" if defined($primary) && !@suffix;
    my (@reports, @resolved);
    for my $index (0 .. $#suffix) {
        my $bound = $bindings->{$suffix[$index]};
        my $error = (($index + (defined($primary) ? 1 : 0)) % 2) ? 'ENOSPC' : 'EIO';
        push @reports, {(map { $_ => $bound->{$_} } qw(address kind symbol occurrence)), errno => $error};
        push @resolved, {%$bound, errno => $error};
    }
    my $winner;
    if (defined($primary)) {
        $winner = {kind => $primary->{kind}, value => $primary->{error_prefix} // $primary->{address},
            errno => $primary->{errno}};
    } elsif (defined($first)) { $winner = {kind => 'close', value => $ERROR{$bindings->{$first}{close_scope}}, errno => 'EIO'}; }
    if ($recipe->{order} eq 'reversed') { @reports = reverse @reports; @resolved = reverse @resolved; }
    my $position = $flow->{position}{$cut};
    my $unlinked = $flow->{position}{'unlink:0:after'} <= $position ? 1 : 0;
    my @checks = grep { $_->{name} eq "${RELEASE}::_assert_absent"
        && $flow->{position}{"call:$_->{id}:before"} <= $position } @$calls;
    my @complete = grep { $flow->{position}{"call:$_->{id}:after"} <= $position } @checks;
    my $last = @checks ? {phase => $checks[-1]{phase},
        state => $flow->{position}{"call:$checks[-1]{id}:after"} <= $position ? 'absent' : 'unknown'} : undef;
    my $witness = {primary => $primary, reports => \@reports, cut_event => $cut, winner => $winner,
        cleanup_order => [map { $bindings->{$_}{address} } @suffix], effects => {
            unlink_attempted => $unlinked, unlink_completed => $unlinked,
            reference_absence_verified => @complete ? 1 : 0, last_reference_check => $last}};
    return {witness => $witness, resolved_reports => \@resolved, resolved_primary => $resolved_primary};
}

1;
