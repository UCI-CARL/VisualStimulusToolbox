classdef PictureStim < BaseStim
    methods (Access = public)
        function obj = PictureStim(fileName, length)
            if nargin == 0
                obj.height = 0;
                obj.width = 0;
                obj.channels = 0;
                obj.initDefaultParams()
                return
            end
            
            img = double(flipud(imread(fileName))) / 255;
			
            obj.height = size(img, 1);
            obj.width = size(img, 2);
            obj.channels = size(img, 3);
            
            obj.initDefaultParams();
            
            % reproduce for length frames
            img = repmat(img, 1, 1, 1, length);
            
            obj.appendFrames(img)
        end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:PictureStim';
            obj.name = 'PictureStim';
			obj.stimType = eval(['obj.supportedStimTypes.' obj.name]);
        end
    end

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
    