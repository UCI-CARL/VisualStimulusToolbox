classdef DotStim < BaseStim
    methods (Access = public)
        function obj = DotStim(dimHWC, length, dotDirection, dotSpeed, ...
                dotDensity, dotCoherence, dotRadius, ptCenter, ...
                densityStyle)
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
            
            if nargin >= 2
                if nargin<3,dotDirection=obj.dotDirection;end
                if nargin<4,dotSpeed=obj.dotSpeed;end
                if nargin<5,dotDensity=obj.dotDensity;end
                if nargin<6,dotCoherence=obj.dotCoherence;end
                if nargin<7,dotRadius=obj.dotRadius;end
                if nargin<8,ptCenter=obj.ptCenter;end
                if nargin<9,densityStyle=obj.densityStyle;end
                
                % shortcut to create and add
                obj.add(length, dir, dotDirection, dotSpeed, dotDensity,...
                    dotCoherence, dotRadius, ptCenter, densityStyle);
            end
        end
        
        function add(obj, length, direction, speed, density, coherence, ...
                radius)
            % stim.addDots(length, type, direction, speed, coherence,
            % radius, densityStyle) adds a field of drifting dots to the
            % existing stimulus.
            % The field consists of roughly DENSITY*width*height drifting 
            % dots, of which a fraction COHERENCE drifts coherently into a
            % DIRECTION.
            %
            % This method uses a script initially authored by Timothy Saint 
            % and Eero P. Simoncelli at NYU.
            %
            % LENGTH     - The number of frames you want to generate.
            %              Default: 10.
            %
            % DIRECTION  - The direction in degrees in which a fraction
            %              COHERENCE of all dots drift (0=rightwards,
            %              90=upwards; angle increases counterclockwise).
            %              Default is 0.
            %
            % SPEED      - The speed in pixels/frame at which a fraction
            %              COHERENCE of all dots drift. Default is 1.
            %
            % DENSITY    - The density of the dots (in the range [0,1]).
            %              This will create roughly DENSITY*width*height
            %              dots. Default is 0.1.
            %
            % COHERENCE  - The fraction of dots that drift coherently in a
            %              given direction of motion or motion gradient.
            %              The remaining fraction moves randomly.
            %              Default is 1.
            %
            % RADIUS     - The radius of the dots. If radius<0, the dots
            %              will be single pixels. If radius>0, the dots
            %              will be Gaussian blobs with sigma=0.5*radius.
            %              Default is -1.
            if nargin<3,direction=obj.dotDirection;end
            if nargin<4,speed=obj.dotSpeed;end
            if nargin<5,density=obj.dotDensity;end
            if nargin<6,coherence=obj.dotCoherence;end
            if nargin<7,radius=obj.dotRadius;end
            % Issue: Should add overwrite obj.properties? What if
            % constructor sets them, then we repeatedly call add with args,
            % then we call add without args. What should happen?
            
            validateattributes(length, {'numeric'}, ...
                {'integer','positive'}, 'add', 'length')
            validateattributes(direction, {'numeric'}, {'real'}, 'add', ...
                'direction')
            validateattributes(speed, {'numeric'}, ...
                {'integer','nonnegative'}, 'add', 'speed')
            validateattributes(density, {'numeric'}, ...
                {'real','>=',0,'<=',1}, 'add', 'density')
            validateattributes(coherence, {'numeric'}, ...
                {'real','>=',0,'<=',1}, 'add', 'coherence')
            validateattributes(radius,{'numeric'},{'real'},'add','radius')
            
            % TODO parse input
            
            if density<0
                if radius<0
                    density = 0.1;
                else
                    density = 0.3/(pi*radius^2);
                end
            end
            
            % in this context, x=row, y=col; but we permute it the result
            % in the end
            
            % make the large dot for sampling
            rLargeDot = linspace(-1.5*radius, 1.5*radius, ...
                ceil(3*radius*obj.sampleFactor));
            largeDot = exp(-rLargeDot.^2 ./ (2.*(radius/2)^2));
            largeDot = largeDot'*largeDot;
            [rLargeDot, cLargeDot] = meshgrid(rLargeDot, rLargeDot);
            
            % There is a buffer area around the image so that we don't 
            % have to worry about getting wraparounds exactly right.
            % This buffer is twice the size of a dot diameter.
            if radius > 0
                bufferSize = 2*ceil(radius*3);
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
            res = zeros(rowFrame, colFrame, obj.channels);
            toInterp = -floor(1.5*radius):floor(1.5*radius);
            dSz = floor(1.5*radius);
            
            for t=1:length
                % update the dot positions according to RDK type
                dotVel = [sin(direction/180*pi), cos(direction/180*pi)];
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
                if radius > 0
                    % in each frame, don't show dots near the edges of the
                    % frame. That's why we have a buffer. The reason we
                    % don't show them is that we don't want to deal with
                    % edge handling
                    w1 = find(tmpDotPos(:,1) > (rowFrame - bufferSize + ...
                        + 1.5*radius));
                    w2 = find(tmpDotPos(:,1) < (bufferSize - 1.5*radius));
                    w3 = find(tmpDotPos(:,2) > (colFrame - bufferSize + ...
                        + 1.5*radius));
                    w4 = find(tmpDotPos(:,2) < (bufferSize - 1.5*radius));
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
                res(:,:,t) = thisFrame;
            end
            % Now trim away the buff
            res = res(bufferSize+1:end-bufferSize, ...
                bufferSize+1:end-bufferSize, :);
            res(res>1) = 1;
            
            % use append method from base class to append frames
            % TODO generalize to 3 channels
            frames(:,:,1,:) = res;%permute(res, [2 1 3]);
            obj.appendFrames(frames);
        end
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.dotDirection = 0;
            obj.dotSpeed = 1;
            obj.dotDensity = 0.1;
            obj.dotCoherence = 0.5;
            obj.dotRadius = -1;
            obj.ptCenter = [obj.width/2 obj.height/2];
            obj.densityStyle = 'random';
            obj.sampleFactor = 10;
            obj.interpMethod = 'linear';
            obj.baseMsgId = 'VisualStimulus:DotStim';
            obj.name = 'DotStim';
        end
    end
    
    properties (Hidden, Access = protected)
        name;
        baseMsgId;
    end
    
    properties (Hidden, Access = private)
        dotDirection;
        dotSpeed;
        dotDensity;
        dotCoherence;
        dotRadius;
        ptCenter;
        densityStyle;
        sampleFactor;
        interpMethod;
    end
end
