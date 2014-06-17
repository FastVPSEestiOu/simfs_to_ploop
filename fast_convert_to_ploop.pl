#!/usr/bin/perl

# Author pavel.odintsov@gmail.com

use strict;
use warnings;

sub debug_print {
    my $log = shift;

    print "$log\n";
}

sub get_usage_percent_in_blocks {
    my $ctid = shift;

    my $result = `/usr/sbin/vzlist $ctid -o diskspace,diskspace.h -H`;
    chomp $result;

    $result =~ s/^\s+//;
    my ($used, $max) = split /\s+/, $result;

    print "CT bytes $ctid used $used max: $max\n";
    return sprintf("%.1f", $used/$max) * 100;
}

sub get_disklimit {
    my $ctid = shift;
    
    my $result = `/usr/sbin/vzlist $ctid -o diskspace,diskspace.h -H`;
    chomp $result;

    $result =~ s/^\s+//;
    my ($used, $max) = split /\s+/, $result;

    return $max;
}

sub get_disklimit_inodes {
    my $ctid = shift;

    my $result = `/usr/sbin/vzlist $ctid -o diskinodes,diskinodes.h -H`;
    chomp $result;

    $result =~ s/^\s+//;
    my ($used, $max) = split /\s+/, $result;

    print "CT inodes $ctid used $used max: $max\n";
}

my @vzlist = `/usr/sbin/vzlist -o veid,layout,status -a -H`;
chomp @vzlist;

for my $line (@vzlist) {
    $line =~ s/^\s+//g;
    $line =~ s/\s+$//g;

    my ($ctid, $layout, $status) = split /\s+/, $line;

    if ($layout eq 'ploop') {
        #debug_print("$ctid is ploop already, skip it");
        next;
    }

    debug_print("Process CT $ctid");
    get_disklimit_inodes($ctid);

    # If this VE disk is overused we should enlarge it for successful conversion
    my $percent_usage = get_usage_percent_in_blocks($ctid);
    if ($percent_usage > 85) {
        my $disk_limit_bytes = get_disklimit($ctid);
        # Add 1Gb for conversion to ploop
        my $new_limit = $disk_limit_bytes + 1000000;

        debug_print("Add 1Gb to VPS $ctid because space usage for this ct is: $percent_usage %");
        `vzctl set $ctid --diskspace  $new_limit --save`;
    }


    if ($status eq 'running') {
        debug_print("We should stop $ctid container (current status: $status)");
        `vzctl stop $ctid`;
    }

    if ($status eq 'mounted') {
        debug_print("We should umount $ctid container (current status: $status)");
        `vzctl umount $ctid`;
    }

    debug_print("Start ploop conversion for: $ctid");
    print `vzctl convert $ctid 2>&1`;


    if ($status eq 'running') {
        debug_print("We should start $ctid stopped container");
        print `vzctl start $ctid 2>&1`;
    }

}
