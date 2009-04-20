package HTTP::Engine::Middleware::AccessLog;
use HTTP::Engine::Middleware;
use Carp ();
use DateTime;

with 'HTTP::Engine::Middleware::Role::Logger';

has format => (
    is      => 'ro',
    isa     => 'Str',
    default => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"',
);

after_handle {
    my ( $c, $self, $req, $res ) = @_;

    my $msg = $self->format;

    $msg =~ s/\%\{([\w-]+)\}i/$req->header($1) || '-'/ge;                  # %{User-Agent}
    $msg =~ s/\%(?:[><])?([a-z])/handle_char($req, $res, $1) || '-'/ge;    # %r
    $msg =~ s/\%\%/%/g;                                                    # %%

    $self->log($msg);

    return $res;
};

sub handle_char {
    my ($req, $res, $char) = @_;
    my $code = +{
        'h' => sub {
            $req->address, # remote host
        },
        'l' => sub {
            '-', # remote log name
        },
        'u' => sub {
            $req->user; # user name
        },
        't' => sub {
            my $dt = DateTime->now;
            $dt->strftime("[%d/%b/%y:%H:%M:%S %z]");
        },
        'r' => sub {
            join ' ', $req->method, $req->uri->path, ($req->protocol||'HTTP/1.0'); # ?
        },
        'b' => sub {
            $res->content_length || '-'; # size of response in bytes, excluding HTTP headers
        },
        's' => sub {
            $res->status
        },
    }->{$char};
    if ($code) {
        return $code->();
    } else {
        Carp::croak "unknown log char '$char'";
    }
}

__MIDDLEWARE__

__END__

=head1 NAME

HTTP::Engine::Middleware::AccessLog - write access log

=head1 SYNOPSIS

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install( 'HTTP::Engine::Middleware::AccessLog' => {
        logger => sub {
            warn @_; # your own callback routine
        },
        format => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"',
    });
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run();

=head1 DESCRIPTION

This middleware prints access log like apache.

This module's log format string is a subset of Apache.
If you want to use more syntax, patches welcome :)

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<HTTP::Engine::Middleware>
L<http://httpd.apache.org/docs/2.0/en/mod/mod_log_config.html>


