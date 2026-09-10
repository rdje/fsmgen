package NativeProxyRuntimeRecord;

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
my $WORKSPACE = qr{\.artifacts/tmp/process-supervisor-tests/fsmgen-[A-Za-z0-9_]+};

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
    die "runtime reference key differs from workspace\n"
        unless $record->{reference_key}
            eq NativeProxyImageCustody::runtime_reference_key($record->{workspace});
}

sub _validate {
    my ($case, $record) = @_;
    die "expected inactive image case\n" unless _string($case) =~ /\A$CASE\z/;
    _fields($record, qw(schema reference_key image_key workspace workspace_identity selected_sources));
    die "expected runtime reference schema\n"
        unless _string($record->{schema}) eq 'fsmgen.test.rust_proxy_image_reference.v1';
    _digest($record->{reference_key});
    _digest($record->{image_key});
    die "expected private workspace path\n"
        unless _string($record->{workspace}) =~ /\A$WORKSPACE\z/;
    _reference_key($record);

    my $directory = $record->{workspace_identity};
    _fields($directory, qw(path device inode));
    die "workspace identity path differs\n"
        unless _string($directory->{path}) eq $record->{workspace};
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
    # These are historical IDs and digest spellings, not observations of a
    # current workspace, volume, file, byte pair or reference filename.
    return 1;
}

sub encode_runtime_record {
    die "expected isolated case and runtime record\n" unless @_ == 2;
    my ($case, $record) = @_;
    _validate($case, $record);
    my $bytes = $JSON->encode($record);
    die "runtime record exceeds byte ceiling\n" if length($bytes) > $LIMIT;
    return $bytes;
}

sub decode_runtime_record {
    die "expected isolated case and runtime bytes\n" unless @_ == 2;
    my ($case, $bytes) = @_;
    die "expected bounded ASCII record bytes\n"
        unless defined($bytes) && !ref($bytes) && !utf8::is_utf8($bytes)
            && length($bytes) <= $LIMIT && $bytes !~ /[^\x00-\x7f]/;
    my $record = eval { $JSON->decode($bytes) };
    die "invalid runtime JSON\n" if $@;
    die "runtime JSON is not canonical\n" unless $bytes eq encode_runtime_record($case, $record);
    return $record;
}

1;
