package NativeProxyObservationRecord;

use strict;
use warnings;
use JSON::PP ();
use ImageCustody ();

# Inactive data codec. No filesystem lookup, publication, liveness inference or
# execution authority is provided by a structurally valid historical record.
my $JSON = JSON::PP->new->canonical->ascii->max_depth(8)->allow_nonref(0);
my $SCALAR = JSON::PP->new->canonical->ascii->allow_nonref(1);
my $LIMIT = 4096;
my $CASE = qr{\.artifacts/tmp/native-proxy-image-custody/cases/fsmgen-[A-Za-z0-9_]+};

sub _fields {
    my ($record, @fields) = @_;
    die "expected closed record fields\n" unless ref($record) eq 'HASH'
        && keys(%$record) == @fields && !grep { !exists($record->{$_}) } @fields;
}

sub _string {
    my ($value) = @_;
    die "expected JSON string\n" unless defined($value) && !ref($value)
        && $SCALAR->encode($value) =~ /\A"/;
    return $value;
}

sub _integer {
    my ($value) = @_;
    die "expected nonnegative JSON integer\n" unless defined($value) && !ref($value)
        && $SCALAR->encode($value) =~ /\A(?:0|[1-9][0-9]*)\z/;
    return $value;
}

sub _digest {
    my ($value) = @_;
    die "expected lowercase SHA-256\n" unless _string($value) =~ /\A[0-9a-f]{64}\z/;
    return $value;
}

sub _reference_key {
    my ($record) = @_;
    die "observation reference key differs from evidence path or births\n"
        unless $record->{reference_key}
            eq NativeProxyImageCustody::observation_reference_key(
                $record->{evidence_directory}, $record->{observer_birth}, $record->{target_birth});
}

sub _validate {
    my ($case, $record) = @_;
    die "expected inactive image case\n" unless _string($case) =~ /\A$CASE\z/;
    _fields($record, qw(schema reference_key image_key evidence_directory
        evidence_directory_identity observer_birth target_birth selected_sources));
    die "expected observation reference schema\n"
        unless _string($record->{schema}) eq 'fsmgen.test.rust_proxy_image_observation_reference.v1';
    _digest($record->{reference_key});
    _digest($record->{image_key});
    NativeProxyImageCustody::_relative_path($record->{evidence_directory});
    NativeProxyImageCustody::_birth($record->{$_}) for qw(observer_birth target_birth);
    _reference_key($record);

    my $directory = $record->{evidence_directory_identity};
    _fields($directory, qw(path device inode));
    die "evidence directory identity path differs\n"
        unless _string($directory->{path}) eq $record->{evidence_directory};
    _integer($directory->{$_}) for qw(device inode);

    my $sources = $record->{selected_sources};
    die "expected ordered canonical source pair\n" unless ref($sources) eq 'ARRAY' && @$sources == 2;
    my @names = qw(rustup.c rustup);
    for my $index (0, 1) {
        my $source = $sources->[$index];
        _fields($source, qw(path device inode size_bytes sha256));
        my $path = "$case/images/$record->{image_key}/$names[$index]";
        die "selected source path differs from image layout\n"
            unless _string($source->{path}) eq $path;
        _integer($source->{$_}) for qw(device inode size_bytes);
        die "selected source exceeds byte ceiling\n" if $source->{size_bytes} > 65_536;
        _digest($source->{sha256});
    }
    # The pair retains the canonical image. Wrapper/reference snapshots belong
    # to separate observation custody. Historical IDs and birth syntax prove
    # neither current filesystem identity nor living/authenticated processes.
    return 1;
}

sub encode_observation_record {
    die "expected isolated case and observation record\n" unless @_ == 2;
    my ($case, $record) = @_;
    _validate($case, $record);
    my $bytes = $JSON->encode($record);
    die "observation record exceeds byte ceiling\n" if length($bytes) > $LIMIT;
    return $bytes;
}

sub decode_observation_record {
    die "expected isolated case and observation bytes\n" unless @_ == 2;
    my ($case, $bytes) = @_;
    die "expected bounded ASCII record bytes\n"
        unless defined($bytes) && !ref($bytes) && !utf8::is_utf8($bytes)
            && length($bytes) <= $LIMIT && $bytes !~ /[^\x00-\x7f]/;
    my $record = eval { $JSON->decode($bytes) };
    die "invalid observation JSON\n" if $@;
    die "observation JSON is not canonical\n" unless $bytes eq encode_observation_record($case, $record);
    return $record;
}

1;
