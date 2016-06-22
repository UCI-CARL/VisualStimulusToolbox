classdef PictureStim < BaseStim
	%% Public Methods
    methods (Access = public)
        function obj = PictureStim(fileName, length)
			% pic = PictureStim(fileName, length), for string FILENAME and
			% scalar LENGTH, reads an image from file FILENAME and creates
			% a stimulus of LENGTH frames.
			%
			% pic = PictureStim, creates an empty picture stimulus
			% container. Call pic.load(fileName) to load a previously saved
			% picture stimulus.
			%
			% Other images can be added to the stimulus via method ADD.
			% If any of the added images has multiple channels (e.g., RGB),
			% the entire stimulus will be converted (e.g., to RGB).
			% If any of the added images has different dimensions, the
			% newly added images will be converted to the size of the
			% previous stimulus.
			%
            % FILENAME  - A string enclosed in single quotation marks that
            %             specifies the name of the file to load.
			% LENGTH     - Number of frames to create.
			%              Default: 1.
			obj.height = 0;
			obj.width = 0;
			obj.channels = 0;
			
			% initialize default parameter values
            obj.initDefaultParams();
			
			if nargin > 0
				if nargin<2,length=1;end
				
				validateattributes(fileName, {'char'}, {}, ...
					'PictureStim', 'fileName')
				validateattributes(length, {'numeric'}, ...
					{'integer','nonnegative'}, 'PictureStim', 'length')
				
				% shortcut to create and add
				obj.add(fileName, length);
			end
		end
		
		function add(obj, fileName, length)
			% pic.add(fileName, length), for string FILENAME and scalar
			% LENGTH, reads an image from file FILENAME and appends LENGTH
			% frames to the existing stimulus.
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
			if nargin<3,length=1;end

			validateattributes(fileName, {'char'}, {}, 'PictureStim', ...
				'fileName')
			validateattributes(length, {'numeric'}, ...
				{'integer','nonnegative'}, 'PictureStim', 'length')
			
			% read image and reproduce for LENGTH
            img = double(flipud(imread(fileName))) / 255;
            img = repmat(img, 1, 1, 1, length);
			
			% update stimulus dimensions
			if obj.height == 0 || obj.width == 0 || obj.channels == 0
	            obj.height = size(img, 1);
		        obj.width = size(img, 2);
				obj.channels = size(img, 3);
			end
			
			% adjust color channels
			if obj.channels == 1 && size(img,3) == 3
				obj.gray2rgb();
			end
			
			% adjust size and pixel values
			img = imresize(img, [obj.height obj.width]);
			img = min(1, max(0, img));
			
			% use append method from base class to append frames
            obj.appendFrames(img)
		end
	end
    
	%% Protected Methods
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:PictureStim';
            obj.name = 'PictureStim';
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
    