classdef BarStim < BaseStim
    methods (Access = public)
        function obj = BarStim(dimHWC, length, direction, speed, ...
                barWidth, edgeWidth, pxBtwBars, startPos)
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
                if nargin<3,direction=obj.direction;end
                if nargin<4,speed=obj.speed;end
                if nargin<5,barWidth=obj.barWidth;end
                if nargin<6,edgeWidth=obj.edgeWidth;end
                if nargin<7,pxBtwBars=obj.pxBtwBars;end
                if nargin<8,startPos=obj.startPos;end

                % shortcut to create and add
                obj.add(length, dir, direction, speed, barWidth, ...
                    edgeWidth, pxBtwBars, startPos);
            end
        end
        
        function add(obj, length, direction, speed, barWidth, ...
                edgeWidth, pxBtwBars, startPos)
            % VS.addBar(length, direction, speed, width, edgeWidth,
            % pxBtwBars, startPos) creates a drifting bar stimulus of
            % LENGTH frames drifting in DIRECTION at SPEED.
            %
            % This method is based on a script by Timothy Saint and Eero P.
            % Simoncelli at NYU.
            %
            % LENGTH       - The number of frames to create the stimulus
            %                for. Default is 10.
            %
            % DIRECTION    - The direction of the bar motion in degrees
            %                (0=rightwards, 90=upwards; angle increases
            %                counterclockwise). Default is 0.
            %
            % SPEED        - The speed of the bar in pixels/frame. Default
            %                is 1.
            %
            % BARWIDTH     - The width of the center of the bar in pixels.
            %                Default is 1.
            %
            % EDGEWIDTH    - The width of the cosine edges of the bar in
            %                pixels. An edge of width EDGEWIDTH will be
            %                tacked onto both sides of the bar, so the
            %                total width will be BARWIDTH + 2*EDGEWIDTH.
            %                Default is 3.
            %
            % PXBTWNBARS   - The number of pixels between the bars in the
            %                stimulus. Default is the image width.
            % STARTPOS     - The starting position of the first bar in
            %                pixels. The coordinate system is a line lying
            %                along the direction of the bar motion and
            %                passing through the center of the stimulus.
            %                The point 0 is the center of the stimulus.
            %                Default is 0.
            if nargin<8,startPos=obj.startPos;end
            if nargin<7,pxBtwBars=obj.pxBtwBars;end
            if nargin<6,edgeWidth=obj.edgeWidth;end
            if nargin<5,barWidth=obj.barWidth;end
            if nargin<4,speed=obj.speed;end
            if nargin<3,direction=obj.direction;end
            if nargin<2,length=10;end
            
            % a bar is basically a single period of the grating
            gratingSf = 1/pxBtwBars;        % spatial freq
            gratingTf = gratingSf * speed;  % temporal freq
            gratingPhase = startPos * gratingSf;
            grating = GratingStim([obj.height obj.width obj.channels]);
            grating.add(length, direction, [gratingSf gratingTf], 1, ...
                gratingPhase);
            res = 2*grating.stim - 1;
            
            for f=1:size(res,4)
                frame = res(:,:,:,f);
                
                % There are three regions:
                % - where stim should be one (centers of the bar)
                % - where stim should be zero (outside the bar)
                % - where it should be in between (edges of the bar)
                barInnerTh = cos(2*pi*gratingSf*barWidth/2);
                barOuterTh = cos(2*pi*gratingSf*(barWidth/2 + edgeWidth));
                wOne = frame >= barInnerTh;
                wEdge = (frame < barInnerTh) & (frame > barOuterTh);
                wZero = frame <= barOuterTh;
                
                % Set the regions to the appropriate level
                frame(wOne) = 1;
                frame(wZero) = 0;
                
                % adjust range to [0,2*pi)
                frame(wEdge) = acos(frame(wEdge));
                
                % adjust range to [0,1] spatial period
                frame(wEdge) = frame(wEdge) / (2*pi*gratingSf);
                frame(wEdge) =  (pi/2)*(frame(wEdge) - barWidth/2)/(edgeWidth);
                frame(wEdge) = cos(frame(wEdge));
                
                res(:,:,:,f) = frame;
            end

            % use append method from base class to append frames
            obj.appendFrames(res);
        end
        
    end
    
    methods (Access = protected)
        function initDefaultParamsDerived(obj)
            obj.direction = 0;
            obj.speed = 1;
            obj.barWidth = 1;
            obj.edgeWidth = 3;
            obj.pxBtwBars = obj.width;
            obj.startPos = 0;
            
            obj.baseMsgId = 'VisualStimulus:BarStim';
        end
    end        
    
    properties (GetAccess = protected)
        baseMsgId;
    end
    
    properties (Access = private)
        direction;
        speed;
        barWidth;
        edgeWidth;
        pxBtwBars;
        startPos;
    end
end
    