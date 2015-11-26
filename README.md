kafka-mose
================
kafka-mose is an Erlang build application that monitors kafka offset changed during last few minutes(which could be configured in config file) ,and then compute the ops during last few minutes .

Requirements
---------------
 - GNU Make
 - Erlang/OTP R15B or higher

confi file
---------------
kafka-mose config file is kafkaMose.config, in this file, some config variables explained here:

kafka_consumer_hosts: the host name and port of kafka

kafka_consumer_topics: configured topics that need to be monitored

kafka_consumer_min_bytes: the min bytes in one time kafka consume, default is 0, and is fine set it 0

kafka_consumer_max_bytes: the max bytes in one time kafka consume , default is 100000

check_interval: configured the time unit monitored

pid_path: store the pid of kafka-mose in file

log_root: the directory for lager logs

other viriables just keep the default

Building kafka-mose
---------------
1. git clone kafka-mose source files

 git clone https://github.com/left2right/kafka-offsets-monitor.gitt

2. run command 
 
 make

 this will use rebar get application dependens, compile the application and generate the application, you could find kafka-mose directory under rel directory which is used for runing kafkaMose...  
 
4. configure kafka-mose 
 edit the sys.config file in rel/kafkaMose/release/$APP_VSN/sys.config for specific use, For example:

  edit kafka hosts, lager log directory and so on.  

Use kafka-mose
---------------
You can use the `kafkaMose` command line administration script to start and stop kafkaMose. For example:
 - cd ./rel/kafkaMose/
 - ./bin/kafkaMose start
 - ./bin/kafkaMose stop
