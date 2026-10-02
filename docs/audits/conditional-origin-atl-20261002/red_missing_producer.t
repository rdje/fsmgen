use strict;
use warnings;
use lib 'perl', 't/lib';
use Test::More;
use JSON::PP;
use File::Spec;
use File::Temp qw(tempdir);
use FSM::Test::ProjectDataLocality;
use FSM::Test::ATLDocumentOriginAuthority;
{
    package MissingATLProducer;
    use parent -norequire, 'FSM::Test::ATLDocumentOriginAuthority::Parser';
    sub _resolve_atl_actor_type_metadata {
        my ($self,@args)=@_;
        local $self->{strip_atl_export}=1;
        return $self->SUPER::_resolve_atl_actor_type_metadata(@args);
    }
    sub _resolve_library {
        my ($self,@args)=@_;
        my $library=$self->SUPER::_resolve_library(@args);
        $self->{resolution_records}[-1]{exports}={} if $self->{strip_atl_export};
        return $library;
    }
}
my $json=JSON::PP->new->canonical;
my @paths=sort grep {!/\/(?:atl-only|finalization)\.json\z/}
    glob '.artifacts/conditional-origin-atl/current-bound/*.json';
for my $path(@paths){
    my $input=$json->decode(read_file($path));
    my $name=$input->{case}{name};
    subtest "actual missing ATL producer $name"=>sub{
        my $directory=File::Spec->abs2rel(tempdir(CLEANUP=>1));
        my $label="$directory/authority-root.isf";
        my %documents;
        for my $original(keys %{$input->{documents}}){
            my $dest=$original eq $input->{label}?$label:"$directory/".(File::Spec->splitpath($original))[2];
            $documents{$dest}=$input->{documents}{$original};
            write_file($dest,$documents{$dest}) if $dest ne $label;
        }
        local $ENV{FSMLIB}=$directory;
        my $ordinary=FSM::Adapter::ISF::Parser->new->parse_source($documents{$label},$label);
        my $actor=eval{MissingATLProducer->new->parse_documents($label,\%documents)};
        my $diagnostic=$@;
        ok(defined($actor),'canonical producers must retain explicit ATL association');
        diag($diagnostic) unless defined($actor);
        if(my$capture=$ENV{FSMGEN_ATL_MISSING_CAPTURE}){
            write_file("$capture/$name.json",$json->encode({case=>$input->{case},label=>$label,documents=>\%documents,
                ordinary=>$ordinary,actor=>$actor,diagnostic=>$diagnostic})."\n");
        }
    };
}
done_testing;
sub read_file{open my$file,'<:raw',$_[0] or die$!;local$/;my$source=<$file>;close$file or die$!;$source}
sub write_file{open my$file,'>:raw',$_[0] or die$!;print{$file}$_[1] or die$!;close$file or die$!}
