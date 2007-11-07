use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Socialtext::Backup::S3',
    VERSION_FROM    => 'lib/Socialtext/Backup/S3.pm',
    EXE_FILES => ['bin/st-backup-s3', 'bin/st-restore-s3'],
);
