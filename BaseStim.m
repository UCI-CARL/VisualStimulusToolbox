classdef (Abstract) BaseStim < matlab.mixin.Copyable
    %% Public Methods for All Derived Classes
    methods (Access = public)
        function new = clone(obj)
            new = copy(obj);
        end
        
        function r = plus(obj1, obj2)
            if strcmpi(class(obj1), class(obj2))
                % two objects are of the same class: keep type
                r = obj1.clone();
                for i=1:numel(obj2.frames)
                    r.addFrame(obj2.frames(i))
                end
            else
                % two objects are different class: make compound
            end
            disp('plus BaseStim')
            r = obj1;
            for i=1:numel(obj2.frames)
                r.addFrame(obj2.frames(i))
            end
        end
        
    end
    
    %% Abstract Methods
    methods (Abstract)
        plot(obj)
    endp
    
    %% Properties
    properties (SetAccess = protected, GetAccess = public)
        width;                      % stimulus width (pixels)
        height;                     % stimulus height (pixels)
        channels;                   % number of channels (gray=1, RGB=3)
        length;                     % stimulus length (number of frames)
        stim;                       % 3-D matrix width-by-height-by-length
    end
end
