package Application::GeneratePDFUseCase;

use strict;
use warnings;
use Infrastructure::PDFGenerator;

sub new {
    my ($class, $dbh) = @_;
    my $self = { dbh => $dbh };
    bless $self, $class;
    return $self;
}

sub execute {
    my ($self, $order_id) = @_;
    return Infrastructure::PDFGenerator::generate_pdf($self->{dbh}, $order_id);
}

1;
