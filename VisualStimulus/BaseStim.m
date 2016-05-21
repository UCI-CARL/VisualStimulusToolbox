classdef (Abstract) BaseStim < matlab.mixin.Copyable
    %% Public Methods for All Derived Classes
    methods (Access = public)
        function new = clone(obj)
            %new = clone(obj) makes a deep copy of the object
            new = copy(obj);
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
        
        function addFrames(obj, frames)
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
    end
    
    %% Protected Methods
    methods (Access = protected)
    end
    
    %% Abstract Methods
    methods (Abstract)
        plot(obj)
    end
    
    %% Properties
    properties (SetAccess = protected, GetAccess = public)
        width;                      % stimulus width (pixels)
        height;                     % stimulus height (pixels)
        channels;                   % number of channels (gray=1, RGB=3)
        length;                     % stimulus length (number of frames)
        stim;                       % 3-D matrix width-by-height-by-length
    end
    
    properties (Abstract, GetAccess = protected)
        baseMsgId;
    end
end
