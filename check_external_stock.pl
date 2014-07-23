#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use CONSTANT;
use common;
use sportdirect;
#use lovellrugby;

###################
# Global variable #
###################
my ($LANGUAGES)							= $CONSTANT::LANGUAGES;
my ($SHOPS)								= $CONSTANT::SHOPS;
my ($IMPORT_PRICESIZESTOCK_PROD_FILE)	= $CONSTANT::IMPORT_PRICESIZESTOCK_PROD_FILE;

my ($EMAILS_FROM)			= $CONSTANT::EMAILS_FROM;
my ($EMAILS_TO)				= $CONSTANT::EMAILS_TO;
my ($EMAILS_CHECK_SUBJECT)	= $CONSTANT::EMAILS_CHECK_SUBJECT;

# Input parameters
my ($INIT_EXT_FILE) = $ARGV[0];
unless ( defined $INIT_EXT_FILE  ) {
	print `perldoc $0`;
	exit 1;
}

#####################
# Method prototypes #
#####################

#################
# Method bodies #
#################

# Main subroutine
sub main()
{
	# create changed message
	my ($e_message) = '';
	my ($o_reports);
	
	#load cookies
	print "# create cookie files...\n";
	my ($cookies) = common::save_cookies($SHOPS);
	unless ( defined $cookies ) {
		exit 1;
	}	
	
	# process input file
	print "# process external products...\n";
	my ($csv) = Text::CSV->new ({
		binary    => 1,
		auto_diag => 1,
		sep_char  => ','    # not really needed as this is the default
	});
	open( my $fh, "<:encoding(utf8)", $INIT_EXT_FILE ) or die "$INIT_EXT_FILE: $!";
	while ( my $row = $csv->getline( $fh ) ) {
		# "virtuemart_product_id","product_name","product_price","custom_title","custom_value","custom_ordering","intnotes"
		if ( scalar(@{$row}) >= 6 ) {
			my ($i_id) = $row->[0]; $i_id=~ s/\"//g; $i_id=~ s/\r//g;
			my ($i_name) = $row->[1]; $i_name=~ s/\"//g; $i_name=~ s/\r//g;
			my ($i_price) = $row->[2]; $i_price=~ s/\"//g; $i_price=~ s/\r//g;
			my ($i_sizetitle) = $row->[3]; $i_sizetitle=~ s/\"//g; $i_sizetitle=~ s/\r//g;
			my ($i_sizes) = $row->[4]; $i_sizes=~ s/\"//g; $i_sizes=~ s/\r//g;
			my ($i_sizeordering) = $row->[5]; $i_sizeordering=~ s/\"//g; $i_sizeordering=~ s/\r//g;
			my ($i_link) = $row->[6]; $i_link=~ s/\"//g; $i_link=~ s/\r//g;
			my ($i_prod) = {
				'id'		=> $i_id,
				'name'		=> $i_name,
				'price'		=> $i_price,
				'link'		=> $i_link,
			};
			my (@aux_sizes) = split('~', $i_sizes);
			my ($sizes);		
			foreach my $s (@aux_sizes) {
				$s =~ s/\s*//g; $s = uc($s); $s =~ s/\r//g;
				push(@{$sizes},$s);								
			}
			$i_prod->{'sizes'} = $sizes if ( defined $sizes and scalar(@{$sizes}) > 0 );
			print "## product > \n".Dumper($i_prod)."\n";
			
			my ($shop_name) = 'sportsdirect';
			if ( index($i_link, $shop_name) != -1 ) {
				print "### checking $shop_name\n";
				my ($logger,$o_report) = sportdirect::update_product($i_prod);
#print STDERR "\n\n\n";
#print STDERR "LOGGER:\n".Dumper($logger)."\n";
#print STDERR "RESULTS:\n".Dumper($o_report)."\n";
				if ( defined $o_report ) {
					foreach my $lang (@{$LANGUAGES}) {
						if ( exists $o_report->{$lang} and ($o_report->{$lang} ne '') ) {
							$o_reports->{$lang} .= $o_report->{$lang};	
						}
					}
				}
				if ( $logger->{'error'} == 1 ) {
					$e_message .= "# $i_id > $i_name [PROBLEMS]\n";
					$e_message .= $logger->{'log'}."\n";
					next; # jump to the next product
				}
				if ( $logger->{'warning'} == 1 ) {
					$e_message .= "# $i_id > $i_name\n";
					$e_message .= $logger->{'log'}."\n";
				}
			}
			else {
				my ($shop_name) = 'lovell-rugby';
				#print "### checking $shop_name\n";
				#if ( index($i_link_en, $shop_name) != -1 ) {
				#	my ($e_msg) = lovellrugby::down_product($i_links, $cookies->{$shop_name});
				#	$e_message .= "$e_msg\n";
				#}
			}

		}
	}
	$csv->eof or $csv->error_diag();
	close $fh;

	print "###########################################################\n\n";
	print "$e_message\n";
	
	#create stock report
	if ( defined $o_reports ) {
		
		# create update file
		print "## printing files\n";
		my ($import_prod_files) = sportdirect::print_prod_result($o_reports, $IMPORT_PRICESIZESTOCK_PROD_FILE);
		unless (defined $import_prod_files and ($import_prod_files ne '') ) {
			print "ERROR!!! Printing files\n";
		}
		# send email
		my ($import_files) = join(';',$import_prod_files);
		print "## sending files: $import_files\n";
		if ( defined $import_files ) {
			common::send_email($EMAILS_FROM, $EMAILS_TO, $EMAILS_CHECK_SUBJECT, $e_message, $import_files);
		}
	}	

	exit 0;
}

main();


__END__

=head1 NAME

check_external_products

=head1 DESCRIPTION

Checks the external stock from a exported file of database. 

=head1 ARGUMENTS

=head2 Required arguments:
	
	<Type of input: file that contains the exported products>

=head1 EXAMPLE

perl check_external_products.pl ExportPriceSizeStockProducts.csv

=head1 AUTHOR

Created and Developed by

	Jose Manuel Rodriguez Carrasco -josemrc@cnio.es-

=cut
