#!perl
# 
# This script runs against the PDC to get a user list. Then, the user list
# array has a last logoff lookup to each DC as well as a lookup against
# your Exchange server. Yes, it's ugly and amateurish. It outputs a list
# to stdout as a comma-delimited list, suitable for piping to a file for
# sorting in the spreadsheet of your choice.
#
# You'll need:
# Win32::AdminMisc from www.roth.net 
# Net::LDAP 
# Win32::NetAdmin
#
# In my case, I stuck with AS 5.6 so the roth ppm install would work. And,
# because I've seen the question before, install the perl-ldap package
# with PPM3, not perldap.
#
# A word about last logoff times. They ain't gospel, or at least I have 
# yet to convince myslef that they are. Only a domain logon counts in changing
# that date. Authentication for Exchange and other apps won't roll the clock.
# And, by example, real road warriors may go weeks without a logon because
# of the cached nt logon on their laptops.
#
# I've also added a column for password age. It is presented in seconds,
# divided by 86400 to turn it into days and truncated to remove any
# decimals. I don't care if my password is 29.4 days old. I just care that it's
# 29 days old, because our auditors only care that it's 29 days old.
#
# As always, YMMV.
# But you knew the job was dangerous when you took it.
# Bok bok bok bok!
# (Superchicken... look it up, Fred)
#
#
#

use Win32::AdminMisc;
use Net::LDAP;
use Win32::NetAdmin;

# ldap variables... everything else is automatic
# don't forget to make this your ldap server's FQDN!
#
my $ldapsrv = 'your.exchangeserver.com';
my $ldapbase = 'c=US';
my @attrs  =     ( 
        'title',
        'department',
        'physicalDeliveryOfficeName',
        'Extension-Attribute-1' # see comment below
              );

# The main reason for the LDAP lookup in our case is to tie an 
# employee ID that we add as a custom attribute to our Exchange
# accounts. You can leave it alone, and the value will be null
# for you. The only side effect will be an empty column in your
# spreadsheet. Or, comment it out here and in the two other following
# locations (search for the comment EA1 to find them).


my $PDC;
my $domain = Win32::DomainName or die "Unable to obtain the domain name\n";

Win32::NetAdmin::GetDomainController("","",$PDC);
Win32::NetAdmin::GetServers($PDC,$domain,SV_TYPE_DOMAIN_CTRL,\@pdc);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_DOMAIN_BAKCTRL, \@bdc);

my @dc = (@pdc, @bdc);

my $server = "\\\\$pdc[0]";
# EA1: Here's one... delete 
# \"Emplid\", (including the following comma)
# if you don't want an empty column where my employee IDs would normally be
print "\"Logon\",\"Username\",\"Emplid\",\"Details\",\"Title\",\"Depar
+tment\",\"Office\",\"Status\",\"Last Logoff\",\"Password Age\"\n";

my %hash;
    Win32::AdminMisc::GetUsers($server, "" , \@array)
        or die "GetUsers() failed: $!";

my %months = (
    "Jan" => "01",
    "Feb" => "02",
    "Mar" => "03",
    "Apr" => "04",
    "May" => "05",
    "Jun" => "06",
    "Jul" => "07",
    "Aug" => "08",
    "Sep" => "09",
    "Oct" => "10",
    "Nov" => "11",
    "Dec" => "12"
    );

@keys = sort {lc $a cmp lc $b} (@array);

foreach $key (@keys) {
    my $logoff;
    my $emplid;
    my $title;
    my $dept;
    my $office;
    my $ldap;
    my $mesg;
    $value = $key;
    Win32::AdminMisc::UserGetAttributes(
        $server, 
        $key, 
        $fullname, 
        $password, 
        $passwordAge, 
        $privilege, 
        $homeDir, 
        $comment, 
        $flags, 
        $scriptPath)
        or die "UserGetAttributes() failed: $!";

# using Net::LDAP, not PerLDAP

    my $filter = "(uid=$key)";
    $ldap = Net::LDAP->new( $ldapsrv ) or die "$@";
    $mesg = $ldap->bind ;
    $mesg = $ldap->search(
                    base   => $ldapbase,
                    filter => $filter,
            attrs  => @attrs
                  );
    foreach $entry ($mesg->entries) { 
# EA1: Here's another...  comment out the line below if you don't want 
# an empty column where my employee IDs would normally be
        chomp( $emplid = $entry->get_value('Extension-Attribute-1') );
    chomp( $title = $entry->get_value('title') );
    chomp( $dept = $entry->get_value('department') );
    chomp( $office = $entry->get_value('physicalDeliveryOfficeName') );
    }
    $mesg->code;
    $mesg = $ldap->unbind;

    my $logoff = "0";
    foreach $dc (@dc) {
        Win32::AdminMisc::UserGetMiscAttributes("\\\\$dc", $key, \%Hash)
            or die "UserGetMiscAttributes() failed: $!";
        if ($Hash{USER_LAST_LOGON} gt $logoff) {
            $logoff = $Hash{USER_LAST_LOGON};
        }
    }
    $logoff = localtime($logoff);
    @lf = split(" ", $logoff);
    $yr = $lf[4];
    $mo = $lf[1];
    $da = $lf[2];
    if (10 > $da) { $da = "0" . $da; }
    $logoff = join("", $yr, $months{$mo}, $da);

    $passwordAgeDay = sprintf("%.0f", $passwordAge/86400);

# EA1: Here's the last... delete 
# \"$emplid\", (including the following comma)
# if you don't want an empty column where my employee IDs would normally be
    print "\"$key\",\"$fullname\",\"$emplid\",\"$comment\",\"$title\",\"$dept\",\"$office\",";
    if (513 =~ $flags) {
        print "\"enabled\",";
    } elsif (515 =~ $flags) {
        print "\"!DISABLED\",";
    } elsif (579 =~ $flags) {
        print "\"!nochpw\",";
    } elsif (66049 =~ $flags) {
        print "\"!noexpw\",";
    } elsif (66113 =~ $flags) {
        print "\"!noexpw, nochpw\",";
    } elsif (66115 =~ $flags) {
        print "\"!DISABLED\",";
    } else {
        print "\"$flags\",";
    }
    print "\"$logoff\",\"$passwordAgeDay\"\n";
}
