use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use FSM::Adapter::ISF;
my $base = 'docs/audits/interface-metadata-runtime-20261004';
my $json = JSON::PP->new->canonical;
my $parser = FSM::Adapter::ISF->new;
my $source = '(actor refused (types (type packet_t (record (flag bit))))'
    . ' (interface (output packet (type packet_t)) (output done))'
    . ' (transaction main (set packet.flag 1) (complete done)))';
open my $fh, '<:raw', 't/1983-isf-interface-port-metadata.t' or die $!;
my $test = do {local $/; <$fh>}; close $fh or die $!;
my $start = index($test, "    ok(!\$ok, 'record output field writer remains deferred');");
my $end = index($test, "\n};", $start);
die 'exact adjacent consumer missing' unless $start >= 0 && $end > $start;
my $consumer = substr($test, $start, $end - $start);
our ($ok, $observed);
eval 'sub adjacent_consumer {' . $consumer . "\n}"; die $@ if $@;
my @rows;
{
    no warnings 'redefine';
    local *main::like = sub ($$;$) {
        my ($actual, $pattern, $label) = @_;
        my ($first) = split /\n/, $actual;
        $observed = {error => $actual, pattern => "$pattern", matched => $actual =~ $pattern ? 1 : 0,
            first_line_matched => defined($first) && $first =~ $pattern ? 1 : 0};
        return Test::More::like($actual, $pattern, $label);
    };
    for my $case (
        ['real_output_writer', $source, 'field-refused.isf'],
        ['earlier_missing_actor', $source, 'field-refused.isf'],
        ['caller_filename_echo', $source, 'record output field writes are not yet admitted.isf'],
    ) {
        my ($id, $submitted, $filename) = @$case;
        $submitted =~ s/\A\(actor /(library / if $id ne 'real_output_writer';
        $observed = undef;
        $ok = eval {$parser->parse_source($submitted, $filename); 1};
        my $error = $@;
        adjacent_consumer();
        die 'actual adjacent consumer missing' unless $observed;
        push @rows, {id => $id, source => $submitted, filename => $filename,
            accepted => $ok ? 1 : 0, saved_error => $error, consumer => $observed};
    }
}
open my $out, '>:raw', "$base/adjacent-controls.json" or die $!;
print {$out} $json->encode({consumer => $consumer, rows => \@rows}), "\n" or die $!;
close $out or die $!;
done_testing;
