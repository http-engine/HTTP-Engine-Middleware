package HTTP::Engine::Middleware;
use 5.00800;
use Any::Moose;
use Any::Moose (
    '::Util' => [qw/apply_all_roles/],
);
our $VERSION = '0.10';

use Carp ();

has 'middlewares' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { +[] },
);

has '_instance_of' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
);

has 'method_class' => (
    is      => 'ro',
    isa     => 'Str',
);

has 'diecatch' => (
    is  => 'rw',
    isa => 'Bool',
);

sub init_class {
    my $klass = shift;
    my $meta  = any_moose('::Meta::Class')->initialize($klass);
    $meta->superclasses(any_moose('::Object'))
        unless $meta->superclasses;

    no strict 'refs';
    no warnings 'redefine';
    *{ $klass . '::meta' } = sub { $meta };
}

sub import {
    my($class, ) = @_;
    my $caller = caller;

    return unless $caller =~ /(?:\:)?Middleware\:\:.+/;

    strict->import;
    warnings->import;

    init_class($caller);

    if (Any::Moose::is_moose_loaded()) {
        Moose->import({ into_level => 1 });
    } else {
        Mouse->export_to_level( 1 );
    }

    no strict 'refs';
    *{"$caller\::__MIDDLEWARE__"} = sub {
        use strict;
        my $caller = caller(0);
        __MIDDLEWARE__($caller);
    };

    *{"$caller\::before_handle"}     = sub (&) { goto \&before_handle     };
    *{"$caller\::after_handle"}      = sub (&) { goto \&after_handle      };
    *{"$caller\::middleware_method"} = sub     { goto \&middleware_method };
    *{"$caller\::outer_middleware"}  = sub ($) { goto \&outer_middleware  };
    *{"$caller\::inner_middleware"}  = sub ($) { goto \&inner_middleware  };
}

sub __MIDDLEWARE__ {
    my ( $caller, ) = @_;

    Any::Moose::unimport;
    apply_all_roles( $caller, 'HTTP::Engine::Middleware::Role' );

    $caller->meta->make_immutable( inline_destructor => 1 );
    "MIDDLEWARE";
}

BEGIN {
    no strict 'refs';
    for my $meth (
        qw(before_handle after_handle middleware_method outer_middleware inner_middleware)
      )
    {
        *{__PACKAGE__ . "::$meth"} = sub {
            Carp::croak("Can't call ${meth} function outside Middleware's load phase");
        };
    }
};

sub install {
    my($self, @middlewares) = @_;

    my $args = $self->_build_args(@middlewares);
    my $dependend = $self->_create_middleware_instance($args);
    my $scores = $self->_check_deps_and_calc_sort_score($dependend);
    @{ $self->middlewares } = sort { $scores->{$a} <=> $scores->{$b} } keys %$scores;
}

# this module accepts
#  $mw->install(qw/HTTP::Engine::Middleware::Foo/);
# and
#  $mw->install('HTTP::Engine::Middleware::Foo' => { arg1 => 'foo'});
sub _build_args {
    my $self = shift;

    # TODO: need refactoring the code
    my %config;
    for my $stuff (@_) {
        if (ref($stuff) eq 'HASH') {
            my $mw_name = $self->middlewares->[-1]; # configuration for last one item
            $config{$mw_name} = $stuff;
        } else {
            my $mw_name = $stuff;
            push @{ $self->middlewares }, $mw_name;
            $config{$mw_name} = +{ };
        }
    }

    return \%config;
}

# load & create middleware instance
sub _create_middleware_instance {
    my ($self, $args) = @_;

    my %instances;
    my %dependend;
    while (my($name, $config) = each %$args) {
        $dependend{$name} = { outer => [], inner => [] };

        unless ($name->can('before_handles')) { # what's this mean?
            # init declear
            my @before_handles;
            my @after_handles;

            no strict 'refs';
            no warnings 'redefine';

            local *before_handle = sub { push @before_handles, @_ };
            local *after_handle  = sub { push @after_handles, @_ };
            local *middleware_method = sub {
                my($method, $code) = @_;
                my $method_class = $self->method_class;
                if ($method =~ /^(.+)\:\:([^\:]+)$/) {
                    ($method_class, $method) = ($1, $2);
                }
                return unless $method_class;

                no strict 'refs';
                *{"$name\::$method"}         = $code;
                *{"$method_class\::$method"} = $code;
            };
            local *outer_middleware = sub { push @{ $dependend{$name}->{outer} }, $_[0] };
            local *inner_middleware = sub { push @{ $dependend{$name}->{inner} }, $_[0] };

            Any::Moose::load_class($name);

            *{"$name\::_before_handles"}    = sub () { @before_handles };
            *{"$name\::_after_handles"}     = sub () { @after_handles };
            *{"$name\::_outer_middlewares"} = sub () { @{ $dependend{$name}->{outer} } };
            *{"$name\::_inner_middlewares"} = sub () { @{ $dependend{$name}->{inner} } };
        } else {
            $dependend{$name}->{outer} = [ $name->_outer_middlewares ];
            $dependend{$name}->{inner} = [ $name->_inner_middlewares ];
        }

        my $instance = $name->new($config);
        @{ $instance->before_handles } = $name->_before_handles;
        @{ $instance->after_handles }  = $name->_after_handles;

        $instances{$name} = $instance;
    }

    $self->_instance_of(+{ %instances, %{ $self->_instance_of || {} } });

    return \%dependend;
}

# i want to remove this -- tokuhirom 20090403
sub _check_deps_and_calc_sort_score {
    my ($self, $dependend) = @_;

    # check dependency and sorting
    my $i = 0;
    my %sort = map { $_ => $i++ } @{ $self->middlewares };
    while (my($from, $conf) = each %$dependend) {
        for my $to (@{ $conf->{outer} }) {
            Carp::croak("'$from' need to '$to'") unless is_class_loaded($to);
            $sort{$to} = $sort{$from} - 1;
        }
        for my $to (@{ $conf->{inner} }) {
            Carp::croak("'$from' need to '$to'") unless is_class_loaded($to);
            $sort{$to} = $sort{$from} + 1;
        }
    }

    return \%sort;
}

sub is_class_loaded {
    my $class = shift;
    return Any::Moose::is_class_loaded($class);
}

sub instance_of {
    my($self, $name) = @_;
    $self->_instance_of->{$name};
}

sub handler {
    my($self, $handle) = @_;

    sub {
        my $req = shift;

        my $res;
        my @run_middlewares;
    LOOP:
        for my $middleware (@{ $self->middlewares }) {
            my $instance = $self->_instance_of->{$middleware};
            for my $code (@{ $instance->before_handles }) {
                my $ret = $code->($self, $instance, $req);
                if ($ret->isa('HTTP::Engine::Response')) {
                    $res = $ret;
                    last LOOP;
                }
                $req = $ret;
            }
            push @run_middlewares, $instance;
        }
        my $msg;
        unless ($res) {
            $self->diecatch(0);
            local $@;
            eval { $res = $handle->($req) };
            $msg = $@ if !$self->diecatch && $@;
        }
        die $msg if $msg;
        for my $instance (reverse @run_middlewares) {
            for my $code (reverse @{ $instance->after_handles }) {
                $res = $code->($self, $instance, $req, $res);
            }
        }

        $res;
    };
}

1;
__END__

=for stopwords Daisuke Maki dann hidek marcus nyarla API middlewares

=encoding utf8

=head1 NAME

HTTP::Engine::Middleware - middlewares distribution

=head1 WARNING! WARNING!

THIS MODULE IS IN ITS ALPHA QUALITY. THE API MAY CHANGE IN THE FUTURE

=head1 SYNOPSIS

simply

    my $mw = HTTP::Engine::Middleware->new;
    $mw->install(qw/ HTTP::Engine::Middleware::DebugScreen HTTP::Engine::Middleware::ReverseProxy /);
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler( \&handler ),
        }
    )->run();

method injection middleware

    my $mw = HTTP::Engine::Middleware->new({ method_class => 'HTTP::Engine::Request' });
    $mw->install(qw/ HTTP::Engine::Middleware::DebugScreen HTTP::Engine::Middleware::ReverseProxy /);
    HTTP::Engine->new(
        interface => {
            module => 'YourFavoriteInterfaceHere',
            request_handler => $mw->handler(sub {
                my $req = shift;
                HTTP::Engine::Response->new( body => $req->mobile_attribute );
            })
        }
    )->run();

=head1 DESCRIPTION

HTTP::Engine::Middleware is official middlewares distribution of HTTP::Engine.

=head1 WISHLIST

Authentication

OpenID

mod_rewrite ( someone write :p )

and more ideas

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

Daisuke Maki

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

nyarla

marcus

hidek

walf443

Takatoshi Kitano E<lt>techmemo@gmail.com<gt>

=head1 SEE ALSO

L<HTTP::Engine>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/HTTP-Engine-Middleware/trunk HTTP-Engine-Middleware

HTTP::Engine::Middleware's Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
