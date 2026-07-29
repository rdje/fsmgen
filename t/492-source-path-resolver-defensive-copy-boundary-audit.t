#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::SourcePathResolver;

subtest 'constructor copies caller-owned extra search path arrays' => sub {
    my @roots = qw(lib_a lib_b);
    my $resolver = FSM::SourcePathResolver->new(
        extra_search_paths => \@roots,
    );

    push @roots, 'mutated_after_construction';

    is_deeply(
        $resolver->extra_search_paths(),
        [qw(lib_a lib_b)],
        'resolver keeps its own copy of constructor search roots',
    );
};

subtest 'extra_search_paths returns a fresh array on every call' => sub {
    my $resolver = FSM::SourcePathResolver->new(
        extra_search_paths => [qw(lib_a lib_b)],
    );

    my $first = $resolver->extra_search_paths();
    push @{$first}, 'caller_mutation';

    is_deeply(
        $resolver->extra_search_paths(),
        [qw(lib_a lib_b)],
        'caller mutation of returned extra_search_paths does not affect resolver state',
    );
};

subtest 'normalized_search_paths returns fresh deduplicated arrays' => sub {
    my $fake_home = File::Spec->rel2abs(
        File::Spec->catdir($FindBin::Bin, '..', '.artifacts', 'tmp', 'tests', 'fsmgen-home'),
    );
    local $ENV{HOME} = $fake_home;
    local $ENV{FSMLIB} = 'env_a:env_b:env_a';

    my @preferred = ('preferred', 'lib_a');
    my $resolver = FSM::SourcePathResolver->new(
        extra_search_paths => ['~/project_lib', 'lib_a', 'lib_b'],
    );

    my $first = $resolver->normalized_search_paths(
        preferred_dirs => \@preferred,
        include_cwd => 1,
    );

    is_deeply(
        $first,
        [
            'preferred',
            'lib_a',
            File::Spec->catdir($fake_home, 'project_lib'),
            'lib_b',
            'env_a',
            'env_b',
            '.',
        ],
        'normalized search roots preserve precedence, tilde expansion, and de-duplication',
    );

    push @{$first}, 'caller_mutation';
    push @preferred, 'preferred_after_call_mutation';

    my $second = $resolver->normalized_search_paths(
        preferred_dirs => ['preferred', 'lib_a'],
        include_cwd => 1,
    );

    is_deeply(
        $second,
        [
            'preferred',
            'lib_a',
            File::Spec->catdir($fake_home, 'project_lib'),
            'lib_b',
            'env_a',
            'env_b',
            '.',
        ],
        'fresh normalized lookup is not affected by prior returned-array or caller-array mutation',
    );
};

done_testing();
