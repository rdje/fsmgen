#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Adapter::ISF;
use FSM::Adapter::IAL2::PPIF;
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

# The catalog selects the supported producer population. Use public adapters
# so generated IAL1 from each IAL2/profile producer also meets the parser boundary.
my %seen;
my @sources = sort grep { /\.(?:isf|ppif|axi|apb|ahb)\z/ }
    map { $_->{relpath} }
    grep { $_->{classification} eq 'supported_smoke' && !$seen{$_->{relpath}}++ }
    regression_corpus_entries();
ok(@sources, 'supported first-party source population is nonempty');
for my $path (@sources) {
    my $adapter = $path =~ /\.isf\z/ ? FSM::Adapter::ISF->new : FSM::Adapter::IAL2::PPIF->new;
    my $result = eval { $adapter->parse_file($path) };
    ok($result, "$path admits its authored/generated interface options") or diag($@);
}
like(build_isf_public_interface_contract()->{actor_shell_interface_shape},
    qr/source options are closed to width\/type\/domain and output-only reset\/default/,
    'capability contract advertises the closed source-option boundary');
done_testing();
