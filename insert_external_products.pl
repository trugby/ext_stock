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
my ($INIT_EXT_FILE) = $ARGV[0];
#my ($INIT_EXT_FILE)				= $CONSTANT::INIT_EXT_FILE;
unless ( defined $INIT_EXT_FILE ) {
	print `perldoc $0`;
	exit 1;
}
my ($IMPORT_EXT_PROD_FILE)		= $CONSTANT::IMPORT_EXT_PROD_FILE;
my ($DOWNN_SCRIPT_FILE)			= $CONSTANT::DOWNN_SCRIPT_FILE;
my ($CSVI_CRON_FILE)			= $CONSTANT::CSVI_CRON_FILE;
my ($LANGUAGES)					= $CONSTANT::LANGUAGES;

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
		my ($file) = $IMPORT_EXT_PROD_FILE;
		$file =~ s/__LANG__/\*/;
		my ($cmd) = "rm -rf $file";
		print "-- -- $cmd\n";		
		system($cmd);
	};
	if ( $@ ) {
		print "ERROR: Deleting exported files\n";
		exit 1;
	}
	
	# download products
	print "-- Download products\n";
	if ( -e $INIT_EXT_FILE and (-s $INIT_EXT_FILE > 0) ) {
		eval {
			my ($cmd) = "perl $DOWNN_SCRIPT_FILE $INIT_EXT_FILE";
			print "-- -- $cmd\n";		
			system($cmd);
		};
		if ( $@ ) {
			print "ERROR: Deleting imported files\n";
			exit 1;
		}
	}
	
	# import products per language
	print "-- Import products\n";
	foreach my $lang (@{$LANGUAGES}) {
		my ($langfile) = $IMPORT_EXT_PROD_FILE;
		my ($lan) = uc($lang);
		$langfile =~ s/__LANG__/_$lan/;		
		if ( -e $langfile and (-s $langfile > 0) ) {	
			eval {
				my ($cmd) = "/usr/local/bin/php5.5 $CSVI_CRON_FILE username=\"josemrc\" passwd=\"123.qwe\" template_name=\"Import Ext Products $lan\" > /dev/null 2>&1";
				print "-- -- $cmd\n";		
				system($cmd);
			};
			if ( $@ ) {
				print "ERROR: Importing products\n";
				exit 1;
			}
		}
	}	
	
	exit 0;
}

main();


__END__

=head1 NAME

insert_external_products

=head1 DESCRIPTION

Main script that update the price/size/stocj of external products 

=head1 ARGUMENTS

=head2 Required arguments:
	
	<Type of input: file that contains the initial links of products>

=head1 EXAMPLE

perl insert_external_products.pl initExtStock.csv

=head1 AUTHOR

Created and Developed by

	Jose Manuel Rodriguez Carrasco -josemrc@cnio.es-

=cut
