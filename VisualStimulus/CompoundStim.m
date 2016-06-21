classdef CompoundStim < BaseStim
    methods (Access = public)
        function obj = CompoundStim(dimHWC)
			if nargin==0,dimHWC=[0 0 1];end
			
            obj.height = dimHWC(1);
            obj.width = dimHWC(2);
            if numel(dimHWC) > 2
                obj.channels = dimHWC(3);
            else
                obj.channels = 1;
            end
            assert(obj.channels == 1)
            
            % needs width/height
            obj.initDefaultParams();
        end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:CompoundStim';
            obj.name = 'CompoundStim';
        end
    end

    properties (Access = protected)
        baseMsgId;
        name;
    end
    
    properties (Access = private)
    end
end
    