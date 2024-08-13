use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Exception;
use File::Slurp;
use File::Temp qw(tempfile);

# Load all modules and test that they are available
BEGIN { use_ok('Infrastructure::Persistence::DBConnection') };
BEGIN { use_ok('Domain::Entities::Customer') };
BEGIN { use_ok('Domain::Entities::Item') };
BEGIN { use_ok('Domain::Entities::Order') };
BEGIN { use_ok('Infrastructure::Persistence::SQLiteCustomerRepository') };
BEGIN { use_ok('Infrastructure::Persistence::SQLiteItemRepository') };
BEGIN { use_ok('Infrastructure::Persistence::SQLiteOrderRepository') };
BEGIN { use_ok('Application::UploadCSVUseCase') };
BEGIN { use_ok('Application::GeneratePDFUseCase') };
BEGIN { use_ok('Infrastructure::CSVProcessor') };
BEGIN { use_ok('Infrastructure::PDFGenerator') };

# Test database connection
subtest 'Database connection' => sub {
    my $dbh = eval { Infrastructure::Persistence::DBConnection::connect() };
    ok($dbh, 'Database connection established');
    done_testing();
};

# Test Customer Entity
subtest 'Customer entity creation' => sub {
    my $customer = Domain::Entities::Customer->new(1, 'John', 'Doe');
    isa_ok($customer, 'Domain::Entities::Customer', 'Customer object created');
    is($customer->customer_id, 1, 'Customer ID is correct');
    is($customer->first_name, 'John', 'Customer first name is correct');
    is($customer->last_name, 'Doe', 'Customer last name is correct');
    done_testing();
};

# Test Customer Repository with Transaction
subtest 'SQLiteCustomerRepository' => sub {
    my $dbh = Infrastructure::Persistence::DBConnection::connect();
    my $customer_repository = Infrastructure::Persistence::SQLiteCustomerRepository->new($dbh);

    # Start a transaction
    $dbh->begin_work;

    eval {
        # Insert a new customer
        my $customer = Domain::Entities::Customer->new(1, 'John', 'Doe');
        my $result = $customer_repository->insert($customer);
        is($result, 'inserted', 'Customer inserted successfully');

        # Insert a duplicate customer
        $result = $customer_repository->insert($customer);
        is($result, 'duplicate', 'Duplicate customer detected successfully');

        # Rollback the transaction to prevent data loss
        $dbh->rollback;
    };

    if ($@) {
        $dbh->rollback;  # Rollback in case of any errors
        die "Test failed with error: $@";
    }

    done_testing();
};

# Test CSV Upload Use Case with Transaction
subtest 'UploadCSVUseCase' => sub {
    my $dbh = Infrastructure::Persistence::DBConnection::connect();

    # Start a transaction
    $dbh->begin_work;

    eval {
        my $upload_csv_use_case = Application::UploadCSVUseCase->new($dbh);

        # Load a CSV file from the seeds directory (or tests directory)
        my $csv_content = read_file('tests/orders.csv');

        # Process the CSV content
        my $message = eval { $upload_csv_use_case->execute(\$csv_content) };
        
        if ($@) {
            diag("Error encountered during CSV processing: $@");
        }

        ok(!$@, 'CSV processed successfully');
        like($message, qr/CSV data has been successfully imported!/, 'CSV upload message is correct');

        # Rollback the transaction to prevent data loss
        $dbh->rollback;
    };

    if ($@) {
        $dbh->rollback;  # Rollback in case of any errors
        die "Test failed with error: $@";
    }

    done_testing();
};

done_testing();
