#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use CONSTANT;
use common;

###################
# Global variable #
###################
my ($EXPORT_PRICESIZESTOCK_PROD_FILE)	= $CONSTANT::EXPORT_PRICESIZESTOCK_PROD_FILE;
my ($IMPORT_PRICESIZESTOCK_PROD_FILE)	= $CONSTANT::IMPORT_PRICESIZESTOCK_PROD_FILE;
my ($CHECK_SCRIPT_FILE)					= $CONSTANT::CHECK_SCRIPT_FILE;
my ($CSVI_CRON_FILE)					= $CONSTANT::CSVI_CRON_FILE;

#####################
# Method prototypes #
#####################

#################
# Method bodies #
#################

# Main subroutine
sub main()
{
	# clear files
	print "-- Clear cached files\n";
	eval {
		my ($cmd) = "rm -rf $EXPORT_PRICESIZESTOCK_PROD_FILE";
		print "-- -- $cmd\n";		
		system($cmd);
	};
	if ( $@ ) {
		print "ERROR: Deleting exported files\n";
		exit 1;
	}
	eval {
		my ($cmd) = "rm -rf $IMPORT_PRICESIZESTOCK_PROD_FILE";
		print "-- -- $cmd\n";
		system($cmd);
	};
	if ( $@ ) {
		print "ERROR: Deleting imported files\n";
		exit 1;
	}
	
	# export products
	print "-- Export products\n";
	eval {
		my ($cmd) = "/usr/local/bin/php5.5 $CSVI_CRON_FILE username=\"josemrc\" passwd=\"123.qwe\" template_name=\"Export PriceSizeStock Products\" > /dev/null 2>&1";
		print "-- -- $cmd\n";		
		system($cmd);
	};
	if ( $@ ) {
		print "ERROR: Exporting products\n";
		exit 1;
	}
	
	# check price/size/stock of products
	print "-- Check price/size/stock products\n";
	if ( -e $EXPORT_PRICESIZESTOCK_PROD_FILE and (-s $EXPORT_PRICESIZESTOCK_PROD_FILE > 0) ) {
		eval {
			my ($cmd) = "perl $CHECK_SCRIPT_FILE $EXPORT_PRICESIZESTOCK_PROD_FILE";
			print "-- -- $cmd\n";		
			system($cmd);
		};
		if ( $@ ) {
			print "ERROR: Deleting imported files\n";
			exit 1;
		}
	}
	
	# import products
	print "-- Import products\n";
	if ( -e $IMPORT_PRICESIZESTOCK_PROD_FILE and (-s $IMPORT_PRICESIZESTOCK_PROD_FILE > 0) ) {	
		eval {
			my ($cmd) = "/usr/local/bin/php5.5 $CSVI_CRON_FILE username=\"josemrc\" passwd=\"123.qwe\" template_name=\"Import PriceSizeStock Products\" > /dev/null 2>&1";
			print "-- -- $cmd\n";		
			system($cmd);
		};
		if ( $@ ) {
			print "ERROR: Importing products\n";
			exit 1;
		}
	}
	
	exit 0;
}

main();


__END__

=head1 NAME

update_external_products

=head1 DESCRIPTION

Main script that update the price/size/stocj of external products 

=head1 ARGUMENTS

=head2 Required arguments:
	
	<Type of input: google, or file that contains the clothes>

=head1 EXAMPLE

perl update_external_products.pl

=head1 AUTHOR

Created and Developed by

	Jose Manuel Rodriguez Carrasco -josemrc@cnio.es-

=cut
