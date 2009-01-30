package HTTP::Engine::Middleware::ModuleReload;
use HTTP::Engine::Middleware;
use Module::Reload;

before_handle {
    my ( $c, $self, $req ) = @_;
    Module::Reload->check;
    $req;
};

__MIDDLEWARE__

__END__

=head1 NAME

HTTP::Engine::MiddleWare::ModuleReload - module reloader for HTTP::Engine

=head1 SYNOPSIS

    - module: ModuleReload

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Module::Reload>
