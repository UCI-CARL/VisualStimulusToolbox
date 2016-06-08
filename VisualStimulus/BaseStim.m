classdef (Abstract) BaseStim < matlab.mixin.Copyable
    %% Public Methods for All Derived Classes
    methods (Access = public)
        function new = clone(obj)
            new = copy(obj);
        end
        
        function clear(obj)
            obj.length = 0;
            obj.stim = [];
        end
        
        function plot(obj, frames, steppingMode)
            if nargin<2,frames=1:obj.length;end
            if nargin<3,steppingMode=false;end

            % reset abort flag, set up callback for key press events
            obj.plotAbort = false;
            obj.plotStepMode = steppingMode;
            set(gcf,'KeyPressFcn',@obj.pauseOnKeyPressCallback)
            
            % display frame in specified axes
            % use a while loop instead of a for loop so that we can
            % implement stepping backward
            idx = 1;
            while idx <= numel(frames)
                if obj.plotAbort
                    close
                    return
                end
                
                % display frame
                imagesc(flipud(permute(obj.stim(:,:,:,frames(idx)), ...
                    [2 1 3 4])),[0 1])
                if obj.channels == 1
                    colormap gray
                end
                axis image
                text(2, obj.height-5, num2str(frames(idx)), ...
                    'FontSize', 10, 'BackgroundColor','white')
                drawnow
                
                % 
                if idx>=numel(frames)
                    waitforbuttonpress;
                    close;
                    return;
                else
                    if obj.plotStepMode
                        % stepping mode: wait for user input
                        while ~obj.plotAbort && ~obj.plotStepFW ...
                                && ~obj.plotStepBW
                            pause(0.1)
                        end
                        if obj.plotStepBW
                            % step one frame backward
                            idx = max(1, idx-1);
                        else
                            % step one frame forward
                            idx = idx + 1;
                        end
                        obj.plotStepBW = false;
                        obj.plotStepFW = false;
                    else
                        % wait according to frames per second, then
                        % step forward
                        pause(0.1)
                        idx = idx + 1;
                    end
                end
                
            end
        end
        
        function addBlanks(obj, numBlanks, grayVal)
            if nargin<3,grayVal=0;end
            if ~isscalar(numBlanks) || ~isnumeric(numBlanks) || ...
                    (isnumeric(numBlanks) && mod(numBlanks,1)~=0)
                msg = 'numBlanks must be an integer';
                error([obj.baseMsgId ':invalidType'], msg)
            else
                if numBlanks <= 0
                    msgId = [obj.baseMsgId ':invalidValue'];
                    msg = 'numBlanks must be > 0';
                    error(msgId, msg)
                end
            end
            if ~isscalar(grayVal) || ~isnumeric(grayVal) || ...
                    (isnumeric(grayVal) && mod(grayVal,1)~=0)
                msg = 'grayVal must be an integer';
                error([obj.baseMsgId ':invalidType'], msg)
            else
                if grayVal < 0 || grayVal > 255
                    msgId = [obj.baseMsgId ':invalidValue'];
                    msg = 'Grayscale value must be in the range [0,255]';
                    error(msgId, msg)
                end
            end
            
            frames = ones(obj.width, obj.height, obj.channels, numBlanks);
            obj.addFrames(frames*grayVal);
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        function appendFrames(obj, frames)
            %addFrames(obj, frames) adds a number of frames
            if size(frames,1) ~= obj.width || ...
                    size(frames,2) ~= obj.height || ...
                    size(frames,3) ~= obj.channels
                msgId = [obj.baseMsgId ':dimensionMismatch'];
                msg = ['frames must be of size width x height x ' ...
                    'channels x number frames'];
                error(msgId, msg)
            end
            try
                obj.stim = cat(4, obj.stim, frames);
                obj.length = size(obj.stim,4);
            catch causeException
                throw(causeException)
            end
        end
        
        function initDefaultParams(obj)
            % initialize protected properties
            obj.length = 0;
            obj.plotAbort = false;
            obj.plotStepMode = false;
            obj.plotStepFW = false;
            obj.plotStepBW = false;
            
            % then initialize all parameters of derived class
            obj.initDefaultParamsDerived();
        end
        
        function pauseOnKeyPressCallback(obj,~,eventData)
            % Callback function to pause plotting
            switch eventData.Key
                case 'p'
                    disp('Paused. Press any key to continue.');
                    waitforbuttonpress;
                case 'q'
                    obj.plotStepMode = false;
                    obj.plotAbort = true;
                case 's'
                    obj.plotStepMode = ~obj.plotStepMode;
                    if obj.plotStepMode
                        disp(['Entering Stepping mode. Step forward ' ...
                            'with right arrow key, step backward with ' ...
                            'left arrow key.']);
                    end
                case 'leftarrow'
                    if obj.plotStepMode
                        obj.plotStepBW = true;
                    end
                case 'rightarrow'
                    if obj.plotStepMode
                        obj.plotStepFW = true;
                    end
                otherwise
            end
        end
    end
    
    %% Abstract Methods
    methods (Abstract)
    end
    
    methods (Abstract, Access = protected)
        initDefaultParamsDerived(obj)
    end
    
    %% Properties
    properties (SetAccess = protected, GetAccess = public)
        width;              % stimulus width (pixels)
        height;             % stimulus height (pixels)
        channels;           % number of channels (gray=1, RGB=3)
        length;             % stimulus length (number of frames)
        stim;               % 3-D matrix width-by-height-by-length
        
        plotAbort;          % flag whether to abort plotting (on-click)
        plotStepMode;       % flag whether to waitforbuttonpress btw frames
        plotStepFW;         % flag whether to make a step forward
        plotStepBW;         % flag whether to make a step backward
    end
    
    properties (Abstract, GetAccess = protected)
        baseMsgId;
    end
end
