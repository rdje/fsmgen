package NativeProxyReleaseFixture;

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use ArchiveFixture;
use WorkRecord;

my $ROOT = FSM::Test::ProcessSupervisor::repository_root();

sub work {
    my ($context, $profile) = @_;
    my @roles = qw(capture helper query);
    my @outcomes = qw(completed failed cancelled);
    my @entries = map { +{work_id => "work:$_", ownership_token => sha256_hex("owner:$_"), role => $roles[$_]} } 0..2;
    my $selection = NativeProxyObservationWorkRecord::work_selection(
        $context->{store}{path}, $context->{request}, $context->{acquired}, \@entries);
    my @receipts = map { +{%{$entries[$_]}, outcome => $outcomes[$_],
        cleanup => {leader_started => 1, leader_reaped => 1, group_gone => 1}} } 0..2;
    if ($profile eq 'never-started') {
        $receipts[1]{outcome} = 'cancelled';
        $receipts[1]{cleanup} = {leader_started => '0', leader_reaped => '0', group_gone => '1'};
    }
    my $settlement = NativeProxyObservationWorkRecord::work_settlement(
        $context->{store}{path}, $context->{request}, $context->{acquired}, $selection, \@receipts, 1);
    return ($selection, $settlement);
}

sub retain {
    my ($context, $path, $suffix) = @_;
    my $destination = "$context->{evidence}{path}/retained-original-$suffix";
    die 'retained fixture destination already exists' if -e "$ROOT/$destination" || -l "$ROOT/$destination";
    rename("$ROOT/$path", "$ROOT/$destination") or die "retain original fixture: $!\n";
    return $destination;
}

sub mutation {
    my ($context, $selection, $arguments) = @_;
    my $kind = $selection->{mutation};
    my $archive = $arguments->[3];
    my $settlement = $arguments->[5];
    my $hold = $context->{acquired}{observation_reference}{source}{identity}{path};
    my $lock = $context->{acquired}{lock}{path};
    my $image = $context->{acquired}{target_sources}[4]{identity}{path};
    my $directory = $archive->{archive_directory_identity}{path};
    my $file = $archive->{source_bindings}[0]{archive}{path};
    my @retained;
    if ($kind eq 'none') { }
    elsif ($kind eq 'unsealed') { $settlement->{selection_sealed} = 0; }
    elsif ($kind eq 'missing-receipt') { pop @{$settlement->{receipts}}; }
    elsif ($kind eq 'wrong-owner') { $settlement->{receipts}[0]{ownership_token} = '0' x 64; }
    elsif ($kind eq 'unreaped') { $settlement->{receipts}[1]{cleanup}{leader_reaped} = 0; }
    elsif ($kind eq 'surviving-group') { $settlement->{receipts}[1]{cleanup}{group_gone} = 0; }
    elsif ($kind eq 'legacy-helper-event') {
        $settlement->{receipts}[1] = {event => 'settled', helper_stopped => JSON::PP::false, helper_shutdown_owner => 'caller'};
    }
    elsif ($kind eq 'foreign-archive-receipt') { $archive->{observation_reference_key} = '0' x 64; }
    elsif ($kind eq 'foreign-selection') { $arguments->[4]{observation_reference_key} = '0' x 64; }
    elsif ($kind eq 'missing-archive') { push @retained, retain($context, $directory, 'archive'); }
    elsif ($kind eq 'partial-archive') { push @retained, retain($context, $file, 'archive-source'); }
    elsif ($kind eq 'changed-archive') {
        my $bytes = NativeProxyArchiveFixture::read_bytes("$ROOT/$file");
        substr($bytes, 0, 1, substr($bytes, 0, 1) eq 'X' ? 'Y' : 'X');
        NativeProxyArchiveFixture::write_bytes("$ROOT/$file", $bytes, 0400);
    }
    elsif ($kind eq 'replaced-archive-file') {
        my $bytes = NativeProxyArchiveFixture::read_bytes("$ROOT/$file");
        push @retained, retain($context, $file, 'archive-source');
        NativeProxyArchiveFixture::write_bytes("$ROOT/$file", $bytes, 0400);
    }
    elsif ($kind eq 'archive-mode') { chmod(0755, "$ROOT/$directory") == 1 or die $!; }
    elsif ($kind eq 'replaced-evidence') {
        my $original = $context->{evidence}{path};
        my $destination = "$context->{store}{path}/retained-original-evidence";
        die 'retained fixture destination exists' if -e "$ROOT/$destination" || -l "$ROOT/$destination";
        rename("$ROOT/$original", "$ROOT/$destination") or die $!;
        push @retained, $destination;
        mkdir("$ROOT/$original", 0700) or die $!;
    }
    elsif ($kind eq 'missing-hold') { push @retained, retain($context, $hold, 'hold'); }
    elsif ($kind eq 'changed-hold') {
        my $bytes = NativeProxyArchiveFixture::read_bytes("$ROOT/$hold");
        NativeProxyArchiveFixture::write_bytes("$ROOT/$hold", $bytes."\n", 0400);
    }
    elsif ($kind eq 'replaced-hold') {
        my $bytes = NativeProxyArchiveFixture::read_bytes("$ROOT/$hold");
        push @retained, retain($context, $hold, 'hold');
        NativeProxyArchiveFixture::write_bytes("$ROOT/$hold", $bytes, 0400);
    }
    elsif ($kind eq 'missing-lock') { push @retained, retain($context, $lock, 'lock'); }
    elsif ($kind eq 'replaced-lock') {
        push @retained, retain($context, $lock, 'lock');
        NativeProxyArchiveFixture::write_bytes("$ROOT/$lock", '', 0600);
    }
    elsif ($kind eq 'lock-mode') { chmod(0400, "$ROOT/$lock") == 1 or die $!; }
    elsif ($kind eq 'changed-image') {
        my $bytes = NativeProxyArchiveFixture::read_bytes("$ROOT/$image");
        substr($bytes, 0, 1, substr($bytes, 0, 1) eq 'X' ? 'Y' : 'X');
        NativeProxyArchiveFixture::write_bytes("$ROOT/$image", $bytes, 0500);
    }
    elsif ($kind eq 'replaced-image') {
        my $bytes = NativeProxyArchiveFixture::read_bytes("$ROOT/$image");
        push @retained, retain($context, $image, 'image');
        NativeProxyArchiveFixture::write_bytes("$ROOT/$image", $bytes, 0500);
    }
    else { die 'unknown selected release mutation'; }
    return {kind => $kind, retained_original_paths => \@retained};
}

sub fingerprint {
    my ($value) = @_;
    return [map { fingerprint($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ => fingerprint($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return {json => JSON::PP->new->canonical->ascii->allow_nonref->encode($value),
            utf8 => !ref($value) && defined($value) && utf8::is_utf8($value) ? 1 : 0};
}

1;
