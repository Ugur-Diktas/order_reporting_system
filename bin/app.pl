use Mojolicious::Lite;
use lib 'lib';

use Infrastructure::Persistence::SQLiteOrderRepository;
use Infrastructure::Persistence::DBConnection;
use Application::UploadCSVUseCase;
use Application::GeneratePDFUseCase;

# Serve static files from the 'public' directory
app->static->paths->[0] = './public';

# Serve the homepage (index.html)
get '/' => sub {
    my $c = shift;
    $c->reply->static('index.html');
};

# Route to handle CSV file upload
post '/upload' => sub {
    my $c = shift;
    my $upload = $c->param('csvfile');

    unless ($upload) {
        return $c->render(json => { error => "No file uploaded" }, status => 400);
    }

    my $csv_content = $upload->slurp;
    my $dbh = Infrastructure::Persistence::DBConnection::connect();  # Use the new DBConnection module
    my $use_case = Application::UploadCSVUseCase->new($dbh);
    my $message = eval { $use_case->execute(\$csv_content) };
    
    if ($@) {
        return $c->render(json => { error => "Failed to process CSV: $@" }, status => 500);
    }

    return $c->render(json => { message => $message });
};

# API route to list orders
get '/api/list_orders' => sub {
    my $c = shift;

    my $dbh = Infrastructure::Persistence::DBConnection::connect();  # Use the new DBConnection module
    my $order_repository = Infrastructure::Persistence::SQLiteOrderRepository->new($dbh);
    my $orders = $order_repository->find_all();

    return $c->render(json => $orders);
};

# API route to generate PDF
post '/api/generate_pdf' => sub {
    my $c = shift;
    my $order_ids = $c->req->json->{order_ids};

    if (!@$order_ids) {
        return $c->render(json => { error => "No orders selected" }, status => 400);
    }

    my $dbh = Infrastructure::Persistence::DBConnection::connect();
    my $pdf_file = eval {
        Infrastructure::PDFGenerator::generate_pdf($dbh, $order_ids);
    };

    if ($@ || !$pdf_file) {
        return $c->render(json => { error => "Failed to generate PDF: $@" }, status => 500);
    }

    $c->res->headers->content_disposition('attachment; filename="order_report.pdf"');
    $c->res->headers->content_type('application/pdf');
    return $c->reply->file($pdf_file);
};

# Start the Mojolicious application
app->start;
