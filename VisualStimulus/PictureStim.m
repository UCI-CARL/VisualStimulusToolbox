classdef PictureStim < BaseStim
    methods (Access = public)
        function obj = PictureStim(fileName)
            if nargin == 0
                obj.height = 0;
                obj.width = 0;
                obj.channels = 0;
                obj.initDefaultParams()
                return
            end
            
            img = double(flipud(imread(fileName))) / 255;
			size(img)
			
            obj.height = size(img, 1);
            obj.width = size(img, 2);
            obj.channels = size(img, 3);
            
            obj.initDefaultParams();
            
            obj.appendFrames(img)
        end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:PictureStim';
            obj.name = 'PictureStim';
        end
    end

    properties (Access = protected)
        baseMsgId;
        name;
    end
    
    properties (Access = private)
    end
end
    