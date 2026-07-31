package FSM::HIAL::VIALBridge::Report;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::HIAL::VIALBridge::Manifest;

sub build($class, @args) {
    confess __PACKAGE__ . "->build must be called with the report class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess __PACKAGE__ . "->build expects exactly one HIAL/VIAL bridge manifest object\n"
        unless @args == 1
            && blessed($args[0])
            && $args[0]->isa('FSM::HIAL::VIALBridge::Manifest');
    return $args[0]->as_hashref;
}

1;
