use strict;
use warnings;
use JSON::PP;
use Carp ();

package PublicFixture;
use Test::More;

our @observations;
our $loaded;
sub frames {
    my @rows;
    for my $depth (0 .. 127) {
        my @frame = caller($depth);
        last unless @frame;
        push @rows, [@frame[0 .. 7]];
    }
    return \@rows;
}
sub leaf { return frames() }
sub more_empty {
    push @observations, { role => 'more-empty', body => 'more_empty',
        arguments => [@_], frames => leaf() };
    pass('public callback executed');
}
sub more_extra {
    push @observations, { role => 'more-extra', body => 'more_extra',
        arguments => [@_], frames => leaf() };
    pass('public callback executed');
}
sub builder_extra {
    push @observations, { role => 'builder-extra', body => 'builder_extra',
        arguments => [@_], frames => leaf() };
    pass('public callback executed');
}
sub eval_success {
    my $frames;
    my $value = eval { $frames = leaf(); 'public-eval-result' };
    my $error = $@;
    return { role => 'eval-success', value => $value, error => $error,
        frames => $frames };
}
sub eval_failure {
    my $frames;
    my $value = eval { $frames = leaf(); die "public-eval-failure\n" };
    my $error = $@;
    return { role => 'eval-failure', value => $value, error => $error,
        frames => $frames };
}
sub do_load {
    local $loaded;
    my $value = do './docs/audits/record-value-public-native-fixtures-20261006/load-body.pl';
    my $error = $@;
    return { role => 'do-load', value => $value, error => $error, loaded => $loaded };
}
sub require_load {
    local $loaded;
    my $value = require './docs/audits/record-value-public-native-fixtures-20261006/require-body.pl';
    return { role => 'require-load', value => $value, error => $@, loaded => $loaded };
}
sub trace_inner { return Carp::longmess("public-trace-message\n") }
sub trace_outer { return trace_inner(@_) }

my $builder = Test::More->builder;
$builder->output(\*STDERR);
plan tests => 3;
subtest 'public empty' => \&more_empty;
subtest 'public extra' => \&more_extra, 'public-argument-A', 'public-argument-B';
$builder->subtest('public builder', \&builder_extra, 'public-builder-A');
push @observations, eval_success(), eval_failure(), do_load(), require_load();
for my $mode ('full', 'suppressed') {
    local $Carp::MaxArgLen = 0;
    local $Carp::MaxArgNums = $mode eq 'full' ? 0 : -1;
    push @observations, { role => 'trace-' . $mode,
        text => trace_outer('public-trace-A', 'public-trace-B') };
}
print JSON::PP->new->canonical->encode({ observations => \@observations }), "\n";
