-module(config).

-export([ get_kafka_consumer_hosts/0, set_kafka_consumer_hosts/1
        , get_kafka_consumer_topics/0, add_kafka_consumer_topic/1
        , get_pid_file/0, write_pid_file/0, write_pid_file/2 
        , get_kafka_partitions_num/2]).

%% ------------------------------------------------------------------
%% includes
%% ------------------------------------------------------------------
-include("logger.hrl").

%% ===================================================================
%% API functions
%% ===================================================================

get_kafka_consumer_hosts() ->
    case application:get_env(kafkaMose, kafka_consumer_hosts) of
	{ok, KafkaHosts} ->
            KafkaHosts;
	undefined ->
            ?ERROR_MSG("Get log kafka hosts not defined", [])
    end.

set_kafka_consumer_hosts(Hosts) ->
    application:set_env(kafkaMose, kafka_consumer_hosts, Hosts).

get_kafka_consumer_topics() ->
    case application:get_env(kafkaMose, kafka_consumer_topics) of
	{ok, KafkaConsumerTopic} ->
            KafkaConsumerTopic;
	undefined ->
            ?ERROR_MSG("Get kafka consumer topic not defined", [])
    end.

add_kafka_consumer_topic(Topic) ->
    application:set_env(kafkaMose, kafka_consumer_topic, Topic).

get_kafka_partitions_num(Hosts, Topic) ->
    case brod:get_metadata(Hosts, [Topic]) of
        {_,{_,_,[{_,_,_,Partitions}]}} ->
            erlang:length(Partitions);
        _Other ->
            error_logger:error_msg("~p get topic ~p partitions ERROR: ~p",[?MODULE, Topic,_Other])
    end.

get_pid_file() ->
    case application:get_env(kafkaMose, pid_path) of
	{ok, PidPath} ->
            PidPath;
	undefined ->
            ?ERROR_MSG("Get pid file not defined", [])
    end.

write_pid_file() ->
    case get_pid_file() of
	undefined ->
	    ok;
	PidFilename ->
	    write_pid_file(os:getpid(), PidFilename)
    end.

write_pid_file(Pid, PidFilename) ->
    case file:open(PidFilename, [write]) of
	{ok, Fd} ->
	    io:format(Fd, "~s~n", [Pid]),
	    file:close(Fd);
	{error, Reason} ->
	    ?ERROR_MSG("Cannot write PID file ~s~nReason: ~p", [PidFilename, Reason])
    end.
