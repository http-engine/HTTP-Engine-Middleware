use strict;
use warnings;
use Test::More;

plan skip_all => 'this middleware requires DateTime' unless eval 'use DateTime; 1;';
plan tests => 3;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
use HTTP::Request::Common;

my $mw = HTTP::Engine::Middleware->new;
$mw->install(
    'HTTP::Engine::Middleware::AccessLog',
    {   logger => sub {
            my ( $message ) = @_;
            ::like $message, qr{127.0.0.1 - - \[\d\d/\w+/\d\d:\d\d:\d\d:\d\d \+0000\] "GET /foo\?getparam=1 HTTP/1.0" 200 - "http://mixi.jp/" "internatoexplolerr"};
        }
    }
);

my $request
    = HTTP::Request->new( 'GET' => 'http://localhost/foo?getparam=1', HTTP::Headers->new(
        'User-Agent' => 'internatoexplolerr',
        Referer => 'http://mixi.jp/',
        'Content-Length' => 0,
        'content-type' => 'text/plain',
    ));
my $res = HTTP::Engine->new(
    interface => {
        module          => 'Test',
        request_handler => $mw->handler(
            sub { HTTP::Engine::Response->new( body => 'ok' ) }
        ),
    },
)->run($request);
my $out = $res->content;

is $res->code, '200', 'response code';
is $out, 'ok', 'response content';

