#!/usr/bin/perl
# txt2pgsql.pl
# very dumb script that writes the bash to copy a delimited text file to postgres.  all field types are the same!
# NB: characters used by regex must be escaped, eg -d "\|". Also, postgres ctid is used to remove header rather than having Perl read file into memory, OR use Postgres CSV format for COPY which produced quoting problems. Sloppy.
# args: -i is input text file, -t is field type string eg "varchar(100)", -d is field delimiter, -p is postgres database
# example use: $0 -i /tmp/foo.dat.txt -d "\|" -t "varchar(100)" -p scratch | sh

use strict;
use warnings;
use File::Basename;
use File::Spec;

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

# get absolute path to input text file
my $txtabs = File::Spec->rel2abs( $args{i} );

my $db = $args{p};
# write the string that will make the empty pgsql table and populate it with the csv
# also remove header with postgres ctid - very sloppy
$str = "psql -d $db -c 
	\"DROP TABLE IF EXISTS $table; 
	CREATE TABLE $table ($str); 
	COPY $table FROM '$txtabs' WITH DELIMITER E'$args{d}';
	DELETE FROM $table WHERE ctid IN ( SELECT ctid FROM $table LIMIT 1 );\"";
# remove any returns or newlines in the string
$str =~ s/\r|\n//g;
print $str;

exit(0);
