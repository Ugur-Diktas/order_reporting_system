use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Model::DB') };
BEGIN { use_ok('Model::Customers') };
BEGIN { use_ok('Model::Orders') };
BEGIN { use_ok('Model::Items') };

done_testing();
