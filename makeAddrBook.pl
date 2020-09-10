
#!perl
#
# makeaddrbook for squirrelmail
#
# change the ldapsrv variable, pipe it to global.abook and
# copy it to where your global.abook lives. And, change
# the other occurance of yourdomain.com in the 
# (mail=*yourdomain.com) search string to match
# your mocal mail domain.
# 

use Net::LDAP;

$ldapsrv = "exchange.yourdomain.com";

$ldap = Net::LDAP->new($ldapsrv) or die "$@";

$mesg = $ldap->bind;

$mesg = $ldap->search(
	base   => "c=US",
	filter => "(& (mail=*yourdomain.com)(objectclass=person))",
	attrs => ['cn', 'mail']
	);

$mesg->code && die $mesg->error;

foreach $entry ($mesg->entries) { 
	#print "DN: ", $entry->dn, "\n";
	#$entry->dump; 
	my $attr;
        my $line;
	my @results;
        foreach $attr ( $entry->attributes ) {
		next if ( $attr =~ /;binary$/ );
		$val = $entry->get_value ( $attr );
		next if ( $val =~ /^SMEX/ );
		push @results, $val;
		#print "  $attr : ", $entry->get_value ( $attr ) ,"\n";
	}
        my ($gn,$sn) = split(/\s/,$results[0],2);
	$line = join ("|", $results[0], $gn, $sn, $results[1]);
	unless ($line =~ /\|\|\|/) { push @addresses, $line; }
}

$mesg = $ldap->unbind;

@addresses = sort @addresses;

foreach $line (@addresses) { print "$line\n"; }

