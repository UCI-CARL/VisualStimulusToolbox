classdef CompoundStim < BaseStim
    %% Public Methods
    methods (Access = public)
        function obj = CompoundStim(dimHW)
            % compound = CompoundStim(dimHW), for 1-by-2 vector DIMHW,
            % creates a stimulus compound made of two or more distinct
            % stimulus types.
            %
            % Stimuli can be combined with the + operator, e.g.:
            % >> res = GratingStim([10 20],'g',10) + DotStim([10 20],'r',4)
            % Whenever two or more stimuli are combined that have distinct
            % stimulus types, the result is a compound stimulus.
            %
			% DIMHW      - 1-by-2 stimulus dimensions: [height width].
			%              Default: [0 0].
            if nargin == 0
                obj.height = 0;
                obj.width = 0;
            else
                obj.height = dimHW(1);
                obj.width = dimHW(2);
            end
            
            % initialize default parameter values
            obj.initDefaultParams();
            
            % compound is always RGB
            obj.channels = 3;
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.baseMsgId = 'VisualStimulus:CompoundStim';
            obj.name = 'CompoundStim';
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
