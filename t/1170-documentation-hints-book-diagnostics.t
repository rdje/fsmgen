#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DocumentationHints qw(
    package_boundary_hint
    package_boundary_sentence
    strict_mode_boundary_hint
    strict_mode_boundary_sentence
    supported_boundary_hint
    supported_boundary_sentence
);

my %sentences = (
    supported => supported_boundary_sentence(),
    strict    => strict_mode_boundary_sentence(),
    package   => package_boundary_sentence(),
);

for my $name (sort keys %sentences) {
    like($sentences{$name}, qr{\ASee docs/book/src/}, "$name sentence points into the book");
    unlike($sentences{$name}, qr{docs/USER_GUIDE\.md}, "$name sentence does not point at the legacy guide");
    like($sentences{$name}, qr{\.\z}, "$name sentence is a complete sentence");
}

is(supported_boundary_hint(), supported_boundary_sentence() . "\n", 'supported hint adds one newline');
is(strict_mode_boundary_hint(), strict_mode_boundary_sentence() . "\n", 'strict hint adds one newline');
is(package_boundary_hint(), package_boundary_sentence() . "\n", 'package hint adds one newline');

my @diagnostic_owners = qw(
    perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm
    perl/FSM/Adapter/FSMGenFull/Parser.pm
    perl/FSM/Pipeline/SourceFrontend.pm
    perl/FSM/Pipeline/SourceGenerationOrchestrator.pm
);

for my $path (@diagnostic_owners) {
    my $full_path = File::Spec->catfile($FindBin::Bin, '..', split('/', $path));
    open my $fh, '<', $full_path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    unlike($text, qr{See docs/USER_GUIDE\.md}, "$path uses book-owned diagnostic hints");
}

done_testing();
