classdef MovieStim < BaseStim
    methods (Access = public)
        function obj = MovieStim(fileName)
            if nargin == 0
                obj.height = 0;
                obj.width = 0;
                obj.channels = 0;
                obj.initDefaultParams()
                return
            end
            
            vidObj = VideoReader(fileName);
            obj.height = vidObj.Height;
            obj.width = vidObj.Width;
            if strfind(lower(vidObj.VideoFormat), 'rgb')
                obj.channels = 3;
            else
                obj.channels = 1;
            end
            
            obj.initDefaultParams()
            
            while hasFrame(vidObj)
                frame = double(flipud(readFrame(vidObj))) / 255;
                obj.appendFrames(frame)
            end
        end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:MovieStim';
            obj.name = 'MovieStim';
        end
    end

    properties (Access = protected)
        baseMsgId;
        name;
    end
    
    properties (Access = private)
    end
end
    