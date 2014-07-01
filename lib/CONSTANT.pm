package CONSTANT;

use strict;
use warnings;

use vars qw(
	$TMP_DIR
	$PRODUCT_IMG_DIR
	
	$UPDATE_FILE
	$IMPORT_EXT_FILE
	
	$EMAILS_FROM
	$EMAILS_TO
	$EMAILS_CC
	$EMAILS_SUBJECT
	$GD_FILE
	$LANGUAGES
	$SHOPS
	$SHOP_COOKIES
	
	$SIZE_TITLE
	$CONV_SPORTDIRECT_SIZES
	$CONV_CATEGORY_IDS
	$PROD_AVAILABILITY
);

$TMP_DIR			= '/kunden/homepages/24/d406245370/htdocs/tmp/external_stock';
#$TMP_DIR			= '/Users/jmrodriguez/tmp';
$PRODUCT_IMG_DIR 	= '/kunden/homepages/24/d406245370/htdocs/tmp/external_stock';
#$PRODUCT_IMG_DIR 	= '/Users/jmrodriguez/tmp';
#$PRODUCT_IMG_DIR 	= '/kunden/homepages/24/d406245370/htdocs/images/stories/virtuemart/product';

$UPDATE_FILE		= $TMP_DIR.'/UpdateExternalStock.csv';
$IMPORT_EXT_FILE	= $TMP_DIR.'/ImportExternalStock__LANG__.csv';

$EMAILS_FROM		= 'admin@thinkingrugby.com';
$EMAILS_TO			= 'thinkingrugby@gmail.com';
$EMAILS_CC			= 'josemrc@gmail.com';
$EMAILS_SUBJECT		= '[InSiS Checking Stock]';
$GD_FILE			= 'https://docs.google.com/uc?id=0Bw3YSiAszMkTaGpza1VLVEQzUzA&export=download';

$LANGUAGES			= ['en','es','pt'];

$SHOPS 				= {
	'sportsdirect' => {
		'link'	=> 'http://www.sportsdirect.com/'
	},
	'lovell-rugby' => {
		'link'	=> 'http://www.lovell-rugby.co.uk',
	}
};
$SHOP_COOKIES 		= {
	'sportsdirect' => $TMP_DIR.'/cookies_sportsdirect.txt',
	'lovell-rugby' => $TMP_DIR.'/cookies_lovell-rugby.txt',
};


$SIZE_TITLE = 'Tallas / Sizes';
$CONV_SPORTDIRECT_SIZES = {
	'junior'	=> 'XS',
	'extrasml'	=> 'XS',
	'small'		=> 'S',
	'medium'	=> 'M',
	'large'		=> 'L',
	'extralge'	=> 'XL',
	'xxlarge'	=> '2XL',
	'xxxlarge'	=> '3XL',
	'xxxxlarge'	=> '4XL',	
	'sml/med'	=> 'S/M',
	'lge/xlge'	=> 'L/XL'	
};

$CONV_CATEGORY_IDS = {
	
};

$PROD_AVAILABILITY = '14d.gif';




1;