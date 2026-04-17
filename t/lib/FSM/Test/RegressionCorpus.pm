package FSM::Test::RegressionCorpus;

use strict;
use warnings;

use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use lib File::Spec->catdir(dirname(__FILE__), '..', '..', '..', '..', 'perl');
use FSM::Support::RegressionCorpus qw(regression_corpus_entries protocol_fixture_entries);

our @EXPORT_OK = qw(regression_corpus_entries protocol_fixture_entries);

1;
