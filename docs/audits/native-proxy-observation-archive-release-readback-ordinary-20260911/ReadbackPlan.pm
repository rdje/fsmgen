package NativeProxyReleaseReadbackPlan;

use strict;
use warnings;
use Errno qw(EIO);

# Resolve the stable Source ordinal against this fixture's prospective flow.
# Reference-name ordering may change helper IDs and content-sensitive consumers.
sub resolve {
    my ($flow, $selected) = @_;
    return undef unless defined($selected);
    die "readback selector fields differ\n" unless ref($selected) eq 'HASH'
        && join(',', sort keys %$selected) eq 'control,occurrence,strong_alias';
    die "invalid readback control\n" unless defined($selected->{control}) && !ref($selected->{control})
        && $selected->{control} =~ /\A(?:first-eio|partial-eio|early-eof|body-xor|one-byte)\z/;
    my @sources = grep { $_->{name} eq 'NativeProxyImageCustody::_source' } @$flow;
    my $number = $selected->{occurrence};
    die "readback ordinal outside current flow\n" unless defined($number) && !ref($number)
        && $number =~ /\A(?:0|[1-9][0-9]*)\z/ && $number < @sources;
    die "invalid strong-alias selection\n" unless defined($selected->{strong_alias}) && !ref($selected->{strong_alias})
        && $selected->{strong_alias} =~ /\A[01]\z/
        && (!$selected->{strong_alias} || ($number == 0 && $selected->{control} eq 'first-eio'));
    return {%$selected, call_id => $sources[$number]{id}, path => $sources[$number]{path}};
}

sub error {
    my ($flow, $selected) = @_;
    return '' unless defined($selected);
    return '' if $selected->{control} eq 'one-byte';
    return "fixture changed during its bounded read\n" if $selected->{control} eq 'early-eof';
    if ($selected->{control} eq 'first-eio' || $selected->{control} eq 'partial-eio') {
        local $! = EIO;
        return "cannot read fixture bytes: $!\n";
    }
    my $source = $flow->[$selected->{call_id}];
    my $parent = $flow->[$source->{parent}]{name};
    my %errors = (
        'NativeProxyImageCoordination::_census' => '',
        'NativeProxyObservationRelease::_prepare' => "release archive bytes differ from retained original\n",
        'NativeProxyObservationRelease::_retain_live_sources' => "release live source differs from original custody\n",
        'NativeProxyObservationArchive::_source_closure' => "archive reread bytes or native identity changed\n",
        'NativeProxyReferenceCensus::_closure' => "reference identity or bytes changed\n",
        'NativeProxyReferenceCensus::_image' => "key does not match compiled bytes\n",
        'NativeProxyReferenceCensus::_inspect_locked' => "expected bounded ASCII reference bytes\n",
        'NativeProxyImageCustody::read_entry' => $source->{path} =~ /\/image\.json\z/
            ? "manifest differs from exact content reconstruction\n" : "image differs from the actual compiled byte pair\n",
    );
    die "unclassified current Source consumer\n" unless exists($errors{$parent});
    return $errors{$parent};
}

1;
