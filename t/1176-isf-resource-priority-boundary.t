#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Support::ISFResourceCatalog qw(
    isf_resource_arbiter_values
    isf_resource_kind_values
);

sub parse_source {
    my ($source) = @_;
    return FSM::Adapter::ISF->new()->parse_source($source, 'resource-priority-boundary.isf');
}

sub assert_parse_rejected {
    my ($source, $label, $diagnostic_re) = @_;

    my $ok = eval {
        parse_source($source);
        1;
    };

    ok(!$ok, "$label is rejected by the parser");
    like($@, $diagnostic_re, "$label diagnostic is targeted");
}

subtest 'valid resource and priority metadata survives parsing' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'full_featured.isf');
    my $actor = FSM::Adapter::ISF->new()->parse_file($path);

    is_deeply(
        $actor->{priorities},
        [['main_transfer', 'over', 'chained']],
        'actor-level priority shape is preserved',
    );
    is_deeply(
        $actor->{resources},
        [
            { name => 'shared_bus', arbiter => 'priority' },
            { name => 'mem_port',   arbiter => 'round_robin' },
        ],
        'resource metadata shape is preserved',
    );
};

subtest 'resource parser accepts the shared resource catalog values' => sub {
    my @resources;
    my $index = 0;
    for my $kind (@{isf_resource_kind_values()}) {
        push @resources, sprintf(
            '    (resource res_%02d (kind %s) (arbiter priority))',
            ++$index,
            $kind,
        );
    }

    my $source = join("\n",
        '(actor resource_catalog_values',
        '  (clock clk)',
        '  (interface (input start) (output done))',
        '  (transaction main (on start) (complete done))',
        '  (resources',
        @resources,
        '  ))',
        '',
    );

    my $actor = parse_source($source);
    is_deeply(
        [map { $_->{kind} } @{$actor->{resources}}],
        isf_resource_kind_values(),
        'parser accepts every shared resource kind from the catalog',
    );
    is_deeply(
        isf_resource_arbiter_values(),
        [qw(priority round_robin)],
        'shared resource arbiter catalog remains explicit',
    );
};

subtest 'output_bundle members survive parsing and validate declared outputs and storage' => sub {
    my $actor = parse_source(<<'ISF');
(actor output_bundle_member_metadata
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid)
    (output err))
  (storage
    (var status (width 1)))
  (transaction main (on start) (complete done))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members valid err status)
      (users high low)))
  (rule high a
    (valid 1))
  (rule low b
    (err 1)
    (status 1)))
ISF

    is_deeply(
        $actor->{resources},
        [
            {
                name    => 'response_outputs',
                kind    => 'output_bundle',
                arbiter => 'priority',
                members => ['valid', 'err', 'status'],
                users   => ['high', 'low'],
            },
        ],
        'output_bundle member metadata is preserved',
    );
};

subtest 'transaction_start resource metadata validates local transactions and rule users' => sub {
    my $actor = parse_source(<<'ISF');
(actor transaction_start_resource_metadata
  (clock clk)
  (interface
    (input high_req)
    (input low_req)
    (output done))
  (transaction work
    (on work_start)
    (complete done))
  (priority high over low)
  (resources
    (resource work
      (kind transaction_start)
      (arbiter priority)
      (users high low)))
  (rule high high_req
    (trigger work))
  (rule low low_req
    (trigger work)))
ISF

    is_deeply(
        $actor->{resources},
        [
            {
                name    => 'work',
                kind    => 'transaction_start',
                arbiter => 'priority',
                users   => ['high', 'low'],
            },
        ],
        'transaction_start resource metadata is preserved',
    );
};

subtest 'storage_port members survive parsing and validate actor-owned storage' => sub {
    my $actor = parse_source(<<'ISF');
(actor storage_port_member_metadata
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done)
    (output valid))
  (storage
    (var slot (width 1))
    (bank data (width 8) (depth 2)))
  (transaction main (on start) (complete done))
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (members slot data_0 data_1)
      (users high low)))
  (priority high over low)
  (rule high a
    (slot 1)
    (data_0 3))
  (rule low b
    (data_1 4)))
ISF

    is_deeply(
        $actor->{resources},
        [
            {
                name    => 'store_bus',
                kind    => 'storage_port',
                arbiter => 'priority',
                members => ['slot', 'data_0', 'data_1'],
                users   => ['high', 'low'],
            },
        ],
        'storage_port member metadata is preserved',
    );
};

subtest 'malformed resources are rejected before actor shell return' => sub {
    assert_parse_rejected(<<'ISF', 'malformed resource keyword', qr/resource entries require/);
(actor bad_resource_keyword
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (shared_bus (arbiter priority))))
ISF

    assert_parse_rejected(<<'ISF', 'unsupported resource arbiter', qr/resource 'shared_bus' arbiter requires/);
(actor bad_resource_arbiter
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource shared_bus (arbiter lottery))))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate resource name', qr/duplicate resource 'shared_bus'/);
(actor duplicate_resource
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource shared_bus (arbiter priority))
    (resource shared_bus (arbiter round_robin))))
ISF

    assert_parse_rejected(<<'ISF', 'members require output_bundle or storage_port kind', qr/resource 'shared_bus' members are supported only with '\(kind output_bundle\)' or '\(kind storage_port\)'/);
(actor members_on_rule_slot
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource shared_bus
      (kind rule_slot)
      (arbiter priority)
      (members done))))
ISF

    assert_parse_rejected(<<'ISF', 'duplicate output_bundle member', qr/duplicate resource 'response_outputs' member 'done'/);
(actor duplicate_output_bundle_member
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members done done))))
ISF

    assert_parse_rejected(<<'ISF', 'input cannot be output_bundle member', qr/resource 'response_outputs' member 'start' is not a declared actor output or actor-owned storage signal/);
(actor input_output_bundle_member
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members start))))
ISF

    assert_parse_rejected(<<'ISF', 'bank root cannot be output_bundle member', qr/resource 'response_outputs' member 'data' is not a declared actor output or actor-owned storage signal/);
(actor bank_root_output_bundle_member
  (clock clk)
  (interface (input start) (output done))
  (storage
    (bank data (width 8) (depth 2)))
  (transaction main (on start) (complete done))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members data))))
ISF

    assert_parse_rejected(<<'ISF', 'unknown output_bundle member', qr/resource 'response_outputs' member 'missing' is not a declared actor output or actor-owned storage signal/);
(actor unknown_output_bundle_member
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (resources
    (resource response_outputs
      (kind output_bundle)
      (arbiter priority)
      (members missing))))
ISF

    assert_parse_rejected(<<'ISF', 'storage_port with users requires members', qr/storage_port resource 'store_bus' with users requires explicit/);
(actor storage_port_without_members
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (var slot (width 1)))
  (transaction main (on start) (complete done))
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (slot 0)))
ISF

    assert_parse_rejected(<<'ISF', 'output cannot be storage_port member', qr/resource 'store_bus' member 'done' is not a declared actor-owned storage signal/);
(actor output_storage_port_member
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (var slot (width 1)))
  (transaction main (on start) (complete done))
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (members done)
      (users high low)))
  (rule high a
    (slot 1))
  (rule low b
    (slot 0)))
ISF

    assert_parse_rejected(<<'ISF', 'bank root cannot be storage_port member', qr/resource 'store_bus' member 'data' is not a declared actor-owned storage signal/);
(actor bank_root_storage_port_member
  (clock clk)
  (interface
    (input start)
    (input a)
    (input b)
    (output done))
  (storage
    (bank data (width 8) (depth 2)))
  (transaction main (on start) (complete done))
  (resources
    (resource store_bus
      (kind storage_port)
      (arbiter priority)
      (members data)
      (users high low)))
  (rule high a
    (data_0 1))
  (rule low b
    (data_1 0)))
ISF

    assert_parse_rejected(<<'ISF', 'transaction_start resource name must be a transaction', qr/transaction_start resource 'missing' is not a declared transaction/);
(actor unknown_transaction_start_resource
  (clock clk)
  (interface
    (input ready)
    (output done))
  (transaction work
    (on work_start)
    (complete done))
  (resources
    (resource missing
      (kind transaction_start)
      (arbiter priority)
      (users high)))
  (rule high ready
    (trigger work)))
ISF
};

subtest 'malformed priorities are rejected before actor shell return' => sub {
    assert_parse_rejected(<<'ISF', 'actor priority without over', qr/\(priority \.\.\.\) requires/);
(actor bad_actor_priority
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (priority main chained))
ISF

    assert_parse_rejected(<<'ISF', 'rule priority without target', qr/rule 'high_pri' priority requires/);
(actor bad_rule_priority
  (clock clk)
  (interface (input start) (output done))
  (transaction main (on start) (complete done))
  (rule high_pri start
    (priority over)
    (done 1)))
ISF
};

done_testing();
