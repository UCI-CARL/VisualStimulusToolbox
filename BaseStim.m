classdef (Abstract) BaseStim < matlab.mixin.Copyable
    %% Public Methods for All Derived Classes
    methods (Access = public)
        function new = clone(obj)
            %new = clone(obj) makes a deep copy of the object
            new = copy(obj);
        end
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
end
