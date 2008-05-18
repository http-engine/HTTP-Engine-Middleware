use strict;
use warnings;
use Test::More;

eval {
    require HTTP::MobileAttribute;
};
plan skip_all => "HTTP::MobileAttribute is not installed." if $@;

plan tests => 3;
use_ok 'HTTP::Engine::Middleware::MobileAttribute';

HTTP::Engine::Middleware::MobileAttribute->setup();

{
    my $req = HTTP::Engine::Request->new();
    $req->user_agent('IE');
    isa_ok $req->mobile_attribute, 'HTTP::MobileAttribute::Agent::NonMobile';
}

{
    my $req = HTTP::Engine::Request->new();
    $req->user_agent('DoCoMo/1.0/D501i');
    isa_ok $req->mobile_attribute, 'HTTP::MobileAttribute::Agent::DoCoMo';
}

