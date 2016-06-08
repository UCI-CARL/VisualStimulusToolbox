classdef GratingStim < BaseStim
    methods (Access = public)
        function obj = GratingStim(dimWHC, length, dir, freq, contrast, ...
                phase)
            obj.initDefaultParams();

            obj.width = dimWHC(1);
            obj.height = dimWHC(2);
            if numel(dimWHC) > 2
                obj.channels = dimWHC(3);
            else
                obj.channels = 1;
            end
            assert(obj.channels == 1)
            
            if nargin >= 2
                if nargin<3,dir=obj.dir;end
                if nargin<4,freq=obj.freq;end
                if nargin<5,contrast=obj.contrast;end
                if nargin<6,phase=obj.phase;end
                
                % shortcut to create and add
                obj.add(length, dir, freq, contrast, phase);
            end
        end
        
        function add(obj, length, dir, freq, contr, phase)
            % Issue: Should add overwrite obj.properties? What if
            % constructor sets them, then we repeatedly call add with args,
            % then we call add without args. What should happen?
            if nargin<3,dir=obj.dir;end
            if nargin<4,freq=obj.freq;end
            if nargin<5,contr=obj.contrast;end
            if nargin<6,phase=obj.phase;end
                
            % TODO parse input
            
            % create rectangular 3D grid
            x = (1:obj.width) - ceil(obj.width/2);
            y = (1:obj.height) - ceil(obj.height/2);
            t = 0:length-1;
            [x,y,t] = ndgrid(x,y,t);
            
            sinGrating = cos(2*pi*freq(1)*cos(dir).*x ...
                + 2*pi*freq(1)*sin(dir).*y ...
                - 2*pi*freq(2).*t ...
                + 2*pi*phase);
            sinGrating = contr.*sinGrating/2 + 0.5;
            
            % use append method from base class to append frames
            % TODO generalize to 3 channels
            frames(:,:,1,:) = sinGrating;
            obj.appendFrames(frames);
        end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.dir = 0;
            obj.freq = [0.1 0.1];
            obj.contrast = 1;
            obj.phase = 0;
            obj.baseMsgId = 'VisualStimulus:GratingStim';
        end
    end

    properties (GetAccess = protected)
        baseMsgId;
    end
    
    properties (Access = private)
        dir;
        freq;
        contrast;
        phase;
    end
end
    