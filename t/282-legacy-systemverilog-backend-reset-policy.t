#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Backend;

subtest 'legacy template SystemVerilog backend honors synchronous active-high sreset policy' => sub {
    my $backend = FSM::Backend::create_backend('systemverilog');
    my $hdl = $backend->generate(fake_module({
        clock => 'clk',
        reset => 'reset',
        reset_keyword => 'sreset',
        reset_kind => 'sync',
        reset_active_level => 1,
    }));

    like($hdl, qr/always_ff \@\(posedge clk\) begin/s, 'legacy backend emits a clock-only event control for sreset');
    like($hdl, qr/if \(reset\) begin/s, 'legacy backend emits an active-high reset condition for sreset');
    unlike($hdl, qr/negedge reset/s, 'legacy backend does not emit asynchronous active-low reset for sreset');
};

subtest 'legacy template SystemVerilog backend honors asynchronous active-low areset policy' => sub {
    my $backend = FSM::Backend::create_backend('systemverilog');
    my $hdl = $backend->generate(fake_module({
        clock => 'clk',
        reset => 'rst_n',
        reset_keyword => 'areset',
        reset_kind => 'async',
        reset_active_level => 0,
    }));

    like($hdl, qr/always_ff \@\(posedge clk or negedge rst_n\) begin/s, 'legacy backend emits an async active-low reset event control for areset');
    like($hdl, qr/if \(!rst_n\) begin/s, 'legacy backend emits an active-low reset condition for areset');
};

done_testing();

sub fake_module {
    my ($system_contract) = @_;
    return Local::LegacyBackendFixture::Module->new($system_contract);
}

package Local::LegacyBackendFixture::Module;

sub new {
    my ($class, $system_contract) = @_;
    return bless { system_contract => $system_contract }, $class;
}

sub name { return 'legacy_reset_policy_fixture' }
sub generics { return {} }
sub ports { return [] }
sub signals { return [] }
sub states {
    return [
        Local::LegacyBackendFixture::State->new('idle', 1),
        Local::LegacyBackendFixture::State->new('run', 0),
    ];
}
sub system { return shift->{system_contract} }

package Local::LegacyBackendFixture::State;

sub new {
    my ($class, $name, $is_reset_state) = @_;
    return bless {
        name => $name,
        is_reset_state => $is_reset_state ? 1 : 0,
    }, $class;
}

sub name { return shift->{name} }
sub is_reset_state { return shift->{is_reset_state} }
sub assignments { return [] }
sub transitions { return [] }
