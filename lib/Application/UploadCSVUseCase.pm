package Application::UploadCSVUseCase;

use strict;
use warnings;
use Infrastructure::Persistence::SQLiteCustomerRepository;
use Infrastructure::CSVProcessor;

sub new {
    my ($class, $dbh) = @_;
    my $self = {
        customer_repository => Infrastructure::Persistence::SQLiteCustomerRepository->new($dbh),
        dbh                 => $dbh,
    };
    bless $self, $class;
    return $self;
}

sub execute {
    my ($self, $csv_content_ref) = @_;
    return Infrastructure::CSVProcessor::process_csv($csv_content_ref, $self->{customer_repository}, $self->{dbh});
}

1;
