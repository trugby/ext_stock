package sportdirect;
 
use strict;
use warnings;
use XML::LibXML;
use FindBin;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use CONSTANT;
use common;

###################
# Global variable #
###################
my ($COOKIES)				= $CONSTANT::SHOP_COOKIES->{'sportsdirect'};
my ($TMP_DIR)				= $CONSTANT::SHOP_TMP_DIR->{'sportsdirect'};
my ($PRODUCT_IMG_DIR)		= $CONSTANT::SHOP_PROD_IMG_DIR->{'sportsdirect'};
my ($SHOP_PROD_IMG_PATH)	= $CONSTANT::SHOP_PROD_IMG_PATH->{'sportsdirect'};
my ($CONV_SIZES)			= $CONSTANT::SHOP_CONV_SIZES->{'sportsdirect'};
my ($SIZE_TITLE)			= $CONSTANT::SIZE_TITLE;
my ($PROD_AVAIL)			= $CONSTANT::PROD_AVAILABILITY;
my ($MAIN_LANG)				= $CONSTANT::MAIN_LANG;


#####################
# Method prototypes #
#####################
sub www_get($$);
sub update_product($);
sub update_prod_wscan($\$);
sub down_product($);
sub down_prod_wscan($\$);
sub down_prod_img(\$);
sub print_update_prod($$$);
sub print_down_prod($$);
sub print_prod_result($$);


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
		my ($output) = $TMP_DIR."/".'down_product_'.$lang.$n."_".common::local_time;
		$output = www_get($link, $output);
		unless (defined $output ) {
			$logger->{'error'} 	= 1;
			$logger->{'log'}	= "Getting $link\n";
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
			if ( exists $o_report->{'link_img'} and ($lang eq $MAIN_LANG) ) {
				$logger = down_prod_img($o_report);
			}
			
			# create report rst
			if ( $logger->{'error'} == 0 ) {
				my ($txt) = print_down_prod($lang, $o_report);
				if ( defined $txt ) {
					$results->{$lang} = $txt;
				}
				else {
					$logger->{'error'} 	= 1;
					$logger->{'log'}	= "Printing product\n";
					return $logger;
				}
			}
			
			# delete downloaded file
			my ($rm_log) = common::rm_file($output);
			unless (defined $rm_log) {
				$logger->{'error'} 	= 1;
				$logger->{'log'}	= "Deleting $link\n";
				return $logger;
			}
		}
	}
		
	return ($logger,$results);
	
} # end down_product

sub update_product($)
{
	my ($i_prod) = @_;
	my ($results);
	my ($logger) = {
		'error'		=> 0,
		'warning'	=> 0,
		'log'		=> '',
	};
	
	my ($o_report);
	my ($id) = $i_prod->{'id'};
	my ($link) = $i_prod->{'link'};
	my ($lang) = $MAIN_LANG;
	my ($n) = $link; if ( $link =~ /\/([^\/]*)$/m ) { $n = $1 };
	my ($output) = $TMP_DIR."/".'down_product_'.$lang.$n."_".common::local_time;
	$output = www_get($link, $output);
	unless (defined $output ) {
		$logger->{'error'} 	= 1;
		$logger->{'log'}	= "Getting $link\n";
		return $logger;
	}
	else {
		# build input report
		my ($i_report) = {
			'link'	=> $link,
			'www'	=> $output,
		};
		$i_report->{'price'} = $i_prod->{'price'};
		$i_report->{'sizes'} = $i_prod->{'sizes'};
		$o_report->{'id'} = $id;
		$o_report->{'link'} = $link;
		$o_report->{'lang'} = $lang;
					
		# web scan
		$logger = update_prod_wscan($i_report,$o_report);
		
		# create report rst
		if ( $logger->{'error'} == 0 ) {
			my ($txt) = print_update_prod($lang, $i_report, $o_report);
			if ( defined $txt ) {
				$results->{$lang} = $txt;
			}
			else {
				$logger->{'error'} 	= 1;
				$logger->{'log'}	= "Printing product\n";
				return $logger;
			}
		}
			
		# delete downloaded file
		my ($rm_log) = common::rm_file($output);
		unless (defined $rm_log) {
			$logger->{'error'} 	= 1;
			$logger->{'log'}	= "Deleting $link\n";
			return $logger;
		}
	}
		
	return ($logger,$results);
	
} # end update_product


#----------------#
# PARSER METHODS #
#----------------#


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
			$logger->{'log'}	= "We don't find the product name\n";
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
			$logger->{'log'}	= "We don't find the product description\n";
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
				if ( !$node2->hasAttribute('class') and $node2->hasAttribute('value') and (defined $node2->getAttribute('value')) and ($node2->getAttribute('value') ne '') ) {
					my ($text) = $node2->getAttribute('value');
					$text =~ s/\s*//g; $text = lc($text);
					if ( exists $CONV_SIZES->{$text} ) {
						my ($conv_txt) = $CONV_SIZES->{$text};
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
			$logger->{'log'}	= "We don't find the product price\n";
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
			${$o_report}->{'link_img'} = $o_images;
		}
		else {
			$logger->{'warning'} = 1;
			$logger->{'log'}	.= "We don't find the images\n";
		}
	}
	else {
		$logger->{'warning'} = 1;
		$logger->{'log'}	.= "## We have not found the product => Product is unpublished\n";
		${$o_report}->{'published'} = '0';
	}
	return $logger;
	
} # end down_prod_wscan

sub down_prod_img(\$)
{
	my ($o_report) = @_;
	my ($logger) = {
		'error'		=> 0,
		'warning'	=> 0,
		'log'		=> '',
	};	
	if ( exists ${$o_report}->{'link_img'} ) {
		foreach my $images (@{${$o_report}->{'link_img'}}) {
			my ($rep);
			foreach my $ty ('l','xxl') {				
				if ( exists $images->{$ty} ) {					
					my ($link) = $images->{$ty};
					my ($n) = $link; if ( $link =~ /\/([^\/]*)$/m ) { $n = $1 };
					my ($output) = $PRODUCT_IMG_DIR."/".$n;
					$output = www_get($link, $output);
					if (defined $output ) {
						$rep->{$ty} = $n;
					}
				}
			}
			if ( defined $rep ) {
				push(@{${$o_report}->{'images'}}, $rep);	
			}
		}
	}
	return $logger;
	
} # end down_prod_img

sub update_prod_wscan($\$)
{
	my ($i_report, $o_report) = @_;
	my ($logger) = {
		'error'		=> 0,
		'warning'	=> 0,
		'log'		=> '',
	};
	${$o_report}->{'published'} = '1';
	
	# open file
	my ($content) = common::open_file($i_report->{'www'});
	if ( defined $content and ($content ne '') ) {
		my ($parser) = XML::LibXML->new( recover => 2 );
		my ($doc) = $parser->load_html( location => $i_report->{'www'} );
		
		# get sizes of website
		my ($o_sizes);
		for my $node ($doc->findnodes('//select[@id="sizeDdl"]')) {
			for my $node2 ($node->findnodes('option[@value]')) {
				my ($text) = $node2->getAttribute('value');
				if ( !$node2->hasAttribute('class') and $node2->hasAttribute('value') and (defined $node2->getAttribute('value')) and ($node2->getAttribute('value') ne '') ) {
					my ($text) = $node2->getAttribute('value');
					$text =~ s/\s*//g; $text = lc($text);
					if ( exists $CONV_SIZES->{$text} ) {
						my ($conv_txt) = $CONV_SIZES->{$text};
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
			$logger->{'warning'} = 1;
			$logger->{'log'}	.= "We have not found the price => Product is unpublished\n";
			${$o_report}->{'published'} = '0';
		}
		
		# compare the local values with the external values
		if ( defined $o_price and ($o_price ne '') ) {
			my ($i_price) = $i_report->{'price'};
			# turn all commas into dots
			#$i_price = sprintf('%.2f',$i_price);
			#$i_price =~ tr[,][.]d;
			$i_price =~ s/\,/./;
			$o_price = sprintf('%.2f',$o_price);
			if ( $i_price < $o_price ) {
					$logger->{'warning'} = 1;
					$logger->{'log'}	.= "Local prices is smaller than external price => We will change the price from $i_price (local) to $o_price (external)\n";
			}
			elsif ( $i_price > $o_price ) {
					$logger->{'warning'} = 0;
					#$logger->{'log'}	.= "Local prices is bigger than external price: $i_price (local) to $o_price (external) => We will not modify the local price\n";
					${$o_report}->{'price'} = $i_price;
			}
		}
		if ( defined $o_sizes and (scalar(@{$o_sizes}) > 0) ) {
			my ($log_cont) = '';
			my ($log_cont2) = '';
			my (%o_map_sizes) = map { $_ => 1 } @{$o_sizes};
			my (%i_map_sizes) = map { $_ => 1 } @{$i_report->{'sizes'}};			
			foreach my $s (@{$i_report->{'sizes'}}) {
				unless ( exists $o_map_sizes{$s} ) {
					$log_cont .= "Out of stock the following sizes: " if ($log_cont eq '');		
					$log_cont .= "$s ";
				}
			}
			foreach my $s (@{$o_sizes}) {
				unless ( exists $i_map_sizes{$s} ) {
					$log_cont2 .= "New sizes: " if ($log_cont2 eq '');
					$log_cont2 .= "$s ";
				}
			}
			if ( $log_cont ne '' ) {
				$logger->{'warning'} = 1;
				$logger->{'log'}	.= "$log_cont\n";				
			}
			if ( $log_cont2 ne '' ) {
				$logger->{'warning'} = 1;
				$logger->{'log'}	.= "$log_cont2\n";
			}					
		}
		else {
			$logger->{'warning'} = 1;
			$logger->{'log'}	.= "We have not found any size => Product is unpublished\n";
			${$o_report}->{'published'} = '0';
		}
	}
	else {
		$logger->{'warning'} = 1;
		$logger->{'log'}	.= "We have not found the product => Product is unpublished\n";
		${$o_report}->{'published'} = '0';
	}
	return $logger;
	
} # end update_prod_wscan

#---------------#
# PRINT METHODS #
#---------------#

sub print_down_prod($$)
{
	my ($lang, $o_report) = @_;
	my ($published) = '0';
	my ($sku) = '';
	my ($name) = '';
	my ($slug) = '';
	my ($s_desc) = '';
	my ($desc) = '';
	my ($manufacter) = '';
	my ($price) = '';
	my ($categories) = '';
	my ($availability) = '';
	my ($cust_title) = '';
	my ($cust_val) = '';
	my ($cust_order) = '';
	my ($img_names) = '';
	my ($img_paths) = '';
	my ($img_order) = '';
	my ($intnotes) = '';
	
	if ( exists $o_report->{'sku'} and defined $o_report->{'sku'} and ($o_report->{'sku'} ne '') ) {
		$sku = $o_report->{'sku'};
	}
	else { return undef } # required field
	
	if ( exists $o_report->{'name'} and defined $o_report->{'name'} and ($o_report->{'name'} ne '') ) {
		$name = $o_report->{'name'};
	}
	else { return undef } # required field
	
	if ( ($sku ne '') and ($name ne '') ) {
		$slug = lc($name); $slug =~ s/\s+/\-/g;
		if ( $sku =~ /\/([\d|\w]*)$/ ) {
			$slug .= "-".$1;
		}
		else { return undef } # required field
	}
	else { return undef } # required field

	if ( exists $o_report->{'s_desc'} and defined $o_report->{'s_desc'} and ($o_report->{'s_desc'} ne '') ) {
		$s_desc = $o_report->{'s_desc'};
		$s_desc =~ s/"/'/g;
	}
	
	if ( exists $o_report->{'description'} and defined $o_report->{'description'} and ($o_report->{'description'} ne '') ) {
		$desc = $o_report->{'description'};
		$desc =~ s/"/'/g;
	}
			
	if ( $lang eq $MAIN_LANG ) {

		#if ( exists $o_report->{'manufacter'} and defined $o_report->{'manufacter'} and ($o_report->{'manufacter'} ne '') ) {
		#	$manufacter = $o_report->{'manufacter'};
		#}
		if ( exists $o_report->{'manufacturer_id'} and defined $o_report->{'manufacturer_id'} and ($o_report->{'manufacturer_id'} ne '') ) {
			$manufacter = $o_report->{'manufacturer_id'};
		}
		
		if ( exists $o_report->{'price'} and defined $o_report->{'price'} and ($o_report->{'price'} ne '') ) {
			$price = $o_report->{'price'};
		}
		else { return undef } # required field
		
		if ( exists $o_report->{'category_id'} and defined $o_report->{'category_id'} and ($o_report->{'category_id'} ne '') ) {
			$categories = $o_report->{'category_id'};
		}
		#else { return undef } # required field
		
		if ( defined $PROD_AVAIL ) {
			$availability = $PROD_AVAIL;
		}		
		
		if ( exists $o_report->{'sizes'} and defined $o_report->{'sizes'} and (scalar(@{$o_report->{'sizes'}}) > 0) ) {		
			for (my $i = 0; $i < scalar(@{$o_report->{'sizes'}}); $i++) {
				my ($sizes) = $o_report->{'sizes'}->[$i];
				if ( defined $sizes and ($sizes ne '') ) {
					$cust_title .= $SIZE_TITLE.'~';
					$cust_val .= $sizes.'~';
					my ($num) = $i+1;
					$cust_order .= $num.'~';
				}
			}
			$cust_title =~ s/\~$//g;
			$cust_val =~ s/\~$//g;
			$cust_order =~ s/\~$//g;
		}
		else { return undef } # required field

		if ( exists $o_report->{'images'} and defined $o_report->{'images'} and (scalar(@{$o_report->{'images'}}) > 0) ) {		
			#foreach my $images (@{$o_report->{'images'}}) {
			for (my $i = 0; $i < scalar(@{$o_report->{'images'}}); $i++) {
				my ($images) = $o_report->{'images'}->[$i];
				#foreach my $ty ('l','xxl') {
				foreach my $ty ('l') {
					if ( exists $images->{$ty} ) {					
						my ($img) = $images->{$ty};
						if ( defined $img and ($img ne '') ) {
							$img_names .= $name.'|';
							$img_paths .= $SHOP_PROD_IMG_PATH.'/'.$img.'|';
							my ($num) = $i+1;
							$img_order .= $num.'|';
						}			
					}
				}			
			}
			$img_names =~ s/\|$//g;
			$img_paths =~ s/\|$//g;
			$img_order =~ s/\|$//g;
		}
		else { return undef } # required field
			
		if ( exists $o_report->{'link'} and defined $o_report->{'link'} and ($o_report->{'link'} ne '') ) {
			if ( defined $lang and ($lang eq $MAIN_LANG) ) { # only for main lang 'EN'
				$intnotes = $o_report->{'link'};
			}
		}
		else { return undef } # required field
	}
	
	my ($result) = 	'"'.$published.'",'.
					'"'.$sku.'",'.
					'"'.$name.'",'.
					'"'.$slug.'",'.
					'"'.$s_desc.'",'.
					'"'.$desc.'",'.
					'"'.$manufacter.'",'.
					'"'.$price.'",'.
					'"'.$categories.'",'.
					'"'.$availability.'",'.
					'"'.$cust_title.'",'.
					'"'.$cust_val.'",'.
					'"'.$cust_order.'",'.
					'"'.$img_names.'",'.
					'"'.$img_paths.'",'.
					'"'.$img_order.'",'.					
					'"'.$intnotes.'"'."\n";
	return $result;
	
} # end print_down_prod

sub print_update_prod($$$)
{
	my ($lang, $i_report, $o_report) = @_;
	my ($published) = '0';
	my ($id) = '';
	my ($price) = '';
	my ($cust_title) = '';
	my ($cust_val) = '';
	my ($cust_order) = '';
	
	if ( exists $o_report->{'published'} and defined $o_report->{'published'} and ($o_report->{'published'} ne '') ) {
		$published = $o_report->{'published'};
	}
	else { return undef } # required field
	
	if ( exists $o_report->{'id'} and defined $o_report->{'id'} and ($o_report->{'id'} ne '') ) {
		$id = $o_report->{'id'};
	}
	else { return undef } # required field

	if ( $lang eq $MAIN_LANG ) {

		if ( exists $o_report->{'price'} and defined $o_report->{'price'} and ($o_report->{'price'} ne '') ) {
			$price = $o_report->{'price'};
		}
		else { $published = '0' }
		
		if ( exists $o_report->{'sizes'} and defined $o_report->{'sizes'} and (scalar(@{$o_report->{'sizes'}}) > 0) ) {		
			for (my $i = 0; $i < scalar(@{$o_report->{'sizes'}}); $i++) {
				my ($sizes) = $o_report->{'sizes'}->[$i];
				if ( defined $sizes and ($sizes ne '') ) {
					$cust_title .= $SIZE_TITLE.'~';
					$cust_val .= $sizes.'~';
					my ($num) = $i+1;
					$cust_order .= $num.'~';
				}
			}
			$cust_title =~ s/\~$//g;
			$cust_val =~ s/\~$//g;
			$cust_order =~ s/\~$//g;
		}
		else { $published = '0' }
	}
	
	my ($result) = 	'"'.$published.'",'.
					'"'.$id.'",'.
					'"'.$price.'",'.
					'"'.$cust_title.'",'.
					'"'.$cust_val.'",'.
					'"'.$cust_order.'"'."\n";
	return $result;
	
} # end print_update_prod

sub print_prod_result($$)
{
	my ($results, $corefile) = @_;
	my ($files) = '';
	
	while (my ($lang, $result_txt) = each(%{$results}) ) {
		my ($langfile) = $corefile;
		my ($lan) = uc($lang);
		$langfile =~ s/__LANG__/_$lan/;

		my ($rm_log) = common::rm_file($langfile);
		unless (defined $rm_log) {
			print "ERROR!!! Deleting old file: $langfile\n";
		}
		
		common::print_file($result_txt, $langfile);
		$files .= $langfile.';';
	}
	$files =~ s/\;$//g;
	
	return $files
	
} # end print_prod_result

1;
