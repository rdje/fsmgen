#!/usr/bin/env perl
use strict;
use warnings;

use File::Spec;
use JSON::PP ();
use Test::More;
use lib 'perl', 't/lib';
use FSM::ProjectDataLocality qw(repository_root);
use FSM::Test::ProjectDataLocality;
use FSM::Support::ProcessSupervisor ();

my $repo_root = repository_root();
my $source = read_source(File::Spec->catfile($repo_root, 't', '1669-task-acceptance-fixture-runtime.t'));
my ($policy) = $source =~ /(subtest 'policy adapters exclusively.*?)(?=subtest 'private wire)/s;
my ($capture) = $source =~ /(sub capture_error \{.*?)(?=sub write_executable)/s;
die 'original architecture boundaries are missing' unless $policy && $capture;
eval "$capture\n1;" or die $@;

sub read_source {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "read $path: $!";
    my $source = do { local $/; <$fh> };
    close $fh or die "close $path: $!";
    return $source;
}

sub inspect_policy {
    my ($injected_path) = @_;
    my @checks;
    my $json = JSON::PP->new->canonical;
    my $error;
    {
        # Run only the original read-only architecture guard. Its unauthorized
        # empty supervisor call must reject at the real caller boundary.
        no warnings qw(redefine once);
        local *main::subtest = sub { $_[1]->(); };
        local *main::like = sub { push @checks, [$_[0] =~ $_[1] ? 1 : 0, $_[2]]; };
        local *main::unlike = sub { push @checks, [$_[0] !~ $_[1] ? 1 : 0, $_[2]]; };
        local *main::is_deeply = sub {
            push @checks, [$json->encode($_[0]) eq $json->encode($_[1]) ? 1 : 0, $_[2]];
        };
        local *main::slurp = sub {
            my ($path) = @_;
            my $body = read_source($path);
            # Deliberately split this token in the test's own source: the
            # original guard inventories source text, including string data.
            $body .= join('', "\n", 'supervise_', 'process', '();', "\n")
                if defined($injected_path) && $path eq File::Spec->catfile($repo_root, $injected_path);
            return $body;
        };
        eval "$policy\n1;";
        $error = $@;
    }
    return ($error, [map { $_->[1] } grep { !$_->[0] } @checks]);
}

subtest 'current canonical supervision boundaries pass in isolation' => sub {
    my ($error, $failed) = inspect_policy();
    is($error, '', 'original architecture guard executes without fixtures');
    is_deeply($failed, [], 'every original architecture assertion passes');
};

for my $control (
    ['t/lib/FSM/Test/ProjectDataLocality.pm', 'only sealed policy adapters call the low-level supervisor'],
    ['t/1595-agent-runtime-ram-guard-macos-metric.t', 'only the hostile-process oracle bypasses a sealed policy adapter'],
) {
    subtest "reject injected ownership in $control->[0]" => sub {
        my $path = File::Spec->catfile($repo_root, $control->[0]);
        my $before = read_source($path);
        my ($error, $failed) = inspect_policy($control->[0]);
        is($error, '', 'source-only injection executes no added code');
        is_deeply($failed, [$control->[1]], 'the exact unauthorized ownership boundary rejects');
        is(read_source($path), $before, 'real source bytes remain unchanged');
    };
}
done_testing();
