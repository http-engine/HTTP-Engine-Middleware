package t::200_middlewares::uploadtemp::base;
use strict;
use warnings;

use File::Path 'rmtree';
use File::Spec;

use HTTP::Engine;
use HTTP::Engine::Middleware;
use HTTP::Engine::Response;
use HTTP::Request;
use HTTP::Request::Common;

sub import {
    my $class  = shift;
    my $caller = caller;

    {
        no strict 'refs';
        *{"$caller\::new_engine"} = \&new_engine;
        *{"$caller\::rmtree"}     = \&rmtree;
        *{"$caller\::rmtree"}     = \&rmtree;
        *{"$caller\::GET"}        = \&GET;
        *{"$caller\::POST"}       = \&POST;
    };

    strict->import;
    warnings->import;
}

sub new_engine (&@) {
    my($code, $config) = @_;

    my @args = ('HTTP::Engine::Middleware::UploadTemp');
    push @args, $config if $config;

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(@args);

    HTTP::Engine->new(
        interface => {
            module          => 'Test',
            request_handler => $mw->handler(
                sub {
                    $code->(@_);
                    HTTP::Engine::Response->new;
                }
            ),
        },
    )
}


1;

