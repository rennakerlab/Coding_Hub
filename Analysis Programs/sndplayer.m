function y = sndplayer(cmd, varargin)
% SNDPLAYER is a wrapper for the audioplayer in matlab. Provides
% functionality for loop play and volume change.
%
%   SNDPLAYER('play', y, fs, nbits) plays signal y with sampling frequency 
%   fs and nbits quantization.
%
%   SNDPLAYER('play', y, fs, nbits, range) plays signal y with sampling 
%   frequency fs and nbits quantization and uses two element vector range
%   to define the range of the signal that will be played.
% 
%   SNDPLAYER('play') plays the sound loaded in player (if available) with
%   settings from sndplayer.
% 
%   SNDPLAYER('stop') stops sndplayer.
%
%   SNDPLAYER('pause') pauses sndplayer.
%
%   SNDPLAYER('volume', vol) changes the volume of the player to the new
%   value. Value of the volume is number from the range [0, 1]. Volume can
%   be chabnged even if the sound is playing.
%
%   SNDPLAYER('loop') set the loop property of the player to 'on'.
%
%   SNDPLAYER('loop', 'on') enables the loop playing.
%
%   SNDPLAYER('loop', 'off') disables the loop playing, if the sound is
%   playing, it will be played to the end, or to the end of the range, then
%   it will be stopped.
%
%   state = SNDPLAYER('state') gets actual state of the player. Returns 0
%   if player is stopped, 1 if it is playing and -1 if it is paused.
%

    persistent signal;
    persistent aplayer;
    persistent loop;
    persistent volume;
    persistent range;
    persistent paused;
    
    if isempty(volume), volume = 1; end; % initialize volume value
    if isempty(loop), loop = 0; end; % initialize loop value
    if isempty(paused), paused = 0; end; % initialize paused value
        
    switch lower(cmd)
        case 'play'
            % if player is playing then stop it
            if ~isempty(aplayer) && isplaying(aplayer),
                aplayer.StopFcn = [];
                stop(aplayer); paused = 0; 
            end;
            
            % load parameters
            if length(varargin) >= 3, % load: signal, fs, nbits, {range}
                signal = varargin{1};
                fs = varargin{2};                
                nbits = varargin{3};
                if length(varargin) > 3, range = varargin{4};
                else range = []; end;
                aplayer = audioplayer(signal .* volume, fs, nbits); % initialize audio player
                paused = 0;
            elseif length(varargin) <= 1, % load play range for player if available
                if isempty(signal), % for empty signal do nothing
                    warning('No input signal to play.');
                    return;
                elseif length(varargin) == 1,
                    range = varargin{1};
                    paused = 0;
                end;
            else
                error('Wrong argument count specified.');
            end;
            
            % set player stop function
            if loop == 1, aplayer.StopFcn = {@sndplayer_stop, range};
            else aplayer.StopFcn = []; end;
            
            % play or resume input
            if paused == 1
                resume(aplayer);
                paused = 0;
            elseif paused == 2
                % volume was changed during the pause, current sample is
                % saved in UserData of audioplayer
                cursample = get(aplayer, 'UserData');
                if isempty(range), play(aplayer, cursample);
                else play(aplayer, [cursample,  range(2)]); end;
                paused = 0;
            else
                if isempty(range), play(aplayer);
                else play(aplayer, range); end;
            end;
            
        case 'loop'
            if length(varargin) > 0, % set loop according to the parameter
                if strcmp(lower(varargin{1}), 'on'), loop = 1;
                elseif strcmp(lower(varargin{1}), 'off'), loop = 0; end;
            else % set loop on
                loop = 1;
            end;
            if ~isempty(aplayer) % set loop for the current player
                if loop == 1,
                    aplayer.StopFcn = {@sndplayer_stop, range};
                else
                    aplayer.StopFcn = [];
                end;
            end;
            
        case 'stop'
            if ~isempty(aplayer)
                aplayer.StopFcn = [];
                stop(aplayer);
                paused = 0;
            end;
            
        case 'pause'
            if ~isempty(aplayer)
                aplayer.StopFcn = [];
                paused = 1;
                pause(aplayer);
            end;
            
        case 'volume'
            if length(varargin) > 0,
                if varargin{1} >= 0 && varargin{1} <= 1,
                    volume = varargin{1};
                else
                    error('Volume value should be from range [0, 1]');
                end;
            else
                error('Volume value must be specified.');
            end;
            if ~isempty(aplayer)
                playing = isplaying(aplayer);
                aplayer.StopFcn = [];
                pause(aplayer);
                cursample = get(aplayer, 'CurrentSample');
                stop(aplayer);
                
                fs = get(aplayer, 'SampleRate');
                nbits = get(aplayer, 'BitsPerSample');
                                
                aplayer = audioplayer(signal .* volume, fs, nbits); % initialize audio player
                if paused == 1, % if sound was paused, set the paused flag to 2 and store current sample to the player user data.
                    paused = 2;
                    set(aplayer, 'UserData', cursample);
                end;
                
                % set player stop function
                if loop == 1, aplayer.StopFcn = {@sndplayer_stop, range};
                else aplayer.StopFcn = []; end;
                
                % continue playing if the player was playing before
                if playing == 1
                    if isempty(range), 
                        play(aplayer, cursample);
                    else
                        play(aplayer, [cursample range(2)]);
                    end;
                end;
            end;
            
        case 'state'
            if ~isempty(aplayer)
                if isplaying(aplayer), state = 1;
                else state = 0; end;
                if state == 0 && paused > 0,
                    state = -1;
                end;
            else
                state = 0;
            end;
            if nargout > 0,
                y = state;
            else
                disp(state);
            end;
        otherwise
            error('Invalid command specified.');
    end;
    
% Helper function triggered when the loop is on and the player stops.
% Player is restarted to continue loop.
function sndplayer_stop(obj, event, range)
    stop(obj)
    if isempty(range), play(obj);
    else play(obj, range); end;
