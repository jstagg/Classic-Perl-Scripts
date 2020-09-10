
#!perl
#
# As long as you have the module, you should not have to change a thing!
#

use Win32::NetAdmin;

my $PDC;
my $domain = Win32::DomainName or die "Unable to obtain the domain name\n";

Win32::NetAdmin::GetDomainController("","",$PDC);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_DOMAIN_CTRL, \@pdc);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_DOMAIN_BAKCTRL, \@bdc);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_SERVER_NT, \@nt);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_SERVER_UNIX, \@nix);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_SQLSERVER, \@mssql);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_WORKSTATION, \@ntwks);
Win32::NetAdmin::GetServers($PDC, $domain, SV_TYPE_WFW, \@wfw);

my @dc = (@pdc, @bdc);
my %nixem;
my %nowks;

foreach $dc (@dc) { $nowks{$dc} = "nowks"; }
foreach $wfw (@wfw) { $nowks{$wfw} = "nowks"; }
foreach $nix (@nix) { $nixem{$nix} = "unix"; $nowks{$nix} = "nowks"; }
foreach $nt (@nt) { $nowks{$nt} = "nowks"; }

print "\nNT/2000/2003 servers in the $domain domain:\n";
foreach $dc (@dc) { 
    if ($pdc[0] eq $dc) { print "$dc (pdc)\n"; } else { print "$dc (bdc)\n"; }
}
foreach $nt (@nt) { unless ($nixem{$nt} eq unix) { print "$nt\n"; } }

print "\nMSSQL servers in the $domain domain:\n";
foreach $mssql (@mssql) { print "$mssql\n"; }

print "\nUnix servers in the $domain domain:\n";
foreach $nix (@nix) { print "$nix\n"; }

print "\nWindows NT/2000/XP workstations in the $domain domain:\n";
foreach $ntwks (@ntwks) { unless ($nowks{$ntwks} eq nowks) { print "$ntwks\n"; } }

print "\nWindows 95/98 workstations in the $domain domain:\n";
foreach $wfw (@wfw) { print "$wfw\n"; }

