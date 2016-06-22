classdef DotStim < BaseStim
    methods (Access = public)
        %% Public Methods
        function obj = DotStim(dimHW, colorChar, length, dir, speed, ....
                density, coherence, dotRadius)
			% dot = DotStim(dimHW, colorChar), for 1-by-2 vector DIMHW and
			% single character COLOR, creates a drifting random dot cloud
			% with dimensions [height width] and color 'k' (black), 'b' 
            % (blue), 'g' (green) 'c' (cyan), 'r' (red), 'm' (magenta), 
            % 'y' (yellow), or 'w' (white).
			%
			% dot = DotStim(dimHW), for vector DIMHW, creates a grayscale
            % drifting random dot cloud with dimensions [height width].
			%
			% dot = DotStim, creates an empty random dot cloud container.
			% Call dot.load(fileName) to load a previously saved dot cloud.
			%
			% dot = DotStim(dimHW, colorChar, length, dir, speed, density,
			% coherence, dotRadius), creates a drifting random dot cloud of 
            % LENGTH frames, where a fraction COHERENCE drifts coherently 
            % into direction DIR (between 0 and 360 degrees) with speed
            % SPEED (in pixels per frame). The remaining dots all drift
            % into random directions. DENSITY (between 0 and 1) will create
            % roughly DENSITY*height*width dots. DOTRADIUS indicates the
            % size of the dots, with DOTRADIUS<0 indicating single-pixel
            % size.
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
			% SPEED       - 1-by-2 stimulus frequency: [spatFreq tempFreq].
			%              Spatial frequency in cycles/pixels, temporal
			%              frequency in cycles/frame.
			%              Default: [0.1 0.1]
			% DENSITY    - Dot density (between 0 and 1). This will create
			%              roughly DENSITY*height*width dots.
			%              Default: 0.1
			% COHERENCE  - Fraction of dots drifting coherently in a given
			%              direction (between 0 and 1). The remaining dots
			%              drift in random directions.
			%              Default: 1.
			% DOTRADIUS  - Dot radius (in pixels). If DOTRADIUS<0, the dots
			%              will have single-pixel size. If DOTRADIUS>0, the
			%              dots will be Gaussian blobs with Gaussian width
			%              sigma=0.5*DOTRADIUS.
			%              Default: -1.
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
                if nargin<4,dir=obj.dotDirection;end
                if nargin<5,speed=obj.dotSpeed;end
                if nargin<6,density=obj.dotDensity;end
                if nargin<7,coherence=obj.dotCoherence;end
                if nargin<8,dotRadius=obj.dotRadius;end
                
				validateattributes(length, {'numeric'}, ...
					{'integer','nonnegative'}, 'DotStim', 'length')
				validateattributes(dir, {'numeric'}, ...
					{'real','>=',0,'<=',360}, 'DotStim', 'dotDirection')
				validateattributes(speed, {'numeric'}, ...
					{'vector', 'real', 'nonnegative'}, 'DotStim', ...
					'dotSpeed')
				validateattributes(density, {'numeric'}, ...
					{'real','>',0,'<=',1}, 'DotStim', 'contr')
                validateattributes(coherence, {'numeric'}, ...
                    {'real','>=',0,'<=',1}, 'DotStim', 'dotCoherence')
                validateattributes(dotRadius, {'numeric'}, ...
                    {'real'}, 'DotStim', 'dotRadius')
				
                % shortcut to create and add
                obj.add(length, dir, speed, density,...
                    coherence, dotRadius);
            end
        end
        
        function add(obj, length, dir, speed, density, coherence, ...
                dotRadius)
            % dot.add(length, type, dir, speed, density, coherence, radius)
            % appends LENGTH frames of a random dot cloud to the existing
            % stimulus, where a fraction COHERENCE of all dots drift into
            % direction DIR (between 0 and 360 degrees) with speed SPEED
            % (in pixels per frame). Dot density (between 0 and 1)
            % determines how many dots are created (# dots is roughly
            % DENSITY*height*width). The size of the dots is given by
            % DOTRADIUS.
            %
            % dot.add(length) appends LENGTH frames of a random dot cloud
            % to the existing stimulus, using the dot cloud specifications
            % from the constructor call.
            %
			% Warning: You cannot add frames to 0-by-0 sized stimulus. Use
			% the empty constructor only to load stimuli.
			%
            % This method uses a script initially authored by Timothy Saint 
            % and Eero P. Simoncelli at NYU.
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
			% SPEED       - 1-by-2 stimulus frequency: [spatFreq tempFreq].
			%              Spatial frequency in cycles/pixels, temporal
			%              frequency in cycles/frame.
			%              Default: [0.1 0.1]
			% DENSITY    - Dot density (between 0 and 1). This will create
			%              roughly DENSITY*height*width dots.
			%              Default: 0.1
			% COHERENCE  - Fraction of dots drifting coherently in a given
			%              direction (between 0 and 1). The remaining dots
			%              drift in random directions.
			%              Default: 1.
			% DOTRADIUS  - Dot radius (in pixels). If DOTRADIUS<0, the dots
			%              will have single-pixel size. If DOTRADIUS>0, the
			%              dots will be Gaussian blobs with Gaussian width
			%              sigma=0.5*DOTRADIUS.
			%              Default: -1.
            if nargin<3,dir=obj.dotDirection;end
            if nargin<4,speed=obj.dotSpeed;end
            if nargin<5,density=obj.dotDensity;end
            if nargin<6,coherence=obj.dotCoherence;end
            if nargin<7,dotRadius=obj.dotRadius;end
            validateattributes(length, {'numeric'}, ...
                {'integer','positive'}, 'add', 'length')
            validateattributes(dir, {'numeric'}, {'real'}, 'add', ...
                'direction')
            validateattributes(speed, {'numeric'}, ...
                {'integer','nonnegative'}, 'add', 'speed')
            validateattributes(density, {'numeric'}, ...
                {'real','>=',0,'<=',1}, 'add', 'density')
            validateattributes(coherence, {'numeric'}, ...
                {'real','>=',0,'<=',1}, 'add', 'coherence')
            validateattributes(dotRadius,{'numeric'}, {'real'}, 'add', ...
                'radius')
            
			if obj.height == 0 || obj.width == 0
				msgId = [obj.baseMsgId ':InvalidStimulusDimensions'];
				msg = 'Cannot add frames to 0-by-0 stimulus.';
				error(msgId, msg)
			end
			
			if density<0
                if dotRadius<0
                    density = 0.1;
                else
                    density = 0.3/(pi*dotRadius^2);
                end
            end
            
            % make the large dot for sampling
            rLargeDot = linspace(-1.5*dotRadius, 1.5*dotRadius, ...
                ceil(3*dotRadius*obj.sampleFactor));
            largeDot = exp(-rLargeDot.^2 ./ (2.*(dotRadius/2)^2));
            largeDot = largeDot'*largeDot;
            [rLargeDot, cLargeDot] = meshgrid(rLargeDot, rLargeDot);
            
            % There is a buffer area around the image so that we don't 
            % have to worry about getting wraparounds exactly right.
            % This buffer is twice the size of a dot diameter.
            if dotRadius > 0
                bufferSize = 2*ceil(dotRadius*3);
            else
                bufferSize = 5;
            end
            
            % the 'frame' is the field across which the dots drift. The
            % final output of this this function will consist of
            % 'snapshots' of this frame without buffer.
            rowFrame = obj.height + 2.*bufferSize;
            colFrame = obj.width + 2.*bufferSize;
            [rFrame, cFrame] = meshgrid(1:colFrame, 1:rowFrame);
            
            % numDots: # of coherently moving dots in the stimulus
            % numDotsNonCoh: # of noncoherently moving dots
            numDots = round(coherence.*density.*numel(cFrame));
            numDotsNonCoh = round((1-coherence).*density.*numel(cFrame));
            
            % Set the initial dot positions.
            % dotPositions is a matrix of positions of the coherently 
            % moving dots in [x,y] coordinates; each row in dotPositions 
            % stores the position of one dot
            if strcmp(obj.densityStyle, 'exact')
                z = zeros(numel(cFrame), 1);
                z(1:numDots) = 1;
                ord = rand(size(z));
                [~, ord] = sort(ord);
                z = z(ord);
                dotPos = [cFrame(z==1), rFrame(z==1)];
            else
                dotPos = rand(numDots, 2) * [rowFrame 0; 0 colFrame];
            end
            
            % s will store the output. After looping over each frame, we
            % will trim away the buffer from s to obtain the final result
            channel = zeros(rowFrame, colFrame, obj.channels);
            toInterp = -floor(1.5*dotRadius):floor(1.5*dotRadius);
            dSz = floor(1.5*dotRadius);
            
            for t=1:length
                % update the dot positions according to RDK type
                dotVel = [sin(dir/180*pi), cos(dir/180*pi)];
                dotVel = dotVel * speed;
                dotPos = dotPos + repmat(dotVel, size(dotPos, 1), 1);
                
                % wrap around for all dots that have gone past the image
                % borders
                w = find(dotPos(:,1) > rowFrame + 0.5);
                dotPos(w,1) = dotPos(w,1) - rowFrame;
                
                w = find(dotPos(:,1) < 0.5);
                dotPos(w,1) = dotPos(w,1) + rowFrame;
                
                w = find(dotPos(:,2) > colFrame + 0.5);
                dotPos(w,2) = dotPos(w,2) - colFrame;
                
                w = find(dotPos(:,2) < 0.5);
                dotPos(w,2) = dotPos(w,2) + colFrame;
                
                
                % add noncoherent dots and make a vector of dot positions 
                % for this frame only
                dotPosNonCoh = rand(numDotsNonCoh, 2) * ...
                    [rowFrame-1 0; 0 colFrame-1] + 0.5;
                
                % create a temporary matrix of positions for dots to be 
                % shown in this frame
                tmpDotPos = [dotPos; dotPosNonCoh];
                
                % prepare a matrix of zeros for this frame
                thisFrame = zeros(size(cFrame));
                if dotRadius > 0
                    % in each frame, don't show dots near the edges of the
                    % frame. That's why we have a buffer. The reason we
                    % don't show them is that we don't want to deal with
                    % edge handling
                    w1 = find(tmpDotPos(:,1) > (rowFrame - bufferSize + ...
                        + 1.5*dotRadius));
                    w2 = find(tmpDotPos(:,1) < (bufferSize - 1.5*dotRadius));
                    w3 = find(tmpDotPos(:,2) > (colFrame - bufferSize + ...
                        + 1.5*dotRadius));
                    w4 = find(tmpDotPos(:,2) < (bufferSize - 1.5*dotRadius));
                    w = [w1; w2; w3; w4];
                    tmpDotPos(w,:) = [];
                    
                    % add the dots to thisFrame
                    for p = 1:size(tmpDotPos, 1)
                        % find the center point of the current dot, in 
                        % thisFrame coordinates. This is where the dot will
                        % be placed.
                        cpX = round(tmpDotPos(p, 1));
                        cpY = round(tmpDotPos(p, 2));
                        
                        rToInterp = toInterp + (round(tmpDotPos(p,1)) - ...
                            tmpDotPos(p,1));
                        cToInterp = toInterp + (round(tmpDotPos(p,2)) - ...
                            tmpDotPos(p,2));
                        [rToInterp, cToInterp] = meshgrid(rToInterp, ...
                            cToInterp);
                        thisSmallDot = interp2(rLargeDot, cLargeDot, ...
                            largeDot, rToInterp, cToInterp, ...
                            obj.interpMethod);
                        
                        % now add this small dot to the frame.
                        thisFrame(cpX-dSz:cpX+dSz, cpY-dSz:cpY+dSz) = ...
                            thisFrame(cpX-dSz:cpX+dSz, cpY-dSz:cpY+dSz) ...
                            + thisSmallDot;
                        
                    end
                else
                    tmpDotPos(tmpDotPos(:,1) > rowFrame, :) = [];
                    tmpDotPos(tmpDotPos(:,1) < 1, :) = [];
                    tmpDotPos(tmpDotPos(:,2) > colFrame, :) = [];
                    tmpDotPos(tmpDotPos(:,2) < 1, :) = [];
                    tmpDotPos = round(tmpDotPos);
                    
                    w = sub2ind(size(thisFrame), tmpDotPos(:,1), ...
                        tmpDotPos(:,2));
                    
                    thisFrame(w) = 1;
                end
                % Add this frame to the final output
                channel(:,:,t) = thisFrame;
            end
            % Now trim away the buff
            channel = channel(bufferSize+1:end-bufferSize, ...
                bufferSize+1:end-bufferSize, :);
            channel(channel>1) = 1;
            
            % adjust for color
			if obj.channels == 1
				if mean(obj.colorVec) == 1
					% white is highest: stimulus unchanged
					dotCloud(:,:,1,:) = channel;
				else
					% reverse contrast
					dotCloud(:,:,1,:) = -channel + 1;
				end
			else
				sz = size(channel);
				dotCloud = zeros([sz(1:2) obj.channels sz(3)]);
				for c=1:obj.channels
					dotCloud(:,:,c,:) = channel * obj.colorVec(c);
				end
            end
            
            dotCloud = min(1, max(0, dotCloud));
            
            % use append method from base class to append frames
            obj.appendFrames(dotCloud);
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.dotDirection = 0;
            obj.dotSpeed = 1;
            obj.dotDensity = 0.1;
            obj.dotCoherence = 0.5;
            obj.dotRadius = -1;
            obj.densityStyle = 'random';
            obj.sampleFactor = 10;
            obj.interpMethod = 'linear';

            obj.baseMsgId = 'VisualStimulus:DotStim';
            obj.name = 'DotStim';
			obj.stimType = eval(['obj.supportedStimTypes.' obj.name]);
			obj.colorChar = 'w';
			obj.colorVec = obj.char2rgb(obj.colorChar);
        end
    end
    
    %% Properties
    properties (Hidden, Access = protected)
        baseMsgId;          % string prepended to error messages
        name;               % string describing the stimulus type
		colorChar;          % single-character specifying stimulus color
		colorVec;           % 3-element vector specifying stimulus color
		stimType;           % integer from obj.supportedStimTypes
    end
    
    properties (Hidden, Access = private)
        dotDirection;       % drift direction
        dotSpeed;           % drift speed
        dotDensity;         % dot density
        dotCoherence;       % dot coherence
        dotRadius;          % dot size
        densityStyle;       % place dots randomly, although some dots might
                            % overlap
        sampleFactor;       % Dots are made by computing one large Gaussian
                            % dot, and interpolating from that dot to make
                            % smaller dots. This param specifies how much
                            % larger (a factor) the large dot compared to
                            % the smaller dots
        interpMethod;       % interpolation method: 'linear', 'cubic', 
                            % 'nearest', or 'v4'
    end
end
