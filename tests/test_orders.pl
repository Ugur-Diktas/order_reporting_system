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
        my $item = Domain::Entities::Item->new(1, 'Fountain Pen', 'Acme', 3.25, 1);
        isa_ok($item, 'Domain::Entities::Item', 'Item object created');
        is($item->item_id, 1, 'Item ID is correct');
        is($item->item_name, 'Fountain Pen', 'Item name is correct');
        is($item->manufacturer, 'Acme', 'Manufacturer is correct');
        is($item->price, 3.25, 'Price is correct');
        is($item->order_id, 1, 'Order ID is correct');
        done_testing();
    };

    subtest 'Order entity creation' => sub {
        my $order = Domain::Entities::Order->new(1, 'ORD123', '2024-02-01', 1);
        isa_ok($order, 'Domain::Entities::Order', 'Order object created');
        is($order->order_id, 1, 'Order ID is correct');
        is($order->order_number, 'ORD123', 'Order number is correct');
        is($order->order_date, '2024-02-01', 'Order date is correct');
        is($order->customer_id, 1, 'Customer ID is correct');
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
            my $item = Domain::Entities::Item->new(1, 'Fountain Pen', 'Acme', 3.25, 1);
            $item_repository->insert($item);
            ok(1, 'Item inserted successfully');
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
            my $order = Domain::Entities::Order->new(1, 'ORD123', '2024-02-01', 1);
            my $order_id = $order_repository->insert($order);
            ok($order_id, 'Order inserted successfully');
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
        my $order = Domain::Entities::Order->new(undef, 'ORD123', '2024-02-01', 1);
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

# Test Item Repository with Transaction
subtest 'SQLiteItemRepository' => sub {
    my $dbh = get_dbh();
    my $item_repository = Infrastructure::Persistence::SQLiteItemRepository->new($dbh);

    $dbh->begin_work;
    eval {
        my $item = Domain::Entities::Item->new(1, 'Fountain Pen', 'Acme', 3.25, 1);
        $item_repository->insert($item);

        ok(1, 'Item inserted successfully');
        $dbh->rollback;
    };
    if ($@) {
        $dbh->rollback;
        die "Test failed with error: $@";
    }
    done_testing();
};

# Test Order Repository with Transaction
subtest 'SQLiteOrderRepository' => sub {
    my $dbh = get_dbh();
    my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);

    $dbh->begin_work;
    eval {
        my $order = Domain::Entities::Order->new(1, 'ORD123', '2024-02-01', 1);
        my $order_id = $order_repository->insert($order);
        ok($order_id, 'Order inserted successfully');
        $dbh->rollback;
    };
    if ($@) {
        $dbh->rollback;
        die "Test failed with error: $@";
    }
    done_testing();
};

done_testing();
