#!/usr/bin/perl
 
#PaloAltoInitialConf.pl
#Copyright 2018 Roman Pikalo (pikalo.roman@gmail.com)
#Licensed under http://www.gnu.org/copyleft/gpl.html
 
# This code configures PaloAlto VM Series Firewall (PANOS 8.1.0)
# through restricted SSH connection.
 
use strict;
use warnings;
use Date::Calc qw(:all);
use Net::OpenSSH;

#for debugging, uncomment the below
# $Net::OpenSSH::debug |= 16;

# get input parameters
use Getopt::Long;

# host - PaloAlto FW VM Series IP or resolvable hostname
# user - Username
# key - private key path
# config - initial config file
GetOptions( 'key=s' => \my $key_path 
          , 'user=s' => \my $user  
          , 'host=s' => \my $host  
          , 'config=s' => \my $config  
          , 'checkHost=s' => \my $checkHost
          );

# read config commands (1 line is command) from file
# commands are read into Array and 
# then passed over to SSH session
open my $handle, '<', $config;
	chomp(my @configInitial = <$handle>);
close $handle;

# Troubleshooting command file
# print @lines; 

# == Basic Palo Alto commands ==
# Enter into configuration mode
my @configMode = "configure";

# commit changes
my @commit = "commit";

# troubleshooting configuration
# my @showConfig = "show config running";

# quit configuration mode and terminate SSH session
my @quitcmd = "exit";

# == Build command ==
# this part appends to $command variable all the commands
# and separates them with NewLine character "\n".
# that's how PaloAlto differentiates command
my $splitter = "\n";

# add enter config mode command
my $command .= join("$splitter", @configMode)."$splitter";

# add all commands found in config file
$command .= join("$splitter", @configInitial)."$splitter";

# add commit command
# will produce errors if syntax is not correct
$command .= "@commit"."$splitter";

# add exit configuration mode command
$command .= "@quitcmd"."$splitter";

# troubleshooting configuration
# $command .= "@showConfig"."$splitter";

# add terminate SSH session
$command .= "@quitcmd";

# troubleshooting command file
#print $command;

# get today's date and time to timestamp the name of the output file
my ($sec, $min, $hour, $mday, $mon, $yr, $wday, $yday, $isdst)=localtime(time);
$yr = ( $yr + 1900 );
my $da = sprintf("%02d",$mday);
my $mo = sprintf("%02d",$mon + 1);
my $hh = sprintf("%02d",$hour);
my $mm = sprintf("%02d",$min);
my $timestamp = "$yr$mo$da$hh$mm";
 
#initiate the ssh connection
my $ssh = Net::OpenSSH->new("$host",
							master_opts => [-o => "StrictHostKeyChecking=$checkHost"], 
							key_path => $key_path, 
							user => "$user", 
							timeout => 90 );
$ssh->error and
   die "Couldn't establish SSH connection: ". $ssh->error;
 
#push the commands to the remote host command line with carriage returns
#stuffing both commands to the command line buffers the "quit" until the data has been retrieved.
#this method makes it possible to close the session cleanly and not leave the admin account logged in
my @output = $ssh->capture({stdin_data => "$command"});
$ssh->error and
   die "Couldn't run remote command: ". $ssh->error;
 
#open a new textfile in the data directory and write the results
open(OUTFILE, ">$timestamp") || die "Can't open $timestamp for writing!\n";
print OUTFILE "@output";
close(OUTFILE);
#close the ssh session
undef $ssh;


open(my $fh, '<:encoding(UTF-8)', $timestamp)
or die "Could not open file '$timestamp' $!";
while (my $row = <$fh>) {
   chomp $row;
   print "$row\n";
}