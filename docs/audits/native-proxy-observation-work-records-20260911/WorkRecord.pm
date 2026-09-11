package NativeProxyObservationWorkRecord;

use strict;
use warnings;
use JSON::PP ();
use ArchiveRecord;
use CleanupReceipts;
use RuntimeRecord;

# Inactive data consistency only. A caller-supplied seal or cleanup receipt
# neither authenticates native owners nor prevents a later process launch.
my $JSON = JSON::PP->new->canonical->ascii->max_depth(8)->allow_nonref(0);
my $SELECTION_LIMIT = 4096;
my $RECEIPT_LIMIT = 4096;
my $WORK_LIMIT = 17;
my $SELECTION_SCHEMA = 'fsmgen.inactive_observation_work_selection.v1';
my $SETTLEMENT_SCHEMA = 'fsmgen.inactive_observation_work_settlement.v1';
my $ENVELOPE = {schema => $SETTLEMENT_SCHEMA, runtime_authorized => 0,
    executable => undef, selection => undef, selection_sealed => 1, receipts => []};
# Conservative encoded envelope + complete selection + every bounded receipt
# and its comma. This does not replace the individual component ceilings.
my $SETTLEMENT_LIMIT = length($JSON->encode($ENVELOPE)) + $SELECTION_LIMIT
    + $WORK_LIMIT * ($RECEIPT_LIMIT + 1);

sub _same { return $JSON->encode($_[0]) eq $JSON->encode($_[1]); }
sub _copy { return $JSON->decode($JSON->encode($_[0])); }

sub _inactive {
    my ($record, $schema) = @_;
    die "expected inactive work record schema\n"
        unless NativeProxyRuntimeRecord::_string($record->{schema}) eq $schema;
    NativeProxyRuntimeRecord::_integer($record->{runtime_authorized});
    die "work record grants execution authority\n"
        unless $record->{runtime_authorized} == 0 && !defined($record->{executable});
}

sub _work {
    my ($entry) = @_;
    die "expected bounded work identifier\n"
        unless NativeProxyRuntimeRecord::_string($entry->{work_id}) =~ /\A[A-Za-z0-9_.:-]{1,64}\z/;
    NativeProxyRuntimeRecord::_digest($entry->{ownership_token});
    die "expected capture, helper or query role\n"
        unless NativeProxyRuntimeRecord::_string($entry->{role}) =~ /\A(?:capture|helper|query)\z/;
}

sub _validate_selection {
    my ($case, $request, $acquired, $selection) = @_;
    my $spec = NativeProxyObservationArchiveRecord::archive_specification($case, $request, $acquired);
    NativeProxyRuntimeRecord::_fields($selection, qw(schema runtime_authorized executable
        evidence_directory_identity observation_reference_key entries));
    _inactive($selection, $SELECTION_SCHEMA);
    die "work selection differs from original evidence identity\n"
        unless _same($selection->{evidence_directory_identity}, $spec->{evidence_directory_identity});
    die "work selection differs from original observation key\n"
        unless NativeProxyRuntimeRecord::_digest($selection->{observation_reference_key}) eq $spec->{observation_reference_key};
    my $entries = $selection->{entries};
    die "expected nonempty bounded work selection\n"
        unless ref($entries) eq 'ARRAY' && @$entries && @$entries <= $WORK_LIMIT;
    my %seen;
    for my $entry (@$entries) {
        NativeProxyRuntimeRecord::_fields($entry, qw(work_id ownership_token role));
        _work($entry);
        die "duplicate selected work identifier\n" if $seen{$entry->{work_id}}++;
    }
    die "work selection exceeds byte ceiling\n" if length($JSON->encode($selection)) > $SELECTION_LIMIT;
    return 1;
}

sub work_selection {
    die "expected store, request, acquisition and selected entries\n" unless @_ == 4;
    my ($case, $request, $acquired, $entries) = @_;
    my $spec = NativeProxyObservationArchiveRecord::archive_specification($case, $request, $acquired);
    my $selection = {schema => $SELECTION_SCHEMA, runtime_authorized => 0, executable => undef,
        evidence_directory_identity => $spec->{evidence_directory_identity},
        observation_reference_key => $spec->{observation_reference_key}, entries => $entries};
    _validate_selection($case, $request, $acquired, $selection);
    return _copy($selection);
}

sub encode_work_selection {
    die "expected store, request, acquisition and selection\n" unless @_ == 4;
    _validate_selection(@_);
    return $JSON->encode($_[3]);
}

sub _decode {
    my ($bytes, $limit) = @_;
    die "expected bounded ASCII work record bytes\n" unless defined($bytes) && !ref($bytes)
        && !utf8::is_utf8($bytes) && length($bytes) <= $limit && $bytes !~ /[^\x00-\x7f]/;
    my $record = eval { $JSON->decode($bytes) };
    die "invalid work record JSON\n" if $@;
    die "work record JSON is not canonical\n" unless $bytes eq $JSON->encode($record);
    return $record;
}

sub decode_work_selection {
    die "expected store, request, acquisition and selection bytes\n" unless @_ == 4;
    my ($case, $request, $acquired, $bytes) = @_;
    my $selection = _decode($bytes, $SELECTION_LIMIT);
    _validate_selection($case, $request, $acquired, $selection);
    return $selection;
}

sub _sealed {
    my ($value) = @_;
    NativeProxyRuntimeRecord::_integer($value);
    die "selected work is not sealed\n" unless $value == 1;
}

sub _complete_order {
    my ($entries, $receipts) = @_;
    die "expected every selected work receipt in original order\n"
        unless ref($receipts) eq 'ARRAY' && @$receipts == @$entries
            && !(grep { ref($_) ne 'HASH' } @$receipts)
            && _same([map { $_->{work_id} } @$receipts], [map { $_->{work_id} } @$entries]);
}

sub _work_match {
    my ($entry, $receipt) = @_;
    die "work receipt changes selected ownership or role\n"
        unless _same($entry, {map { $_ => $receipt->{$_} } qw(work_id ownership_token role)});
}

sub _cleanup_settled {
    my ($cleanup) = @_;
    NativeProxyRuntimeRecord::_fields($cleanup, qw(leader_started leader_reaped group_gone));
    die "selected work cleanup is incomplete\n"
        unless NativeProxyCleanupReceipts::_settled_owner({cleanup => $cleanup});
}

sub validate_work_settlement {
    die "expected store, request, acquisition, original selection and settlement\n" unless @_ == 5;
    my ($case, $request, $acquired, $selection, $settlement) = @_;
    _validate_selection($case, $request, $acquired, $selection);
    NativeProxyRuntimeRecord::_fields($settlement, qw(schema runtime_authorized executable selection selection_sealed receipts));
    _inactive($settlement, $SETTLEMENT_SCHEMA);
    die "settlement replaces original selection\n" unless _same($settlement->{selection}, $selection);
    _sealed($settlement->{selection_sealed});
    my $receipts = $settlement->{receipts};
    _complete_order($selection->{entries}, $receipts);
    for my $index (0..$#$receipts) {
        my $receipt = $receipts->[$index];
        NativeProxyRuntimeRecord::_fields($receipt, qw(work_id ownership_token role outcome cleanup));
        _work($receipt);
        _work_match($selection->{entries}[$index], $receipt);
        die "expected completed, failed or cancelled outcome\n"
            unless NativeProxyRuntimeRecord::_string($receipt->{outcome}) =~ /\A(?:completed|failed|cancelled)\z/;
        _cleanup_settled($receipt->{cleanup});
        die "work receipt exceeds byte ceiling\n" if length($JSON->encode($receipt)) > $RECEIPT_LIMIT;
    }
    die "work settlement exceeds byte ceiling\n" if length($JSON->encode($settlement)) > $SETTLEMENT_LIMIT;
    return 1;
}

sub work_settlement {
    die "expected store, request, acquisition, selection, receipts and seal\n" unless @_ == 6;
    my ($case, $request, $acquired, $selection, $receipts, $sealed) = @_;
    my $settlement = {%$ENVELOPE, selection => $selection, receipts => $receipts, selection_sealed => $sealed};
    validate_work_settlement($case, $request, $acquired, $selection, $settlement);
    return _copy($settlement);
}

sub encode_work_settlement {
    die "expected store, request, acquisition, selection and settlement\n" unless @_ == 5;
    validate_work_settlement(@_);
    return $JSON->encode($_[4]);
}

sub decode_work_settlement {
    die "expected store, request, acquisition, selection and settlement bytes\n" unless @_ == 5;
    my ($case, $request, $acquired, $selection, $bytes) = @_;
    my $settlement = _decode($bytes, $SETTLEMENT_LIMIT);
    validate_work_settlement($case, $request, $acquired, $selection, $settlement);
    return $settlement;
}

1;
