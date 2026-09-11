package NativeProxyReleaseCallPlan;

use strict;
use warnings;
use JSON::PP ();

# Pure prospective input-flow construction. This helper never opens a path or
# executes release. The independent Python oracle derives the flow separately.
my $RELEASE = 'NativeProxyObservationRelease';
my $COORD = 'NativeProxyImageCoordination';
my $CUSTODY = 'NativeProxyImageCustody';
my $ARCHIVE = 'NativeProxyObservationArchive';
my $CENSUS = 'NativeProxyReferenceCensus';

sub _call {
    my ($self, $package, $symbol, $body, %metadata) = @_;
    my $parent = @{$self->{stack}} ? $self->{stack}[-1] : undef;
    my $caller = delete $metadata{caller};
    if (!defined($caller)) {
        $caller = defined($parent) ? $self->{calls}[$parent]{name} : $COORD;
        $caller =~ s/::[^:]+\z// if defined($parent);
    }
    my $row = {id => scalar(@{$self->{calls}}), name => "$package\::$symbol",
        parent => $parent, caller => $caller, %metadata};
    push @{$self->{calls}}, $row; push @{$self->{stack}}, $row->{id};
    $body->();
    die "prospective call stack changed\n" unless pop(@{$self->{stack}}) == $row->{id};
    return $row;
}

sub _leaf {
    my ($self, $package, $symbol, %metadata) = @_;
    return $self->_call($package, $symbol, sub {}, %metadata);
}

sub _directory {
    my ($self, $path, %metadata) = @_;
    $self->_leaf($CUSTODY, '_directory', path => $path, %metadata);
}

sub _names {
    my ($self, $path) = @_;
    $self->_leaf($COORD, '_names', path => $path);
}

sub _source {
    my ($self, $path, $mode, $limit) = @_;
    $mode = 0400 unless defined($mode); $limit = 65_536 unless defined($limit);
    my $alias = 'source:'.scalar(keys %{$self->{source_paths}});
    $self->{source_paths}{$alias} = $path;
    $self->_leaf($CUSTODY, '_source', path => $path, mode => $mode, limit => $limit, opens => $alias);
    return $alias;
}

sub _recheck {
    my ($self, $alias) = @_;
    die "prospective recheck has no source\n" unless exists($self->{source_paths}{$alias});
    $self->_leaf($CUSTODY, '_recheck_source', path => $self->{source_paths}{$alias}, source_handle => $alias);
}

sub _archive_members {
    my ($self) = @_;
    $self->_call($ARCHIVE, '_members', sub { $self->_names($self->{archive}); });
}

sub _archive_directories {
    my ($self) = @_;
    $self->_call($ARCHIVE, '_directory_closure', sub {
        $self->_directory($self->{evidence}); $self->_directory($self->{archive});
    });
}

sub _archive_closure {
    my ($self) = @_;
    $self->_call($RELEASE, '_archive_closure', sub {
        $self->_archive_members(); $self->_archive_directories();
        $self->_call($ARCHIVE, '_source_closure', sub {
            for my $alias (@{$self->{archive_sources}}) {
                $self->_recheck($alias); $self->_recheck($self->_source($self->{source_paths}{$alias}));
            }
            $self->_recheck($_) for @{$self->{archive_sources}};
        });
        $self->_leaf($ARCHIVE, '_receipt'); $self->_archive_members(); $self->_archive_directories();
        $self->_recheck($_) for @{$self->{archive_sources}};
    });
}

sub _read_entry {
    my ($self, $key) = @_;
    my $entry = "$self->{store}/images/$key";
    $self->_call($CUSTODY, 'read_entry', sub {
        $self->_directory($_) for ($self->{store}, "$self->{store}/images", $entry);
        $self->_leaf($CUSTODY, '_members', path => $entry);
        my @sources = ($self->_source("$entry/rustup.c"), $self->_source("$entry/rustup", 0500),
            $self->_source("$entry/image.json", 0400, 4096));
        $self->_leaf($CUSTODY, '_members', path => $entry);
        $self->_directory($_) for ($self->{store}, "$self->{store}/images", $entry);
        $self->_recheck($_) for @sources;
    });
}

sub _image {
    my ($self, $key) = @_;
    my $entry = "$self->{store}/images/$key";
    $self->_call($CENSUS, '_image', sub {
        $self->_directory($entry);
        my @sources = ($self->_source("$entry/rustup.c"), $self->_source("$entry/rustup", 0500));
        $self->_read_entry($key); $self->_recheck($_) for @sources;
        $self->_directory($entry);
    }, image_key => $key);
}

sub _structure {
    my ($self) = @_;
    $self->_call($COORD, '_structure', sub {
        $self->_names($self->{store});
        $self->_directory("$self->{store}/images"); $self->_directory("$self->{store}/references");
        $self->_names($self->{store});
    });
}

sub _census {
    my ($self, $records) = @_;
    $self->_call($COORD, '_census', sub {
        $self->_names("$self->{store}/images"); $self->_names("$self->{store}/references");
        $self->_directory("$self->{store}/images/$_") for @{$self->{available}};
        $self->_recheck($self->_source("$self->{store}/references/$_", 0400, 4096)) for sort keys %$records;
    });
}

sub _inspect {
    my ($self, $records) = @_;
    $self->_call($CENSUS, '_inspect_locked', sub {
        my (@held, %images);
        for my $name (sort keys %$records) {
            my $alias = $self->_source("$self->{store}/references/$name", 0400, 4096); push @held, $alias;
            $self->_leaf($CENSUS, '_decode_record'); $self->_leaf($CENSUS, '_filename_key');
            my $key = $records->{$name}{image_key};
            if (!$images{$key}) { $self->_image($key); $images{$key} = 1; }
            $self->_leaf($CENSUS, '_matches_image'); $self->_recheck($alias);
        }
        $self->_call($CENSUS, '_closure', sub {
            $self->_names("$self->{store}/references");
            for my $alias (@held) {
                $self->_recheck($alias); $self->_recheck($self->_source($self->{source_paths}{$alias}, 0400, 4096));
            }
            $self->_image($_) for sort keys %images;
        });
    }, reference_names => [sort keys %$records]);
}

sub _retain_live {
    my ($self) = @_;
    my $entry = "$self->{store}/images/$self->{selected_key}";
    $self->_call($RELEASE, '_retain_live_sources', sub {
        for my $item (["$entry/rustup.c", 0400, 65_536], ["$entry/rustup", 0500, 65_536], [$self->{hold}, 0400, 4096]) {
            my $alias = $self->_source(@$item); push @{$self->{live_sources}}, $alias; $self->_recheck($alias);
        }
    });
}

sub _absence {
    my ($self, $phase) = @_;
    $self->_call($RELEASE, '_assert_absent', sub {
        $self->_leaf('NativeProxyPrivateWorkspace', '_absent', path => $self->{hold});
    }, phase => $phase);
}

sub derive {
    die "expected context, physical before-state and original archive specification\n" unless @_ == 3;
    my ($context, $before, $spec) = @_;
    my $self = bless {calls => [], stack => [], source_paths => {}, archive_sources => [], live_sources => [],
        store => $context->{store}{path}, evidence => $context->{evidence}{path},
        archive => "$context->{evidence}{path}/retained-sources",
        hold => $context->{acquired}{observation_reference}{source}{identity}{path},
        selected_key => $context->{acquired}{observation_reference}{record}{image_key}}, __PACKAGE__;
    my (%records, @available);
    for my $path (sort keys %{$before->{store}}) {
        if ($path =~ m{\Areferences/([^/]+)\z}) {
            my $name = $1;
            $records{$name} = JSON::PP->new->decode(pack('H*', $before->{store}{$path}{bytes_hex}));
        } elsif ($path =~ m{\Aimages/([0-9a-f]{64})\z} && $before->{store}{$path}{kind} eq 'directory') {
            push @available, $1;
        }
    }
    $self->{available} = \@available;
    $self->_call($RELEASE, '_prepare', sub {
        $self->_leaf($ARCHIVE, '_limits');
        $self->_directory($self->{evidence}, caller => 'NativeProxyObservationAcquisition');
        $self->_directory($self->{archive}); $self->_archive_members();
        for my $file (@{$spec->{files}}) {
            my $alias = $self->_source($file->{path}); push @{$self->{archive_sources}}, $alias; $self->_recheck($alias);
        }
        $self->_archive_closure();
    }, caller => $RELEASE);
    $self->_leaf($RELEASE, '_coordinator_request'); $self->_directory($self->{store});
    $self->_leaf($COORD, '_lock_identity'); $self->_leaf($COORD, '_lock_identity'); $self->_directory($self->{store});
    $self->_structure(); $self->_directory("$self->{store}/images"); $self->_directory("$self->{store}/references");
    $self->_census(\%records); $self->_inspect(\%records);
    $self->_call($RELEASE, '_admit_locked', sub {
        $self->_leaf($RELEASE, '_current_image'); $self->_archive_closure(); $self->_retain_live();
    });
    $self->_census(\%records); $self->_inspect(\%records);
    $self->_call($RELEASE, '_release_locked', sub {
        $self->_archive_closure(); $self->_image($self->{selected_key}); $self->_retain_live();
        $self->_recheck($_) for (@{$self->{archive_sources}}, @{$self->{live_sources}});
        $self->_leaf($RELEASE, '_unlink_exact'); $self->_absence('after_unlink');
    });
    my %remaining = map { $_ => $records{$_} } grep { "$self->{store}/references/$_" ne $self->{hold} } keys %records;
    $self->_census(\%remaining); $self->_inspect(\%remaining);
    $self->_call($RELEASE, '_finish_locked', sub {
        $self->_image($self->{selected_key}); $self->_archive_closure(); $self->_absence('finish');
    });
    $self->_structure(); $self->_directory("$self->{store}/images"); $self->_directory("$self->{store}/references");
    $self->_directory($self->{store}); $self->_leaf($COORD, '_lock_identity');
    die "prospective flow left an open frame\n" if @{$self->{stack}};
    return $self->{calls};
}

sub resolve {
    my ($calls, $selection, $sealed) = @_;
    die "expected call array, closed selector and sealed-symbol map\n"
        unless @_ == 3 && ref($calls) eq 'ARRAY' && ref($selection) eq 'HASH' && ref($sealed) eq 'HASH';
    my %keys = map { $_ => 1 } qw(address symbol occurrence phase source_call_id source_event baseline_effects);
    die "selector fields differ from the pinned contract\n"
        unless keys(%$selection) == keys(%keys) && !grep { !$keys{$_} } keys %$selection;
    for my $key (qw(address symbol phase)) {
        die "selector text is missing or structured\n" unless defined($selection->{$key}) && !ref($selection->{$key});
    }
    die "unsupported fault phase\n" unless $selection->{phase} eq 'before' || $selection->{phase} eq 'after';
    die "unsafe source or sealed return selection\n" if $selection->{phase} eq 'after'
        && ($sealed->{$selection->{symbol}} || $selection->{symbol} eq "$CUSTODY\::_source");
    my @matches = grep { $_->{name} eq $selection->{symbol} } @$calls;
    my $occurrence = $selection->{occurrence};
    die "fault occurrence is outside the current input flow\n"
        unless defined($occurrence) && !ref($occurrence) && $occurrence =~ /\A(?:0|[1-9][0-9]*)\z/ && $occurrence < @matches;
    my $address = "$selection->{symbol}#$occurrence:$selection->{phase}";
    die "fault address differs from its typed selection\n" unless $address eq $selection->{address};
    return {address => $address, call_id => $matches[$occurrence]{id}, symbol => $selection->{symbol},
        occurrence => 0 + $occurrence, phase => $selection->{phase}};
}

1;
