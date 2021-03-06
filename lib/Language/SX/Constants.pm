package Language::SX::Constants;
use strict;
use warnings;

use constant {

    SCOPE_STRUCTURAL    => 'structural',
    SCOPE_FUNCTIONAL    => 'functional',

    CELL_NORMAL         => '(',
    CELL_SQUARE         => '[',
    CELL_CURLY          => '{',

    QUOTE_FULL          => 'full',
    QUOTE_QUASI         => 'quasi',
};

use constant {

    CELL_APPLICATION    => CELL_NORMAL,
    CELL_ARRAY          => CELL_SQUARE,
    CELL_HASH           => CELL_CURLY,
    CELL_NODE           => CELL_NORMAL,
    CELL_NODE_ATTRSET   => CELL_CURLY,
};

use constant {

    E_SYNTAX            => 'Language::SX::Exception::Syntax',
    E_RESERVED          => 'Language::SX::Exception::Syntax::Reserved',
    E_END_OF_STREAM     => 'Language::SX::Exception::Syntax::EndOfStream',
    E_UNBOUND           => 'Language::SX::Exception::UnboundVar',
    E_INTERNAL          => 'Language::SX::Exception::Internal',
    E_TYPE              => 'Language::SX::Exception::Type',
    E_CAPTURED          => 'Language::SX::Exception::Captured',
    E_APPLY             => 'Language::SX::Exception::Apply',
    E_PROTOTYPE         => 'Language::SX::Exception::Prototype',
    E_PARAMETER         => 'Language::SX::Exception::Parameter',
    E_FILE              => 'Language::SX::Exception::File',
    E_INSERT            => 'Language::SX::Exception::Insert',
};

use Sub::Exporter -setup => {
    exports => [qw(

        SCOPE_STRUCTURAL
        SCOPE_FUNCTIONAL

        CELL_NORMAL
        CELL_SQUARE
        CELL_CURLY

        CELL_APPLICATION
        CELL_ARRAY
        CELL_HASH
        CELL_NODE
        CELL_NODE_ATTRSET

        E_SYNTAX
        E_INTERNAL
        E_UNBOUND
        E_RESERVED
        E_TYPE
        E_CAPTURED
        E_APPLY
        E_PROTOTYPE
        E_PARAMETER
        E_END_OF_STREAM
        E_FILE
        E_INSERT

        QUOTE_FULL
        QUOTE_QUASI
    )],
};

1;
