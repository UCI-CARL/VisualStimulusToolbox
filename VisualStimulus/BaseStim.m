classdef (Abstract) BaseStim < matlab.mixin.Copyable
    %% Public Methods for All Derived Classes
    methods (Access = public)
        function new = clone(obj)
            new = copy(obj);
        end
        
        function res = plus(obj1, obj2)
            % resize to size of first object
            obj2.resize([obj1.height obj1.width]);
            
            if strcmpi(class(obj1), class(obj2))
                res = obj1.clone();
                res.appendFrames(obj2.stim);
            else
                res = CompoundStim([obj1.height obj1.width obj1.channels]);
                res.appendFrames(obj1.stim);
                res.appendFrames(obj2.stim);
            end
        end
        
        function clear(obj)
            obj.length = 0;
            obj.stim = [];
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
            
            if ~obj.width || ~obj.height || ~obj.channels || ...
                    ~obj.length
                error('Stimulus is empty.')
            end
            
            % reshape
            obj.stim = reshape(obj.stim, obj.height, obj.width, ...
                obj.channels, obj.length);
            disp([obj.baseMsgId ' - Successfully loaded stimulus from ' ...
                'file "' fileName '".'])
        end            
        
        function save(obj, fileName)
            if nargin<2,fileName=[obj.name '.dat'];end
            fid = fopen(fileName,'w');
            if fid == -1
                error(['Could not open "' fileName ...
                    '" with write permission.']);
            end
            
            if obj.length == 0
                error('Stimulus is empty. Nothing to save.')
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
            disp([obj.baseMsgId ' - Successfully saved stimulus to ' ...
                'file "' fileName '".'])
        end
        
        function plot(obj, frames, steppingMode)
            if nargin<2 || isempty(frames),frames=1:obj.length;end
            if nargin<3,steppingMode=false;end
            
            if ~numel(frames)
                disp([obj.baseMsgId ' - Nothing to plot.'])
                return
            end

            % reset abort flag, set up callback for key press events
            if obj.interactiveMode
                obj.plotAbort = false;
                obj.plotStepMode = steppingMode;
                set(gcf,'KeyPressFcn',@obj.pauseOnKeyPressCallback)
            end
            
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
        
        function record(obj, fileName, fps)
            if nargin<3,fps=5;end
            if nargin<2,fileName='movie.avi';end
            
            if obj.length == 0
                error('Stimulus is empty. Can''t record.')
            end
            
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
            disp([obj.baseMsgId ' - Created file "' fileName '".'])
        end
        
        % TODO: needed? Make BlankStim?
        function appendBlanks(obj, numBlanks, grayVal)
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
        
        function addNoise(obj, type, frames, options)
            if nargin<2,type='poisson';end
            if nargin<3 || isempty(frames),frames=1:obj.length;end
            if nargin<4,options={};end
            
%             options = options{:};
            
            for f=frames
                frame = obj.stim(:,:,:,f);
                
                switch lower(type)
                    case 'gaussian'
                        valMean = 0;
                        valVar = 0.01;
                        if numel(options)>=1
                            valMean=options{1};
                            if ~isnumeric(valMean)
                                error('Mean for Gaussian noise must be numeric')
                            end
                        end
                        if numel(options)>=2
                            valVar = options{2};
                            if ~isnumeric(valVar)
                                error('Variance for Gaussian noise must be numeric')
                            end
                        end
                        noisy = imnoise(frame,'gaussian',valMean,valVar);
                    case 'localvar'
                        if numel(options)<1
                            error('Must specify local variance of image')
                        end
                        if size(options{1}) ~= size(frame)
                            error('Local variance must have same size as image')
                        end
                        noisy = imnoise(frame,'localvar',options{1});
                    case 'poisson'
                        noisy = imnoise(frame,'poisson');
                    case 'salt & pepper'
                        valD = 0.05;
                        if numel(options)>=1
                            valD=options{1};
                            if ~isnumeric(valD)
                                error(['Noise density for Salt & Pepper noise ' ...
                                    'must be numeric'])
                            end
                        end
                        noisy = imnoise(frame,'salt & pepper',valD);
                    case 'speckle'
                        valVar = 0.04;
                        if numel(options)>=1
                            valVar=options{1};
                            if ~isnumeric(valVar)
                                error('Variance for Speckle noise must be numeric')
                            end
                        end
                        noisy = imnoise(frame,'speckle',valVar);
                    otherwise
                        error(['Unknown noise type "' type '". Currently ' ...
                            'supported are: ' obj.supportedNoiseTypes])
                end
                
                obj.stim(:,:,:,f) = noisy;
            end
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
            
            disp([obj.baseMsgId ' - Erased frames [' num2str(frames) ']'])
        end
        
        function rgb2gray(obj)
            if obj.channels == 1
                warning('Stimulus is already grayscale.')
                return
            end
            
            assert(obj.channels == 3)
            obj.stim = mean(obj.stim, 3);
            obj.channels = 1;
            disp([obj.baseMsgId ' - Stimulus successfully converted ' ...
                'to grayscale.'])
        end
        
        function resize(obj, dim)
            assert(numel(dim)<=2)
            obj.stim = imresize(obj.stim, dim);
            obj.height = size(obj.stim, 1);
            obj.width = size(obj.stim, 2);
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

            % the following noise types are supported
            obj.supportedNoiseTypes = {'gaussian', 'localvar', ...
                'poisson', 'salt & pepper', 'speckle'};
                        
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
        supportedNoiseTypes;
	end
	
	properties (Hidden, Access = protected)
        plotAbort;          % flag whether to abort plotting (on-click)
        plotStepMode;       % flag whether to waitforbuttonpress btw frames
        plotStepFW;         % flag whether to make a step forward
        plotStepBW;         % flag whether to make a step backward
        
        interactiveMode;
    end
    
    properties (Hidden, SetAccess = private, GetAccess = protected)
        version;
        fileSignature;
    end
    
    properties (Hidden, Abstract, Access = protected)
        baseMsgId;
        name;
    end
end
