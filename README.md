kafka-offset-monitor
================
kafka-offset-monitor is an Erlang build application that monitors kafka offset changed during last few minutes(which could be configured in config file) ,and then compute the ops during last few minutes .

Requirements
---------------
 - GNU Make
 - Erlang/OTP R15B or higher

confi file
---------------
kafka-offset-monitor config file is kafkaOffsetMonit.config, in this file, some config variables explained here:

kafka_consumer_hosts: the host name and port of kafka

kafka_consumer_topics: configured topics that need to be monitored

kafka_consumer_min_bytes: the min bytes in one time kafka consume, default is 0, and is fine set it 0

kafka_consumer_max_bytes: the max bytes in one time kafka consume , default is 100000

check_interval: configured the time unit monitored

pid_path: store the pid of kafka-offset-monitor in file

log_root: the directory for lager logs

other viriables just keep the default

Building kafka-offset-monitor
---------------
1. git clone kafka-offset-monitor source files

 git clone https://github.com/left2right/kafka-offsets-monitor.gitt

2. run command 
 
 make

 this will use rebar get application dependens, compile the application and generate the application, you could find kafka-offset-monitor directory under rel directory which is used for runing kafkaOffsetMonit...  
 
4. configure kafka-offset-monitor 
 edit the sys.config file in rel/kafkaOffsetMonit/release/$APP_VSN/sys.config for specific use, For example:

  edit kafka hosts, lager log directory and so on.  

Use kafka-offset-monitor
---------------
You can use the `kafkaOffsetMonit` command line administration script to start and stop kafkaOffsetMonit. For example:
 - cd ./rel/kafkaOffsetMonit/
 - ./bin/kafkaOffsetMonit start
 - ./bin/kafkaOffsetMonit stop
