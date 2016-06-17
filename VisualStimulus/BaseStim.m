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
            if nargin<2 || isempty(frames),frames=1:obj.length;end
            if nargin<3,steppingMode=false;end

            % reset abort flag, set up callback for key press events
            if obj.interactiveMode
                obj.plotAbort = false;
                obj.plotStepMode = steppingMode;
                set(gcf,'KeyPressFcn',@obj.pauseOnKeyPressCallback)
            end
            
            numel(frames)
            % display frame in specified axes
            % use a while loop instead of a for loop so that we can
            % implement stepping backward
            idx = 1;
            while idx <= numel(frames)
                if obj.interactiveMode && obj.plotAbort
                    close
                    return
                end
                
                % display frame
                imagesc(flipud(obj.stim(:,:,:,frames(idx))), [0 1])
                if obj.channels == 1
                    colormap gray
                end
                axis image
                text(2, obj.height-5, num2str(frames(idx)), ...
                    'FontSize', 10, 'BackgroundColor','white')
                drawnow
                
                if obj.interactiveMode
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
                else
                    pause(0.1)
                    idx = idx + 1;
                end
            end
        end
        
        function load(obj, fileName, loadHeaderOnly)
            if nargin<3,loadHeaderOnly=false;end
            fid = fopen(fileName,'r');
            if fid == -1
                error(['Could not open "' fileName ...
                    '" with read permission.']);
            end
            
            % read signature
            sign = fread(fid, 1, 'int');
            if sign ~= obj.fileSignature
                error('Unknown file type: Could not read file signature')
            end
            
            % read version number
            ver = fread(fid, 1, 'float');
            if (ver ~= obj.version)
                error(['Unknown file version, must have Version ' ...
                    num2str(obj.version) ' (Version ' ...
                    num2str(ver) ' found)'])
            end
            
            % read number of channels
            obj.channels = fread(fid, 1, 'int8');
            
            % read stimulus dimensions
            obj.width = fread(fid, 1, 'int');
            obj.height = fread(fid, 1, 'int');
            obj.length = fread(fid, 1, 'int');
            
            % don't read stimulus if this flag is set
            if loadHeaderOnly
                return
            end
            
            % read stimulus
            obj.stim = fread(fid, 'uchar')/255;
            fclose(fid);
            
            % make sure dimensions match up
            dim = obj.width*obj.height*obj.length*obj.channels;
            if size(obj.stim,1) ~= dim
                error(['Error during reading of file "' fileName '". ' ...
                    'Expected width*height*length = ' ...
                    num2str(obj.privSizeOf()) ...
                    'elements, found ' num2str(numel(obj.stim))])
            end
            
            % reshape
            obj.stim = reshape(obj.stim, obj.height, obj.width, ...
                obj.channels, obj.length);
            disp(['Successfully loaded stimulus from file "' fileName '"'])
        end            
        
        function save(obj, fileName)
            if nargin<2,fileName=[obj.name '.dat'];end
            fid = fopen(fileName,'w');
            if fid == -1
                error(['Could not open "' fileName ...
                    '" with write permission.']);
            end
            if obj.width<0 || obj.height<0 || obj.length<0
                error('Stimulus width/height/length not set.');
            end
            
            % check whether fwrite is successful
            wrErr = false;
            
            % start with file signature
            sign = obj.fileSignature; % some random number
            cnt=fwrite(fid,sign,'int');           wrErr = wrErr | (cnt~=1);
            
            % include version number
            cnt=fwrite(fid,obj.version,'float');  wrErr = wrErr | (cnt~=1);
            
            % include number of channels (1 for GRAY, 3 for RGB)
            cnt=fwrite(fid,obj.channels,'int8');  wrErr = wrErr | (cnt~=1);
            
            % specify width, height, length
            cnt=fwrite(fid,obj.width,'int');      wrErr = wrErr | (cnt~=1);
            cnt=fwrite(fid,obj.height,'int');     wrErr = wrErr | (cnt~=1);
            cnt=fwrite(fid,obj.length,'int');     wrErr = wrErr | (cnt~=1);
            
            % read stimulus
            cnt=fwrite(fid,obj.stim*255,'uchar');
            wrErr = wrErr | (cnt~=obj.width*obj.height*obj.length*obj.channels);
            
            % if there has been an error along the way, inform user
            if wrErr
                error(['Error during writing to file "' fileName '"'])
            end
            
            fclose(fid);
            disp(['Successfully saved stimulus to file "' fileName '"'])
        end
        
        function record(obj, fileName, fps)
            if nargin<3,fps=5;end
            if nargin<2,fileName='movie.avi';end
            
            % display frames in specified axes
            set(gcf,'color','white');
            set(gcf,'PaperPositionMode','auto');
            
            % open video object
            vidObj = VideoWriter(fileName);
            vidObj.Quality = 100;
            vidObj.FrameRate = fps;
            open(vidObj);
            
            % display frame in specified axes
            obj.interactiveMode = false;
            for i=1:obj.length
                obj.plot(i, false);
                drawnow
                writeVideo(vidObj, getframe(gcf));
            end
            obj.interactiveMode = true;
            close(gcf)
            close(vidObj);
            disp(['created file "' fileName '"'])
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
        
        function popFront(obj, numFrames)
            % removes the first NUMFRAMES number of frames
            obj.erase(1:numFrames);
        end
        
        function popBack(obj, numFrames)
            % removes the last NUMFRAMES number of frames
            obj.erase(end-numFrames+1:end);
        end
        
        function erase(obj, frames)
            % removes either a single frame (position) or a range of FRAMES
            obj.stim(:,:,:,frames) = [];
            obj.length = size(obj.stim,4);
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        function appendFrames(obj, frames)
            if size(frames,1) ~= obj.height || ...
                    size(frames,2) ~= obj.width || ...
                    size(frames,3) ~= obj.channels
                msgId = [obj.baseMsgId ':dimensionMismatch'];
                msg = ['frames must be of size height x width x ' ...
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
        
        function prependFrames(obj, frames)
            if size(frames,1) ~= obj.height || ...
                    size(frames,2) ~= obj.width || ...
                    size(frames,3) ~= obj.channels
                msgId = [obj.baseMsgId ':dimensionMismatch'];
                msg = ['frames must be of size height x width x ' ...
                    'channels x number frames'];
                error(msgId, msg)
            end
            try
                obj.stim = cat(4, frames, obj.stim);
                obj.length = size(obj.stim,4);
            catch causeException
                throw(causeException)
            end
        end
        
        function initDefaultParams(obj)
            % needs width/height
            assert(~isempty(obj.width))
            assert(~isempty(obj.height))
            
            % VisualStimulus version number
            obj.version = 1.0;
            
            % some unique identifier to ID binary files
            obj.fileSignature = 293390619;

            % initialize protected properties
            obj.length = 0;
            obj.plotAbort = false;
            obj.plotStepMode = false;
            obj.plotStepFW = false;
            obj.plotStepBW = false;
            
            obj.interactiveMode = true;
                        
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
        
        interactiveMode;
    end
    
    properties (SetAccess = private, GetAccess = protected)
        version;
        fileSignature;
    end
    
    properties (Abstract, Access = protected)
        baseMsgId;
        name;
    end
end
