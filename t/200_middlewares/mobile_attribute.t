use strict;
use warnings;
use Test::More;

eval {
    require HTTP::Engine;
};
plan skip_all => "HTTP::Engine is not installed." if $@;

eval {
    require HTTP::MobileAttribute;
};
plan skip_all => "HTTP::MobileAttribute is not installed." if $@;

plan tests => 3;
use_ok 'HTTP::Engine::Middleware::MobileAttribute';

HTTP::Engine::Middleware::MobileAttribute->setup();

sub do_test {
    my $coderef = shift;

    HTTP::Engine->new(
        interface => {
            module  => 'Test',
            request_handler => sub {
                my $req = shift;

                $coderef->($req);

                HTTP::Engine::Response->new(body => 'OK');
            },
        },
    )->run(HTTP::Request->new(GET => 'http://example.org'));
}

do_test(sub {
    my $req = shift;
    $req->user_agent('IE');
    isa_ok $req->mobile_attribute, 'HTTP::MobileAttribute::Agent::NonMobile';
});

do_test(sub {
    my $req = shift;
    $req->user_agent('DoCoMo/1.0/D501i');
    isa_ok $req->mobile_attribute, 'HTTP::MobileAttribute::Agent::DoCoMo';
});

