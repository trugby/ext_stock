package common;

use strict;
use warnings;
use Time::localtime;
use File::Path;
use MIME::Lite;
use Exporter;
use FindBin;
use lib "$FindBin::Bin";
use CONSTANT;

use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(
	local_time
	print_file
	open_file
	prepare_wspace
	rm_file
	open_web_file
	save_cookies
	send_email
);

###################
# Global variable #
###################
my ($SHOP_COOKIES)		= $CONSTANT::SHOP_COOKIES;

#####################
# Method prototypes #
#####################
sub local_time();
sub print_file($$);
sub open_file($);
sub rm_file($);
sub open_web_file($);
sub get_cookies($);
sub send_email($$$$;$);

#################
# Method bodies #
#################

sub local_time()
{
	my($systime)=localtime();
	my($date_string)=sprintf("%04d%02d%02d%02d%02d%02d", $systime->year()+1900 ,$systime->mon()+1, $systime->mday(), $systime->hour(), $systime->min(), $systime->sec());
	return $date_string;
}

sub print_file($$)
{
	my ($string, $file) = @_;

	local(*FILE);
	open(FILE,">$file") or return undef;
	print FILE $string;
	close(FILE);

	return $file;
}

sub open_file($)
{
	my ($file) = @_;

	local(*FILE);
	open(FILE,$file) or return undef;
	my(@array)=<FILE>;
	close(FILE);
	my($string)= join "", @array;

	return $string;
}

sub rm_file($)
{
	my ($file) = @_;

	eval {
		my ($cmd) = "rm $file";
		system($cmd);
	};
	return undef if ($@);

	return $file
}

sub prepare_wspace($)
{
	my ($dir) = @_;

	eval {
		my ($cmd) = "mkdir -p $dir";
		system($cmd);
	};
	return undef if ($@);
	return $dir;	
}

sub open_web_file($)
{
	my ($link) = @_;
	my ($string);
	eval {
		my ($cmd) = "wget --no-check-certificate -O - $link &> /dev/null";
		my (@array) = `$cmd`;
		$string = join "", @array;
	};
	if ($@) {
		return undef;
	}
	return $string;
}

sub save_cookies($)
{
	my ($inshops) = @_;
	my ($cookies);	
	#my ($shops_cont) = _open_file($inshops);
	#my (@rows) = split('\n', $shops_cont);
	#foreach my $line (@rows) {
		#my (@cols) = split('\t', $line);
		#my ($shop_name) = $cols[0];
		#my ($shop_link) = $cols[1];
	#foreach my $shop (@{$inshops}) {
	while (my ($shop_name, $shop_report) = each (%{$inshops}) ) {
		my ($shop_link) = $shop_report->{'link'};
		if ( exists $SHOP_COOKIES->{$shop_name} ) {
			my ($cookie_file) = $SHOP_COOKIES->{$shop_name};
			my ($cmd) = "wget --save-cookies $cookie_file -O - -U \"Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16\" $shop_link &> /dev/null";
			print "## $cmd\n";
			eval {
				#system($cmd);
			};
			if ($@) {
				return undef;
			}
			$cookies->{$shop_name} = $cookie_file;
			
		}
	}
	return $cookies;
}

sub send_email($$$$;$)
{
	my ($from, $to, $subject, $content, $files) = @_;

	# Part using which the attachment is sent to an email
	my ($msg) = MIME::Lite->new(
        From     	=> $from,
        To 			=> $to,
        Subject 	=> $subject,
		Type		=> 'multipart/mixed',
	);
	my ($text) = "Message control:\n\n".$content;
	$msg->attach(
		Type    	=> 'text/plain',
		Encoding 	=> 'quoted-printable',
		Data    	=> $text,
	);
	foreach my $file (split(';', $files)) {
		$msg->attach(
			Type    	 => 'text/plain',
			Path    	 => $file,
			Disposition	=> 'attachment'
		);		
	}
	$msg->send;
}


1;