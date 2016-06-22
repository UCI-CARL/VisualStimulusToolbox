classdef BarStim < BaseStim
	%% Public Methods
    methods (Access = public)
        function obj = BarStim(dimHW, colorChar, length, dir, speed, ...
				barWidth, edgeWidth, pxBtwBars, startPos)
			% bar = BarStim(dimHW, colorChar), for 1-by-2 vector DIMHW and
			% single character COLOR, creates a drifting bar stimulus
			% with dimensions [height width] and color 'k' (black), 'b' 
			% (blue), 'g' (green) 'c' (cyan), 'r' (red), 'm' (magenta),
			% 'y' (yellow), or 'w' (white).
			%
			% bar = BarStim(dimHW), for vector DIMHW, creates a drifting
			% bar stimulus with dimensions [height width].
			%
			% bar = BarStim, creates an empty bar stimulus container.
			% Call grating.load(fileName) to load a previously saved bar
			% stimulus.
			%
			% bar = BarStim(dimHW, colorChar, length, dir, speed, barWidth
			% edgeWidth, pxBtwBars, startPos), creates a drifting bar
			% stimulus of LENGTH frames, drifting into direction DIR 
			% (between 0 and 360 degrees) with speed SPEED (in pixels per
			% frame); with BARWIDTH indicating the width of the center of
			% the bar (in pixels), EDGEWIDTH indicating the width of the
			% cosine edges of the bar (in pixels), PXBTWNBARS indicating
			% the number of pixels between the bars, and STARTPOS
			% indicating the starting position of the first bar (in
			% pixels).
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
            % SPEED      - The speed of the bar in pixels/frame.
            %              Default: 1.
            % BARWIDTH   - The width of the center of the bar in pixels.
            %              Default: 1.
            % EDGEWIDTH  - The width of the cosine edges of the bar in
            %              pixels. An edge of width EDGEWIDTH will be
            %              tacked onto both sides of the bar, so the
            %              total width will be BARWIDTH + 2*EDGEWIDTH.
            %              Default: 3.
            % PXBTWNBARS - The number of pixels between the bars in the
            %              stimulus.
			%              Default: image width.
            % STARTPOS   - The starting position of the first bar in
            %              pixels. The coordinate system is a line lying
            %              along the direction of the bar motion and
            %              passing through the center of the stimulus.
            %              The point 0 is the center of the stimulus.
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
                if nargin<4,dir=obj.direction;end
                if nargin<5,speed=obj.speed;end
                if nargin<6,barWidth=obj.barWidth;end
                if nargin<7,edgeWidth=obj.edgeWidth;end
                if nargin<8,pxBtwBars=obj.pxBtwBars;end
                if nargin<9,startPos=obj.startPos;end

				validateattributes(length, {'numeric'}, ...
					{'integer','nonnegative'}, 'BarStim', 'length')
				validateattributes(dir, {'numeric'}, ...
					{'real','>=',0,'<=',360}, 'BarStim', 'direction')
				validateattributes(speed, {'numeric'}, ...
					{'real', 'nonnegative'}, 'BarStim', 'speed')
				validateattributes(barWidth, {'numeric'}, ...
					{'integer','nonnegative'}, 'BarStim', 'barWidth')
				validateattributes(edgeWidth, {'numeric'}, ...
					{'integer','nonnegative'}, 'BarStim', 'edgeWidth')
				validateattributes(pxBtwBars, {'numeric'}, ...
					{'integer','nonnegative'}, 'BarStim', 'pxBtwBars')
				validateattributes(startPos, {'numeric'}, ...
					{'integer'}, 'BarStim', 'startPos')

				% shortcut to create and add
                obj.add(length, dir, speed, barWidth, ...
                    edgeWidth, pxBtwBars, startPos);
            end
        end
        
        function add(obj, length, dir, speed, barWidth, edgeWidth, ...
				pxBtwBars, startPos)
			% bar.add(length, dir, speed, barWidth, edgeWidth, pxBtwBars,
			% startPos) appends LENGTH frames of a drifting bar stimulus to
			% the existing stimulus, where the bar drifts into direction
			% DIR (between 0 and 360 degrees) with speed SPEED (in pixels
			% per frame); with BARWIDTH indicating the width of the center
			% of the bar (in pixels), EDGEWIDTH indicating the width of the
			% cosine edges of the bar (in pixels), PXBTWNBARS indicating
			% the number of pixels between the bars, and STARTPOS
			% indicating the starting position of the first bar (in
			% pixels).
			%
			% bar.add(length) appends LENGTH frames of a drifting bar
			% stimulus to the existing stimulus, using the bar
			% specifications from the constructor call.
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
            % SPEED      - The speed of the bar in pixels/frame.
            %              Default: 1.
            % BARWIDTH   - The width of the center of the bar in pixels.
            %              Default: 1.
            % EDGEWIDTH  - The width of the cosine edges of the bar in
            %              pixels. An edge of width EDGEWIDTH will be
            %              tacked onto both sides of the bar, so the
            %              total width will be BARWIDTH + 2*EDGEWIDTH.
            %              Default: 3.
            % PXBTWNBARS - The number of pixels between the bars in the
            %              stimulus.
			%              Default: image width.
            % STARTPOS   - The starting position of the first bar in
            %              pixels. The coordinate system is a line lying
            %              along the direction of the bar motion and
            %              passing through the center of the stimulus.
            %              The point 0 is the center of the stimulus.
            %              Default: 0.
            if nargin<8,startPos=obj.startPos;end
            if nargin<7,pxBtwBars=obj.pxBtwBars;end
            if nargin<6,edgeWidth=obj.edgeWidth;end
            if nargin<5,barWidth=obj.barWidth;end
            if nargin<4,speed=obj.speed;end
            if nargin<3,dir=obj.direction;end
            if nargin<2,length=10;end
            
			if obj.height == 0 || obj.width == 0
				msgId = [obj.baseMsgId ':InvalidStimulusDimensions'];
				msg = 'Cannot add frames to 0-by-0 stimulus.';
				error(msgId, msg)
			end
			
			% a bar is basically a single period of a sinusoidal grating
			gratingSf = 1/pxBtwBars;        % spatial freq
			gratingTf = gratingSf * speed;  % temporal freq
			gratingPhase = startPos * gratingSf;
			grating = GratingStim([obj.height obj.width], obj.colorChar);
			grating.add(length, dir, [gratingSf gratingTf], 1, ...
				gratingPhase);
			barStim = grating.stim;
			
			for f=1:size(barStim,4)
				for c=1:size(barStim,3)
					channel = barStim(:,:,c,f);
					
					% inverting grayscale messes with the below code, so we
					% flip the contrast here and then flip the contrast back at
					% the end of the day
					if strcmpi(obj.colorChar, 'k')
						channel = 1 - channel;
					end
					
					% There are three regions:
					% - where stim should be one (centers of the bar)
					% - where stim should be zero (outside the bar)
					% - where it should be in between (edges of the bar)
					barInnerTh = cos(2*pi*gratingSf*barWidth/2);
					barOuterTh = cos(2*pi*gratingSf*(barWidth/2 + edgeWidth));
					wOne = channel >= barInnerTh;
					wEdge = (channel < barInnerTh) & (channel > barOuterTh);
					wZero = channel <= barOuterTh;
					
					% Set the regions to the appropriate level
					channel(wOne) = 1;
					channel(wZero) = 0;
					
					% adjust range to [0,2*pi)
					channel(wEdge) = acos(channel(wEdge));
					
					% adjust range to [0,1] spatial period
					channel(wEdge) = channel(wEdge) / (2*pi*gratingSf);
					channel(wEdge) =  (pi/2)*(channel(wEdge) - barWidth/2)/(edgeWidth);
					channel(wEdge) = cos(channel(wEdge));
					
					% flip contrast back
					if strcmpi(obj.colorChar, 'k')
						barStim(:,:,c,f) = 1 - channel;
					else
						barStim(:,:,c,f) = channel;
					end
				end
			end
			
			barStim = min(1, max(0, barStim));

            % use append method from base class to append frames
            obj.appendFrames(barStim);
        end
	end
    
	%% Protected Methods
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.direction = 0;
            obj.speed = 1;
            obj.barWidth = 1;
            obj.edgeWidth = 3;
            obj.pxBtwBars = obj.width;
            obj.startPos = 0;
            
            obj.baseMsgId = 'VisualStimulus:BarStim';
            obj.name = 'BarStim';
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
        direction;          % drift direction
        speed;              % drift speed
        barWidth;           % width of thecenter of the bar
        edgeWidth;          % width of the cosine used for edges
        pxBtwBars;          % pixels between bars
        startPos;           % starting position of initial bar
    end
end
    