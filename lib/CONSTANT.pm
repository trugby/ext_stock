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

	$SCRIPT_DIR
	$DATA_DIR
	$TMP_DIR
	$PRODUCT_IMG_DIR
	$PRODUCT_IMG_PATH
	
	$INIT_EXT_FILE
	$UPDATE_EXT_FILE
	$IMPORT_EXT_PROD_FILE
	$EXPORT_PRICESIZESTOCK_PROD_FILE
	$IMPORT_PRICESIZESTOCK_PROD_FILE
	
	$DOWNN_SCRIPT_FILE
	$CHECK_SCRIPT_FILE
	$CSVI_CRON_FILE
	
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

#$SCRIPT_DIR			= '/kunden/homepages/24/d406245370/htdocs/scripts/ext_stock';
#$DATA_DIR			= '/kunden/homepages/24/d406245370/htdocs/data/stock';
#$TMP_DIR			= '/kunden/homepages/24/d406245370/htdocs/tmp/external_stock';
#$PRODUCT_IMG_DIR 	= '/kunden/homepages/24/d406245370/htdocs/images/stories/virtuemart/product';
$SCRIPT_DIR			= '/Users/jmrodriguez/Google\ Drive/Stock/ext_stock';
$DATA_DIR			= '/Users/jmrodriguez/tmp';
$TMP_DIR			= '/Users/jmrodriguez/tmp';
$PRODUCT_IMG_DIR 	= '/Users/jmrodriguez/tmp';
$PRODUCT_IMG_PATH 	= 'images/stories/virtuemart/product';

$INIT_EXT_FILE			= $DATA_DIR.'/../initExtStock.csv';
$UPDATE_EXT_FILE		= $DATA_DIR.'/UpdateExternalStock.csv';
$IMPORT_EXT_PROD_FILE	= $DATA_DIR.'/ImportExternalStock__LANG__.csv';
$EXPORT_PRICESIZESTOCK_PROD_FILE	= $DATA_DIR.'/ExportPriceSizeStockProducts.csv';
$IMPORT_PRICESIZESTOCK_PROD_FILE	= $DATA_DIR.'/ImportPriceSizeStockProducts.csv';

$DOWNN_SCRIPT_FILE		= $SCRIPT_DIR.'/download_external_products.pl';
$CHECK_SCRIPT_FILE		= $SCRIPT_DIR.'/check_external_stock.pl';
$CSVI_CRON_FILE			= '/kunden/homepages/24/d406245370/htdocs/dev/administrator/components/com_csvi/helpers/cron.php';

############################
# GLOBAL VARIABLES OF SHOP #
############################

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
		'lge/xlge'	=> 'L/XL',
		'10oz'		=> '10OZ',
		'12oz'		=> '12OZ',
		'14oz'		=> '14OZ',
		'16oz'		=> '16OZ',
		'6'			=> '6',
		'6.5'		=> '6.5',
		'7'			=> '7',
		'7.5'		=> '7.5',
		'8'			=> '8',
		'8.5'		=> '8.5',
		'9'			=> '9',
		'9.5'		=> '9.5',
		'10'		=> '10',
		'10.5'		=> '10.5',
		'11'		=> '11',
		'11.5'		=> '11.5',
		'12'		=> '12',
		'12.5'		=> '12.5',
		'13'		=> '13',
		'13.5'		=> '13.5',
	},
	'lovell-rugby' => {
		
	},
};

$SIZE_TITLE = 'Tallas / Sizes';

$PROD_AVAILABILITY = '14d.gif';

$CONV_CATEGORY_IDS = {
	
};





1;