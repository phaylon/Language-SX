use inc::Module::Install;

name            'Language-SX';
license         'perl';
all_from        'lib/Language/SX.pm';

auto_provides_class;

no_index        directory => 'maint';
no_index        package => 'Language::SX::Test';

install_script  'script/sx-repl';

test_requires   'MooseX::InstanceTracking'      => 0.04;
test_requires   'Test::Most';

requires        'B::Hooks::OP::Check::EntersubForCV';
requires        'CLASS';
requires        'Carp';
requires        'Class::MOP'                    => 0.94;
requires        'Continuation::Escape'          => 0.03;
requires        'Data::Alias'                   => 1.07;
requires        'Data::Dump';
requires        'HTML::Entitires';
requires        'List::AllUtils'                => 0.02;
requires        'Moose'                         => 0.92;
requires        'MooseX::ClassAttribute'        => 0.10;
requires        'MooseX::Declare'               => 0.31;
requires        'MooseX::MultiMethods'          => 0.09;
requires        'MooseX::StrictConstructor';
requires        'MooseX::Traits'                => 0.07;
requires        'MooseX::Types'                 => 0.20;
requires        'MooseX::Types::Path::Class'    => 0.05;
requires        'MooseX::Types::Structured'     => 0.19;
requires        'Path::Class'                   => 0.17;
requires        'Perl6::Junction'               => 1.40000;
requires        'Perl::Tidy'                    => 20090616;
requires        'Regexp::Compare'               => 0.10;
requires        'String::Escape'                => 2002.001;
requires        'Sub::Call::Tail'               => 0.04;
requires        'Sub::Exporter';
requires        'Sub::Name'                     => 0.04;
requires        'Term::ReadLine::Zoid'          => 0.07;
requires        'TryCatch'                      => 1.001001;
requires        'encoding::stdio';
requires        'namespace::clean';

auto_install;

WriteAll;
