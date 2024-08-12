#!/usr/bin/env perl
use Mojolicious::Lite;
use lib 'lib';  # Ensure the 'lib' directory is included

use Model::DB;
use Service::CSVProcessor;

# Serve static files from the 'public' directory
app->static->paths->[0] = './public';

# Route to serve the homepage (index.html)
get '/' => sub {
    my $c = shift;
    $c->reply->static('index.html');
};

# Route to handle CSV file upload
post '/upload' => sub {
    my $c = shift;
    my $upload = $c->param('csvfile');  # Uploaded CSV file

    unless ($upload) {
        return $c->render(json => { error => "No file uploaded" }, status => 400);
    }

    # Read the uploaded CSV file content
    my $csv_content = $upload->slurp;

    # Connect to the database
    my $dbh = Model::DB::connect();

    # Process the uploaded CSV file content
    my $message = eval {
        Service::CSVProcessor::process_csv(\$csv_content, $dbh);
    };
    if ($@) {
        return $c->render(json => { error => "Failed to process CSV: $@" }, status => 500);
    }

    return $c->render(json => { message => $message });
};

# API route to list orders
get '/api/list_orders' => sub {
    my $c = shift;

    my $dbh = Model::DB::connect();
    my $sth = $dbh->prepare("SELECT order_id, order_number, order_date FROM orders");
    $sth->execute();

    my @orders;
    while (my $row = $sth->fetchrow_hashref) {
        push @orders, $row;
    }

    return $c->render(json => \@orders);
};

# API route to get order details
get '/api/order_details' => sub {
    my $c = shift;
    my $order_id = $c->param('order_id');

    my $dbh = Model::DB::connect();
    my $sth = $dbh->prepare("
        SELECT o.order_id, o.order_number, o.order_date, 
               c.first_name, c.last_name, 
               i.item_name, i.manufacturer, i.price
        FROM orders o
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN items i ON o.order_id = i.order_id
        WHERE o.order_id = ?
    ");
    $sth->execute($order_id);

    my @details;
    while (my $row = $sth->fetchrow_hashref) {
        push @details, $row;
    }

    return $c->render(json => \@details);
};

# API route to generate PDF (simplified example)
get '/api/generate_pdf' => sub {
    my $c = shift;
    my $order_id = $c->param('order_id');

    # Generate and serve a simple PDF (you can replace this with your actual PDF logic)
    my $pdf_content = "Order ID: $order_id\nOrder Number: 123\nOrder Date: 2024-08-12\n...";
    $c->res->headers->content_disposition('attachment; filename="order_report.pdf"');
    $c->render(data => $pdf_content, format => 'pdf');
};

# Start the Mojolicious application
app->start;
