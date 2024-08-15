use Module::Build;

my $builder = Module::Build->new(
    module_name => 'OrderReportingSystem',
    license     => 'perl',
    dist_version_from => 'lib/OrderReportingSystem.pm',
    dist_abstract => 'An order reporting system built with Mojolicious',
    dist_author   => 'Ugur Diktas <ugur.diktas@werft22.com>',
    requires    => {
        'DBI'          => 0,
        'DBD::SQLite'  => 0,
        'Text::CSV'    => 0,
        'Mojolicious'  => 0,
        'File::Slurp'  => 0,
        'File::Temp'   => 0,
        'PDF::API2'    => 0,
    },
);

$builder->create_build_script;
