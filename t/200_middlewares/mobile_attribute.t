use strict;
use warnings;
use Test::More;

eval { require HTTP::Engine; };
plan skip_all => "HTTP::Engine is not installed." if $@;

use HTTP::Request;
use HTTP::Engine::Response;

eval { require HTTP::MobileAttribute; };
plan skip_all => "HTTP::MobileAttribute is not installed." if $@;

plan tests => 3;
use_ok 'HTTP::Engine::Middleware';

sub do_test {
    my $coderef = shift;

    my $mw = HTTP::Engine::Middleware->new(
        { method_class => 'HTTP::Engine::Request' } );
    $mw->install( 'HTTP::Engine::Middleware::MobileAttribute', );

    HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => sub {
                my $req = shift;

                $coderef->($req);

                HTTP::Engine::Response->new( body => 'OK' );
            },
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

