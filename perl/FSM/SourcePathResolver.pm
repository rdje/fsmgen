package FSM::SourcePathResolver;

use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

sub new($class, %args) {
    my $extra_search_paths = $args{extra_search_paths} || [];
    return bless {
        extra_search_paths => [ @$extra_search_paths ],
    }, $class;
}

sub extra_search_paths($self) {
    return [ @{$self->{extra_search_paths} || []} ];
}

sub normalized_search_paths($self, %args) {
    my @search_paths;
    push @search_paths, @{ $args{preferred_dirs} || [] };
    push @search_paths, @{$self->{extra_search_paths} || []};
    push @search_paths, grep { defined && length } split /:/, ($ENV{FSMLIB} || '');
    push @search_paths, '.' if $args{include_cwd};

    my %seen;
    my @normalized = grep { defined && length && !$seen{$_}++ } map {
        my $path = $_;
        $path =~ s/^~/$ENV{HOME}/ if defined($path) && defined($ENV{HOME});
        $path;
    } @search_paths;

    return \@normalized;
}

1;
