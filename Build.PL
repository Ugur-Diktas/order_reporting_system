use Module::Build;

my $builder = Module::Build->new(
    module_name => 'OrderReportingSystem',
    license     => 'perl',
    requires    => {
        'DBI'          => 0,
        'DBD::SQLite'  => 0,
        'Text::CSV'    => 0,
        'PDF::API2'    => 0,
    },
);

$builder->create_build_script;
