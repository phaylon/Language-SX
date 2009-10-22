package Template::SX::Constants;
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

    E_SYNTAX            => 'Template::SX::Exception::Syntax',
    E_RESERVED          => 'Template::SX::Exception::Syntax::Reserved',
    E_UNBOUND           => 'Template::SX::Exception::UnboundVar',
    E_INTERNAL          => 'Template::SX::Exception::Internal',
    E_TYPE              => 'Template::SX::Exception::Type',
    E_CAPTURED          => 'Template::SX::Exception::Captured',
    E_APPLY             => 'Template::SX::Exception::Apply',
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

        QUOTE_FULL
        QUOTE_QUASI
    )],
};

1;
