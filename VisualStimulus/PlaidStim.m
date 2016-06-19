classdef PlaidStim < BaseStim
    methods (Access = public)
        function obj = PlaidStim(dimHWC, length, plaidDir, gratFreq, ...
                plaidAngle, plaidContrast)
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
            
            if nargin >= 2
                if nargin<3,plaidDir=obj.plaidDir;end
                if nargin<4,gratFreq=obj.gratFreq;end
                if nargin<5,plaidAngle=obj.plaidAngle;end
                if nargin<6,plaidContrast=obj.plaidContrast;end
                
                % shortcut to create and add
                obj.add(length, plaidDir, gratFreq, plaidAngle, ...
                    plaidContrast);
            end
        end
        
        function add(obj, length, plaidDir, gratFreq, plaidAngle, ...
                plaidContrast)
            % plaid.add(length, plaidDir, gratFreq, plaidAngle, 
            % plaidContrast) drifting plaid stimulus with mean intensity 
            % value 128 and a contrast of value PLAIDCONTRAST to your
            % existing stimulus object.
            % The plaid stimulus is made of two sinusoidal gratings 
            % ("grating components") separated by a specified PLAIDANGLE.
            %
            % LENGTH        - The number of frames to create.
            %                 Default is 10.
            %
            % PLAIDDIR      - The drifting direction of the stimulus in 
            %                 degrees (0=rightwards, 90=upwards; angle 
            %                 increases counterclockwise). Default is 0.
            %
            % GRATFREQ      - 2-D vector of stimulus frequency for the
            %                 grating components. The first vector element
            %                 is the spatial frequency (cycles/pixels), 
            %                 whereas the second vector element is the 
            %                 temporal frequency (cycles/frame). 
            %                 Default is [0.1 0.1].
            %
            % PLAIDANGLE    - The angle between the grating components in
            %                 degrees. Default is 120 degrees.
            %
            % PLAIDCONTRAST - The grating contrast. Default is 1.
            if nargin<3,plaidDir=obj.plaidDir;end
            if nargin<4,gratFreq=obj.gratFreq;end
            if nargin<5,plaidAngle=obj.plaidAngle;end
            if nargin<6,plaidContrast=obj.plaidContrast;end
            % Issue: Should add overwrite obj.properties? What if
            % constructor sets them, then we repeatedly call add with args,
            % then we call add without args. What should happen?
            
%             validateattributes(length, {'numeric'}, ...
%                 {'integer','positive'}, 'add', 'length')
%             validateattributes(plaidDir, {'numeric'}, {'real'}, 'add', ...
%                 'direction')
%             validateattributes(speed, {'numeric'}, ...
%                 {'integer','nonnegative'}, 'add', 'speed')
%             validateattributes(density, {'numeric'}, ...
%                 {'real','>=',0,'<=',1}, 'add', 'density')
%             validateattributes(coherence, {'numeric'}, ...
%                 {'real','>=',0,'<=',1}, 'add', 'coherence')
%             validateattributes(radius,{'numeric'},{'real'},'add','radius')
            
            % TODO parse input
            
            grating1 = GratingStim([obj.height obj.width obj.channels], ...
                length, mod(plaidDir-plaidAngle/2, 360), gratFreq, ...
                plaidContrast/2, 0);
            grating2 = GratingStim([obj.height obj.width obj.channels], ...
                length, mod(plaidDir+plaidAngle/2, 360), gratFreq, ...
                plaidContrast/2, 0);
            
            plaid(:,:,1,:) = grating1.stim + grating2.stim - 0.5;
            obj.appendFrames(plaid);
       end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.plaidDir = 0;
            obj.gratFreq = [0.1 0.1];
            obj.plaidAngle = 120;
            obj.plaidContrast = 1;
            obj.baseMsgId = 'VisualStimulus:PlaidStim';
            obj.name = 'PlaidStim';
        end
    end
    
    properties (Access = protected)
        baseMsgId;
        name;
    end
    
    properties (Access = private)
        plaidDir;
        gratFreq;
        plaidAngle;
        plaidContrast;
    end
end
