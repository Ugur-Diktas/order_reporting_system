#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Server::Simple::CGI;
use JSON ();
use lib 'lib';  # Add your custom library path
use Model::DB;  # Database model
use Controller::PDFGenerator;  # PDF generator controller

{
    package MyWebServer;

    use base qw(HTTP::Server::Simple::CGI);

    sub handle_request {
        my ($self, $cgi) = @_;
        my $path = $cgi->path_info();

        if ($path eq '/api/test') {
            print "HTTP/1.0 200 OK\r\n";
            print $cgi->header('text/plain');
            print "Hello, World!\n";
        } elsif ($path eq '/api/list_orders') {
            list_orders($cgi);  # Call the function to list orders
        } elsif ($path eq '/api/order_details') {
            my $order_id = $cgi->param('order_id');
            order_details($cgi, $order_id);  # Call the function to get order details
        } elsif ($path eq '/api/generate_pdf') {
            my $order_id = $cgi->param('order_id');
            generate_pdf($cgi, $order_id);  # Call the function to generate PDF
        } else {
            print "HTTP/1.0 404 Not Found\r\n";
            print $cgi->header('text/plain');
            print "Page not found\n";
        }
    }

    sub list_orders {
        my ($cgi) = @_;

        my $dbh = Model::DB::connect();
        my $sth = $dbh->prepare("SELECT order_id, order_number, order_date FROM orders");
        $sth->execute();

        my @orders;
        while (my $row = $sth->fetchrow_hashref) {
            push @orders, $row;
        }

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header('application/json');
        print JSON::encode_json(\@orders);
    }

    sub order_details {
        my ($cgi, $order_id) = @_;

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

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header('application/json');
        print JSON::encode_json(\@details);
    }

    sub generate_pdf {
        my ($cgi, $order_id) = @_;

        # Connect to the database
        my $dbh = Model::DB::connect();

        # Generate the PDF file
        my $pdf_filename = Controller::PDFGenerator::generate_pdf($dbh, $order_id);

        # Return the PDF file as a response
        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header(-type => 'application/pdf', -attachment => 'orders_report.pdf');
        open my $fh, '<', $pdf_filename or die "Cannot open PDF file: $!";
        print while <$fh>;
        close $fh;

        # Clean up the temporary files
        unlink $pdf_filename;
    }
}

# Start the server on port 8080
my $server = MyWebServer->new(8080);
$server->run();
