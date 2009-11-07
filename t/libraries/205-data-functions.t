#!/usr/bin/env perl
use strict;
use warnings;
use MooseX::Declare;
use Template::SX::Test      qw( :all );
use Template::SX::Constants qw( :all );
use Test::Most;

class TestObj {
    method decorate (Str $body) { "[$body]" }
    method values { 1, 2, 3 }
}

my @try = (
    ['(apply + 1 2 `(3 4))',                10,     'simple function application'],
    ['(apply apply + `(1 2 (3 4)))',        10,     'applying apply to itself'],

    ['(lambda? (-> _))',                    1,      'lambda predicate with single lambda'],
    ['(lambda? (-> _) (-> 3))',             1,      'lambda predicate with multiple lambdas'],
    ['(lambda? (-> _) 23 (-> 4))',          undef,  'lambda predicate with non-lambda argument'],

    ['(cascade "abcd" length even?)',       1,      'cascade'],
    ['(cascade "abc"  length even?)',       undef,  'cascade with last false'],
    ['(cascade #f 3)',                      undef,  'cascade with skipped'],
    ['(cascade)',                           undef,  'cascade without arguments'],
    ['(cascade 23)',                        23,     'cascade with single argument'],

    [   '((curry list 1 2) 3 4)',
        [1, 2, 3, 4],
        'currying',
    ],
    [   '((rcurry list 1 2) 3 4)',
        [3, 4, 1, 2],
        'right currying',
    ],
    [   ['((curry obj :decorate) "foo")', { obj => TestObj->new }],
        '[foo]',
        'currying an object',
    ],
    [   ['((rcurry obj "foo") :decorate)', { obj => TestObj->new }],
        '[foo]',
        'right currying an object',
    ],

    [   q{
            (define while-ret)
            (define gathered
              (gather 
                (lambda (take)
                  (let* ((ls   `(1 2 3))
                         (next (let ((n -1))
                                 (<- (at ls 
                                         (set! n 
                                               (++ n)))))))
                    (set! while-ret
                          (while next
                                 defined? 
                                 (-> (take _))))))))
            (list while-ret gathered)
        },
        [3, [1, 2, 3]],
        'while iteration',
    ],

    [   ['(apply/list foo 1 2 `(3))', { foo => sub { @_ } }],
        [1, 2, 3],
        'applying in list context',
    ],
    [   ['(apply/list obj :values `())', { obj => TestObj->new }],
        [1, 2, 3],
        'applying an object in list context',
    ],
);

my @fails = (

    ['(apply)',             [E_PARAMETER,   qr/argument/],      'apply without any arguments'],
    ['(apply +)',           [E_PARAMETER,   qr/argument/],      'apply with missing arguments'],
    ['(apply + 3 4)',       [E_PARAMETER,   qr/list/],          'apply with non-list as last argument'],
    ['(apply 3 `())',       [E_TYPE,        qr/applicant/],     'apply with invalid applicant'],

    ['(apply/list)',        [E_PARAMETER,   qr/argument/],      'apply/list without any arguments'],
    ['(apply/list +)',      [E_PARAMETER,   qr/argument/],      'apply/list with missing arguments'],
    ['(apply/list + 3 4)',  [E_PARAMETER,   qr/list/],          'apply/list with non-list as last argument'],
    ['(apply/list 3 `())',  [E_TYPE,        qr/applicant/],     'apply/list with invalid applicant'],

    ['(lambda?)',           [E_PARAMETER,   qr/at least/],      'lambda predicate without arguments'],

    ['(cascade 3 4)',       [E_TYPE,        qr/argument 1/],    'cascade with non-applicant'],

    ['(curry)',             [E_PARAMETER,   qr/not enough/],    'currying without arguments'],
    ['(curry +)',           [E_PARAMETER,   qr/not enough/],    'currying with single argument'],
    ['(curry 3 4)',         [E_TYPE,        qr/applicant/],     'currying a non-applicant'],

    ['(rcurry)',            [E_PARAMETER,   qr/not enough/],    'right currying without arguments'],
    ['(rcurry +)',          [E_PARAMETER,   qr/not enough/],    'right currying with single argument'],
    ['(rcurry 3 4)',        [E_TYPE,        qr/applicant/],     'right currying a non-applicant'],
);

with_libs(sub {

    is_result @$_ for @try;
    is_error  @$_ for @fails;

}, qw( Data::Numbers Data::Functions Quoting ScopeHandling Data::Common Data::Lists ));

done_testing;
