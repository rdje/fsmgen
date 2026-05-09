#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;

{
    package Test::HDLGeneratorDirectExtensionAliasProbe;

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
        push @{$context->result->{direct_extensions_alias_markers}}, $self->{label};
    }

    sub calls {
        my ($self) = @_;
        return [@{$self->{calls}}];
    }
}

subtest 'facade direct extensions are registered from the constructor-time object list snapshot' => sub {
    my $source_path = write_direct_fixture();
    my $first = Test::HDLGeneratorDirectExtensionAliasProbe->new('first');
    my $second = Test::HDLGeneratorDirectExtensionAliasProbe->new('second');
    my $extensions = [$first];
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 0,
        target_language => 'systemverilog',
        strict_mode => 1,
        quiet => 1,
        extensions => $extensions,
    );

    $extensions->[0] = $second;
    push @$extensions, Test::HDLGeneratorDirectExtensionAliasProbe->new('third');
    $first->{label} = 'first_live_object';

    my $result = $pipeline->generate_hdl_from_file($source_path);
    is_deeply(
        $result->{direct_extensions_alias_markers},
        ['first_live_object'],
        'generation dispatches only objects registered from the constructor-time extensions list',
    );
    is_deeply(
        $first->calls,
        ['first_live_object'],
        'facade preserves live extension object identity for dispatch',
    );
    is_deeply(
        $second->calls,
        [],
        'extension object swapped into caller array after construction is not dispatched',
    );
};

done_testing();

sub write_direct_fixture {
    my $tempdir = tempdir(CLEANUP => 1);
    my $source_path = File::Spec->catfile($tempdir, 'direct_extensions_alias_root.fsm');
    write_file(
        $source_path,
        <<'FSM'
(?fsm:direct_extensions_alias_root
  (+system
    (clock clk)
    (sreset rst)
  )
  (+size
    (OUT 1)
  )
  (idle
    (= (OUT 1))
  )
)
FSM
    );
    return $source_path;
}

sub write_file {
    my ($path, $contents) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $contents or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
