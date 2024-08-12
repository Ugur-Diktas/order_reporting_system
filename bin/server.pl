#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Server::Simple::CGI;
use JSON ();
use CGI;
use File::Spec;
use Cwd qw(abs_path getcwd);
use lib 'lib';
use Model::DB;
use Controller::PDFGenerator;
use Model::Customers;
use Model::Orders;
use Model::Items;

{
    package MyWebServer;

    use base qw(HTTP::Server::Simple::CGI);

    sub handle_request {
        my ($self, $cgi) = @_;
        my $path = $cgi->path_info();

        print "Requested Path: $path\n";  # Debugging output to the terminal

        if ($path eq '/' || $path eq '/index.html') {
            serve_static_file('public/index.html', 'text/html');
        } elsif ($path eq '/css/styles.css') {
            serve_static_file('public/css/styles.css', 'text/css');
        } elsif ($path eq '/js/app.js') {
            serve_static_file('public/js/app.js', 'application/javascript');
        } elsif ($path eq '/api/list_orders') {
            list_orders($cgi);
        } elsif ($path eq '/api/order_details') {
            my $order_id = $cgi->param('order_id');
            order_details($cgi, $order_id);
        } elsif ($path eq '/api/generate_pdf') {
            my $order_id = $cgi->param('order_id');
            if ($order_id) {
                generate_pdf($cgi, $order_id);
            } else {
                generate_pdf($cgi);
            }
        } elsif ($path eq '/upload') {
            handle_file_upload($cgi);
        } else {
            print "HTTP/1.0 404 Not Found\r\n";
            print $cgi->header('application/json');
            print JSON::encode_json({ message => "Page not found" });
        }
    }

    sub serve_static_file {
        my ($file_path, $content_type) = @_;

        print "HTTP/1.0 200 OK\r\n";

        my $current_dir = Cwd::getcwd();
        my $full_path = File::Spec->catfile($current_dir, $file_path);
        print "Current Directory: $current_dir\n";  # Print current directory
        print "Attempting to serve file: $full_path\n";  # Debugging output to the terminal

        if (-e $full_path) {
            open my $fh, '<', $full_path or die "Cannot open file: $!";
            print "HTTP/1.0 200 OK\r\n";
            print "Content-Type: $content_type\r\n\r\n";
            print while <$fh>;
            close $fh;
        } else {
            print "File not found: $full_path\n";  # Debugging output to the terminal
            print "HTTP/1.0 404 Not Found\r\n";
            print "Content-Type: text/plain\r\n\r\n";
            print "File not found";
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

    sub handle_file_upload {
        my ($cgi) = @_;

        my $dbh = Model::DB::connect();

        # Check if a file was uploaded
        my $upload_filehandle = $cgi->upload('csvfile');
        if (!$upload_filehandle) {
            print "HTTP/1.0 400 Bad Request\r\n";
            print $cgi->header('application/json');
            print JSON::encode_json({ error => "No file uploaded" });
            return;
        }

        # Process the uploaded file
        my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });
        <$upload_filehandle>;  # Skip the header row

        while (my $row = $csv->getline($upload_filehandle)) {
            my ($order_date, $customer_id, $first_name, $last_name, $order_number, $item_name, $manufacturer, $price) = @$row;
            
            # Insert customer data
            Model::Customers::insert($dbh, $customer_id, $first_name, $last_name);
            
            # Insert order data
            my $order_id = Model::Orders::insert($dbh, $order_number, $order_date, $customer_id);
            
            # Insert item data
            Model::Items::insert($dbh, $item_name, $manufacturer, $price, $order_id);
        }

        print "HTTP/1.0 200 OK\r\n";
        print $cgi->header('application/json');
        print JSON::encode_json({ message => "File uploaded and data processed successfully" });
    }
}

# Start the server on port 8080
my $server = MyWebServer->new(8080);
$server->run();
