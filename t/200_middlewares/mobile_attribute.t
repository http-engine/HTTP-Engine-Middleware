use strict;
use warnings;
use Test::More;

eval { use HTTP::MobileAttribute; };
plan skip_all => "HTTP::MobileAttribute is not installed." if $@;

plan tests => 2;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;

sub do_test {
    my $coderef = shift;

    my $mw = HTTP::Engine::Middleware->new(
        { method_class => 'HTTP::Engine::Request' } );
    $mw->install( 'HTTP::Engine::Middleware::MobileAttribute', );

    HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(sub {
                my $req = shift;

                $coderef->($req);

                HTTP::Engine::Response->new( body => 'OK' );
            }),
        },
    )->run( HTTP::Request->new( GET => 'http://example.org' ) );
}

do_test(
    sub {
        my $req = shift;
        $req->user_agent('IE');
        isa_ok $req->mobile_attribute,
            'HTTP::MobileAttribute::Agent::NonMobile';
    }
);

do_test(
    sub {
        my $req = shift;
        $req->user_agent('DoCoMo/1.0/D501i');
        isa_ok $req->mobile_attribute, 'HTTP::MobileAttribute::Agent::DoCoMo';
    }
);

