classdef GratingStim < BaseStim
	%% Public Methods
    methods (Access = public)
        function obj = GratingStim(dimHW, colorChar, length, dir, freq, ...
				contrast, phase)
			% grating = GratingStim(dimHW, colorChar), for 1-by-2 vector
			% DIMHW and single character COLOR, creates a drifting
			% sinusoidal grating with dimensions [height width] and color
			% 'k' (black), 'b' (blue), 'g' (green) 'c' (cyan), 'r' (red), 
			% 'm' (magenta), 'y' (yellow), or 'w' (white).
			%
			% grating = GratingStim(dimHW), for vector DIMHW, creates a 
			% grayscale drifting sinusoidal grating with dimensions 
			% [height width].
			%
			% grating = GratingStim, creates an empty grating stimulus
			% container. Call grating.load(fileName) to load a previously
			% saved grating stimulus.
			%
			% grating = GratingStim(dimHW, colorChar, length, dir, freq,
			% contrast, phase), creates a drifting sinusoidal grating of
			% LENGTH frames, drifting into direction DIR (between 0 and 360
			% degrees); with FREQ a 1-by-2 vector [spatFreq tempFreq]
			% indicating spatial and temporal frequency of the grating,
			% CONTRAST indicating stimulus contrast between 0 and 1, and
			% PHASE indicating the initial phase of the sinusoidal grating
			% in periods.
			%
			% DIMHW      - 1-by-2 stimulus dimensions: [height width].
			%              Default: [0 0].
			% COLORCHAR  - ColorSpec: 'k' (black), 'b' (blue), 'g' (green),
			%              'c' (cyan), 'r' (red), 'm' (magenta), 'y' 
			%              (yellow), and 'w' (white).
			%              Default: 'w'.
			% LENGTH     - Number of frames to create.
			%              Default: 0.
			% DIR        - Drifting directions in degrees (where
			%              0=rightward, 90=upward, 180=leftward,
			%              270=downward).
			%              Default: 0.
			% FREQ       - 1-by-2 stimulus frequency: [spatFreq tempFreq].
			%              Spatial frequency in cycles/pixels, temporal
			%              frequency in cycles/frame.
			%              Default: [0.1 0.1]
			% CONTRAST   - Stimulus contrast between 0 and 1.
			%              Default: 1.
			% PHASE      - Initial phase in periods.
			%              Default: 0.
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
                if nargin<4,dir=obj.dir;end
                if nargin<5,freq=obj.freq;end
                if nargin<6,contrast=obj.contrast;end
                if nargin<7,phase=obj.phase;end
                
				validateattributes(length, {'numeric'}, ...
					{'integer','nonnegative'}, 'GratingStim', 'length')
				validateattributes(dir, {'numeric'}, ...
					{'real','>=',0,'<=',360}, 'GratingStim', 'dir')
				validateattributes(freq, {'numeric'}, ...
					{'vector', 'real', 'nonnegative'}, 'GratingStim', ...
					'freq')
				validateattributes(contrast, {'numeric'}, ...
					{'real','>',0,'<=',1}, 'GratingStim', 'contr')
				
				% shortcut to create and add
                obj.add(length, dir, freq, contrast, phase);
            end
        end
        
        function add(obj, length, dir, freq, contrast, phase)
			% grating.add(length, dir, freq, contrast, phase) appends
			% LENGTH frames of a drifting sinusoidal grating to the
			% existing stimulus, where the grating drifts into direction
			% DIR (between 0 and 360 degrees); with FREQ a 1-by-2 vector
			% [spatFreq tempFreq] indicating spatial and temporal frequency
			% of the grating, CONTRAST indicating stimulus contrast between
			% 0 and 1, and PHASE indicating the initial phase of the 
			% sinusoidal grating in periods.
			%
			% grating.add(length) appends LENGTH frames of a drifting
			% sinusoidal grating to the existing stimulus, using the
			% grating specifications from the constructor call.
			%
			% Warning: You cannot add frames to 0-by-0 sized stimulus. Use
			% the empty constructor only to load stimuli.
			%
            % This method uses a script initially authored by Timothy Saint 
            % and Eero P. Simoncelli at NYU.
            %
			% DIMHW      - 1-by-2 stimulus dimensions: [height width].
			%              Default: [0 0].
			% LENGTH     - Number of frames to create.
			%              Default: 0.
			% DIR        - Drifting directions in degrees (where
			%              0=rightward, 90=upward, 180=leftward,
			%              270=downward).
			%              Default: 0.
			% FREQ       - 1-by-2 stimulus frequency: [spatFreq tempFreq].
			%              Spatial frequency in cycles/pixels, temporal
			%              frequency in cycles/frame.
			%              Default: [0.1 0.1]
			% CONTRAST   - Stimulus contrast between 0 and 1.
			%              Default: 1.
			% PHASE      - Initial phase in periods.
			%              Default: 0.
            if nargin<3,dir=obj.dir;end
            if nargin<4,freq=obj.freq;end
            if nargin<5,contrast=obj.contrast;end
            if nargin<6,phase=obj.phase;end
			
			if obj.height == 0 || obj.width == 0
				msgId = [obj.baseMsgId ':InvalidStimulusDimensions'];
				msg = 'Cannot add frames to 0-by-0 stimulus.';
				error(msgId, msg)
			end
			
            validateattributes(length, {'numeric'}, ...
                {'integer','nonnegative'}, 'add', 'length')
            validateattributes(dir, {'numeric'}, ...
                {'real','>=',0,'<=',360}, 'add', 'dir')
			validateattributes(freq, {'numeric'}, ...
				{'vector', 'real', 'nonnegative'}, 'add', 'freq')
			validateattributes(contrast, {'numeric'}, ...
				{'real','>',0,'<=',1}, 'add', 'contr')
			validateattributes(contrast, {'numeric'}, {'real'}, 'add', ...
				'contr')
            
            % create rectangular 3D grid
            x = (1:obj.width) - ceil(obj.width/2);
            y = (1:obj.height) - ceil(obj.height/2);
            t = 0:length-1;
            [x,y,t] = ndgrid(x,y,t);
            
			% single-channel stimulus, float e[0,1]
            channel = cos(2*pi*freq(1)*cos(dir/180*pi).*x ...
                + 2*pi*freq(1)*sin(dir/180*pi).*y ...
                - 2*pi*freq(2).*t ...
                + 2*pi*phase);
            channel = contrast.*channel/2 + 0.5;
			
			% flip X and Y
			channel = permute(channel, [2 1 3]);
			
			% adjust for color
			if obj.channels == 1
				if mean(obj.colorVec) == 1
					% white is highest: stimulus unchanged
					sinGrating(:,:,1,:) = channel;
				else
					% reverse contrast
					sinGrating(:,:,1,:) = 1 - channel;
				end
			else
				sz = size(channel);
				sinGrating = zeros([sz(1:2) obj.channels sz(3)]);
				for c=1:obj.channels
					sinGrating(:,:,c,:) = channel * obj.colorVec(c);
				end
			end
			
			sinGrating = min(1, max(0, sinGrating));
            
            % use append method from base class to append frames
            obj.appendFrames(sinGrating);
        end
	end
    
	%% Protected Methods
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
			% grating.initDefaultParamsDerived() initializes all derived
			% class properties with default values.
            obj.dir = 0;
            obj.freq = [0.1 0.1];
            obj.contrast = 1;
            obj.phase = 0;

			obj.baseMsgId = 'VisualStimulus:GratingStim';
            obj.name = 'GratingStim';
			obj.stimType = eval(['obj.supportedStimTypes.' obj.name]);
			obj.colorChar = 'w';
			obj.colorVec = obj.char2rgb(obj.colorChar);
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
        dir;                % drifting direction
        freq;               % spatial and temporal frequency
        contrast;           % stimulus contrast
        phase;              % initial phase
    end
end
    