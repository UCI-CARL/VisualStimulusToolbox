classdef MovieStim < BaseStim
	%% Public Methods
    methods (Access = public)
        function obj = MovieStim(fileName)
			% mov = MovieStim(fileName), for string FILENAME, creates a 
			% stimulus from a video file FILENAME.
			%
			% mov = MovieStim, creates an empty movie stimulus container.
			% Call mov.load(fileName) to load a previously saved movie
			% stimulus.
			%
			% Other movies can be added to the stimulus via method ADD.
			% If any of the added movies has multiple channels (e.g., RGB),
			% the entire stimulus will be converted (e.g., to RGB).
			% If any of the added movies has different dimensions, the
			% newly added movies will be converted to the size of the
			% previous stimulus.
			%
            % FILENAME  - A string enclosed in single quotation marks that
            %             specifies the name of the file to load.
			obj.height = 0;
			obj.width = 0;
			obj.channels = 0;
			
			% initialize default parameter values
            obj.initDefaultParams();
			
			if nargin > 0
				if nargin<2,length=1;end
				
				validateattributes(fileName, {'char'}, {}, ...
					'PictureStim', 'fileName')
				
				% shortcut to create and add
				obj.add(fileName);
			end
		end
		
		function add(obj, fileName)
			% pic.add(fileName), for string FILENAME, reads a movie from
			% file FILENAME and appends it to the existing stimulus.
			%
			% If any of the added images has multiple channels (e.g., RGB),
			% the entire stimulus will be converted (e.g., to RGB).
			%
			% If any of the added images has different dimensions, the
			% newly added images will be converted to the size of the
			% previous stimulus.
			%
            % FILENAME  - A string enclosed in single quotation marks that
            %             specifies the name of the file to load.
			% LENGTH     - Number of frames to create.
			%              Default: 1.
			validateattributes(fileName, {'char'}, {}, 'PictureStim', ...
				'fileName')

			% create video object from file
			vidObj = VideoReader(fileName);
			
			% update stimulus dimensions
			if obj.height == 0 || obj.width == 0 || obj.channels == 0
				obj.height = vidObj.Height;
				obj.width = vidObj.Width;
				if strfind(lower(vidObj.VideoFormat), 'rgb')
					obj.channels = 3;
				else
					obj.channels = 1;
				end
			end
			
			% adjust color channels
			if strfind(lower(vidObj.VideoFormat), 'rgb') && ...
					obj.channels == 1
				obj.gray2rgb();
			end
			
			if ismember('hasFrame', methods('VideoReader'))
				while hasFrame(vidObj)
					% newer method: read single frame
					frame = double(flipud(readFrame(vidObj))) / 255;

					% adjust size and pixels
					frame = imresize(frame, [obj.height obj.width]);
					frame = min(1, max(0, frame));
					
					% use append method to add single frame
					obj.appendFrames(frame)
				end
			else
				frames = double(flipud(read(vidObj))) / 255;
				
				% adjust size and pixels
				frames = imresize(frames, [obj.height obj.width]);
				frames = min(1, max(0, frames));
				
				% use append method to add all frames
				obj.appendFrames(frames);
			end
		end
	end
    
	%% Protected Methods
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:MovieStim';
            obj.name = 'MovieStim';
			obj.stimType = eval(['obj.supportedStimTypes.' obj.name]);
        end
	end

	%% Properties
    properties (Access = protected)
        baseMsgId;          % string prepended to error messages
        name;               % string describing the stimulus type
		colorChar;          % single-character specifying stimulus color
		colorVec;           % 3-element vector specifying stimulus color
		stimType;           % integer from obj.supportedStimTypes
    end
    
    properties (Access = private)
    end
end
    