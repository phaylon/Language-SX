use MooseX::Declare;

class Template::SX::Library::Core extends Template::SX::Library::Group {
    use MooseX::ClassAttribute;
    use CLASS;

    class_has '+sublibraries';

    CLASS->add_sublibrary($_->new) for map { Class::MOP::load_class($_); $_ } qw(
        Template::SX::Library::Branching
        Template::SX::Library::Data
        Template::SX::Library::Inserts
        Template::SX::Library::Operators
        Template::SX::Library::Quoting
        Template::SX::Library::ScopeHandling
    );
}
