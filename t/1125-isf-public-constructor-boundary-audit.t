#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::ISFPublicInterfaceContract qw(
    isf_public_interface_constructor_option_names
);

my @facades = (
    {
        label => 'adapter facade',
        class => 'FSM::Adapter::ISF',
    },
    {
        label => 'scheduler facade',
        class => 'FSM::Scheduler::ISF',
    },
);

subtest 'ISF public constructors accept the advertised debug option' => sub {
    is_deeply(
        isf_public_interface_constructor_option_names(),
        [qw(debug)],
        'contract advertises only debug as a constructor option',
    );

    for my $facade (@facades) {
        my $class = $facade->{class};
        my $default = $class->new();
        isa_ok($default, $class, "$facade->{label} default constructor");

        my $debug = $class->new(debug => 1);
        isa_ok($debug, $class, "$facade->{label} debug constructor");
    }
};

subtest 'ISF public constructors reject malformed option lists' => sub {
    for my $facade (@facades) {
        my $class = $facade->{class};

        my $odd_ok = eval { $class->new('debug'); 1 };
        ok(!$odd_ok, "$facade->{label} rejects odd option list");
        like(
            $@,
            qr/\Q$class\E->new expects an even-length option\/value list/,
            "$facade->{label} odd-list diagnostic is bounded",
        );

        my $unknown_ok = eval { $class->new(verbose => 1); 1 };
        ok(!$unknown_ok, "$facade->{label} rejects unsupported option");
        like(
            $@,
            qr/\Q$class\E->new unsupported option 'verbose'; supported option: debug/,
            "$facade->{label} unsupported-option diagnostic is bounded",
        );
    }
};

done_testing();
