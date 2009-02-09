use strict;
use warnings;
use lib 't/lib';
use Test::More;
plan tests => 8;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

our $i = 1;
my $mw = HTTP::Engine::Middleware->new;
$mw->install(qw/ Middleware::Zero Middleware::One Middleware::Two Middleware::Three /);
my $res = HTTP::Engine->new(
    interface => {
        module          => 'Test',
        request_handler => $mw->handler(
            sub { HTTP::Engine::Response->new( body => 'ERROR2' ) }
        ),
    },
)->run( HTTP::Request->new( GET => 'http://localhost/') );
is $res->code, '200', 'response code';
is $res->content, 'OK', 'response content';
is $i++, 6, 'last';

