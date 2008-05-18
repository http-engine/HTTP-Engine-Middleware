package HTTP::Engine::Middleware::ModuleReload;
use Moose;
use Module::Reload;

sub wrap {
    my $next = shift;

    Module::Reload->check;

    $next->(@_);
}

1;
__END__

=head1 NAME

HTTP::Engine::MiddleWare::ModuleReload - module reloader for HTTP::Engine

=head1 SYNOPSIS

    - module: ModuleReload

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Module::Reload>
