use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Flickr::API::Simple',
    license             => 'perl',
    dist_author         => 'Todd W. Harris <info@toddharris.net>',
    dist_version_from   => 'lib/Flickr/API/Simple.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Flickr-API-Simple-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
