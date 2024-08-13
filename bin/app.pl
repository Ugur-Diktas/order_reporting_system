use Mojolicious::Lite;
use lib 'lib';

use Infrastructure::Persistence::SQLiteOrderRepository;
use Infrastructure::Persistence::DBConnection;
use Application::UploadCSVUseCase;
use Application::GeneratePDFUseCase;
use Application::Validation qw(validate_csv_file validate_order_ids);

# ========================================================
# Run Migrations Before Starting the App
# ========================================================
sub run_migrations {
    my $migration_script = 'bin/run_migrations.pl';
    my $output = system("perl $migration_script");

    if ($output != 0) {
        die "Failed to execute migrations script: $migration_script";
    }

    print "Migrations completed successfully.\n";
}

# Call the function to run migrations
run_migrations();

app->static->paths->[0] = './public';

# ========================================================
# Utility: Establish Database Connection
# ========================================================
sub establish_db_connection {
    my $dbh = eval { Infrastructure::Persistence::DBConnection::connect() };
    if ($@) {
        die "Database connection failed: $@";
    }
    return $dbh;
}

# ========================================================
# Utility: Render Error Response
# ========================================================
sub render_error {
    my ($c, $error, $status) = @_;
    return $c->render(json => { error => $error }, status => $status);
}

# ========================================================
# Route: Homepage
# ========================================================
get '/' => sub {
    my $c = shift;
    $c->reply->static('index.html');
};

# ========================================================
# Route: CSV File Upload
# POST /upload
# This route handles the uploading of a CSV file. The file is 
# validated to ensure it's a CSV, and then its contents are 
# processed to update the database. If any errors occur during 
# file reading, database connection, or CSV processing, 
# appropriate error messages are returned.
# ========================================================
post '/upload' => sub {
    my $c = shift;
    my $upload = $c->param('csvfile');

    # Validate CSV file input
    my ($valid, $error) = validate_csv_file($upload);
    unless ($valid) {
        return render_error($c, $error, 400);
    }

    my $csv_content = eval { $upload->slurp };
    if ($@) {
        return render_error($c, "Failed to read the uploaded file: $@", 500);
    }

    # Establish a database connection
    my $dbh = eval { establish_db_connection() };
    if ($@) {
        return render_error($c, $@, 500);
    }

    # Execute the use case to process the CSV content
    my $use_case = Application::UploadCSVUseCase->new($dbh);
    my $message = eval { $use_case->execute(\$csv_content) };

    if ($@) {
        return render_error($c, "Failed to process CSV: $@", 500);
    }

    return $c->render(json => { message => $message });
};

# ========================================================
# Route: List Orders
# GET /api/list_orders
# This route retrieves and returns a list of all orders stored 
# in the database. It connects to the database, fetches the 
# orders using the OrderRepository, and returns them as JSON.
# If an error occurs during the database connection or data 
# retrieval, appropriate error messages are returned.
# ========================================================
get '/api/list_orders' => sub {
    my $c = shift;

    # Establish a database connection
    my $dbh = eval { establish_db_connection() };
    if ($@) {
        return render_error($c, $@, 500);
    }

    # Retrieve all orders
    my $orders = eval {
        my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
        return $order_repository->find_all();
    };

    if ($@) {
        return render_error($c, "Failed to retrieve orders: $@", 500);
    }

    return $c->render(json => $orders);
};

# ========================================================
# Route: Generate PDF
# POST /api/generate_pdf
# This route generates a PDF report based on selected orders. 
# The order IDs are validated and then passed to the PDF 
# generator. If successful, the PDF is returned as a downloadable 
# file. Errors during validation, database connection, or PDF 
# generation are handled and returned to the client.
# ========================================================
post '/api/generate_pdf' => sub {
    my $c = shift;
    my $order_ids = $c->req->json->{order_ids};

    # Validate order IDs input
    my ($valid, $error) = validate_order_ids($order_ids);
    unless ($valid) {
        return render_error($c, $error, 400);
    }

    # Establish a database connection
    my $dbh = eval { establish_db_connection() };
    if ($@) {
        return render_error($c, $@, 500);
    }

    # Generate the PDF report
    my $pdf_file = eval {
        Infrastructure::PDFGenerator::generate_pdf($dbh, $order_ids);
    };

    if ($@ || !$pdf_file) {
        return render_error($c, "Failed to generate PDF: $@", 500);
    }

    # Set the response headers to indicate a file download
    $c->res->headers->content_disposition('attachment; filename="order_report.pdf"');
    $c->res->headers->content_type('application/pdf');
    return $c->reply->file($pdf_file);
};

app->start;
