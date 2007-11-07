package Socialtext::S3;
use strict;
use warnings;
use YAML qw/LoadFile/;
use Net::Amazon::S3;

sub s3 {
    my $self = shift;
    $self->{_s3} ||= Net::Amazon::S3->new($self->{config});
    return $self->{_s3};
}

sub load_config {
    my $self = shift;
    return $self->{config} if $self->{config};

    my $config_file = $self->{backup_config_file} 
                          || '/etc/socialtext/backup-s3.yaml';
    $self->{config} ||= LoadFile($config_file);
    return $self->{config};
}

sub bucket {
    my $self = shift;
    my $s3 = $self->s3;
    my $bucket_name = $self->{config}{bucket_name} || 'socialtext-backup';

    my $response = $s3->buckets;
    my $bucket_exists = 0;
    foreach my $bucket ( @{ $response->{buckets} } ) {
        next unless $bucket->bucket eq $bucket_name;
        $bucket_exists++;
        last;
    }

    unless ($bucket_exists) {
        $s3->add_bucket( { bucket => $bucket_name } )
            or die $s3->err . ": " . $s3->errstr;
        print "Created new bucket: $bucket_name\n";
    }

    return $s3->bucket($bucket_name);
}

1;
