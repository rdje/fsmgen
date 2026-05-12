#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_parser_method_names
);

subtest 'ISF parser facade advertises and accepts the public method set' => sub {
    is_deeply(
        isf_public_interface_parser_method_names(),
        [qw(new parse_file parse_source)],
        'contract advertises the public parser method names',
    );

    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();

    my $from_file = $adapter->parse_file($path);
    is($from_file->{actor_name}, 'apb_requester', 'parse_file accepts one scalar path');

    my $from_source = $adapter->parse_source($source, 'inline-apb-requester.isf');
    is($from_source->{actor_name}, 'apb_requester', 'parse_source accepts source text and label');
};

subtest 'ISF parser facade rejects malformed public method arguments' => sub {
    my $adapter = FSM::Adapter::ISF->new();

    assert_rejects(
        sub { $adapter->parse_file() },
        qr/parse_file expects exactly 1 scalar argument\(s\)/,
        'parse_file rejects missing path',
    );
    assert_rejects(
        sub { $adapter->parse_file('one.isf', 'two.isf') },
        qr/parse_file expects exactly 1 scalar argument\(s\)/,
        'parse_file rejects extra path',
    );
    assert_rejects(
        sub { $adapter->parse_file(['not-scalar']) },
        qr/parse_file argument 1 must be a defined scalar/,
        'parse_file rejects reference path',
    );

    assert_rejects(
        sub { $adapter->parse_source('(actor x)',) },
        qr/parse_source expects exactly 2 scalar argument\(s\)/,
        'parse_source rejects missing label',
    );
    assert_rejects(
        sub { $adapter->parse_source('(actor x)', 'x.isf', 'extra') },
        qr/parse_source expects exactly 2 scalar argument\(s\)/,
        'parse_source rejects extra argument',
    );
    assert_rejects(
        sub { $adapter->parse_source([], 'x.isf') },
        qr/parse_source argument 1 must be a defined scalar/,
        'parse_source rejects reference source text',
    );
    assert_rejects(
        sub { $adapter->parse_source('(actor x)', undef) },
        qr/parse_source argument 2 must be a defined scalar/,
        'parse_source rejects undefined source label',
    );
};

done_testing();

sub assert_rejects {
    my ($code, $pattern, $label) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok, $label);
    like($@, $pattern, "$label diagnostic");
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
