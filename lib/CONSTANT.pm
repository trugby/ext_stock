package CONSTANT;

use strict;
use warnings;

use vars qw(
	$EMAILS_FROM
	$EMAILS_TO
	$EMAILS_CC
	$EMAILS_SUBJECT
	
	$GD_FILE
	
	$MAIN_LANG
	$LANGUAGES

	$TMP_DIR
	$PRODUCT_IMG_DIR
	$PRODUCT_IMG_PATH
	
	$UPDATE_EXT_FILE
	$IMPORT_EXT_PROD_FILE
	
	$SHOPS
	$SHOP_COOKIES
	$SHOP_TMP_DIR
	$SHOP_PROD_IMG_DIR
	$SHOP_PROD_IMG_PATH
	$SHOP_CONV_SIZES
	
	$SIZE_TITLE
	$CONV_CATEGORY_IDS
	$PROD_AVAILABILITY
);

$EMAILS_FROM		= 'admin@thinkingrugby.com';
$EMAILS_TO			= 'thinkingrugby@gmail.com';
$EMAILS_CC			= 'josemrc@gmail.com';
$EMAILS_SUBJECT		= '[InSiS Checking Stock]';

$GD_FILE			= 'https://docs.google.com/uc?id=0Bw3YSiAszMkTaGpza1VLVEQzUzA&export=download';

$MAIN_LANG			= 'en';
$LANGUAGES			= ['en','es','pt'];

#$TMP_DIR			= '/kunden/homepages/24/d406245370/htdocs/tmp/external_stock';
#$PRODUCT_IMG_DIR 	= '/kunden/homepages/24/d406245370/htdocs/images/stories/virtuemart/product';
$TMP_DIR			= '/Users/jmrodriguez/tmp';
$PRODUCT_IMG_DIR 	= '/Users/jmrodriguez/tmp';
$PRODUCT_IMG_PATH 	= 'images/stories/virtuemart/product';

$UPDATE_EXT_FILE		= $TMP_DIR.'/UpdateExternalStock.csv';
$IMPORT_EXT_PROD_FILE	= $TMP_DIR.'/ImportExternalStock__LANG__.csv';

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
$SHOP_TMP_DIR	= {
	'sportsdirect' => $TMP_DIR.'/sportsdirect',
	'lovell-rugby' => $TMP_DIR.'/lovell-rugby',
};
$SHOP_PROD_IMG_DIR	= {
	'sportsdirect' => $PRODUCT_IMG_DIR.'/sportsdirect',
	'lovell-rugby' => $PRODUCT_IMG_DIR.'/lovell-rugby',
};
$SHOP_PROD_IMG_PATH	= {
	'sportsdirect' => $PRODUCT_IMG_PATH.'/sportsdirect',
	'lovell-rugby' => $PRODUCT_IMG_PATH.'/lovell-rugby',
};
$SHOP_CONV_SIZES	= {
	'sportsdirect' => {
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
	},
	'lovell-rugby' => {
		
	},
};

$SIZE_TITLE = 'Tallas / Sizes';

$PROD_AVAILABILITY = '14d.gif';

$CONV_CATEGORY_IDS = {
	
};





1;