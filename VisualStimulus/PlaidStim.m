classdef PlaidStim < BaseStim
    methods (Access = public)
        function obj = PlaidStim(dimHW, colorChar, length, plaidDir, ...
				gratFreq, plaidAngle, plaidContrast)
			% plaid = PlaidStim(dimHW, colorChar), for 1-by-2 vector
			% DIMHW and single character COLOR, creates a drifting
			% plaid stimulus with dimensions [height width] and color
			% 'k' (black), 'b' (blue), 'g' (green) 'c' (cyan), 'r' (red), 
			% 'm' (magenta), 'y' (yellow), or 'w' (white).
			% The plaid is made of two overlaid sinusoidal gratings.
			%
			% plaid = PlaidStim(dimHW), for vector DIMHW, creates a 
			% grayscale drifting plaid stimulus with dimensions 
			% [height width].
			%
			% plaid = PlaidStim, creates an empty plaid stimulus container.
			% Call plaid.load(fileName) to load a previously saved plaid
			% stimulus.
			%
			% plaid = PlaidStim(dimHW, colorChar, length, plaidDir, 
			% gratFreq, plaidAngle, plaidContrast), creates a drifting 
			% plaid stimulus of LENGTH frames, made of two sinusoidal
			% gratings with GRATFREQ a 1-by-2 vector [spatFreq tempFreq]
			% indicating spatial and temporal frequency of the gratings,
			% PLAIDANGLE indicating the angle in degrees that separates the
			% two gratings, and PLAIDCONTRAST indicating stimulus contrast
			% between 0 and 1.
			%
			% DIMHW         - 1-by-2 stimulus dimensions: [height width].
			%                 Default: [0 0].
			% COLORCHAR     - ColorSpec: 'k' (black), 'b' (blue), 'g'
			%                 (green), 'c' (cyan), 'r' (red), 'm'
			%                 (magenta), 'y' (yellow), and 'w' (white).
			%                 Default: 'w'.
			% LENGTH        - Number of frames to create.
			%                 Default: 0.
			% PLAIDDIR      - Drifting directions in degrees (where
			%                 0=rightward, 90=upward, 180=leftward,
			%                 270=downward).
			%                 Default: 0.
			% GRATFREQ      - 1-by-2 stim frequency: [spatFreq tempFreq].
			%                 Spatial frequency in cycles/pixels, temporal
			%                 frequency in cycles/frame.
			%                 Default: [0.1 0.1]
			% PLAIDANGLE    - The angle between the two grating components
			%                 in degrees.
			%                 Default: 120.
			% PLAIDCONTRAST - Stimulus contrast between 0 and 1.
			%                 Default: 1.
			if nargin == 0
				obj.height = 0;
				obj.width = 0;
			else
				obj.height = dimHW(1);
				obj.width = dimHW(2);
			end
			if nargin<2,colorChar='w';end
			
			% initialize default parameter values
			obj.initDefaultParams();

			% determine whether stimulus should be grayscale or color
			if strcmpi(colorChar, 'w') || strcmpi(colorChar, 'k')
				obj.channels = 1;
			else
				obj.channels = 3;
			end
			obj.colorChar = colorChar;
			obj.colorVec = obj.char2rgb(colorChar);

			% optionally, create stimulus in the same line of code
            if nargin >= 3
                if nargin<4,plaidDir=obj.plaidDir;end
                if nargin<5,gratFreq=obj.gratFreq;end
                if nargin<6,plaidAngle=obj.plaidAngle;end
                if nargin<7,plaidContrast=obj.plaidContrast;end
                                
				validateattributes(length, {'numeric'}, ...
					{'integer','nonnegative'}, 'PlaidStim', 'length')
				validateattributes(plaidDir, {'numeric'}, ...
					{'real','>=',0,'<=',360}, 'PlaidStim', 'plaidDir')
				validateattributes(gratFreq, {'numeric'}, ...
					{'vector', 'real', 'nonnegative'}, 'PlaidStim', ...
					'gratFreq')
				validateattributes(plaidAngle, {'numeric'}, ...
					{'real','>=',0,'<=',360}, 'PlaidStim', 'plaidAngle')
				validateattributes(plaidContrast, {'numeric'}, ...
					{'real','>',0,'<=',1}, 'PlaidStim', 'plaidContr')
				
				% shortcut to create and add
                obj.add(length, plaidDir, gratFreq, plaidAngle, ...
                    plaidContrast);
            end
		end
        
        function add(obj, length, plaidDir, gratFreq, plaidAngle, ...
                plaidContrast)
			% plaid.add(length, plaidDir, gratFreq, plaidAngle, 
			% plaidContrast) appends LENGTH frames of a drifting plaid
			% stimulus to the existing stimulus, where the plaid drifts
			% into direction DIR (between 0 and 360 degrees); with FREQ a 
			% 1-by-2 vector [spatFreq tempFreq] indicating spatial and 
			% temporal frequency of the two grating components, PLAIDANGLE
			% the angle in degrees that separates the two gratings, and
			% CONTRAST indicating stimulus contrast between 0 and 1.
			%
			% plaid.add(length) appends LENGTH frames of a drifting
			% plaid to the existing stimulus, using the plaid
			% specifications from the constructor call.
			%
			% Warning: You cannot add frames to 0-by-0 sized stimulus. Use
			% the empty constructor only to load stimuli.
			%
			% DIMHW         - 1-by-2 stimulus dimensions: [height width].
			%                 Default: [0 0].
			% LENGTH        - Number of frames to create.
			%                 Default: 0.
			% PLAIDDIR      - Drifting directions in degrees (where
			%                 0=rightward, 90=upward, 180=leftward,
			%                 270=downward).
			%                 Default: 0.
			% GRATFREQ      - 1-by-2 stim frequency: [spatFreq tempFreq].
			%                 Spatial frequency in cycles/pixels, temporal
			%                 frequency in cycles/frame.
			%                 Default: [0.1 0.1]
			% PLAIDANGLE    - The angle between the two grating components
			%                 in degrees.
			%                 Default: 120.
			% PLAIDCONTRAST - Stimulus contrast between 0 and 1.
			%                 Default: 1.
            if nargin<3,plaidDir=obj.plaidDir;end
            if nargin<4,gratFreq=obj.gratFreq;end
            if nargin<5,plaidAngle=obj.plaidAngle;end
			if nargin<6,plaidContrast=obj.plaidContrast;end
			
			validateattributes(length, {'numeric'}, ...
				{'integer','nonnegative'}, 'add', 'length')
			validateattributes(plaidDir, {'numeric'}, ...
				{'real','>=',0,'<=',360}, 'add', 'plaidDir')
			validateattributes(gratFreq, {'numeric'}, ...
				{'vector', 'real', 'nonnegative'}, 'add', 'gratFreq')
			validateattributes(plaidAngle, {'numeric'}, ...
				{'real','>=',0,'<=',360}, 'add', 'plaidAngle')
			validateattributes(plaidContrast, {'numeric'}, ...
				{'real','>',0,'<=',1}, 'add', 'plaidContr')
			
			% create the individual grating components
			grating1 = GratingStim([obj.height obj.width], ...
				obj.colorChar, length, mod(plaidDir-plaidAngle/2, 360), ...
				gratFreq, plaidContrast/2, 0);
            grating2 = GratingStim([obj.height obj.width], ...
				obj.colorChar, length, mod(plaidDir+plaidAngle/2, 360), ...
				gratFreq, plaidContrast/2, 0);
            
            plaid = min(1, max(0, grating1.stim + grating2.stim - 0.5));
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
			obj.stimType = eval(['obj.supportedStimTypes.' obj.name]);
			obj.colorChar = 'w';
			obj.colorVec = obj.char2rgb(obj.colorChar);
        end
    end
    
    properties (Access = protected)
        baseMsgId;          % string prepended to error messages
        name;               % string describing the stimulus type
		colorChar;          % single-character specifying stimulus color
		colorVec;           % 3-element vector specifying stimulus color
		stimType;           % integer from obj.supportedStimTypes
    end
    
    properties (Access = private)
        plaidDir;           % drifting direction
        gratFreq;           % spatial and temporal frequency
        plaidAngle;         % angle between grating components
        plaidContrast;      % stimulus contrast
    end
end
