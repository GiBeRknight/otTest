package Kernel::Config::Files::ZZZCustom;
use strict;
use warnings;
no warnings 'redefine';
sub Load {
    my ($File, $Self) = @_;
    $Self->{DatabaseHost} = '127.0.0.1';
    $Self->{Database}     = $ENV{OTRS_DB_NAME}     // 'otrs';
    $Self->{DatabaseUser} = $ENV{OTRS_DB_USER}     // 'otrs';
    $Self->{DatabasePw}   = $ENV{OTRS_DB_PASSWORD} // 'some-pass';
}
1;
