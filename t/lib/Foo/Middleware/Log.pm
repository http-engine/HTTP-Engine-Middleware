package Foo::Middleware::Log;
use HTTP::Engine::Middleware;

after_handle {
    my($c, $self, $req, $res) = @_;
    $self->log('info', 'ok');
    $res;
};

__MIDDLEWARE__
