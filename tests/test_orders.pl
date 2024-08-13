use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Model::DB') };
BEGIN { use_ok('Domain::Entities::Customer') };
BEGIN { use_ok('Infrastructure::Persistence::SQLiteCustomerRepository') };
BEGIN { use_ok('Application::UploadCSVUseCase') };

done_testing();
