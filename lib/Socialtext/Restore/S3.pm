package Socialtext::Restore::S3;
use strict;
use warnings;
use File::Temp qw/tempdir/;
use Sys::Hostname qw/hostname/;
use Socialtext::System qw/shell_run/;
use base 'Socialtext::S3';

sub new {
    my $class = shift;
    my $self = {
        @_,
    };

    bless $self, $class;
    $self->load_config;

    return $self;
}

sub restorable_files {
    my $self = shift;
    my $s3 = $self->s3;
    my $bucket = $self->bucket;

    my $response = $bucket->list_all
        or die $s3->err . ": " . $s3->errstr;
    foreach my $key ( @{ $response->{keys} } ) {
        my $key_name = $key->{key};
        my $key_size = $key->{size};
        print "Found backup '$key_name' of size $key_size\n";
    }
}

sub fetch_file {
    my $self = shift;
    my $filename = shift;
    my $local_filename = "/tmp/$filename";
    my $s3 = $self->s3;
    my $bucket = $self->bucket;

    print "Fetching $filename\n";
    $bucket->get_key_filename( $filename, 'GET', $local_filename )
        or die $s3->err . ": " . $s3->errstr;

    print "Fetched file $local_filename\n";
}


1;
