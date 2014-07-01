#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use sportdirect;
#use lovellrugby;
use constant;
use common;

###################
# Global variable #
###################
use CONSTANT qw(
	$TMP_DIR
	$UPDATE_FILE
	$IMPORT_EXT_FILE
	$GD_FILE
	$SHOPS_FILE
	$LANGUAGES
	$SHOPS
	$CONV_SPORTDIRECT_SIZES
	$SIZE_TITLE
);

# Input parameters
my ($intype) = $ARGV[0];
my ($infile) = 'kk'; #$CONSTANT::GD_FILE2; # by default
unless ( defined $infile and defined $intype ) {
	print `perldoc $0`;
	exit 1;
}
else {
	if ( $intype eq 'google' ) {
		$infile = $CONSTANT::GD_FILE;
	}
	else {
		$infile = $intype;
	}
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
	my ($cookies) = common::save_cookies($CONSTANT::SHOPS);
	unless ( defined $cookies ) {
		exit 1;
	}	
	
	# get list of links/products/languages
	print "# process initial products...\n";
	my ($csv) = Text::CSV->new ({
		binary    => 1,
		auto_diag => 1,
		sep_char  => ','    # not really needed as this is the default
	});
	open( my $fh, "<:encoding(utf8)", $infile ) or die "$infile: $!";
	while ( my $row = $csv->getline( $fh ) ) {
		# "sku", "category_path", "link_en","link_es","link_pt"
		if ( scalar(@{$row}) >= 4 ) {
			my ($i_sku) = $row->[0]; $i_sku=~ s/\"//g; $i_sku=~ s/\r//g;
			my ($i_cat_path) = $row->[1]; $i_cat_path=~ s/\"//g; $i_cat_path=~ s/\r//g;
			my ($i_man_path) = $row->[1]; $i_man_path=~ s/\"//g; $i_man_path=~ s/\r//g;
			my ($i_link_en) = $row->[2]; $i_link_en=~ s/\"//g; $i_link_en=~ s/\r//g;
			my ($i_link_es) = $row->[3]; $i_link_es=~ s/\"//g; $i_link_es=~ s/\r//g;
			my ($i_link_pt) = $row->[4]; $i_link_en=~ s/\"//g; $i_link_en=~ s/\r//g;
			my ($i_prod) = {
				'sku'				=> $i_sku,
				'category_id'		=> $i_cat_path,
				'manufacturer_id'	=> $i_man_path,
				'lang'				=> {
					$CONSTANT::LANGUAGES->[0]	=> $i_link_en,
					$CONSTANT::LANGUAGES->[1]	=> $i_link_es,
					$CONSTANT::LANGUAGES->[2]	=> $i_link_pt
				}
			};
			print "## product > \n".Dumper($i_prod)."\n";
			
			my ($shop_name) = 'sportsdirect';
			if ( index($i_link_en, $shop_name) != -1 ) {
				print "### checking $shop_name\n";
				my ($logger,$o_report) = sportdirect::down_product($i_prod);
#print STDERR "\n\n\n";
#print STDERR "LOGGER:\n".Dumper($logger)."\n";
#print STDERR "RESULTS:\n".Dumper($o_report)."\n";

				if ( $logger->{'error'} == 1 ) {
					print "ERROR!!! ".$logger->{'log'}."\n\n\n";
					next; # jump to the next product
				}
				if ( $logger->{'warning'} == 1 ) {
					print "WARNING: ".$logger->{'log'}."\n";
				
				}
				if ( defined $o_report ) {
					foreach my $lang (@{$CONSTANT::LANGUAGES}) {
						$o_reports->{$lang} = $o_report->{$lang};						
					}
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
		# delete old update file
		#print "## delete old file\n";
		#my ($rm_log) = common::rm_file($CONSTANT::UPDATE_FILE);
		#unless (defined $rm_log) {
		#	print "## ERROR: deleting $CONSTANT::UPDATE_FILE\n";
		#}
		# create update file
		print "## printing files\n";
print STDERR "RESULTS:\n".Dumper($o_reports)."\n";
		my ($prt_log) = sportdirect::print_down_result($o_reports, $CONSTANT::IMPORT_EXT_FILE);
		unless (defined $prt_log) {
			print "## ERROR: printing files\n";
		}

		# send email
		#print "## sending file\n";
		#if ( -e $CONSTANT::UPDATE_FILE and (-s $CONSTANT::UPDATE_FILE > 0) ) {
		#	common::send_email($e_message,$CONSTANT::UPDATE_FILE);
		#}
	}	

	exit 0;
}

main();


__END__

=head1 NAME

download_external

=head1 DESCRIPTION

Script that check the stock given from an email. These items come from a list of online shops 

=head1 ARGUMENTS

=head2 Required arguments:
	
	<Type of input: google, or file that contains the clothes>

=head1 EXAMPLE

perl check_stock.pl google

perl check_stock.pl clothes.txt

=head1 AUTHOR

Created and Developed by

	Jose Manuel Rodriguez Carrasco -josemrc@cnio.es-

=cut
