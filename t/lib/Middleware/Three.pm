package Middleware::Three;
use HTTP::Engine::Middleware;

before_handle {
    HTTP::Engine::Response->new( body => 'ERROR1' );
};
after_handle {
    HTTP::Engine::Response->new( body => 'ERROR3' );
};
__MIDDLEWARE__


