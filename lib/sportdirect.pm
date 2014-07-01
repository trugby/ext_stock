package sportdirect;
 
use strict;
use warnings;
use XML::LibXML;
use FindBin;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use common;

###################
# Global variable #
###################
use CONSTANT qw(
	$SHOP_COOKIES
	$TMP_DIR
	$PRODUCT_IMG_DIR
	$PROD_AVAILABILITY
);
my ($COOKIES) = $CONSTANT::SHOP_COOKIES->{'sportsdirect'};

#####################
# Method prototypes #
#####################
sub www_get($$);
sub update_product($$$$$);
sub down_product($);
sub down_prod_wscan($\$);
sub down_prod_img($);
sub print_down_prod($);
sub print_down_result($$);


#################
# Method bodies #
#################

sub www_get($$)
{
	my ($input, $output) = @_;
	
	my ($cmd) = "wget --header \"Cookie: SportsDirect_AnonymousUserCurrency=EUR\" --load-cookies $COOKIES -O '$output' -U \"Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16\" $input &> /dev/null";
	#my ($cmd) = "wget --header \"Cookie: SportsDirect_AnonymousUserCurrency=EUR\" -O $output -U \"Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16\" $input &> /dev/null";

	eval {
		system($cmd);
	};
	if ($@) {
		return undef;
	}
	return $output;
}

sub update_product($$$$$)
{
	my ($name, $link, $i_published, $i_price, $i_sizes) = @_;
	my ($report, $rst_published, $rst_price, $rst_tsizes, $rst_sizes) = ("# $name\n",$i_published,$i_price,'','');
	my ($o_sizes);
	my ($o_price);
		
	# get www content
	my ($n) = $link; if ( $link =~ /\/([^\/]*)$/m ) { $n = $1 };	
	my ($output) = $CONSTANT::TMP_DIR."/".'update_product.'.$n."_".common::local_time;
	common::prepare_wspace($CONSTANT::TMP_DIR);	
	$output = www_get($link, $output);
	unless (defined $output ) {
		$report = "Error getting $link";
		return $report;		
	}
	
	# open file
	my ($content) = common::open_file($output);
	if ( defined $content and ($content ne '') ) {
		my ($parser) = XML::LibXML->new( recover => 2 );
		my ($doc) = $parser->load_html( location => $output );

		# get sizes of website
		for my $node ($doc->findnodes('//select[@id="sizeDdl"]')) {
			for my $node2 ($node->findnodes('option[@value]')) {
				unless ( $node2->hasAttribute('selected') ) {
					#my ($text) = $node2->textContent();
					my ($text) = $node2->getAttribute('value');
					$text =~ s/\s*//g; $text = lc($text);
					my ($conv_txt) = $CONSTANT::CONV_SPORTDIRECT_SIZES->{$text};
					$o_sizes->{$conv_txt} = 1;
				}
			}
		}
		# get price of website
		for my $node ($doc->findnodes('//span[@id="lblSellingPrice"]')) {
			my ($o_price_cont) = $node->textContent();
			if ( $o_price_cont =~ /(\d{1,2},\d{1,2})/ ) {
				$o_price = $1; $o_price =~ s/\s//g; $o_price =~ s/\,/./;
			}
		}

		# compare the local values with the external values
		if ( defined $o_price ) {
			print "### External price: $o_price\n";
			my ($c1) = '';
			# turn all commas into dots
			#$i_price = sprintf('%.2f',$i_price);
			#$i_price =~ tr[,][.]d;
			$i_price =~ s/\,/./;
			$o_price = sprintf('%.2f',$o_price);
			if ( $i_price < $o_price ) {
					$c1 .= "## Local prices is smaller than external price.\n\t=> We will change the price from $i_price (local) to $o_price (external)";
					$rst_price = $o_price;
			}
			elsif ( $i_price > $o_price ) {
					$c1 .= "## Local prices is bigger than external price: $i_price (local) to $o_price (external).\n\t=> We will not modify the local price";
			}
			$report .= "$c1\n" if ($c1 ne '');
		}
		else {
			$report .= "## We have not found the price.\n\t=> Product is unpublished\n";
			$rst_published  = '0';
		}
		if ( defined $o_sizes ) {
			print "### External sizes: ".join(" ",keys(%{$o_sizes}))."\n";
			my ($c2) = '';
			foreach my $s (keys(%{$i_sizes})) {
				unless ( exists $o_sizes->{$s} ) {
					$c2 .= "## Out of stock the following sizes: " if ($c2 eq '');		
					$c2 .= "$s ";
				}
				else {
					$rst_sizes .= $s.'~';
					$rst_tsizes .= $CONSTANT::SIZE_TITLE.'~';
				}
			}
			my ($c3) = '';
			foreach my $s (keys(%{$o_sizes})) {
				unless ( exists $i_sizes->{$s} ) {
					$c3 .= "## New sizes: " if ($c3 eq '');
					$c3 .= "$s ";
					$rst_sizes .= $s.'~';
					$rst_tsizes .= $CONSTANT::SIZE_TITLE.'~';
				}
			}
			$report .= "$c2\n" if ($c2 ne '');
			$report .= "$c3\n" if ($c3 ne '');				
		}
		else {
			$report .= "## We have not found the sizes.\n\t=> Product is unpublished\n";
			$rst_published = '0';				
		}
	}
	else {
		$report .= "## We have not found the product.\n\t=> Product is unpublished\n";
		$rst_published = '0';
	}
	
	# delete downloaded file
	#my ($rm_log) = common::rm_file($output);
	#unless (defined $rm_log) {
	#	$report .= "Error deleting FILE: $output ";
	#}
	$rst_tsizes =~ s/\~$//g;
	$rst_sizes =~ s/\~$//g;
	return ($report, $rst_published, $rst_price, $rst_tsizes, $rst_sizes);
}

sub down_product($)
{
	my ($i_prod) = @_;
	my ($results);
	my ($logger) = {
		'error'		=> 0,
		'warning'	=> 0,
		'log'		=> '',
	};
	
	# get www content by language
	while (my ($lang, $link) = each(%{$i_prod->{'lang'}}) ) {
		
		my ($o_report);
		my ($sku) = $i_prod->{'sku'};
		my ($category_id) = $i_prod->{'category_id'};
		my ($manufacturer_id) = $i_prod->{'manufacturer_id'};	
		my ($n) = $link; if ( $link =~ /\/([^\/]*)$/m ) { $n = $1 };
		common::prepare_wspace($CONSTANT::TMP_DIR);
		my ($output) = $CONSTANT::TMP_DIR."/".'down_product_'.$lang.$n."_".common::local_time;
		$output = www_get($link, $output);
		unless (defined $output ) {
			$logger->{'error'} 	= 1;
			$logger->{'log'}	= "Error getting $link";
			return $logger;
		}
		else {
			# build input report
			my ($i_report) = {
				'link'	=> $link,
				'www'	=> $output,
			};
			$o_report->{'link'} = $link;
			$o_report->{'lang'} = $lang;
			$o_report->{'sku'} = $sku;
			$o_report->{'category_id'} = $category_id;
			$o_report->{'manufacturer_id'} = $manufacturer_id;
			
			# web scan
			$logger = down_prod_wscan($i_report,$o_report);

			# download images
			if ( exists $o_report->{'images'} and ($lang eq 'en') ) {
				$logger = down_prod_img($o_report);
			}
			
			# create report rst
			if ( $logger->{'error'} == 0 ) {
				my ($txt) = print_down_prod($o_report);
				if ( defined $txt ) {
					$results->{$lang} = $txt;
				}
				else {
					$logger->{'error'} 	= 1;
					$logger->{'log'}	= "Error printing $link";
					return $logger;
				}
			}
			
			# delete downloaded file
			#my ($rm_log) = common::rm_file($output);
			#unless (defined $rm_log) {
			#	$logger->{'error'} 	= 1;
			#	$logger->{'log'}	= "Error deleting $link";
			#	return $logger;
			#}
		}
	}
		
	return ($logger,$results);
	
} # end down_product

sub down_prod_wscan($\$)
{
	my ($i_report, $o_report) = @_;
	my ($logger) = {
		'error'		=> 0,
		'warning'	=> 0,
		'log'		=> '',
	};
	${$o_report}->{'published'} = '0';
	
	# open file
	my ($content) = common::open_file($i_report->{'www'});
	if ( defined $content and ($content ne '') ) {
		my ($parser) = XML::LibXML->new( recover => 2 );
		my ($doc) = $parser->load_html( location => $i_report->{'www'} );

		# get product name
		my ($o_name) = '';
		for my $node ($doc->findnodes('//span[@id="ProductName"]')) {
			#$o_name = $node->toString(2, 'UTF-8');
			$o_name = $node->textContent();
		}
		if ( defined $o_name and ($o_name ne '') ) {
			${$o_report}->{'name'} = $o_name;
		}
		else {
			$logger->{'error'} 	= 1;
			$logger->{'log'}	= "We don't find the product name";
			return $logger;
		}		

		# get description of product and manufacter
		my ($num_br) = 0; # if there are too many breaklines, we think stop
		my ($o_s_desc) = '';
		my ($o_desc) = '';
		my ($o_manu) = '';
		for my $node ($doc->findnodes('//div[@class="infoTabPage"]/span[@itemprop="description"]')) {
			for my $node2 ($node->childNodes()) {
				if ( $node2->nodeName eq 'a' ) {
					$o_manu .= $node2->textContent();
				}
				elsif ( ($node2->nodeName ne 'a') && ($num_br < 2) ) {
					my ($txt) = $node2->toString(2, 'UTF-8');
					$o_desc .= $txt;
					if ( $node2->nodeName eq 'br' && ($num_br >= 0) ) {
						$num_br++;
					}
					else {
						$num_br = 0;
					}
				}
			}
		}
		if ( defined $o_desc and ($o_desc ne '') ) {
			${$o_report}->{'description'} = $o_desc;
			if ( defined $o_s_desc and ($o_s_desc ne '') ) {
				${$o_report}->{'s_desc'} = $o_s_desc;
			}
			
		}
		else {
			$logger->{'error'} 	= 1;
			$logger->{'log'}	= "We don't find the product description";
			return $logger;
		}		
		if ( defined $o_manu and ($o_manu ne '') ) {		
			${$o_report}->{'manufacter'} = $o_manu;
		}
		else {
			$logger->{'warning'} = 1;
			$logger->{'log'}	.= "We don't find the manufacter\n";
		}		
		
		# get sizes of website
		my ($o_sizes);		
		for my $node ($doc->findnodes('//select[@id="sizeDdl"]')) {
			for my $node2 ($node->findnodes('option[@value]')) {
				unless ( $node2->hasAttribute('selected') ) {
					my ($text) = $node2->getAttribute('value');
					$text =~ s/\s*//g; $text = lc($text);
					if ( exists $CONSTANT::CONV_SPORTDIRECT_SIZES->{$text} ) {
						my ($conv_txt) = $CONSTANT::CONV_SPORTDIRECT_SIZES->{$text};
						#$o_sizes->{$conv_txt} = 1;
						push(@{$o_sizes},$conv_txt);
					}
					else {
						$logger->{'warning'} = 1;
						$logger->{'log'}	.= "We don't find the size: $text\n";
					}
				}
			}
		}
		${$o_report}->{'sizes'} = $o_sizes;
		
		# get price of website
		my ($o_price) = '';		
		for my $node ($doc->findnodes('//span[@id="lblSellingPrice"]')) {
			my ($o_price_cont) = $node->textContent();
			if ( $o_price_cont =~ /(\d{1,2},\d{1,2})/ ) {
				$o_price = $1; $o_price =~ s/\s//g; $o_price =~ s/\,/./;
			}
		}
		if ( defined $o_price and ($o_price ne '') ) {
			${$o_report}->{'price'} = $o_price;
		}
		else {
			$logger->{'error'} 	= 1;
			$logger->{'log'}	= "We don't find the product price";
			return $logger;
		}			
		
		# download images
		my ($o_images);		
		for my $node ($doc->findnodes('//ul[@id="piThumbList"]/li/a')) {
			my ($img_l) = $node->getAttribute('href');
			my ($img_xxl) = $node->getAttribute('srczoom');
			if ( defined $img_l and $img_xxl ) {
				my ($o_img) = {
					'l'		=> $img_l,
					'xxl'	=> $img_xxl
				};
				push(@{$o_images},$o_img);				
			}
		}
		if ( defined $o_images ) {
			${$o_report}->{'images'} = $o_images;
		}
		else {
			$logger->{'warning'} = 1;
			$logger->{'log'}	.= "We don't find the images\n";
		}
	}
	else {
		$logger->{'warning'} = 1;
		$logger->{'log'}	.= "## We have not found the product.\n\t=> Product is unpublished\n";
		${$o_report}->{'published'} = '0';
	}
	return $logger;
	
} # end down_prod_wscan

sub down_prod_img($)
{
	my ($o_report) = @_;
	my ($logger);
		
	if ( exists $o_report->{'images'} ) {		
		foreach my $images (@{$o_report->{'images'}}) {
			foreach my $ty ('l','xxl') {				
				if ( exists $images->{$ty} ) {					
					my ($link) = $images->{$ty};
					my ($n) = $link; if ( $link =~ /\/([^\/]*)$/m ) { $n = $1 };
					my ($output) = $CONSTANT::PRODUCT_IMG_DIR."/".$n;
					$output = www_get($link, $output);
					unless (defined $output ) {

					}
				}					
			}				
		}
	}
	return $logger;
	
} # end down_prod_img

sub print_down_prod($)
{
	my ($o_report) = @_;
	my ($published) = '0';
	my ($sku) = '';
	my ($name) = '';
	my ($s_desc) = '';
	my ($desc) = '';
	my ($manufacter) = '';
	my ($price) = '';
	my ($categories) = '';
	my ($availability) = '';
	my ($cust_title) = '';
	my ($cust_val) = '';
	my ($intnotes) = '';
	if ( exists $o_report->{'sku'} and defined $o_report->{'sku'} and ($o_report->{'sku'} ne '') ) {
		$sku = $o_report->{'sku'};
	}
	if ( exists $o_report->{'name'} and defined $o_report->{'name'} and ($o_report->{'name'} ne '') ) {
		$name = $o_report->{'name'};
	}
	if ( exists $o_report->{'s_desc'} and defined $o_report->{'s_desc'} and ($o_report->{'s_desc'} ne '') ) {
		$s_desc = $o_report->{'s_desc'};
		$s_desc =~ s/"/'/g;
	}
	if ( exists $o_report->{'description'} and defined $o_report->{'description'} and ($o_report->{'description'} ne '') ) {
		$desc = $o_report->{'description'};
		$desc =~ s/"/'/g;
	}
	#if ( exists $o_report->{'manufacter'} and defined $o_report->{'manufacter'} and ($o_report->{'manufacter'} ne '') ) {
	#	$manufacter = $o_report->{'manufacter'};
	#}
	if ( exists $o_report->{'manufacturer_id'} and defined $o_report->{'manufacturer_id'} and ($o_report->{'manufacturer_id'} ne '') ) {
		$manufacter = $o_report->{'manufacturer_id'};
	}
	if ( exists $o_report->{'price'} and defined $o_report->{'price'} and ($o_report->{'price'} ne '') ) {
		$price = $o_report->{'price'};
	}
	if ( exists $o_report->{'category_id'} and defined $o_report->{'category_id'} and ($o_report->{'category_id'} ne '') ) {
		$categories = $o_report->{'category_id'};
	}
	if ( defined $CONSTANT::PROD_AVAILABILITY ) {
		$availability = $CONSTANT::PROD_AVAILABILITY;
	}
	if ( exists $o_report->{'sizes'} and defined $o_report->{'sizes'} and (scalar(@{$o_report->{'sizes'}}) > 0) ) {		
		foreach my $sizes (@{$o_report->{'sizes'}}) {
			if ( defined $sizes and ($sizes ne '') ) {
				$cust_title .= $CONSTANT::SIZE_TITLE.'~';
				$cust_val .= $sizes.'~';				
			}
		}
		$cust_title =~ s/\~$//g;
		$cust_val =~ s/\~$//g;
	}
	if ( exists $o_report->{'link'} and defined $o_report->{'link'} and ($o_report->{'link'} ne '') ) {
		$intnotes = $o_report->{'link'};
	}	
	
	my ($result) = 	'"'.$published.'",'.
					'"'.$sku.'",'.
					'"'.$name.'",'.
					'"'.$s_desc.'",'.
					'"'.$desc.'",'.
					'"'.$manufacter.'",'.
					'"'.$price.'",'.
					'"'.$categories.'",'.
					'"'.$availability.'",'.
					'"'.$cust_title.'",'.
					'"'.$cust_val.'",'.
					'"'.$intnotes.'"'."\n";
	return $result;
	
} # end print_down_prod

sub print_down_result($$)
{
	my ($results, $corefile) = @_;
	
	while (my ($lang, $result_txt) = each(%{$results}) ) {
		my ($langfile) = $corefile;
		my ($lan) = uc($lang);
		$langfile =~ s/__LANG__/_$lan/;
		common::print_file($result_txt, $langfile);
	}
	
} # end print_down_result

1;
