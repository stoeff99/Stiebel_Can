#!/bin/bash

# Start CAN interface and FHEM Server
    sudo ip link set can0 type can bitrate 20000
    sudo ip link set can0 up
    #sudo /etc/init.d/fhem start

# Define folders
logdir="/opt/can_logs"
scriptsdir="/opt/can_logs/can_scripts"
indexfile="$scriptsdir/indices"


# Exit if scripts not found
if ! [ -d $scriptsdir ]
then
    echo Directory $scriptsdir does not exist!
    exit 1
fi


# Create log dir if it does not exist yet
if ! [ -d $logdir ]
then
    mkdir $logdir
fi

sleep 5

echo ======================================================================


# Start logging
while [ 0 -le 1 ]
do

# Get current date and start new logging line
now=$(date +'%Y-%m-%d;%H:%M:%S')
line=$now
year=$(date +'%Y')
month=$(date +'%m')
logfile=$year-$month-WP-log.csv
logfilepath=$logdir/$logfile

# Create a new file for every month, write header line
# Create a new file for every month
if ! [ -f $logfilepath ]
then
    headers="Datum;Uhrzeit"
    while read indexline
    do
        header=$(echo $indexline | cut -d" " -f2)
        headers+=";"$header
    done < $indexfile ; echo "$headers" > $logfilepath
fi

# Loop through interesting Elster indices
while read indexline
do
    # Get output of can_scan for this index, search for line with output values

    index=$(echo $indexline | cut -d" " -f1)
    value=$($scriptsdir/./can_scan can0 680 180.$index | grep "value")
    value="${value//)/}"
    value="${value//(/}"
    value=$(echo $value | cut -d" " -f4)
    echo "$index $value"

    # Append value to line of CSV file
    line="$line;$value"

#done < $indexfile ; echo $line >> $logfilepath

    index=$(echo $indexline | cut -d" " -f1)
    value_UDP=$($scriptsdir/./can_scan can0 680 180.$index | grep "value")
    value_UDP="${value_UDP//)/}"
    value_UDP="${value_UDP//(/}"
    value_UDP=$(echo $value_UDP | cut -d" " -f3,4)
    #echo "$value_UDP"

    # Prepare to send UDP message
    line_UDP="$line_UDP;$value_UDP"

done < $indexfile ; echo $line >> $logfilepath

echo -n "value=$line_UDP" >/dev/udp/192.168.20.2/7006

unset line_UDP

echo "------------------------------------------------------------------"

# Wait - next logging data point
sleep 180

# Runs forever, use Ctrl+C to stop
done
