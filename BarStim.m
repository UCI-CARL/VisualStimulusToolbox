classdef BarStim < BaseStim
    methods (Access = public)
        function obj = BarStim(dimWHC)
            obj.width = dimWHC(1);
            obj.height = dimWHC(2);
            obj.channels = dimWHC(3);
            obj.length = 0;
            obj.stim = [];
        end
        
        function setLength(obj, n)
            obj.length = n;
        end
    
        function plot(obj)
            disp('Plotting BarStim')
        end
    end
end
    