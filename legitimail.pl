#!/usr/bin/perl
#
# legitimail.pl
#
# Running this script WILL REWRITE some of your Postfix
# config files, if the paths are the same!!!
#
# Assumes: Postfix
#
# We use this to run an ldap query to an Exchange 5.5 server
# so we can generate a Postfix relay recipient map of legitimate
# mailboxes (witty, eh?). We reject non-legit mail at the 
# external MTA level.
#
# All ya need to change are the srvname and domain variables
# at the beginning. You might have to change the path to the
# Postfix config files, too, depending on your OS...
#
# ...and it calls a simple shell script to rebuild the db. Here's
# the 3-line shell script code to cut and paste:
# 
# 
# !/bin/sh
# /usr/local/sbin/postmap /etc/postfix/relay_recipients
# /usr/local/sbin/postfix reload
#
# (remove the comments and save to /usr/local/bin/postrecip.sh)
#
#
# ...and (no, it couldn't be that easy) I'm not covering how
# to use relay recipient maps in Postfix to reject unknown addys. I
# would add that the docs at http://www.postifx.org or
# http://www.unixwiz.net/techtips/postfix-exchange-users.html have 
# the answers to that. You are welcome to a copy of my main.cf file
# if you want. Email me at jstagg@charter.net. It may take a day
# or two to reply.
#
# Here's the "othermailbox" addresses that I discard:
# Scanmail:    next if ( $val =~ /^SMEX/ );
# CCMail:      next if ( $val =~ /^CCMAIL/ );
# MSMail:      next if ( $val =~ /^MS\$/ );
#
# You might have others you want to discard. 
#

use File::Copy;
use Net::LDAP;

# ldap server to query
$ldapsrv = "exchange.yourdomain.com";

# for what domain will we search in the mail addresses?
$domain = "yourdomain.com";

# postfix conf files live here
$postfix_conf = "/etc/postfix";

# path to relay_recipients file/db: current, new and backups
$rr_file = "$postfix_conf/relay_recipients";
$rr_db = "$postfix_conf/relay_recipients.db";
$rr_file_bak = "$postfix_conf/relay_recipients.bak";
$rr_db_bak = "$postfix_conf/relay_recipients.db.bak";
$rr_file_new = "$postfix_conf/relay_recipients.new";

# postfix db rebuild and reload command
$postfix = "/usr/local/bin/postrecip.sh";

my @thelist;

$ldap = Net::LDAP->new($ldapsrv) or die "$@";

$mesg = $ldap->bind;

$mesg = $ldap->search(
    base   => "c=US",
    filter => "(& (mail=*$domain)(objectclass=organizationalperson))",
    attrs => ['mail','othermailbox']
    );

$mesg->code && die $mesg->error;

foreach $entry ($mesg->entries) { 
    my $attr;
    my $line;
    my @results;
    foreach $attr ( $entry->attributes ) {
        next if ( $attr =~ /;binary$/ );
        my $val = $entry->get_value ( $attr );
        next if ( $val =~ /^SMEX/ );
        next if ( $val =~ /^CCMAIL/ );
        next if ( $val =~ /^MS\$/ );
        $_ = $val;
        s/^smtp\$//ig;
        s/\%20//ig;
        $val = $_;
        $val = lc $val;
        if ($val) { push @thelist,$val; }
    }
}

$mesg = $ldap->unbind;

@thelist = sort @thelist;

# make a copy of the relay_recipients file and db just in case
copy($rr_file,$rr_file_bak);
copy($rr_db,$rr_db_bak);

# open a filehandle for writing
open (RELAY, "> $rr_file_new") or die "Can't open $rr_file_new $!\n";
## yup. this is almost the same as the test case above
foreach $line (@thelist) {
    # make it all lowercase
    # here's what is different from the stdout example above:
    # print the remaining address and a newline the filehandle
    print RELAY "$line\tdummy\n";
        #print "$line\tdummy\n";
}
# close that filehandle
close RELAY;

## copy the new file to the current file
copy($rr_file_new,$rr_file) or die "Can't copy $rr_file_new to $rr_file: $! \n";

## rebuild db and reload postfix with an external script
system($postfix);
