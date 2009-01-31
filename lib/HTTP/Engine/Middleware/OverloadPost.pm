package HTTP::Engine::Middleware::OverloadPost;
use HTTP::Engine::Middleware;

before_handle {
    my ( $c, $self, $req ) = @_;
    $self->overload_request_method($req);
    $req;
};

sub overload_request_method {
    my ( $self, $req ) = @_;

    my $method = $req->method;
    if ( $method && uc $method ne 'POST' ) {
        return $req;
    }

    my $overload = $req->param('_method')
        || $req->param('x-tunneled-method')
        || $req->header('X-HTTP-Method-Override');
    $req->method($overload) if $overload;
    $req;
}

__MIDDLEWARE__
