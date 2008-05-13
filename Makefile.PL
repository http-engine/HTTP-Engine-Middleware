use inc::Module::Install;
name 'HTTP-Engine-Middleware';
all_from 'lib/HTTP/Engine/Middleware.pm';

# requires '';

tests 't/*.t t/*/*.t t/*/*/*.t';
build_requires 'Test::More';
build_requires 'YAML';
use_test_base;
auto_include;
WriteAll;
