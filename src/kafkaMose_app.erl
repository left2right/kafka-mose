-module(kafkaMose_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    config:write_pid_file(),
    logger:start(),
    kafkaMose_sup:start_link().

stop(_State) ->
    ok.
