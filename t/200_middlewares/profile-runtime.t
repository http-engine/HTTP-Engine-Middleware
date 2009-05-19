use strict;
use warnings;
use Test::More;
use IO::Scalar;

eval q{ use Time::HiRes };
plan skip_all => "Time::HiRes is not installed: $@" if $@;

plan tests => 8;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
use Scalar::Util 'looks_like_number';

my $mw = HTTP::Engine::Middleware->new;
$mw->install( 'HTTP::Engine::Middleware::Profile',{
    logger  => sub {
        my $re = qr/Request handling execution time: (.+) secs/;
        ::like $_[0], $re, 'log msg';
        $_[0] =~ $re;
        ::ok looks_like_number($1), 'time is number';
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
ok looks_like_number($res->header('X-Runtime')), 'X-Runtime header time is number';

tie *STDERR, 'IO::Scalar', \my $err;
my $response = HTTP::Engine->new(
    interface => {
        module          => 'Test',
        request_handler => $mw->handler(sub {}),
    },
)->run( HTTP::Request->new( GET => '/' ) );
untie *STDERR;
like $err, qr/You should return instance of HTTP::Engine::Response./, 'You should return instance of HTTP::Engine::Response.';
