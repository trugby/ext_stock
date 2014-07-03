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
my ($GOOGLE_FILE)			= $CONSTANT::GD_FILE;
my ($MAIN_LANG)				= $CONSTANT::MAIN_LANG;
my ($LANGUAGES)				= $CONSTANT::LANGUAGES;
my ($SHOPS)					= $CONSTANT::SHOPS;
my ($SHOP_TMP_DIR)			= $CONSTANT::SHOP_TMP_DIR;
my ($SHOP_PROD_IMG_DIR)		= $CONSTANT::SHOP_PROD_IMG_DIR;				
my ($IMPORT_EXT_PROD_FILE)	= $CONSTANT::IMPORT_EXT_PROD_FILE;
my ($IMPORT_EXT_IMG_FILE)	= $CONSTANT::IMPORT_EXT_IMG_FILE;

# Input parameters
my ($intype) = $ARGV[0];
my ($infile) = 'kk'; #$CONSTANT::GD_FILE2; # by default
unless ( defined $infile and defined $intype ) {
	print `perldoc $0`;
	exit 1;
}
else {
	if ( $intype eq 'google' ) {
		$infile = $GOOGLE_FILE;
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
	foreach my $lang (@{$LANGUAGES}) {
		$o_reports->{$lang} = '';	
	}	
	
	#load cookies
	print "# create cookie files...\n";
	my ($cookies) = common::save_cookies($SHOPS);
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
			my ($i_man_path) = $row->[2]; $i_man_path=~ s/\"//g; $i_man_path=~ s/\r//g;
			my ($i_link_en) = $row->[3]; $i_link_en=~ s/\"//g; $i_link_en=~ s/\r//g;
			my ($i_link_es) = $row->[4]; $i_link_es=~ s/\"//g; $i_link_es=~ s/\r//g;
			my ($i_link_pt) = $row->[5]; $i_link_en=~ s/\"//g; $i_link_en=~ s/\r//g;
			my ($i_prod) = {
				'sku'				=> $i_sku,
				'category_id'		=> $i_cat_path,
				'manufacturer_id'	=> $i_man_path,
				'lang'				=> {
					$LANGUAGES->[0]	=> $i_link_en,
					$LANGUAGES->[1]	=> $i_link_es,
					$LANGUAGES->[2]	=> $i_link_pt
				}
			};
			print "## product > \n".Dumper($i_prod)."\n";
			
			my ($shop_name) = 'sportsdirect';
			if ( index($i_link_en, $shop_name) != -1 ) {
				
				
				print "### prepare workspace $shop_name\n";
				my ($tmp_dir)	= $SHOP_TMP_DIR->{$shop_name};
				my ($prod_tmp_dir)	= $SHOP_PROD_IMG_DIR->{$shop_name};				
				common::prepare_wspace($tmp_dir);
				common::prepare_wspace($prod_tmp_dir);
				
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
					foreach my $lang (@{$LANGUAGES}) {
						if ( $lang eq $MAIN_LANG ) {
							if ( exists $o_report->{'images'} ) {
								$o_reports->{'images'} .= $o_report->{'images'};								
							}
						}
						$o_reports->{$lang} .= $o_report->{$lang};						
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
		print "## delete old file\n";
		my ($rm_log) = common::rm_file($IMPORT_EXT_PROD_FILE);
		unless (defined $rm_log) {
			print "ERROR!!! Deleting $IMPORT_EXT_PROD_FILE\n";
		}
		my ($rm2_log) = common::rm_file($IMPORT_EXT_IMG_FILE);
		unless (defined $rm2_log) {
			print "ERROR!!! Deleting $IMPORT_EXT_IMG_FILE\n";
		}
		# create update file
		print "## printing files\n";
#print STDERR "RESULTS:\n".Dumper($o_reports)."\n";
		my ($import_prod_files) = sportdirect::print_down_prod_result($o_reports, $IMPORT_EXT_PROD_FILE);
		unless (defined $import_prod_files and ($import_prod_files ne '') ) {
			print "ERROR!!! Printing files\n";
		}
		my ($import_img_files) = sportdirect::print_down_img_result($o_reports, $IMPORT_EXT_IMG_FILE);
		unless (defined $import_img_files and ($import_img_files ne '') ) {
			print "ERROR!!! Printing img files\n";
		}

		# send email
		my ($import_files) = join(';',$import_prod_files,$import_img_files);
		print "## sending files: $import_files\n";
		if ( defined $import_files ) {
			common::send_email($e_message, $import_files);
		}
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
