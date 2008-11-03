package HTTP::Engine::Middleware::ReverseProxy;
use Moose;

sub wrap {
    my ($class, $next) = @_;

    sub {
        my $req = shift;

        my $env = $req->_connection->{env};
        if ( $env ) {
            # in apache httpd.conf (RequestHeader set X-Forwarded-HTTPS %{HTTPS}s)
            $env->{HTTPS} = $env->{HTTP_X_FORWARDED_HTTPS} if $env->{HTTP_X_FORWARDED_HTTPS};
            $env->{HTTPS} = 'ON'                         if $env->{HTTP_X_FORWARDED_PROTO}; # Pound
            $req->secure(1) if $env->{HTTPS} && uc $env->{HTTPS} eq 'ON';

            # If we are running as a backend server, the user will always appear
            # as 127.0.0.1. Select the most recent upstream IP (last in the list)
            if ($env->{HTTP_X_FORWARDED_FOR}) {
                my ($ip, ) = $env->{HTTP_X_FORWARDED_FOR} =~ /([^,\s]+)$/;
                $req->address($ip);
            }

            if ($env->{HTTP_X_FORWARDED_HOST}) {
                my $host = $env->{HTTP_X_FORWARDED_HOST};
                if ($host =~ /^(.+):(\d+)$/ ) {
                    $host = $1;
                    $env->{SERVER_PORT} = $2;
                } elsif ($env->{HTTP_X_FORWARDED_PORT}) {
                    # in apache httpd.conf (RequestHeader set X-Forwarded-Port 8443)
                    $env->{SERVER_PORT} = $env->{HTTP_X_FORWARDED_PORT};
                }
                $env->{HTTP_HOST} = $host;

                $req->headers->header( 'Host' => $env->{HTTP_HOST} );
            }

            for my $attr (qw/uri base/) {
                my $scheme = $req->secure ? 'https' : 'http';
                my $host = $env->{HTTP_HOST} || $env->{SERVER_NAME};
                my $port = $env->{SERVER_PORT} || ( $req->secure ? 443 : 80 );
                # my $path_info = $env->{PATH_INFO} || '/';

                $req->$attr->scheme($scheme);
                $req->$attr->host($host);
                $req->$attr->port($port);
                # $req->$attr->path($path_info);
                # $req->$attr( $req->$attr->canonical );
            }
        }
        $next->($req);
    };
}

1;
