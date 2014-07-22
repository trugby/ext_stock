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

#####################
# Method prototypes #
#####################

#################
# Method bodies #
#################

# Main subroutine
sub main()
{
	# export products
	eval {
		my ($cmd) = '/usr/local/bin/php5.5 /kunden/homepages/24/d406245370/htdocs/dev/administrator/components/com_csvi/helpers/cron.php username="josemrc" passwd="123.qwe" template_name="Export PriceSizeStock Products" > /dev/null 2>&1';
		system($cmd);
	};
	if ( $@ ) {
		print STDERR "Exporting products\n";
		exit 1;
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
