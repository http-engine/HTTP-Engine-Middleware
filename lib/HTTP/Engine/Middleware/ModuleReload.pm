package HTTP::Engine::Middleware::ModuleReload;
use Moose;
use Module::Reload;

sub wrap {
    my ($class, $next) = shift;

    sub {
        my $req = shift;
        Module::Reload->check;

        $next->($req);
    };
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
