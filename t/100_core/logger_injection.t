use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 2;

use HTTP::Engine;
use HTTP::Engine::Response;
use HTTP::Engine::Middleware;
use HTTP::Request;

my @msg;
my $mw = HTTP::Engine::Middleware->new({ logger => sub { push @msg, @_ } });
$mw->install(
    'Foo::Middleware::Log',
);

my $res = HTTP::Engine->new(
    interface => {
        module => 'Test',
        request_handler => $mw->handler( \&handler ),
    }
)->run( HTTP::Request->new( GET => 'http://localhost/') );
is join(',', @msg), 'info,ok';
is $res->content, 'ok', 'end of request';

sub handler {
    my $req = shift;
    HTTP::Engine::Response->new( body => 'ok' );
}

