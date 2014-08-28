#!/usr/bin/perl
# txt2pgsql.pl
# very dumb script that writes the bash to copy a delimited text file to postgres.  all field types are the same!
# NB: characters used by regex must be escaped, eg -d "\|"
# args: -i is input text file, -t is field type string eg "varchar(100)", -d is field delimiter, -p is postgres database
# example use: $0 -i /tmp/foo.dat.txt -d "\|" -t "varchar(100)" -p scratch | sh

use strict;
use warnings;
use File::Basename;

use Getopt::Std;
my %args;
getopts('i:t:d:p:', \%args);

# get first line of csv
open my $csv, '<', "$args{i}" or die "Can't read file $args{i}";
my $header = <$csv>;
close $csv;

# add each field name to an array
my @fields = split($args{d}, $header);
my $type = $args{t};

# for each field name, pad with quotes and field type, escape double quotes
my @format;
foreach my $quoted (@fields) {
  push(@format, "\\\"$quoted\\\" $type,");
}

# define the scalar $str as the array @format getting printed
my $str = "@format";
# remove trailing comma
$str =~ s/,$//g;

# name table after input - no file extension, encase in escaped double quotes, use basename
my $table = $args{i};
# get basename
$table = fileparse($table);
$table =~ s/.*(^[^.]*).*/$1/g;
$table =~ s/^|$/\\"/g;

my $db = $args{p};
# write the string that will make the empty pgsql table and populate it with the csv
$str = "psql -d $db -c \"DROP TABLE IF EXISTS $table; CREATE TABLE $table ($str); COPY $table FROM '$args{i}' WITH DELIMITER E'$args{d}' CSV HEADER\"";
# remove any returns or newlines in the string
$str =~ s/\r|\n//g;
print $str;

exit(0);
