#!/usr/bin/perl -W
use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/lib";
use sportdirect;
use lovellrugby;
use common;

###################
# Global variable #
###################
use CONSTANT qw(
	$TMP_DIR
	$UPDATE_FILE
	$GD_FILE
	$SHOPS_FILE
	$SHOPS
	$CONV_SPORTDIRECT_SIZES
	$SIZE_TITLE
);

# Input parameters
my ($intype) = $ARGV[0];
my ($infile) = $CONSTANT::GD_FILE; # by default
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
	my ($e_result) = '';

	#my ($clothes_cont);
	#if ( $intype eq 'google' ) {
	#	print "# open google doc file: $infile\n";
	#	$clothes_cont = common::open_web_file($infile);
	#}
	#else {
	#	print "# open local file: $infile\n";
	#	$clothes_cont = common::open_file($infile);		
	#}

	#load cookies
	print "# create cookie files...\n";
	my ($cookies) = common::save_cookies($CONSTANT::SHOPS);
	unless ( defined $cookies ) {
		exit 1;
	}
	
	print "# process external products...\n";
	my ($csv) = Text::CSV->new ({
		binary    => 1,
		auto_diag => 1,
		sep_char  => ','    # not really needed as this is the default
	});
	open( my $fh, "<:encoding(utf8)", $infile ) or die "$infile: $!";
	while ( my $row = $csv->getline( $fh ) ) {
		# '"virtuemart_product_id","product_name","product_price","discountamount","published","custom_title","custom_value","intnotes"';			
		if ( scalar(@{$row}) >= 3 ) {
			my ($i_id) = $row->[0]; $i_id=~ s/\"//g; $i_id=~ s/\r//g;
			my ($i_name) = $row->[1]; $i_name=~ s/\"//g; $i_name=~ s/\r//g;
			my ($i_price) = $row->[2]; $i_price=~ s/\"//g; $i_price=~ s/\r//g;
			my ($i_discount) = $row->[3]; $i_discount=~ s/\"//g; $i_discount=~ s/\r//g;
			my ($i_published) = $row->[4]; $i_published=~ s/\"//g; $i_published=~ s/\r//g;
			my ($i_sizetitle) = $row->[5]; $i_sizetitle=~ s/\"//g; $i_sizetitle=~ s/\r//g;
			my ($i_sizes) = $row->[6]; $i_sizes=~ s/\"//g; $i_sizes=~ s/\r//g;
			my ($i_link) = $row->[7]; $i_link=~ s/\"//g; $i_link=~ s/\r//g;

			my (@aux_sizes) = split('~', $i_sizes);
			my ($sizes);		
			foreach my $s (@aux_sizes) {
				$s =~ s/\s*//g; $s = uc($s); $s =~ s/\r//g;
				$sizes->{$s} = 1;
			}
			my (@sizetitles) = split('~', $i_sizetitle);
			$CONSTANT::SIZE_TITLE = $sizetitles[0];

			if ( defined $i_published and ($i_published eq "1") ) {
				if ( defined $i_name and defined $i_link and defined $i_price and defined $sizes ) {
					print "## product > $i_id | $i_name | $i_link\n";
					print "### Local price: $i_price\n";
					print "### Local sizes: ".join(" ",keys(%{$sizes}))."\n";
					my ($shop_name) = 'sportsdirect';
					if ( index($i_link, $shop_name) != -1 ) {
						print "## checking $shop_name\n";
						my ($e_msg, $rst_published, $rst_price, $rst_tsizes, $rst_sizes) = sportdirect::update_product($i_name, $i_link, $i_published, $i_price, $sizes);
						$e_message .= "$e_msg\n";
						$e_result .= 	'"'.$i_id.'",'.
										'"'.$i_name.'",'.
										'"'.$rst_price.'",'.
										'"'.$rst_tsizes.'",'.
										'"'.$rst_sizes.'",'.
										'"'.$rst_published.'"'."\n";
					}
					else {
						# my ($shop_name) = 'lovell-rugby';
						# print "## checking $shop_name\n";
						# if ( index($i_link, $shop_name) != -1 ) {
						# 	$e_msg = lovellrugby::update_product($i_name, $i_link, $cookies->{$shop_name}, $i_published, $i_price, $sizes);
						# }
					}
				}
			}
		}
	}
	$csv->eof or $csv->error_diag();
	close $fh;

	print "###########################################################\n\n";
	print "$e_message\n";
	
	#create stock report
	if ( defined $e_result and ($e_result ne '') ) {
		# delete old update file
		print "## delete old file\n";
		my ($rm_log) = common::rm_file($CONSTANT::UPDATE_FILE);
		unless (defined $rm_log) {
			print "## ERROR: deleting $CONSTANT::UPDATE_FILE\n";
		}
		# create update file
		print "## printing file\n";
		common::print_file($e_result,$CONSTANT::UPDATE_FILE);

		# send email
		print "## sending file\n";
		if ( -e $CONSTANT::UPDATE_FILE and (-s $CONSTANT::UPDATE_FILE > 0) ) {
			common::send_email($e_message,$CONSTANT::UPDATE_FILE);
		}
	}

	exit 0;
}

main();


__END__

=head1 NAME

check_stock

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
