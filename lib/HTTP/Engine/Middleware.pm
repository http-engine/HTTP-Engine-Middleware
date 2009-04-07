package HTTP::Engine::Middleware;
use 5.00800;
use Any::Moose;
use Any::Moose (
    '::Util' => [qw/apply_all_roles/],
);
our $VERSION = '0.11_01';

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

has '_instance_ary_ex' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { +[] },
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
        qw(before_handle after_handle middleware_method)
      )
    {
        *{__PACKAGE__ . "::$meth"} = sub {
            Carp::croak("Can't call ${meth} function outside Middleware's load phase");
        };
    }
};

# this method's return value is indefinite.
sub install {
    my($self, @middlewares) = @_;

    my $args = $self->_build_args(@middlewares);
    $self->_create_middleware_instance($args);
}

# this module accepts
#  $mw->install(qw/HTTP::Engine::Middleware::Foo/);
# and
#  $mw->install('HTTP::Engine::Middleware::Foo' => { arg1 => 'foo'});
sub _build_args {
    my $self = shift;

    # basis of Data::OptList
    my @middlewares;
    my $max = scalar(@_);
    for (my $i = 0; $i < $max ; $i++) {
        if ($i + 1 < $max && ref($_[$i + 1])) {
            push @middlewares, [ $_[$i++] => $_[$i] ];
        } else {
            push @middlewares, [ $_[$i] => {} ];
        }
    }

    return \@middlewares;
}

# load & create middleware instance
my %IS_INITIALIZED;
sub _create_middleware_instance {
    my ($self, $args) = @_;

    my %instances;
    for my $stuff (@$args) {
        my $klass  = $stuff->[0];
        my $config = $stuff->[1];

        unless ($IS_INITIALIZED{$klass}++) {
            $self->_init_middleware_class($klass);
        }

        my $instance = $klass->new(
            %$config,
            before_handles => [$klass->_before_handles()],
            after_handles  => [$klass->_after_handles() ],
        );

        push @{ $self->_instance_ary_ex }, $instance;
        push @{ $self->middlewares }, $klass;
        push @{ $self->_instance_of->{$klass} }, $instance;
    }
}

# load one middleware 'class'
sub _init_middleware_class {
    my ($self, $klass,) = @_;

    my @before_handles;
    my @after_handles;

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
        *{"$klass\::$method"}        = $code;
        *{"$method_class\::$method"} = $code;
    };

    Any::Moose::load_class($klass);

    no strict 'refs';
    *{"${klass}::_before_handles"}    = sub () { @before_handles    };
    *{"${klass}::_after_handles"}     = sub () { @after_handles     };
}

sub is_class_loaded {
    my $class = shift;
    return Any::Moose::is_class_loaded($class);
}

sub instance_of {
    my($self, $name) = @_;
    my $stuff = $self->_instance_of->{$name};
    return wantarray ? @{$stuff} : $stuff->[0];
}

sub handler {
    my($self, $handle) = @_;

    sub {
        my $req = shift;

        my $res;
        my @run_middlewares;
    LOOP:
        for my $instance (@{ $self->_instance_ary_ex }) {
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
