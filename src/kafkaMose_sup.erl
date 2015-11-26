-module(kafkaMose_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(H,T), {T, {kafkaMose_worker, start_link, [H, T]}, permanent, brutal_kill, worker, [kafkaMose_worker]}).
-define(TOPICSTABLE, topics_etstable).


%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    Hosts = config:get_kafka_consumer_hosts(),
    Topics = config:get_kafka_consumer_topics(),
    Children = [?CHILD(Hosts, Topic) || Topic <- Topics],
    {ok, { {one_for_one, 5, 10}, Children} }.
