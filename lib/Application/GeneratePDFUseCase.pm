package Application::GeneratePDFUseCase;

use strict;
use warnings;
use Infrastructure::PDFGenerator;

# ========================================================
# Constructor: new
# Initializes the GeneratePDFUseCase with a database handle.
# ========================================================
sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

# ========================================================
# Method: execute
# Generates a PDF report for the given order IDs.
# ========================================================
sub execute {
    my ($self, $order_ids) = @_;
    return Infrastructure::PDFGenerator::generate_pdf($self->{dbh}, $order_ids);
}

1;
