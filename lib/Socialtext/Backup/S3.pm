package Socialtext::Backup::S3;
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

sub backup {
    my $self = shift;
    my $bucket = $self->bucket;
    my $tarball = $self->_create_backup_tarball;

    return unless $tarball and -e $tarball;
    (my $backup_key = $tarball) =~ s#.+/##;
    print "Uploading $backup_key...\n";
    $bucket->add_key_filename($backup_key, $tarball, {
            content_type => 'application/x-tar-gz',
        },
    );
    unlink $tarball or warn "Can't unlink $tarball: $!";
}

sub _create_backup_tarball {
    my $self = shift;

    my $tmpdir = tempdir(CLEANUP => 1);
    print "Using tempdir: $tmpdir\n";
    my @workspaces = qx(st-admin list-workspaces);
    chomp @workspaces;

    for my $w (@workspaces) {
        next if $w =~ m/^help-\w\w$/; # no need to backup the help workspaces

        print "Backing up workspace $w...\n";
        my $output = qx(st-admin export-workspace --dir $tmpdir -w $w);
        unless ($output =~ m/has been exported to (\S+).\s+/s) {
            warn "Failed to backup $w: $output\n";
            next;
        }
    }

    my $hostname = hostname();
    my @now = localtime;
    my $timestamp = sprintf('%4d-%02d-%02d-%02d-%02d',
                            $now[5] + 1900, $now[4] + 1, @now[3,2,1]);
    my $tarball = "/tmp/$hostname-$timestamp.tar.gz";

    print "Creating backup tarball $tarball...\n";
    shell_run("cd $tmpdir && tar cvzf $tarball *");
    return $tarball;
}

1;
