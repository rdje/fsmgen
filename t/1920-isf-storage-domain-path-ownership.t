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
 (storage (var record (type record_t) (domain aux))
          (var lanes (type list_t) (domain aux))
          (var scalar (width 8) (domain aux)))
ISF

for my $case (
 ['member read', '(transaction main (on start) (set seen record.payload))', 'read', 'record.payload'],
 ['nested list read', '(transaction main (on start) (set seen lanes[0].payload))', 'read', 'lanes[0].payload'],
 ['member write', '(transaction main (on start) (set record.payload data))', 'write', 'record.payload'],
 ['nested list write', '(transaction main (on start) (set lanes[0].payload data))', 'write', 'lanes[0].payload'],
 ['whole write', '(transaction main (on start) (set record data))', 'write', 'record'],
 ['scalar write', '(transaction main (on start) (set scalar data))', 'write', 'scalar'],
 ['output write', '(transaction main (on start) (set aux_seen data))', 'write', 'aux_seen'],
 ['nested write', '(transaction main (on start) (when data (set scalar 1)))', 'write', 'scalar'],
 ['read then inferred write', '(transaction main (on start) (set seen scalar) (set scalar data))', 'read', 'scalar'],
 ['rule read', '(rule observe 1 (seen record.payload))', 'read', 'record.payload'],
 ['rule write', '(rule observe 1 (lanes[0].payload data))', 'write', 'lanes[0].payload'],
 ['guard read', '(rule observe lanes[0].payload (seen data))', 'read', 'lanes[0].payload'],
) {
 my ($label,$body,$access,$signal)=@$case;
 subtest $label => sub {
  my $error=lower_error($header.$body.')');
  like($error,qr/clock-domain violation: .* $access signal '\Q$signal\E' owned by domain 'aux' from domain 'core' without a crossing primitive/,
       'declared root ownership rejects access before emission');
 };
}

subtest 'same-domain leaves, inferred locals and enum members remain valid' => sub {
 my $source=$header;
 $source =~ s/\(domain aux\)/\(domain core\)/g;
 my $body=<<'ISF';
 (transaction main (on start)
  (set scratch data) (set record.payload scratch) (set lanes[0].payload record.payload)
  (when mode.BUSY (set seen lanes[0].payload))))
ISF
 is(lower_error($source.$body),'','same-domain paths and inferred local assignments lower');
};

subtest 'explicit generated transaction ports retain their local identity and domain' => sub {
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
