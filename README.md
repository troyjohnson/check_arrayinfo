# check_arrayinfo
A Nagios check for Linux disk arrays locally or via SSH.

This is now not used as much as putting this line:

extend .1.3.6.1.4.1.2021.52 cciss_vol_status /usr/bin/cciss_vol_status -u /dev/sg2

into the /etc/snmp/snmpd.conf file.
