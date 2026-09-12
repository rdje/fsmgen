#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP ();

our (@calls, @delegations);

# These are inert language-binding probes. No branch invokes a real syscall.
# Install initial hooks before the reader compiles, as the integrated seam will.
BEGIN {
    *CORE::GLOBAL::sysread = sub (*$$;$) {
        push @calls, {hook => 'early_read', caller => scalar(caller), arity => scalar(@_)};
        $_[1] = 'early';
        return 11;
    };
    *CORE::GLOBAL::sysopen = sub (*$$;$) {
        push @calls, {hook => 'early_open', caller => scalar(caller), arity => scalar(@_)};
        $_[0] = 'early-handle';
        return 11;
    };
}

{
    package NativeProxyReadbackBindingReader;
    sub read_three { return sysread($_[0], $_[1], $_[2]); }
    sub read_four { return sysread($_[0], $_[1], $_[2], $_[3]); }
    sub open_three { return sysopen($_[0], $_[1], $_[2]); }
    sub open_four { return sysopen($_[0], $_[1], $_[2], $_[3]); }
}

# Replace hooks after the target code compiles. Tail delegation must keep both
# the immediate caller and caller-owned argument aliases intact.
BEGIN {
    no warnings 'redefine';
    my $read = sub (*$$;$) {
        push @calls, {hook => 'late_read', caller => scalar(caller), arity => scalar(@_),
            handle => $_[0], requested => $_[2], offset => @_ == 4 ? $_[3] : undef};
        $_[1] = 'late-buffer';
        return 1;
    };
    *CORE::GLOBAL::sysread = sub (*$$;$) {
        push @delegations, {operation => 'read', arity => scalar(@_), requested => $_[2]};
        splice @_, 2, 1, 1;
        goto &$read;
    };
    my $open = sub (*$$;$) {
        push @calls, {hook => 'late_open', caller => scalar(caller), arity => scalar(@_),
            path => $_[1], flags => $_[2], mode => @_ == 4 ? $_[3] : undef};
        $_[0] = 'late-handle';
        return 1;
    };
    *CORE::GLOBAL::sysopen = sub (*$$;$) {
        push @delegations, {operation => 'open', arity => scalar(@_)};
        goto &$open;
    };
}

my $handle = 'inert-handle';
my $buffer = 'original';
my $requested = 16;
is(NativeProxyReadbackBindingReader::read_three($handle, $buffer, $requested), 1,
   'compiled three-argument read reaches replacement hook');
is($buffer, 'late-buffer', 'read buffer alias survives tail delegation');
is($requested, 16, 'slot replacement leaves caller request scalar intact');
is($handle, 'inert-handle', 'read handle argument remains intact');
is(NativeProxyReadbackBindingReader::read_four($handle, $buffer, 32, 2), 1,
   'compiled four-argument read reaches replacement hook');
is($buffer, 'late-buffer', 'four-argument read retains buffer alias');
my $opened;
is(NativeProxyReadbackBindingReader::open_three($opened, 'inert-source', 123), 1,
   'compiled three-argument open reaches replacement hook');
is($opened, 'late-handle', 'open handle slot remains a caller alias');
is(NativeProxyReadbackBindingReader::open_four($opened, 'inert-source', 123, 256), 1,
   'compiled four-argument open reaches replacement hook');
is($opened, 'late-handle', 'four-argument open retains caller handle alias');
is_deeply(\@delegations, [
    {operation => 'read', arity => 3, requested => 16},
    {operation => 'read', arity => 4, requested => 32},
    {operation => 'open', arity => 3},
    {operation => 'open', arity => 4},
], 'wrappers preserve original arity and record caller request before reducing it');
is_deeply(\@calls, [
    {hook => 'late_read', caller => 'NativeProxyReadbackBindingReader', arity => 3,
        handle => 'inert-handle', requested => 1, offset => undef},
    {hook => 'late_read', caller => 'NativeProxyReadbackBindingReader', arity => 4,
        handle => 'inert-handle', requested => 1, offset => 2},
    {hook => 'late_open', caller => 'NativeProxyReadbackBindingReader', arity => 3,
        path => 'inert-source', flags => 123, mode => undef},
    {hook => 'late_open', caller => 'NativeProxyReadbackBindingReader', arity => 4,
        path => 'inert-source', flags => 123, mode => 256},
], 'compiled calls use replacement hooks with exact caller, aliases and delegated arguments');
diag(JSON::PP->new->canonical->ascii->encode({perl_version => "$^V", calls => \@calls,
    delegations => \@delegations, real_syscalls => 0, allocated_fixtures => 0}));
done_testing;
