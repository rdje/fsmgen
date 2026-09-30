#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'perl';
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $header=<<'ISF';
(actor domain_paths
 (clock-domains (domain core (clock clk) :default) (domain aux (clock aux_clk)))
 (types (type record_t (record (payload (bits 8))))
        (type list_t (list (record (payload (bits 8))))))
 (enums (mode (IDLE 0) (BUSY 1)))
 (interface (input start) (input data (width 8)) (output seen (width 8)) (output finished)
            (output aux_seen (width 8) (domain aux)))
 (storage (var record_value (type record_t) (domain aux))
          (var lanes (type list_t) (domain aux))
          (var scalar (width 8) (domain aux)))
ISF

for my $case (
 ['member read', '(transaction main (on start) (set seen record_value.payload))', 'read', 'record_value.payload'],
 ['member slice read', '(transaction main (on start) (set seen record_value.payload[3:0]))', 'read', 'record_value.payload[3:0]'],
 ['nested list member slice read', '(transaction main (on start) (set seen lanes[0].payload[3:0]))', 'read', 'lanes[0].payload[3:0]'],
 ['scalar storage slice read', '(transaction main (on start) (set seen scalar[3:0]))', 'read', 'scalar[3:0]'],
 ['nested list read', '(transaction main (on start) (set seen lanes[0].payload))', 'read', 'lanes[0].payload'],
 ['member write', '(transaction main (on start) (set record_value.payload data))', 'write', 'record_value.payload'],
 ['nested list write', '(transaction main (on start) (set lanes[0].payload data))', 'write', 'lanes[0].payload'],
 ['whole write', '(transaction main (on start) (set record_value data))', 'write', 'record_value'],
 ['scalar write', '(transaction main (on start) (set scalar data))', 'write', 'scalar'],
 ['output write', '(transaction main (on start) (set aux_seen data))', 'write', 'aux_seen'],
 ['nested write', '(transaction main (on start) (when data (set scalar 1)))', 'write', 'scalar'],
 ['read then inferred write', '(transaction main (on start) (set seen scalar) (set scalar data))', 'read', 'scalar'],
 ['rule read', '(rule observe 1 (seen record_value.payload))', 'read', 'record_value.payload'],
 ['rule write', '(rule observe 1 (lanes[0].payload data))', 'write', 'lanes[0].payload'],
 ['guard read', '(rule observe lanes[0].payload (seen data))', 'read', 'lanes[0].payload'],
) {
 my ($label,$body,$access,$signal)=@$case;
 subtest $label => sub {
  my $error=lower_error($header.$body.')');
  my ($diagnostic) = split /\n/, $error;
  like($diagnostic // '',qr/clock-domain violation: .* $access signal '\Q$signal\E' owned by domain 'aux' from domain 'core' without a crossing primitive/,
       'declared root ownership rejects access before emission');
 };
}

subtest 'scalar input slices and bit indexes retain declared ownership' => sub {
 my $source = $header;
 $source =~ s/\(input data \(width 8\)\)/(input data (width 8) (domain aux))/;
 for my $token (qw(data data[3:0] data[0:3] data[7:7] data[0])) {
  my $error=lower_error($source."(transaction main (on start) (set seen $token)))");
  my ($diagnostic) = split /\n/, $error;
  like($diagnostic // '',qr/clock-domain violation: .* read signal '\Q$token\E' owned by domain 'aux' from domain 'core' without a crossing primitive/,
       "foreign input '$token' refuses in its diagnostic line");
 }
};

subtest 'same-domain leaves, inferred locals and enum members remain valid' => sub {
 my $source=$header;
 $source =~ s/\(domain aux\)/\(domain core\)/g;
 my $body=<<'ISF';
 (transaction main (on start)
 (set scratch data) (set record_value.payload scratch) (set lanes[0].payload record_value.payload)
  (set seen record_value.payload[3:0]) (set seen scalar[3:0]) (set seen data[0])
  (when mode.BUSY (set seen lanes[0].payload))))
ISF
 is(lower_error($source.$body),'','same-domain paths and inferred local assignments lower');
};

subtest 'explicit generated transaction ports retain their local identity and domain' => sub {
 is(lower_error($header.'(transaction worker (ports (input scalar (width 8)) (output result (width 8))) (set result scalar[3:0]) (complete done)) (transaction parent (on start) (spawn worker as reader (bind (input scalar data) (output result seen))) (await_all done) (complete finished)))'),
    '', 'formal scalar slice uses local ownership despite foreign same-named storage');
 is(lower_error($header.'(transaction worker (ports (input scalar (width 8)) (output result (width 8))) (set result scalar) (complete done)) (transaction parent (on start) (spawn worker as reader (bind (input scalar data) (output result seen))) (await_all done) (complete finished)))'),
    '', 'explicit input shadows sibling-domain actor storage');
 is(lower_error($header.'(transaction worker (ports (output scalar (width 8))) (set scalar data) (complete done)) (transaction parent (on start) (spawn worker as writer (bind (output scalar seen))) (await_all done) (complete finished)))'),
    '', 'explicit output shadows sibling-domain actor storage');
 is(lower_error($header.'(transaction worker (ports (input aux_seen (width 8)) (output result (width 8))) (set result aux_seen) (complete done)) (transaction parent (on start) (spawn worker as reader (bind (input aux_seen data) (output result seen))) (await_all done) (complete finished)))'),
    '', 'explicit child port keeps its domain despite a sibling-domain actor port with the same name');
};

done_testing();
sub lower_error {
 my ($text)=@_;
 my $ok=eval {
  my $actor=FSM::Adapter::ISF->new->parse_source($text,'domain_paths.isf');
  FSM::Scheduler::ISF->new->lower($actor);
  1;
 };
 return $ok ? '' : $@;
}
