use Module::Build;

my $builder = Module::Build->new(
    module_name => 'OrderReportingSystem',
    license     => 'perl',
    requires    => {
        'DBI'          => 0,
        'DBD::SQLite'  => 0,
        'Text::CSV'    => 0,
        'Mojolicious'  => 0,
        'File::Slurp'  => 0,
        'File::Temp'   => 0,
    },
);

$builder->create_build_script;
