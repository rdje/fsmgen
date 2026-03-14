#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Extension::Registry;

{
    package Test::RecordingExtension;

    use v5.20;
    use strict;
    use warnings;
    use feature qw(signatures);
    no warnings 'experimental::signatures';

    sub new ($class) {
        return bless {
            parse_calls => [],
            result_calls => [],
        }, $class;
    }

    sub after_parse_source ($self, $context) {
        push @{$self->{parse_calls}}, {
            stage => $context->stage,
            source_path => $context->source_path,
            source_kind => $context->source_info->{kind},
            has_raw_ast => ($context->raw_ast ? 1 : 0),
        };
    }

    sub after_generate_result ($self, $context) {
        push @{$self->{result_calls}}, {
            stage => $context->stage,
            source_path => $context->source_path,
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            module_name => $context->result->{module_info}{module_name},
        };

        $context->result->{extension_marker} = {
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
            saw_parse_hook => scalar(@{$self->{parse_calls}}),
        };
    }

    sub parse_calls ($self) { return $self->{parse_calls} }
    sub result_calls ($self) { return $self->{result_calls} }
}

my $tempdir = tempdir(CLEANUP => 1);
my $fsm_path = File::Spec->catfile($tempdir, 'extension_smoke.fsm');
my $composition_path = File::Spec->catfile($tempdir, 'extension_comp_top.fsm');

write_file(
    $fsm_path,
    <<'FSM'
(?fsm:extension_smoke
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (OUT <= 1)
  )
  (+size
    (OUT 1)
  )
)
FSM
);

write_file(
    $composition_path,
    <<'FSM'
(?top:extension_comp_top
  (?ports:public_io
    clk
    rstn
    output_data>8
  )
  (?fsmc:child child_src)
)

(?fsm:child_src
  (+system
    (clock clk)
    (sreset rstn)
  )
  (-state0
    (output_data> <= 8'1)
  )
  (+size
    (output_data 8)
  )
)
FSM
);

my $extension = Test::RecordingExtension->new;
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    debug_level => 0,
    target_language => 'systemverilog',
    quiet => 1,
    extensions => [$extension],
);

my $fsm_result = $pipeline->generate_hdl_from_file($fsm_path);
is($fsm_result->{extension_marker}{saw_parse_hook}, 1, 'parse-source hook runs before FSM result hook');
is($fsm_result->{extension_marker}{source_kind}, 'fsm', 'typed extension hook runs for the FSM pipeline path');
is($fsm_result->{extension_marker}{target_language}, 'systemverilog', 'typed extension hook sees target-language context');

my $composition_result = $pipeline->generate_hdl_from_file($composition_path);
is($composition_result->{extension_marker}{saw_parse_hook}, 2, 'parse-source hook also runs for the composition path');
is($composition_result->{extension_marker}{source_kind}, 'composition', 'typed extension hook runs for the composition pipeline path');
is($composition_result->{module_info}{module_name}, 'extension_comp_top', 'composition result still preserves generated top module information');

is(scalar(@{$extension->parse_calls}), 2, 'parse-source hook ran once per generation call');
is($extension->parse_calls->[0]{stage}, 'after_parse_source', 'parse hook context carries its typed stage name');
is($extension->parse_calls->[0]{source_kind}, 'fsm', 'parse hook sees FSM source classification');
ok($extension->parse_calls->[0]{has_raw_ast}, 'parse hook receives raw parsed AST data');
is($extension->parse_calls->[1]{source_kind}, 'composition', 'parse hook sees composition source classification');

is(scalar(@{$extension->result_calls}), 2, 'result hook ran once per generation call');
is($extension->result_calls->[0]{stage}, 'after_generate_result', 'result hook context carries its typed stage name');
is($extension->result_calls->[0]{module_name}, 'extension_smoke', 'result hook records FSM module information');
is($extension->result_calls->[1]{module_name}, 'extension_comp_top', 'result hook records composition module information');

my $registry_error = eval {
    FSM::Extension::Registry->new(extensions => ['not_an_object']);
    undef;
};
$registry_error = $@;

like(
    $registry_error,
    qr/accepts only blessed extension objects/s,
    'typed extension registry rejects non-object extension entries',
);

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}
