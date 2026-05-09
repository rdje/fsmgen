#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use Scalar::Util qw(refaddr);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Extension::Context;
use FSM::Extension::Registry;

{
    package Test::RegistryArrayAliasExtension;

    use strict;
    use warnings;

    sub new {
        my ($class, $label) = @_;
        return bless {
            label => $label,
            calls => [],
        }, $class;
    }

    sub after_generate_result {
        my ($self, $context) = @_;
        push @{$self->{calls}}, $self->{label};
        push @{$context->result->{registry_array_alias_markers}}, $self->{label};
    }

    sub calls {
        my ($self) = @_;
        return [@{$self->{calls}}];
    }
}

subtest 'typed extension registry copies extension arrays while preserving live extension objects' => sub {
    my $first = Test::RegistryArrayAliasExtension->new('first');
    my $second = Test::RegistryArrayAliasExtension->new('second');
    my $extensions = [$first];
    my $registry = FSM::Extension::Registry->new(
        extensions => $extensions,
    );

    push @$extensions, $second;
    is(
        scalar(@{$registry->extensions}),
        1,
        'mutating caller extension array after construction does not add registry extensions',
    );
    is(
        refaddr($registry->extensions->[0]),
        refaddr($first),
        'registry preserves the live extension object identity',
    );

    my $returned_extensions = $registry->extensions;
    push @$returned_extensions, $second;
    is(
        scalar(@{$registry->extensions}),
        1,
        'mutating an extensions() accessor snapshot does not add registry extensions',
    );

    $first->{label} = 'first_mutated_live_object';
    my $result = {};
    $registry->after_generate_result(context_for_result($result));

    is_deeply(
        $first->calls,
        ['first_mutated_live_object'],
        'registry dispatch still uses the live extension object',
    );
    is_deeply(
        $second->calls,
        [],
        'extension appended after construction is not dispatched',
    );
    is_deeply(
        $result->{registry_array_alias_markers},
        ['first_mutated_live_object'],
        'result hook observes live object state without accepting caller array mutation',
    );
};

done_testing();

sub context_for_result {
    my ($result) = @_;
    return FSM::Extension::Context->new(
        stage => 'after_generate_result',
        pipeline => bless({}, 'Test::RegistryArrayAliasPipeline'),
        source_path => 'registry_array_alias.fsm',
        target_language => 'systemverilog',
        source_info => {
            kind => 'fsm',
        },
        result => $result,
    );
}
