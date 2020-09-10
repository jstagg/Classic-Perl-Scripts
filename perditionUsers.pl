#!/usr/bin/perl
#
# perditionusers.pl
#
# We use this to run an ldap query to an Exchange 5.5 server
# so we can generate a Perdition proxy list for internal Exchange
# servers.
#
# You'll have to dump the Exchange directory using instructions
# here: http://www.unixwiz.net/techtips/postfix-exchange-users.html
# before running the script. And, you'll have to get that dump
# to the Perdition server, too.
#
# Don't forget my versions of the above configs and batch files
# in the description at:
# http://www.perlmonks.org/index.pl?node_id=386951
#

use File::Copy;

# for what domain will we search in the mail addresses?
$domain = "yourdomain.com";

# path to relay_recipients file/db: current, new and backups
$perdition_dir = "/etc/perdition";
$exchusers = "$perdition_dir/exchusers.txt";
$imapusers = "$perdition_dir/imapusers.txt";
$popmap = "$perdition_dir/popmap";

# postfix db rebuild and reload command
$perdition_stop = "/etc/init.d/perdition stop";
$perdition_start = "/etc/init.d/perdition start";

# localize the results array variable
my @results;

open (EXCH, "< $exchusers"); 

# while the filehandle has data...
while (<EXCH>) {
    # remove the trailing newline
    chomp;
    if (/^Mailbox/) {
        $_ = lc $_;
        ($mb,$alias,$homesrv) = split /\t/;
        push @results, "$alias:$alias\@$homesrv.$domain";
    }
}

# close the filehandle
close EXCH;

open (IMAP, "> $imapusers") or die "Can't open $imapusers $!\n";
foreach $line (@results) {
    print IMAP "$line\n"
#    print "$line\n"
}
close IMAP;

copy($popmap,"$popmap.bak");
copy($imapusers,$popmap);
chdir($perdition_dir);
system("make");
system($perdition_stop);
system($perdition_start);
