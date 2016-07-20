#!/usr/bin/perl

# check_arrayinfo.pl

# modules
use Getopt::Long;
use strict;

# variables
my $host = '';
my $warning_default = 85;
my $warning = $warning_default;
my $critical_default = 90;
my $critical = $critical_default;
my $need_help = 0;
my $nagios_status = 'OK';
my $nagios_label = 'ARRAYINFO';
my $array_info_bin = '/usr/sbin/array-info';
my $array_info_opt = '-A';
my $device_default = '/dev/cciss/c0d0';
my $device = $device_default;

# get options
my $good_options = GetOptions(
	'w=i' => \$warning, # numeric
	'c=i' => \$critical, # numeric
	'd=s' => \$device, # string
	'help' => \$need_help, #boolean
);
#print "good_options=\"${good_options}\"\n";
#print "need_help=\"${need_help}\"\n";
if ((not $good_options) or ($need_help)) {
	help_message();
	exit;
}
if ($critical !~ m/^[\d]+$/) {
        # error message for nagios
        print "${nagios_label} WARNING - critical value not an int (${critical})\n";
        exit 1;
}
if ($warning !~ m/^[\d]+$/) {
        # error message for nagios
        print "${nagios_label} WARNING - warning value not an int (${warning})\n";
        exit 1;
}

# get output
my $command = "${array_info_bin} ${array_info_opt} -d ${device} " . '2>&1';
my $output = `$command`;
#print "output: ${output}   ";
my @out_lines = split("\n", $output);
chomp(@out_lines);
my $controller = $out_lines[0];
my ($firmware) = grep { m/firmware\srevision/i } @out_lines;
$firmware =~ s/^\s*firmware\s*revision\s*:\s*//i;
my ($rom) = grep { m/rom\srevision/i } @out_lines;
$rom =~ s/^\s*rom\s*revision\s*:\s*//i;
my ($ft) = grep { m/fault\stolerance/i } @out_lines;
$ft =~ s/^\s*fault\s*tolerance\s*:\s*(.+)\s*\(.+$/$1/i;
my ($size) = grep { m/size/i } @out_lines;
$size =~ s/^\s*Size\s*:\s*(.+)\s*\(.+$/$1/i;
$size =~ s/\s+//gi;
my ($status) = grep { m/status/i } @out_lines;
$status =~ s/^\s*Status\s*:\s*//;

#print "\nfirmware:${firmware} rom:${rom} ft:$ft} size:${size} status:${status}\n";

# check for unknown
if ($status =~ m/^\s*$/) {
	$nagios_status = "UNKNOWN";
	$status = "Cannot read array status";
	print "${nagios_label} ${nagios_status} - ${status}\n";
	exit 3;
}

# display nagios output
if ($status !~ m/logical drive is ok/i) {
	$nagios_status = "CRITICAL";
	print "${nagios_label} ${nagios_status} - ${status} \|firmware=${firmware};;;; rom=${rom};;;; size=${size};;;;\n";
	exit 2;
}
else {
	print "${nagios_label} ${nagios_status} - ${status} \|firmware=${firmware};;;; rom=${rom};;;; size=${size};;;;\n";
	exit 0;

}

# subroutines
sub help_message {
	print "\nUsage: check_arrayinfo.pl [OPTION]...\n\n";
	print "  -d 		disk device to check (Default: $device_default)\n";
	print "  --help		print this help message\n\n";
	print "Example: check_arrayinfo.pl -H myhost -d \"/dev/cciss/c0d0\"\n\n";
}
