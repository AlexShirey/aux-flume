#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo "error: wrong number of args (input_data_file, source_type - exec or netcat)"
	exit 1
fi

INPUT_FILE=$1
SOURCE_TYPE=$2

if [[ ! -f $INPUT_FILE ]]; then
	echo "error: $INPUT_FILE is not a file, exiting!"
	exit 1
fi

if [[ $SOURCE_TYPE == "exec" ]]; then
	CONF_FILE=./conf/flume_exec.conf	
	TEMP_DIR=/tmp/flume
	TEMP_FILE=$TEMP_DIR/output.txt
	echo "creating temporary file $TEMP_FILE that will be used as a source for flume..."
	if [[ ! -d $TEMP_DIR ]]; then mkdir $TEMP_DIR; fi	
	if [[ -f $TEMP_FILE ]]; then rm $TEMP_FILE;	fi
	touch $TEMP_FILE
	if [[ $? -eq 0 ]]; then
		echo "temp file $TEMP_FILE was created!"
	else
		echo "error: temp file $TEMP_FILE wasn't created, exiting"
		exit 1
	fi
	SOURCE=$TEMP_FILE	
elif [[ $SOURCE_TYPE == "netcat" ]]; then
		CONF_FILE=./conf/flume_netcat.conf
		SOURCE=/dev/tcp/127.0.0.1/44445
else 
	echo "error: wrong source type, exec or netcat are only supported, exiting"
	exit 1
fi

echo "Starting flume..."

flume-ng agent --conf-file $CONF_FILE --name a1 &
FLUME_PID=$!

echo "flume started, waiting it to init and be ready for listening a source..."
sleep 15

INPUT_COUNT=$(cat $INPUT_FILE | wc -l)
echo "Suppose flume is ready, filling flume's source with lines from input file (total lines to write $INPUT_COUNT)..."
cat $INPUT_FILE | while read line ; do echo "$line" ; sleep 0.2 ; done > $SOURCE

echo "Seems the source is filled up, no more lines to add, no more job for flume. Check HDFS for result."
echo "Do you want to terminate flume proccess? (y for yes)"
read CHOICE
if [[ $CHOICE == "y" ]]; then
	sleep 10 #to make flume finish his job
	kill -9 $FLUME_PID
	KILLED=true
	echo "flume proccess killed."	
else 
	echo "keeping flume running, you can kill it manualy."	
fi

#remove temporary file, we don't need it anymore
if [[ $SOURCE_TYPE == "exec" ]]; then
	echo "removing temporary file from local file system..."
	if [[ ! $KILLED ]]; then sleep 10; fi
	rm $TEMP_FILE
	echo "...done!"	
fi

echo "the app is finished."
	





