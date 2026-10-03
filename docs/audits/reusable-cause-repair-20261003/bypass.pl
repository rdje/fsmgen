use strict;
use warnings;
use lib 'perl', 't/lib';
use FSM::Scheduler::ISF;
open my $fh, '<:raw', 'perl/FSM/Scheduler/ISF/LoweringIR.pm' or die $!;
my $source = do {local $/; <$fh>};
close $fh or die $!;
my $start = index($source, 'sub _build_module_child_products(');
my $end = index($source, 'sub _build_generated_transaction_children(', $start);
die 'actual child producer missing' unless $start >= 0 && $end > $start;
my $body = substr($source, $start, $end - $start);
# Disable only the library-versus-generated module collision guard. All actual
# child construction and subsequent validation remain in the original body.
my $guard = 'if exists $child_irs{$module};';
my $position = index($body, $guard);
die 'library collision guard missing' unless $position >= 0;
substr($body, $position, length($guard), 'if 0 && exists $child_irs{$module};');
{
    no warnings 'redefine';
    eval 'package FSM::Scheduler::ISF::LoweringIR; use feature "signatures";'
        . 'no warnings "experimental::signatures";' . $body;
    die $@ if $@;
}
my $result = do './t/1947-isf-formal-reusable-products.t';
die $@ if $@;
die $! unless defined $result;
