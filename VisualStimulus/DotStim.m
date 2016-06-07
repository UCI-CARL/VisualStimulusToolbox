classdef DotStim < BaseStim
    methods (Access = public)
        function obj = DotStim(dimWHC, length, dotDirection, dotSpeed, ...
                dotDensity, dotCoherence, dotRadius, ptCenter, ...
                densityStyle)
            obj.width = dimWHC(1);
            obj.height = dimWHC(2);
            if numel(dimWHC) > 2
                obj.channels = dimWHC(3);
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
        
        function add(obj, length, dotDirection, dotSpeed, dotDensity, ...
                dotCoherence, dotRadius, ptCenter, densityStyle)
            % Issue: Should add overwrite obj.properties? What if
            % constructor sets them, then we repeatedly call add with args,
            % then we call add without args. What should happen?
                if nargin<3,dotDirection=obj.dotDirection;end
                if nargin<4,dotSpeed=obj.dotSpeed;end
                if nargin<5,dotDensity=obj.dotDensity;end
                if nargin<6,dotCoherence=obj.dotCoherence;end
                if nargin<7,dotRadius=obj.dotRadius;end
                if nargin<8,ptCenter=obj.ptCenter;end
                if nargin<9,densityStyle=obj.densityStyle;end
                
            % TODO parse input
            
            if dotDensity<0
                if dotRadius<0
                    dotDensity = 0.1;
                else
                    dotDensity = 0.3/(pi*dotRadius^2);
                end
            end
            
            % in this context, x=row, y=col; but we permute it the result
            % in the end
            
            % make the large dot for sampling
            xLargeDot = linspace(-(3/2)*dotRadius, (3/2)*dotRadius, ...
                ceil(3*dotRadius*obj.sampleFactor));
            sigmaLargeDot = dotRadius/2;
            largeDot = exp(-xLargeDot.^2./(2.*sigmaLargeDot^2));
            largeDot = largeDot'*largeDot;
            [xLargeDot, yLargeDot] = meshgrid(xLargeDot, xLargeDot);
            
            % There is a buffer area around the image so that we don't have to
            % worry about getting wraparounds exactly right.  This buffer is
            % twice the size of a dot diameter.
            if dotRadius > 0
                bufferSize = 2*ceil(dotRadius*3);
            else
                bufferSize = 5;
            end
            
            % the 'frame' is the field across which the dots drift. The final
            % output of this this function will consist of 'snapshots' of this
            % frame without buffer. We store the size of the frame and a
            % coordinate system for it here:
            frameSzX = obj.height + 2.*bufferSize;
            frameSzY = obj.width + 2.*bufferSize;
            [yFrame, xFrame] = meshgrid(1:frameSzY, 1:frameSzX);
            
            % adjust center point for frameSz
            frameScaling = [frameSzX frameSzY]./[obj.height obj.width];
            ptCenter = ptCenter.*frameScaling;
                        
            % nDots is the number of coherently moving dots in the stimulus.
            % nDotsNonCoherent is the number of noncoherently moving dots.
            nDots = round(dotCoherence.*dotDensity.*numel(xFrame));
            nDotsNonCoherent = round((1-dotCoherence).*dotDensity.*numel(xFrame));
            
            % Set the initial dot positions.
            % dotPositions is a matrix of positions of the coherently moving
            % dots in [x,y] coordinates; each row in dotPositions stores the
            % position of one dot
            if strcmp(densityStyle, 'exact')
                z = zeros(numel(xFrame), 1);
                z(1:nDots) = 1;
                ord = rand(size(z));
                [~, ord] = sort(ord);
                z = z(ord);
                dotPositions = [xFrame(z==1), yFrame(z==1)];
            else
                dotPositions = rand(nDots, 2) * [frameSzX 0; 0 frameSzY];
            end
            
            % s will store the output. After looping over each frame, we will
            % trim away the buffer from s to obtain the final result.
            res = zeros(frameSzX, frameSzY, obj.channels);
            toInterpolate = -floor((3/2)*dotRadius):floor((3/2)*dotRadius);
            dSz = floor((3/2)*dotRadius);
            
            for t=1:length
                % update the dot positions according to RDK type
                dotVelocity = [sin(dotDirection), ...
                    cos(dotDirection)];
                dotVelocity = dotVelocity*dotSpeed;
                dotPositions = dotPositions + repmat(dotVelocity, ...
                    size(dotPositions, 1), 1);
                
                % wrap around for all dots that have gone past the image
                % borders
                w = find(dotPositions(:,1)>frameSzX+.5);
                dotPositions(w,1) = dotPositions(w,1) - frameSzX;
                
                w = find(dotPositions(:,1)<.5);
                dotPositions(w,1) = dotPositions(w,1) + frameSzX;
                
                w = find(dotPositions(:,2)>frameSzY+.5);
                dotPositions(w,2) = dotPositions(w,2) - frameSzY;
                
                w = find(dotPositions(:,2)<.5);
                dotPositions(w,2) = dotPositions(w,2) + frameSzY;
                
                
                % add noncoherent dots and make a vector of dot positions for
                % this frame only
                dotPositionsNonCoherent = rand(nDotsNonCoherent, 2) ...
                    * [frameSzX-1 0; 0 frameSzY-1] + .5;
                
                % create a temporary matrix of positions for dots to be shown in
                % this frame
                tmpDotPositions = [dotPositions; dotPositionsNonCoherent];
                
                % prepare a matrix of zeros for this frame
                thisFrame = zeros(size(xFrame));
                if dotRadius > 0
                    % in each frame, don't show dots near the edges of the
                    % frame. That's why we have a buffer. The reason we don't
                    % show them is that we don't want to deal with edge 
                    % handling
                    w1 = find(tmpDotPositions(:,1) > (frameSzX - bufferSize ...
                        + (3/2)*dotRadius));
                    w2 = find(tmpDotPositions(:,1) < (bufferSize - (3/2)*dotRadius));
                    w3 = find(tmpDotPositions(:,2) > (frameSzY - bufferSize ...
                        + (3/2)*dotRadius));
                    w4 = find(tmpDotPositions(:,2) < (bufferSize - (3/2)*dotRadius));
                    w = [w1; w2; w3; w4];
                    tmpDotPositions(w, :) = [];
                    
                    % add the dots to thisFrame
                    for p = 1:size(tmpDotPositions, 1)
                        % find the center point of the current dot, in thisFrame
                        % coordinates. This is where the dot will be placed.
                        cpX = round(tmpDotPositions(p, 1));
                        cpY = round(tmpDotPositions(p, 2));
                        
                        xToInterpol = toInterpolate ...
                            + (round(tmpDotPositions(p,1)) ...
                            - tmpDotPositions(p,1));
                        yToInterpol = toInterpolate ...
                            + (round(tmpDotPositions(p,2)) ...
                            - tmpDotPositions(p,2));
                        [xToInterpol, yToInterpol] = meshgrid(xToInterpol, ...
                            yToInterpol);
                        thisSmallDot = interp2(xLargeDot, yLargeDot, ...
                            largeDot, xToInterpol, yToInterpol, ...
                            obj.interpMethod);
                        
                        % now add this small dot to the frame.
                        thisFrame(cpX-dSz:cpX+dSz, cpY-dSz:cpY+dSz) = ...
                            thisFrame(cpX-dSz:cpX+dSz, cpY-dSz:cpY+dSz) + ...
                            thisSmallDot;
                        
                    end
                else
                    tmpDotPositions(tmpDotPositions(:,1) > frameSzX, :) = [];
                    tmpDotPositions(tmpDotPositions(:,1) < 1, :) = [];
                    tmpDotPositions(tmpDotPositions(:,2) > frameSzY, :) = [];
                    tmpDotPositions(tmpDotPositions(:,2) < 1, :) = [];
                    tmpDotPositions = round(tmpDotPositions);
                    
                    w = sub2ind(size(thisFrame), tmpDotPositions(:,1), ...
                        tmpDotPositions(:,2));
                    
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
            frames(:,:,1,:) = permute(res, [2 1 3]);
            obj.appendFrames(frames);
        end
    end
    
    methods (Access = protected)
        function initDefaultParams(obj)
            obj.length = 0;
            obj.dotDirection = 0;
            obj.dotSpeed = 1;
            obj.dotDensity = 0.1;
            obj.dotCoherence = 0.5;
            obj.dotRadius = -1;
            obj.ptCenter = [obj.width/2 obj.height/2];
            obj.densityStyle = 'random';
            obj.sampleFactor = 10;
            obj.interpMethod = 'linear';
            obj.baseMsgId = 'VisualStimulus:GratingStim';
        end
    end

    properties (GetAccess = protected)
        baseMsgId;
    end
    
    properties (Access = private)
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
    