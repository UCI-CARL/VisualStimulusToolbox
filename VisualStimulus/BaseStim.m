classdef (Abstract) BaseStim < matlab.mixin.Copyable
    %% Public Methods for All Derived Classes
    methods (Access = public)
        function new = clone(obj)
            % new = old.clone() makes a deep copy of an existing stimulus. 
            new = copy(obj);
        end
        
        function res = plus(obj1, obj2)
            % C = A + B, where A and B are visual stimuli, combines two or
            % more stimuli into a compound stimulus. If A and B have the
            % same stimulus type (e.g., GratingStim), C will have the same
            % type. If A and B have distinct stimulus types, C will always
            % be of type CompoundStim.
            %
            % If the two stimuli have distinct canvas dimensions, the 
            % second stimulus will be resized to match the first stimulus'
            % [height width].
            %
            % If any of the two stimuli have more than one color channel
            % (e.g., RGB), the result will also have more than one color
            % channel.
            %
            % Example:
            % >> res = DotStim([60 90],'w',10) + PlaidStim([60 90],'r',10);
            % >> res.plot;
            obj2.resize([obj1.height obj1.width]);
            
            % different objects: create compound stimulus
            needCompound = ~strcmpi(class(obj1), class(obj2));
            
            % if any of the objects are RGB, both need be RGB
            if obj1.channels == 3 || obj2.channels == 3 || needCompound
                obj1.gray2rgb();
                obj2.gray2rgb();
            end
            
            if needCompound
                % different objects: compound
                res = CompoundStim([obj1.height obj1.width]);
                res.appendFrames(obj1.stim);
                res.appendFrames(obj2.stim);
            else
                % same object: start from first, add second
                res = obj1.clone();
                res.appendFrames(obj2.stim);
            end
        end
        
        function clear(obj)
            % stim.clear() truncates all stimulus frames.
            obj.length = 0;
            obj.stim = [];
        end
        
        function load(obj, fileName)
            % stim.load(fileName) loads a previously saved stimulus from
            % file FILENAME. Loading a stimulus will overwrite all
            % currently unsaved frames.
            %
            % In order to load a stimulus, use an empty constructor:
            % >> plaid = PlaidStim;
            % >> plaid.load('previouslyStoredPlaidStim.dat');
            %
            % The loaded stimulus must be of same stimulus type as the
            % constructor.
            %
            % The loaded stimulus must have previously been saved with the
            % stimulus' SAVE method.
            %
            % FILENAME  - A string enclosed in single quotation marks that
            %             specifies the name of the file to load.
            fid = fopen(fileName,'r');
            if fid == -1
                msgId = [obj.baseMsgId ':filePermissions'];
                msg = ['Could not open "' fileName '" with read ' ...
                    'permission.'];
                error(msgId, msg)
            end

            % truncate all frames
			obj.clear();
			
            % read signature
            sign = fread(fid, 1, 'int');
            if sign ~= obj.fileSignature
                msgId = [obj.baseMsgId ':fileSignatureMismatch'];
                msg = 'Unknown file type: Could not read file signature';
                error(msgId, msg)
            end
            
            % read version number
            ver = fread(fid, 1, 'float');
            if ver ~= obj.version
                msgId = [obj.baseMsgId ':fileVersionMismatch'];
                msg = ['Unknown file version, must have Version ' ...
                    num2str(obj.version) ' (Version ' num2str(ver) ...
                    ' found)'];
                error(msgId, msg)
			end
			
			% read stimulus type and make sure it's same as obj
			type = fread(fid, 1, 'int');
			if type ~= obj.stimType
				msgId = [obj.baseMsgId ':stimTypeMismatch'];
				msg = ['Expected stimulus type "' class(obj) '"'];
				error(msgId, msg)
			end
            
            % read number of channels
            obj.channels = fread(fid, 1, 'int8');
            
            % read stimulus dimensions
            obj.width = fread(fid, 1, 'int');
            obj.height = fread(fid, 1, 'int');
            obj.length = fread(fid, 1, 'int');
            
            % read stimulus
            obj.stim = fread(fid, 'uchar')/255;
            fclose(fid);
            
            % make sure dimensions match up
            dim = obj.width*obj.height*obj.length*obj.channels;
            if dim ~= numel(obj.stim)
                msgId = [obj.baseMsgId ':stimDimensionMismatch'];
                msg = ['Error during reading of file "' fileName '". ' ...
                    'Expected width*height*length = ' num2str(dim) ...
                    'elements, found ' num2str(numel(obj.stim))];
                error(msgId, msg)
            end
            
            if ~obj.width || ~obj.height || ~obj.channels || ...
                    ~obj.length
                msgId = [obj.baseMsgId ':stimDimensionMismatch'];
                error(msgId, 'Stimulus is empty.')
            end
            
            % reshape
            obj.stim = reshape(obj.stim, obj.height, obj.width, ...
                obj.channels, obj.length);
			obj.stim = flipud(permute(obj.stim, [2 1 3 4]));
            disp([obj.baseMsgId ' - Successfully loaded stimulus from ' ...
                'file "' fileName '".'])
        end            
        
        function save(obj, fileName)
            % stim.save(fileName) saves a stimulus to a binary file
            % FILENAME. A saved stimulus can then be re-loaded with the
            % stimulus' LOAD method.
            %
            % FILENAME  - A string enclosed in single quotation marks that
            %             specifies the name of the file to create.
            if nargin<2,fileName=[obj.name '.dat'];end
            fid = fopen(fileName,'w');
            if fid == -1
				msgId = [obj.baseMsgId ':filePermission'];
				msg = ['Could not open "' fileName '" with write ' ...
					'permission.'];
				error(msgId, msg);
            end
            
            if obj.length == 0
				msgId = [obj.baseMsgId ':stimEmpty'];
                error(msgId, 'Stimulus is empty. Nothing to save.')
            end
            
            % check whether fwrite is successful
            wrErr = false;
            
            % start with file signature
            sign = obj.fileSignature; % some random number
            cnt=fwrite(fid,sign,'int');           wrErr = wrErr | (cnt~=1);
            
            % include version number
            cnt=fwrite(fid,obj.version,'float');  wrErr = wrErr | (cnt~=1);
			
			% include stimulus type
			if ~isfield(obj.supportedStimTypes, class(obj))
				msgId = [obj.baseMsgId ':stimTypeMismatch'];
				msg = ['Stimulus type "' class(obj) '" is not part of ' ...
					'obj.supportedStimTypes'];
				error(msgId, msg)
			end
			typeInt = eval(['obj.supportedStimTypes.' class(obj)]);
			cnt=fwrite(fid,typeInt,'int');        wrErr = wrErr | (cnt~=1);
            
            % include number of channels (1 for GRAY, 3 for RGB)
            cnt=fwrite(fid,obj.channels,'int8');  wrErr = wrErr | (cnt~=1);
            
            % specify width, height, length
            cnt=fwrite(fid,obj.width,'int');      wrErr = wrErr | (cnt~=1);
            cnt=fwrite(fid,obj.height,'int');     wrErr = wrErr | (cnt~=1);
            cnt=fwrite(fid,obj.length,'int');     wrErr = wrErr | (cnt~=1);
            
            % read stimulus
			ss = permute(flipud(obj.stim), [2 1 3 4]);
            cnt=fwrite(fid,ss*255,'uchar');
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
            % stim.plot(frames, steppingMode), for 1-by-N vector FRAMES,
            % displays the specified frames in the current figure/axis
            % handle. If the flag STEPPINGMODE is set to true, the plot
            % will only advance upon pressing one of the key arrows.
            %
            % After the last frame is displayed, press any key to close the
            % window.
            %
            % During plotting, key events can be used to pause, stop, and 
            % step through the frames:
            % - Pressing 'p' will pause plotting until another key is 
            %   pressed.
            % - Pressing 's' will enter stepping mode, where the succeeding 
            %   frame can be reached by pressing the right-arrow key, and
            %   the preceding frame can be reached by pressing the 
            %   left-arrow key. Pressing 's' again will exit stepping mode.
            % - Pressing 'q' will exit plotting.
            %
            % FRAMES       - A list of frame numbers. For example,
            %                requesting frames=[1 2 8] will plot the first,
            %                second, and eighth frame.
            %                Default: Display all frames.
            % STEPPINGMODE - Flag whether to advance to the next frame
            %                automatically (false) or only by pressing
            %                arrow keys (true).
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
            % stim.record(fileName, fps), for a nonnegative number fps,
            % records an AVI movie using the VIDEOWRITER utility and stores
            % the result in a file FILENAME.
            %
            % FILENAME  - A string enclosed in single quotation marks that
            %             specifies the name of the file to create.
            %             Default: 'movie.avi'.
            % FPS       - Rate of playback for the video in frames per
            %             second.
            %             Default: 5.
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
        
        function addNoise(obj, type, frames, options)
            % stim.addNoise(type, frames, options), for a string TYPE and a
            % 1-by-N vector FRAMES, adds noise of a given TYPE to a list of
            % FRAMES. TYPE is a string that specifies any of the following
            % types of noise: 'gaussian', 'localvar', 'poisson', 'salt &
            % pepper', or 'speckle'. OPTIONS encompasses additional
            % optional arguments required for the specific noise type.
            %
            % For example, Gaussian noise with 0.1 mean and 0.01 variance:
            % >> stim.addNoise('gaussian', [], 0.1, 0.01)
            %
            % FRAMES  - A vector of frame numbers to which noise shall be
            %           added. Use the empty array to denote all frames.
            %           Default: [].
            % TYPE    - A string that specifies any of the following noise
            %           types. Default is 'gaussian'.
            %           'gaussian'      - Gaussian with constant mean (1st
            %                             additional argument) and variance
            %                             (2nd additional argument).
            %                             Default: 0.0, 0.01.
            %           'localvar'      - Zero-mean, Gaussian white noise
            %                             of a certain local variance (1st
            %                             additional argument; must be of
            %                             size width-by-height).
            %           'poisson'       - Generates Poisson noise from the
            %                             data instead of adding additional
            %                             noise.
            %           'salt & pepper' - Salt and pepper noise of a
            %                             certain noise density d (1st
            %                             additional argument).
            %                             Default: 0.05.
            %           'speckle'       - Multiplicative noise, using the
            %                             equation J=I+n*I, where n is
            %                             uniformly distributed random
            %                             noise with zero mean and variance
            %                             v (1st additional argument).
            %                             Default: 0.04.
            %
            % OPTIONS - Additional arguments as required by the noise types
            %           described above.
            if nargin<2,type='poisson';end
            if nargin<3 || isempty(frames),frames=1:obj.length;end
            if nargin<4,options={};end
            
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
            % stim.popFront(numFrames), for a scalar NUMFRAMES, removes the
            % first NUMFRAMES number of stimulus frames.
            obj.erase(1:numFrames);
        end
        
        function popBack(obj, numFrames)
            % stim.popBack(numFrames), for a scalar NUMFRAMES, removes the
            % last NUMFRAMES number of stimulus frames.
            obj.erase(end-numFrames+1:end);
        end
        
        function erase(obj, frames)
            % stim.erase(frames), for a scalar or 1-by-N vector FRAMES,
            % erases specific stimulus frames.
            %
            % For example, remove the first and third frame:
            % >> stim.erase([1 3])
            obj.stim(:,:,:,frames) = [];
            obj.length = size(obj.stim,4);
            disp([obj.baseMsgId ' - Erased frames [' num2str(frames) ']'])
        end
        
        function rgb2gray(obj)
            % stim.rgb2gray() converts an existing RGB stimulus to
            % grayscale format. If the stimulus is already in grayscale 
            % format, the stimulus remains unchanged.
            if obj.channels == 1
                return
            end
            
            assert(obj.channels == 3)
            obj.stim = mean(obj.stim, 3);
            obj.channels = 1;
            disp([obj.baseMsgId ' - Stimulus successfully converted ' ...
                'to grayscale.'])
        end
        
        function gray2rgb(obj)
            % stim.gray2rgb() converts an existing grayscale stimulus to
            % RGB format. If the stimulus is already in RGB format, the
            % stimulus remains unchanged.
            if obj.channels == 3
                return
			end
            
            assert(obj.channels == 1)
            channel = obj.stim;
            obj.stim(:,:,1,:) = channel;
            obj.stim(:,:,2,:) = channel;
            obj.stim(:,:,3,:) = channel;
			obj.channels = 3;
            disp([obj.baseMsgId ' - Stimulus successfully converted ' ...
                'to RGB.'])
        end
        
        function resize(obj, dim)
            % stim.resize(dim), for a scalar or 1-by-2 vector DIM, resizes
            % an existing stimulus according to a scaling factor DIM or to
            % a specific canvas size [DIM(1) DIM(2)]==[height width]. If
            % the stimulus already has the appropriate dimensions, the
            % stimulus remains unchanged.
            assert(numel(dim)<=2)
            if numel(dim)==2 && dim(1)==obj.height && dim(2)==obj.width
                return
            end
            
            obj.stim = imresize(obj.stim, dim);
            obj.height = size(obj.stim, 1);
            obj.width = size(obj.stim, 2);
        end
    end
    
    %% Protected Methods
    methods (Hidden, Access = protected)
        function appendFrames(obj, frames)
            % Private method to append frames to existing stimulus.
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
        
        function initDefaultParams(obj)
            % Private method to initialize all base class properties with
            % default values. The method also calls an initializer for
            % parameters of the derived class, which is an abstract method
            % that needs to be implemented by each child class.
            
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
			
			% the following stimulus types are supported
			obj.supportedStimTypes = struct( ...
				'GratingStim', 0, ...
				'PlaidStim', 1, ...
				'DotStim', 2, ...
				'BarStim', 3, ...
				'PictureStim', 4, ...
				'MovieStim', 5, ...
				'CompoundStim', 6);
                        
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
		
		function rgb = char2rgb(obj, character)
			% rgb = char2rgb(character) converts a single character
			% (ColorSpec) to a 3-element vector (RGB).
			% Supported colors are: 'k' (black), 'b' (blue), 'g' (green),
			% 'c' (cyan), 'r' (red), 'm' (magenta), 'y' (yellow), and 'w'
			% (white).
			if numel(character) ~= 1 || ~ischar(character)
				msgId = [obj.baseMsgId ':typeMismatch'];
				msg = 'Color must be a single character.';
				error(msgId, msg)
			end
			
			f = strfind('kbgcrmyw', lower(character));
			if isempty(f)
				msgId = [obj.baseMsgId ':unknownColor'];
                msg = ['Color must be one of kbgcrmyw, ' character ...
					' found'];
                error(msgId, msg)
			end
			
			rgb = rem(floor((f - 1) * [0.25 0.5 1]), 2);
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
        
        interactiveMode;    % flag whether key press events are active
                            % these need to be deactivated in order to
                            % record a stim to AVI format
    end
    
    properties (Hidden, SetAccess = private, GetAccess = protected)
        version;
        fileSignature;
		supportedStimTypes;
    end
    
    properties (Hidden, Abstract, Access = protected)
        baseMsgId;          % string prepended to error messages
        name;               % string describing the stimulus type
		colorChar;          % single-character specifying stimulus color
		colorVec;           % 3-element vector specifying stimulus color
		stimType;           % integer from obj.supportedStimTypes
    end
end
