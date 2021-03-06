# syncFrom is the directory where files will be taken from
# syncTo is the directory where files will be written to with the randomised time
syncFrom=$1
syncTo=$2

echo "Syncing directory $syncFrom to $syncTo"

# check if it is run as a root user
if [ "$EUID" -ne 0 ]
	then echo "Please run as root user"
	exit
fi

# check if correct number of arguements are given.
if (( $# != 2 ))
then
	echo "Error: Wrong number of arguements."
	echo "./program.sh /input/directory /output/directory"
fi

function randomiseClock {
sec=$(((($RANDOM%59))+1))
min=$(((($RANDOM%59))+1))
hour=$(((($RANDOM%23))+1))
day=$(((($RANDOM%28))+1))
month=$(((($RANDOM%12))+1))
year=$(((($RANDOM%2038))+1))
#note the day only goes up to 28, as that is the min number of days in any month

while (( $year<1970 ))
do
	year=$(($RANDOM%2039))
done

sudo hwclock --set --date "$month/$day/$year $hour:$min:$sec"
# Note you will have to turn off "network time" to stop the 
# clock syncing with an NTP server
sudo hwclock -s
}

# check if the program can set the system time
orgDate=$(date|awk '{print $1 $2 $3}')
randomiseClock
sleep 2
setDate=$(date|awk '{print $1 $2 $3}')

if [[ "$orgDate" == "$setDate" ]]
then
	echo "Error: Failed to set the hwclock. check if network time is turned on"
	echo "Exiting."
	exit
fi

# For some reason it occasionally fails to set the time
# It will keep trying until the system accepts the time
for file in $syncFrom/*
do
	setFail="0"
	randomiseClock || setFail="1"
	while [[ "$setFail" == "1" ]]
	do
		echo "Failed to set clock. Trying again."
		randomiseClock && setFail="0" || setFail="1"
	done
	echo "Doing file $file with $(sudo hwclock --show --verbose | grep "Hw clock time")"
	cp -r "$file" "$syncTo"
	
done

ls -lt $syncTo
echo ""
echo "Please confirm this worked correctly by comparing the dates written on the files above"
