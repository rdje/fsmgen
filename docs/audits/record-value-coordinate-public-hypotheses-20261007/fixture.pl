use strict;
use warnings;
use lib 'lib';
use JSON::PP;
use Carp ();
use Test::More;
use CoordinateDependency;

package CoordinatePublic;
our @observations;
sub frames {
    my @rows;
    for my $depth (0 .. 127) {
        my @frame = caller($depth);
        last unless @frame;
        push @rows, [@frame[0 .. 7]];
    }
    return \@rows;
}
sub observe {
    my ($role) = @_;
    my $frames = frames();
    my $trace = Carp::longmess("public coordinate fixture\n");
    my $ok = eval { Carp::confess("public coordinate guard\n"); 1 };
    my $error = $@;
    push @observations, {role => $role, frames => $frames, trace => $trace,
        guard_ok => $ok, guard_error => $error};
    return 1;
}
sub single {
    observe('single'); # site single
}
sub multiline {
    observe( # site multiline
        'multiline'
    ); # end multiline
}
sub postfix {
    observe('postfix') for 1 .. 1; # site postfix
}
sub block_eval {
    my $ok = eval { # site eval boundary
        observe('block-eval'); # site block-eval
        1;
    }; # end eval boundary
    die $@ unless $ok;
}
sub anonymous {
    my $body = sub { observe('anonymous'); }; # site anonymous
    $body->(); # site anonymous delegate
}
sub load {
    my $value = do './load-body.pl'; # site do boundary
    die $@ if $@;
    die $! unless defined $value;
    my $required = require './require-body.pl'; # site require boundary
    die 'public require result' unless $required;
}

package main;
my $builder = Test::More->builder;
$builder->output(\*STDERR);
plan tests => 1;
CoordinatePublic::single();
CoordinatePublic::multiline();
CoordinatePublic::postfix();
CoordinatePublic::block_eval();
CoordinatePublic::anonymous();
CoordinatePublic::load();
CoordinateDependency::module_call();
my $subtest = Test::More->can('subtest');
$subtest->('public coordinate callback', sub {
    CoordinatePublic::observe('subtest'); # site subtest
    pass('public callback ran');
}); # end subtest boundary
print JSON::PP->new->canonical->encode({observations => \@CoordinatePublic::observations,
    module_filename => $INC{'CoordinateDependency.pm'}}), "\n";
