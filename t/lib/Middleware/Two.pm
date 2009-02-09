package Middleware::Two;
use HTTP::Engine::Middleware;

before_handle {
    ::is $::i++, 3, 'Two before';
    HTTP::Engine::Response->new( body => 'OK' );
};
after_handle {
    HTTP::Engine::Response->new( body => 'ERROR4' );
};
__MIDDLEWARE__


