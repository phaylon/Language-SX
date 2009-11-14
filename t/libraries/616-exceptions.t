#!/usr/bin/env perl
use strict;
use warnings;
use Template::SX::Test          qw( :all );
use Template::SX::Constants     qw( :all );
use Test::Most;

my @should_work = (

    [   '(catch (<- (error { foo: 23 })) (-> { caught: (_ :captured) }))',         
        { caught => { foo => 23 } },
        'throwing and catching an exception',
    ],
);

my @should_fail = (

    ['(catch)',                                     [E_PARAMETER,   qr/not enough/],        'catch without arguments'],
    ['(catch (<- 23))',                             [E_PARAMETER,   qr/not enough/],        'catch with single argument'],
    ['(catch (<- 23) (-> _) 4)',                    [E_PARAMETER,   qr/too many/],          'catch with more than two arguments'],
    ['(catch 23 (-> _))',                           [E_TYPE,        qr/lambda/],            'catch with non-lambda cage argument'],
    ['(catch (<- 23) 23)',                          [E_TYPE,        qr/lambda/],            'catch with non-lambda handler argument'],

    ['(error)',                                     [E_PARAMETER,   qr/not enough/],        'error without arguments'],
    ['(error 3 4)',                                 [E_PARAMETER,   qr/too many/],          'error with more than one argument'],
    ['(error "foo")',                               [E_CAPTURED,    qr/foo/],               'error'],
);

with_libs(sub {

    is_result @$_ for @should_work;
    is_error  @$_ for @should_fail;

}, qw( Exceptions Data ScopeHandling ));

done_testing;
