package lovellrugby;

use strict;
use warnings;
use XML::LibXML;
use FindBin;
use lib "$FindBin::Bin";
use common;

#####################
# Method prototypes #
#####################
sub update_product($$$$$$);


#################
# Method bodies #
#################

sub update_product($$$$$$)
{
	my ($name, $link, $cookies, $i_published, $i_price, $i_sizes) = @_;
	my ($change) = '';
	
	my ($prefix) = 'update_product';
	my ($n) = $link;
	$n = $1 if ( $link =~ /\/([^\/]*)$/m );
	my ($output) = $CONSTANT::TMP_DIR."/".$prefix.'.'.$n."_".common::local_time;

	my ($cmd) = "wget --load-cookies $cookies -O $output -U \"Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16\" $link &> /dev/null";
	#my ($cmd) = "wget -O $output -U \"Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16\" $link &> /dev/null";

	eval {
		system($cmd);
	};
	if ($@) {
		$change = "Error getting $link";
		return $change;
	}
	else {

		my ($o_sizes);
		my ($o_price);
		my ($content) = common::open_file($output);

		if ( defined $content and ($content ne '') ) {
			my ($parser) = XML::LibXML->new( recover => 2 );
			my ($doc) = $parser->load_html( location => $output );

			# get sizes of website
			for my $node ($doc->findnodes('//a[@class="orderButton"]')) {
				my ($text) = $node->textContent();
				if ( $text ne 'Please Select') {
					$text =~ s/\s*//g; $text = lc($text);
					$o_sizes->{$text} = 1;
				}
			}
			# get price of website
			for my $node ($doc->findnodes('//p[@class="priceinfo"][1]')) {
				my ($o_price_cont) = $node->textContent();
				if ( $o_price_cont =~ /(\d{1,2}[\.|\,]\d{1,2})/ ) {
					$o_price = $1; $o_price =~ s/\s//g; $o_price =~ s/\,/./;
				}
			}
			if ( defined $o_price ) {
				print "In Price: $i_price\n";
				print "Web Price: $o_price\n";
				my ($c1) = '';
				$i_price = sprintf('%.2f',$i_price);
				$o_price = sprintf('%.2f',$o_price);
				if ( $i_price ne $o_price ) {
						$c1 .= "CHANGED the PRICE from $i_price to $o_price ";
				}
				$change .= "$c1\n" if ($c1 ne '');
			}
			else {
				$change .= "We have not found the price\n";
			}
			if ( defined $o_sizes ) {
				print "In Sizes: ".join(" ",keys(%{$i_sizes}))."\n";
				print "Web Sizes: ".join(" ",keys(%{$o_sizes}))."\n";
				my ($c2) = '';
				foreach my $s (keys(%{$i_sizes})) {
					unless ( exists $o_sizes->{$s} ) {
						$c2 .= "OUT of STOCK the following SIZES: " if ($c2 eq '');
						$c2 .= "$s ";
					}
				}
				my ($c3) = '';
				foreach my $s (keys(%{$o_sizes})) {
					unless ( exists $i_sizes->{$s} ) {
						$c3 .= "NEW following SIZES: " if ($c3 eq '');
						$c3 .= "$s ";
					}
				}
				$change .= "$c2\n" if ($c2 ne '');
				$change .= "$c3\n" if ($c3 ne '');				
			}
			else {
				$change .= "We have not found the sizes.\n";
			}
		}
	}
	my ($rm_log) = common::rm_file($output);
	unless (defined $rm_log) {
		$change .= "Error deleting FILE: $output ";
	}
	return $change;
}

1;