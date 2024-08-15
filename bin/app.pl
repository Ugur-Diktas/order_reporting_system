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

    die "Failed to execute migrations script: $migration_script" if $output != 0;
    print "Migrations completed successfully.\n";
}

run_migrations();

app->static->paths->[0] = './public';

# ========================================================
# Utility: Establish Database Connection
# Connects to the database using the DBConnection module.
# ========================================================
sub establish_db_connection {
    my $dbh = eval { Infrastructure::Persistence::DBConnection::connect() };
    die "Database connection failed: $@" if $@;
    return $dbh;
}

# ========================================================
# Utility: Render Error Response
# Sends a JSON error response with the specified status code.
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
# Handles the uploading and processing of a CSV file.
# ========================================================
post '/upload' => sub {
    my $c = shift;
    my $upload = $c->param('csvfile');

    # Validate and process CSV file input
    my ($valid, $error) = validate_csv_file($upload);
    return render_error($c, $error, 400) unless $valid;

    my $csv_content = eval { $upload->slurp };
    return render_error($c, "Failed to read the uploaded file: $@", 500) if $@;

    my $dbh = eval { establish_db_connection() };
    return render_error($c, $@, 500) if $@;

    my $use_case = Application::UploadCSVUseCase->new($dbh);
    my $message = eval { $use_case->execute(\$csv_content) };
    return render_error($c, "Failed to process CSV: $@", 500) if $@;

    return $c->render(json => { message => $message });
};

# ========================================================
# Route: List Orders
# GET /api/list_orders
# Retrieves and returns all orders as JSON.
# ========================================================
get '/api/list_orders' => sub {
    my $c = shift;

    my $dbh = eval { establish_db_connection() };
    return render_error($c, $@, 500) if $@;

    my $orders = eval {
        my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
        return $order_repository->find_all();
    };
    return render_error($c, "Failed to retrieve orders: $@", 500) if $@;

    return $c->render(json => $orders);
};

# ========================================================
# Route: Generate PDF
# POST /api/generate_pdf
# Generates and returns a PDF report based on selected orders.
# ========================================================
post '/api/generate_pdf' => sub {
    my $c = shift;
    my $order_ids = $c->req->json->{order_ids};

    # Validate order IDs input
    my ($valid, $error) = validate_order_ids($order_ids);
    return render_error($c, $error, 400) unless $valid;

    my $dbh = eval { establish_db_connection() };
    return render_error($c, $@, 500) if $@;

    my $pdf_file = eval {
        my $use_case = Application::GeneratePDFUseCase->new($dbh);
        return $use_case->execute($order_ids);
    };
    return render_error($c, "Failed to generate PDF: $@", 500) if $@ || !$pdf_file;

    # Return PDF as a downloadable file
    $c->res->headers->content_disposition('attachment; filename="order_report.pdf"');
    $c->res->headers->content_type('application/pdf');
    return $c->reply->file($pdf_file);
};

# ========================================================
# Route: Delete Orders
# POST /api/delete_orders
# Deletes the selected orders from the database.
# ========================================================
post '/api/delete_orders' => sub {
    my $c = shift;
    my $order_ids = $c->req->json->{order_ids};

    # Validate order IDs input
    my ($valid, $error) = validate_order_ids($order_ids);
    return render_error($c, $error, 400) unless $valid;

    my $dbh = eval { establish_db_connection() };
    return render_error($c, $@, 500) if $@;

    my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
    my $deleted_count = eval { $order_repository->delete_orders($order_ids) };
    return render_error($c, "Failed to delete orders: $@", 500) if $@;

    return $c->render(json => { message => "$deleted_count orders deleted successfully." });
};

app->start;
