# NtLogonDetailList
Find and sort all domain users by account status (enabled, disabled, etc) and/or last logoff time

We needed a way to find and sort all domain users by account status (enabled, disabled, etc) and/or last logoff time. It could be cleaner, simpler and take less time to run (45 minutes with 7 domain controllers). This takes the logon, adds details from Exchange and calculates the most recent last logoff time before dumping the whole mess to stdout as a comma-delimited list.

The only variable you need to change is the $ldapsrv scalar near the beginning. Everything else will (hopefully) just work.

Good luck... hope it helps... muchos gracias to everyone who ever wrote something related... I'm sure I looked at it a dozen times... feel free to improve it!

2004-08-25: Added pdc/bdc lookup (so you don't have to manually change the array) and fixed a problem with the headers. Thanks to Marza's domain disk space check program for the pointer to the obvious routine for adding the pdc and bdcs generically.

2004-11-16: Tweaked a lot of little stuff

    Changed output to comma-separated from tab-separated
    Wrapped the data in double-quotes for the csv output
    Added password age variable (for auditing)
    Left my company-specific employee ID attrib in place with an explanation (since someone may find it useful) 
