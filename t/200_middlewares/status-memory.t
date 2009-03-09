use strict;
use warnings;
use Test::More;

plan skip_all => "Set TEST_STATUS_MEMORY environment variable to run this test"
    unless $ENV{TEST_STATUS_MEMORY};
eval q{ use B::TerseSize };
plan skip_all => "B::TerseSize is not installed" if $@;
eval q{ use Devel::Symdump };
plan skip_all => "Devel::Symdump is not installed" if $@;

plan tests => 3;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

my $mw = HTTP::Engine::Middleware->new;
$mw->install(
    'HTTP::Engine::Middleware::Status' => {
        plugins => [
            'Memory',
        ],
    },
);

my $res = HTTP::Engine->new(
    interface => {
        module          => 'Test',
        request_handler => $mw->handler( sub { HTTP::Engine::Response->new( body => 'dynamic' ) } ),
    },
)->run( HTTP::Request->new(GET => 'http://example.com/httpengine-status') );
is $res->code, '200', 'response code is 200';
my $html = $res->content;
like $html, qr{<h2>Memory</h2>}, 'plugin loaded';
like $html, qr{<td>HTTP::Engine\s+</td>}, 'memory size table';
