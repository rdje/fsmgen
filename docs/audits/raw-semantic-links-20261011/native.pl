use strict;
use warnings;
use JSON::PP;
use Encode qw(encode);
use Digest::SHA qw(sha256_hex);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Cwd qw(getcwd);

my $base = 'docs/audits/raw-semantic-links-20261011';
sub plain {
    my ($path) = @_;
    die "own relative native body path" if $path =~ m{^/|(?:^|/)\.\.(?:/|$)|(?:^|/)\.git(?:/|$)};
    my @parts = split m{/}, $path;
    my $current = '';
    my @root = stat '.';
    for my $part (@parts) {
        $current .= ($current eq '' ? '' : '/') . $part;
        die "ordinary own native body boundary" if -l $current || -e "$current/.git";
        my @st = stat $current;
        die "same-volume native body boundary" if !@st || $st[0] != $root[0];
    }
    die "ordinary native body member" unless -f $path;
    return $path;
}
sub bytes {
    my ($path) = @_;
    open my $fh, '<:raw', plain($path) or die "open native body input: $!";
    local $/;
    my $raw = <$fh>;
    close $fh or die "close native body input: $!";
    return $raw;
}
my $json = JSON::PP->new->utf8->canonical;
my @modes;
for my $mode (qw(ordinary storable controls)) {
    my $path = "docs/audits/record-value-original-candidate-20261004/$mode.json";
    my $raw = bytes($path);
    my $native = $json->decode($raw);
    my %domains;
    for my $domain (qw(api copies parses test_run)) {
        my $records = $domain eq 'test_run' ? [$native->{$domain}] : $native->{$domain};
        my (@empty, @nonempty);
        for my $index (0 .. $#$records) {
            my $body = $records->[$index]{error};
            die "original native serialized body kind" if !defined($body) || ref($body);
            if ($body eq '') { push @empty, $index; next; }
            my $encoded = encode('UTF-8', $body);
            push @nonempty, {index => $index, body => $body, body_identity => {bytes => length($encoded), sha256 => sha256_hex($encoded)}};
        }
        $domains{$domain} = {population => scalar(@$records), empty_string_members => \@empty, nonempty => \@nonempty};
    }
    push @modes, {mode => $mode, input => {path => $path, bytes => length($raw), sha256 => sha256_hex($raw)}, domains => \%domains};
}
if (!@ARGV) {
    print $json->encode({modes => \@modes}), "\n";
    exit 0;
}
die "one complete native body candidate" unless @ARGV == 1;
my $path = $ARGV[0];
die "own complete native candidate namespace" unless index($path, "$base/") == 0;
plain($path);
my $decoded;
gunzip \(bytes($path)) => \$decoded or die "complete candidate decompression: $GunzipError";
my $candidate = $json->decode($decoded);
die "complete candidate mode population" unless ref($candidate->{modes}) eq 'ARRAY' && @{$candidate->{modes}} == @modes;
for my $mi (0 .. $#modes) {
    my $actual = $candidate->{modes}[$mi];
    my $wanted = $modes[$mi];
    die "complete candidate original mode order" unless $actual->{mode} eq $wanted->{mode};
    die "complete candidate original domain population" unless join(',', sort keys %{$actual->{domains}}) eq join(',', sort keys %{$wanted->{domains}});
    for my $domain (sort keys %{$wanted->{domains}}) {
        my $a = $actual->{domains}{$domain};
        my $w = $wanted->{domains}{$domain};
        die "complete original empty and nonempty body allocation" unless $json->encode([$a->{population}, $a->{empty_string_members}, [map {$_->{original}{index}} @{$a->{records}}]]) eq $json->encode([$w->{population}, $w->{empty_string_members}, [map {$_->{index}} @{$w->{nonempty}}]]);
        for my $ri (0 .. $#{$w->{nonempty}}) {
            my $original = $a->{records}[$ri]{original};
            my $expected = $w->{nonempty}[$ri];
            die "complete original native body bytes" unless defined($original->{body}) && !ref($original->{body}) && encode('UTF-8', $original->{body}) eq encode('UTF-8', $expected->{body});
            die "complete original native wire kind" unless $original->{wire_kind} eq 'string';
            die "complete original native body identity" unless $json->encode($original->{body_identity}) eq $json->encode($expected->{body_identity});
            my ($joined, $offset) = ('', 0);
            for my $segment (@{$original->{segments}}) {
                my $raw = encode('UTF-8', $segment->{raw});
                die "complete original physical segment byte partition" unless $segment->{offset_bytes} == $offset && $segment->{bytes} == length($raw);
                $joined .= $raw;
                $offset += length($raw);
            }
            die "complete original physical segment reconstruction" unless $joined eq encode('UTF-8', $expected->{body});
        }
    }
}
print "PASS independent original UTF-8 body, empty membership and lossless physical byte conservation; semantics remain pending.\n";
