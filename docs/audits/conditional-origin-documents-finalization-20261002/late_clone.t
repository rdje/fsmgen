use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::LibraryDocumentOriginAuthority;
{
    package LateClone;
    use parent -norequire, 'FSM::Test::LibraryDocumentOriginAuthority::Parser';
    sub _finalize_actor_crossings {
        my ($self,$actor,@args)=@_;
        my $result=$self->SUPER::_finalize_actor_crossings($actor,@args);
        $actor->{library_uses}[0]{actor}{transactions}[0]{clauses}[0][1]='forged_guard';
        return $result;
    }
}
my $directory=File::Spec->abs2rel(tempdir(CLEANUP=>1));
my $label="$directory/root.isf";
my $library="$directory/probe.lib.isf";
my %documents=(
    $label => '(actor root (clock clk) (interface (input start) (output done)) (imports (library probe.lib as lib)) (use lib.worker as child (bind (clock clk) (input start start) (output done done))))',
    $library => '(library probe.lib (exports (actor worker)) (actor worker (clock clk) (interface (input start) (output done)) (transaction main (when start (sample start as value)) (complete done))))',
);
open my $file,'>:raw',$library or die $!;print {$file} $documents{$library};close $file or die $!;
local $ENV{FSMLIB}=$directory;
ok(!eval{LateClone->new->parse_documents($label,\%documents);1},'actual late clone target mutation must refuse before publishing provenance');
diag($@) if $@;
done_testing;
