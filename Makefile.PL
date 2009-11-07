use inc::Module::Install;

name        'Template-SX';
all_from    'lib/Template/SX.pm';

requires    'B::Hooks::OP::Check::EntersubForCV';
requires    'CLASS';
requires    'Class::MOP';
requires    'Data::Dump';
requires    'List::AllUtils';
requires    'List::MoreUtils';
requires    'MooseX::ClassAttribute';
requires    'MooseX::Declare';
requires    'MooseX::MultiMethods';
requires    'MooseX::Types';
requires    'MooseX::Types::Path::Class';
requires    'MooseX::Types::Structured';
requires    'Perl6::Junction';
requires    'Perl::Tidy';
requires    'String::Escape';
requires    'Sub::Call::Tail';
requires    'Sub::Exporter';
requires    'Sub::Name';
requires    'Term::ReadLine::Zoid';
requires    'Test::Most';
requires    'TryCatch';
requires    'encoding::stdio';
requires    'namespace::clean';

auto_install;

WriteAll;
