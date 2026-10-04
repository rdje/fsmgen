use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
use FSM::Test::DiagnosticCause qw(diagnostic_cause_matches);

my $json = JSON::PP->new->canonical;
my $base = 'docs/audits/interface-metadata-cause-repair-20261004';
open my $old_file, '<:raw', "$base/test-after.t" or die $!;
my $prior = do {local $/; <$old_file>}; close $old_file or die $!;
open my $current_file, '<:raw', 't/1983-isf-interface-port-metadata.t' or die $!;
my $current = do {local $/; <$current_file>}; close $current_file or die $!;
sub consumer {
    my ($body) = @_;
    my $start = index($body, "    ok(!\$ok, 'record output field writer remains deferred');");
    my $end = index($body, "\n};", $start);
    die 'complete writer consumer missing' unless $start >= 0 && $end > $start;
    return substr($body, $start, $end - $start);
}
{
    package PriorWriterContext;
    our ($ok, $error, @bits);
    sub ok {push @bits, $_[0] ? 1 : 0}
    sub like {push @bits, $_[0] =~ $_[1] ? 1 : 0}
}
{
    package CurrentWriterContext;
    our ($ok, $error, @bits, @causes);
    sub ok {push @bits, $_[0] ? 1 : 0}
    sub diagnostic_cause_matches {
        push @causes, [@_];
        return FSM::Test::DiagnosticCause::diagnostic_cause_matches(@_);
    }
}
my $old_consumer = consumer($prior);
my $current_consumer = consumer($current);
# Compile complete source consumers before any native call. Their expected
# text cannot become evidence through an active eval-source stack frame.
eval 'package PriorWriterContext; sub check {' . $old_consumer . "\n}";
die $@ if $@;
eval 'package CurrentWriterContext; sub check {' . $current_consumer . "\n}";
die $@ if $@;

my $source = '(actor refused (types (type packet_t (record (flag bit))))'
    . ' (interface (output packet (type packet_t)) (output done))'
    . ' (transaction main (set packet.flag 1) (complete done)))';
my $expected = "Invalid ISF record context: transaction 'main' set target record output field writes are not yet admitted; "
    . "target 'packet.flag' requires output-field writer qualification";
my @rows;
for my $case (
    ['real_output_writer', 1, 'field-refused.isf'],
    ['real_writer_wanted_filename', 1, 'record output field writes are not yet admitted.isf'],
    ['earlier_missing_actor', 0, 'field-refused.isf'],
    ['earlier_wanted_filename', 0, 'record output field writes are not yet admitted.isf'],
) {
    my ($id, $real, $filename) = @$case;
    my $submitted = $source;
    $submitted =~ s/\A\(actor /(library / unless $real;
    my $before = $json->encode([$submitted, $filename]);
    my $parser = FSM::Adapter::ISF->new;
    my ($result, @warnings);
    my $accepted = eval {
        local $SIG{__WARN__} = sub {push @warnings, @_};
        $result = $parser->parse_source($submitted, $filename);
        1;
    } ? 1 : 0;
    my $error = $@;
    @PriorWriterContext::bits = (); @CurrentWriterContext::bits = ();
    @CurrentWriterContext::causes = ();
    $PriorWriterContext::ok = $CurrentWriterContext::ok = $accepted;
    $PriorWriterContext::error = $CurrentWriterContext::error = $error;
    # The prior source reads ambient $@. Give it the exact saved native error,
    # without reconstructing, trimming or replacing any native diagnostic.
    {local $@ = $error; PriorWriterContext::check()}
    {local $@ = $error; CurrentWriterContext::check()}
    is($accepted, 0, "$id: actual public parser refuses");
    is_deeply(\@CurrentWriterContext::bits, [1, $real ? 1 : 0], "$id: complete current cause distinguishes intended refusal");
    is_deeply(\@PriorWriterContext::bits, [1, $real || $id eq 'earlier_wanted_filename' ? 1 : 0], "$id: exact prior fragment reproduces native outcome");
    is_deeply(\@CurrentWriterContext::causes, [[$error, $expected]], "$id: full native error and intended cause reach predicate");
    is($json->encode([$submitted, $filename]), $before, "$id: complete submitted source and filename unchanged");
    is_deeply(\@warnings, [], "$id: no incidental warnings");
    if ($real) {
        is((split /\n/, $error)[0], $expected, "$id: complete record/transaction/target primary retained");
    } else {
        is((split /\n/, $error)[0], "No (actor ...) form found in ISF source ($filename)", "$id: actual earlier parser primary retained");
    }
    push @rows, {id => $id, source => $submitted, filename => $filename,
        accepted => $accepted, error => $error, warnings => \@warnings,
        prior_bits => [@PriorWriterContext::bits], current_bits => [@CurrentWriterContext::bits],
        causes => [@CurrentWriterContext::causes], before => $json->decode($before),
        after => [$submitted, $filename], result => $result};
}
if (defined $ENV{FSMGEN_WRITER_CONTEXT_CAPTURE}) {
    open my $out, '>:raw', $ENV{FSMGEN_WRITER_CONTEXT_CAPTURE} or die $!;
    print {$out} $json->encode({prior_source => $prior, current_source => $current,
        prior_consumer => $old_consumer, current_consumer => $current_consumer,
        source => $source, expected => $expected, rows => \@rows}), "\n" or die $!;
    close $out or die $!;
}
done_testing;
