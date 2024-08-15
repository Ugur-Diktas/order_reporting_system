use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Exception;
use File::Slurp;
use File::Temp qw(tempfile);

# Load all modules and test that they are available
BEGIN {
    use_ok('Infrastructure::Persistence::DBConnection');
    use_ok('Domain::Entities::Customer');
    use_ok('Domain::Entities::Item');
    use_ok('Domain::Entities::Order');
    use_ok('Infrastructure::Persistence::SQLiteCustomerRepository');
    use_ok('Infrastructure::Persistence::SQLiteItemRepository');
    use_ok('Infrastructure::Persistence::SQLiteOrderRepository');
    use_ok('Application::UploadCSVUseCase');
    use_ok('Application::GeneratePDFUseCase');
    use_ok('Infrastructure::CSVProcessor');
    use_ok('Infrastructure::PDFGenerator');
    use_ok('Application::Validation');
}

# Utility function to create a database connection
sub get_dbh {
    my $dbh = eval { Infrastructure::Persistence::DBConnection::connect() };
    ok($dbh, 'Database connection established');
    return $dbh;
}

# Test Entity Creation
subtest 'Entity Creation' => sub {
    subtest 'Customer entity creation' => sub {
        my $customer = Domain::Entities::Customer->new(1, 'John', 'Doe');
        isa_ok($customer, 'Domain::Entities::Customer', 'Customer object created');
        is($customer->customer_id, 1, 'Customer ID is correct');
        is($customer->first_name, 'John', 'Customer first name is correct');
        is($customer->last_name, 'Doe', 'Customer last name is correct');
        done_testing();
    };

    subtest 'Item entity creation' => sub {
        my $item = Domain::Entities::Item->new(1, 'Fountain Pen', 'Acme', 3.25);
        isa_ok($item, 'Domain::Entities::Item', 'Item object created');
        is($item->item_id, 1, 'Item ID is correct');
        is($item->item_name, 'Fountain Pen', 'Item name is correct');
        is($item->manufacturer, 'Acme', 'Manufacturer is correct');
        is($item->price, 3.25, 'Price is correct');
        done_testing();
    };

    subtest 'Order entity creation' => sub {
        my $order = Domain::Entities::Order->new(1, 'ORD123', '2024-02-01', 1, 1);
        isa_ok($order, 'Domain::Entities::Order', 'Order object created');
        is($order->order_id, 1, 'Order ID is correct');
        is($order->order_number, 'ORD123', 'Order number is correct');
        is($order->order_date, '2024-02-01', 'Order date is correct');
        is($order->customer_id, 1, 'Customer ID is correct');
        is($order->item_id, 1, 'Item ID is correct');
        done_testing();
    };
};

# Test Repositories
subtest 'SQLite Repositories' => sub {
    my $dbh = get_dbh();
    my $customer_repository = Infrastructure::Persistence::SQLiteCustomerRepository->new($dbh);

    subtest 'SQLiteCustomerRepository' => sub {
        $dbh->begin_work;
        eval {
            my $customer = Domain::Entities::Customer->new(1, 'John', 'Doe');
            my $result = $customer_repository->insert($customer);
            is($result, 'inserted', 'Customer inserted successfully');

            $result = $customer_repository->insert($customer);
            is($result, 'duplicate', 'Duplicate customer detected successfully');

            my $invalid_customer = Domain::Entities::Customer->new(2, undef, 'Doe');
            throws_ok { $customer_repository->insert($invalid_customer) } qr/Failed to insert customer/, 'Attempting to insert customer with missing fields should fail';

            $dbh->rollback;
        };
        if ($@) {
            $dbh->rollback;
            die "Test failed with error: $@";
        }
        done_testing();
    };

    subtest 'SQLiteItemRepository' => sub {
        my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);
        $dbh->begin_work;
        eval {
            my $item = Domain::Entities::Item->new(1, 'Fountain Pen', 'Acme', 3.25);
            $item_repository->insert($item);
            ok(1, 'Item inserted successfully');

            my $duplicate_item_id = $item_repository->find_or_insert('Fountain Pen', 'Acme', 3.25);
            ok($duplicate_item_id, 'Duplicate item found successfully');
            is($duplicate_item_id, 1, 'Duplicate item ID is correct');

            $dbh->rollback;
        };
        if ($@) {
            $dbh->rollback;
            die "Test failed with error: $@";
        }
        done_testing();
    };

    subtest 'SQLiteOrderRepository' => sub {
        my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
        $dbh->begin_work;
        eval {
            my $order = Domain::Entities::Order->new(1, 'ORD123', '2024-02-01', 1, 1);
            my $order_id = $order_repository->insert($order);
            ok($order_id, 'Order inserted successfully');

            my $duplicate_order_id = $order_repository->find_or_insert('ORD123', '2024-02-01', 1, 1);
            ok($duplicate_order_id, 'Duplicate order found successfully');
            is($duplicate_order_id, $order_id, 'Duplicate order ID is correct');

            $dbh->rollback;
        };
        if ($@) {
            $dbh->rollback;
            die "Test failed with error: $@";
        }
        done_testing();
    };
};

# Test Order Deletion
subtest 'Order deletion' => sub {
    my $dbh = get_dbh();
    my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);

    $dbh->do("DELETE FROM orders");
    $dbh->do("DELETE FROM items");

    $dbh->begin_work;

    eval {
        my $order = Domain::Entities::Order->new(undef, 'ORD123', '2024-02-01', 1, 1);
        my $order_id = $order_repository->insert($order);
        ok($order_id, 'Order inserted successfully');

        my $deleted_count = $order_repository->delete_orders([$order_id]);
        is($deleted_count, 1, 'Order deleted successfully');

        my $orders = $order_repository->find_all();
        is(scalar @$orders, 0, 'No orders should exist after deletion');

        $dbh->rollback;
    };
    if ($@) {
        $dbh->rollback;
        die "Test failed with error: $@";
    }
    done_testing();
};

# Test CSV Processing
subtest 'CSV Processing' => sub {
    my $dbh = get_dbh();
    my $csv_content = "order_date,customer_id,first_name,last_name,order_number,item_name,manufacturer,price\n2024-02-01,1,John,Doe,ORD123,Fountain Pen,Acme,3.25";
    my $use_case = Application::UploadCSVUseCase->new($dbh);

    $dbh->begin_work;
    eval {
        my $message = $use_case->execute(\$csv_content);
        like($message, qr/CSV data has been successfully imported!/, 'CSV processed successfully');

        my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
        my $orders = $order_repository->find_all();
        is(scalar @$orders, 1, 'One order should exist after CSV import');

        $dbh->rollback;
    };
    if ($@) {
        $dbh->rollback;
        die "Test failed with error: $@";
    }
    done_testing();
};

# Test PDF Generation
subtest 'PDF Generation' => sub {
    my $dbh = get_dbh();
    my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
    
    $dbh->begin_work;
    eval {
        my $order = Domain::Entities::Order->new(1, 'ORD123', '2024-02-01', 1, 1);
        my $order_id = $order_repository->insert($order);
        ok($order_id, 'Order inserted successfully for PDF test');
        
        my $use_case = Application::GeneratePDFUseCase->new($dbh);
        my $pdf_file = $use_case->execute([$order_id]);

        ok(-e $pdf_file, 'PDF file generated successfully');
        unlink $pdf_file if -e $pdf_file;  # Clean up the generated PDF file

        $dbh->rollback;
    };
    if ($@) {
        $dbh->rollback;
        die "Test failed with error: $@";
    }
    done_testing();
};

# Test Validation Utilities
subtest 'Validation Utilities' => sub {
    subtest 'CSV File Validation' => sub {
        my $valid_file = File::Temp->new(SUFFIX => '.csv');
        print $valid_file "order_date,customer_id,first_name,last_name,order_number,item_name,manufacturer,price\n";
        my ($valid, $error) = Application::Validation::validate_csv_file($valid_file);
        is($valid, 1, 'CSV file is valid');
        is($error, 'Valid CSV file', 'Validation message is correct');

        my $invalid_file = File::Temp->new(SUFFIX => '.txt');
        ($valid, $error) = Application::Validation::validate_csv_file($invalid_file);
        is($valid, 0, 'Non-CSV file is invalid');
        is($error, 'Invalid file type. Please upload a CSV file.', 'Validation message is correct');

        done_testing();
    };

    subtest 'Order ID Validation' => sub {
        my ($valid, $error) = Application::Validation::validate_order_ids([1, 2, 3]);
        is($valid, 1, 'Order IDs are valid');

        ($valid, $error) = Application::Validation::validate_order_ids([]);
        is($valid, 0, 'Empty order ID list is invalid');

        ($valid, $error) = Application::Validation::validate_order_ids(['abc']);
        is($valid, 0, 'Non-numeric order ID is invalid');

        done_testing();
    };
};

done_testing();
