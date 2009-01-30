use strict;
use warnings;
use Test::More;

eval q{ use CGI::ExceptionManager };
plan skip_all => "CGI::ExceptionManager is not installed" if $@;
eval q{ use Scope::Upper };
plan skip_all => "Scope::Upper is not installed: $@" if $@;

plan tests => 6;

use HTTP::Engine;
use HTTP::Engine::Response;
use HTTP::Request;

use HTTP::Engine::Middleware;

{
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::DebugScreen', { powerd_by => 'HE::Middleware test' } );
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { die 'ERROR TEST HE' }
            ),
        },
    )->run( HTTP::Request->new( GET => 'http://localhost/') );
    my $out = $res->content;

    is $res->code, '500';
    like $out, qr/ERROR TEST HE/;
    like $out, qr/Powered by HE::Middleware test/;
    like $out, qr/request_handler =&gt; \$mw-&gt;handler\(/;
}

{
    my $mw = HTTP::Engine::Middleware->new;
    $mw->install();
    my $res = HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub { die 'ERROR TEST HE' }
            ),
        },
    )->run( HTTP::Request->new( GET => 'http://localhost/') );
    my $out = $res->content;

    is $res->code, '500';
    is $out, 'internal server errror';
}
