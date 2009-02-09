use strict;
use warnings;
use Test::More;

eval q{ use Time::HiRes };
plan skip_all => "Time::HiRes is not installed: $@" if $@;

plan tests => 5;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

my $mw = HTTP::Engine::Middleware->new;
$mw->install( 'HTTP::Engine::Middleware::Profile',{
    logger  => sub {
        ::is  $_[0], 'debug', 'log level';
        ::like $_[1], qr/Request handling execution time: \d+\.\d+ secs/, 'log msg';
    },
    config  => +{
        send_header => 1,
        log_level   => 'debug',
    },
});
my $res = HTTP::Engine->new(
    interface => {
        module          => 'Test',
        request_handler => $mw->handler(
            sub { HTTP::Engine::Response->new( body => 'ok' ) }
        ),
    },
)->run( HTTP::Request->new( GET => 'http://localhost/') );
my $out = $res->content;

is $res->code, '200', 'response code';
is $out, 'ok', 'response content';
like $res->header('X-Runtime'), qr/^\d+\.\d+$/, 'X-Runtime header';
