use inc::Module::Install;
BEGIN
{
    if (!$ENV{SHIPIT} && eval {
        require Moose  && Moose->VERSION(
            '0.68'
        )
    }) {
        *HAVE_MOOSE = sub { 1 };
    } else {
        *HAVE_MOOSE = sub { 0 };
    }
}

{
    no warnings 'redefine';
    *recommends_hack = $Module::Install::VERSION > 0.70 ?
        sub { recommends(@_); $_[0] } :
        \&recommends;
}

name 'HTTP-Engine-Middleware';
all_from 'lib/HTTP/Engine/Middleware.pm';

requires 'Any::Moose'   => '0.04';
requires 'Mouse'        => '0.17';
requires 'HTTP::Engine' => '0.1.4';
requires 'HTTP::Request';

features(

# For Developer's

    'ModuleReload' => [
        -default => 0,
        recommends_hack('Module::Reload'),
    ],

    'DebugScreen' => [
        -default => 0,
        recommends_hack('CGI::ExceptionManager'),
        recommends_hack('Scope::Upper'),
    ],

    'DebugRequest' => [
        -default => 0,
        recommends_hack('Text::SimpleTable'),
    ],

# static file maneger ( developer ? )

    'Static' => [
        -default => 0,
        recommends_hack('MIME::Types'),
        recommends_hack('Path::Class'),
        recommends_hack('MouseX::Types::Path::Class'),
    ],

# fill in form

    'FillInForm' => [
        -default => 0,
        recommends_hack('HTML::FillInForm' => '2.00'),
    ],

# encoding

    'Encode' => [
        -default => 0,
        recommends_hack('Data::Visitor::Encode'),
        recommends_hack('Encode'),
    ],

# For Japanese Mobile

    'MobileAttribute' => [
        -default => 0,
        recommends_hack('HTTP::MobileAttribute'),
    ],

    'DoCoMoGUID' => [
        -default => 0,
        recommends_hack('HTML::StickyQuery'),
    ],

# session support

    'HTTPSession' => [
        -default => 0,
        recommends_hack('MouseX::Types'),
        recommends_hack('HTTP::Session'),
    ],
);

my @tests = qw( t/*.t t/*/*.t t/*/*/*.t );
author_tests 'xt';

if (HAVE_MOOSE) {
    my $tests = 
        join ' ', (
            @tests,
            (map {
                my $t = $_;
                $t =~ s{^t/}{t/moose/};
                ($t eq 't/moose/*.t' || $t eq 't/moose/*/*.t') ? () : $t;
            } @tests)
        );
    tests($tests);
} else {
    tests(join ' ', @tests);
}

build_requires 'IO::Scalar';
build_requires 'Test::More';
build_requires 'YAML';
use_test_base;
auto_include;
WriteAll;

# generate moose's test
if (HAVE_MOOSE) {
    warn "generating to Moose's test... please wait few minutes";
    my @testfiles;
    require File::Find;
    require File::Path;
    require File::Spec;

    File::Path::rmtree(File::Spec->catfile( 't', 'moose' ));

    File::Find::find(
        sub {
            return if $File::Find::dir =~ /\./ || /^\./; # skip dot directory
            return unless -f $_;

            my @dirs = File::Spec->splitpath( $File::Find::dir );
            while (!!!$dirs[0]) {
                shift @dirs;
            }
            shift @dirs;
            return if $dirs[0] eq 'xxx'; # skip to moose's test directory remover
            push @testfiles, [ $File::Find::dir, File::Spec->catfile( 't', 'moose', @dirs ), $_ ];
        }, 't'
    );

    for my $stuff (@testfiles) {
        File::Path::mkpath($stuff->[1]);

        my $from = File::Spec->catfile($stuff->[0], $stuff->[2]);
        my $to   = File::Spec->catfile($stuff->[1], $stuff->[2]);

        open my $from_fh, '<', $from;
        open my $to_fh, '>', $to;
        if ($to =~ /\.t$/) {
            print $to_fh "BEGIN { \$ENV{ANY_MOOSE} = 'Moose'; }\n";
        }

        while (<$from_fh>) {
            print $to_fh $_;
        }
    }
    warn "... done";
}
