% A test case for all public methods of BaseStim base class
classdef TestBaseStim < matlab.unittest.TestCase
    %% Test Case Setup
    methods (TestClassSetup)
        function addParentDirToPath(testCase)
            currentDir = cd('..');
            addpath(pwd)
            cd(currentDir)
        end
    end
    
    %% Unit Tests
    methods (Test)
        function testAddFramesFailure(testCase)
            % create some derived stim, try to add frame with wrong
            % dimensions
            errId = 'VisualStimulus:BarStim:dimensionMismatch';
            w=8;h=12;c=3;
            b = BarStim([w h c]);
            testCase.verifyError(@()b.addFrames([1 2]), errId)
            testCase.verifyError(@()b.addFrames(zeros(w+3,h,c)), errId)
            testCase.verifyError(@()b.addFrames(zeros(w,h-4,c)), errId)
            testCase.verifyError(@()b.addFrames(zeros(w,h,c+2)), errId)
            testCase.verifyError(@()b.addFrames([]), errId)
        end
        
        function testAddFramesSuccess(testCase)
            % create some derived stim, try to add some frames, then make
            % sure length is correct
            w=8;h=12;c=3;
            b = BarStim([w h c]);
            testCase.verifyEqual(b.length, 0);
            
            % omitting 4-th dimension should add 1 frame
            b.addFrames(zeros(w,h,c));
            testCase.verifyEqual(b.length, 1);
            
            b.addFrames(zeros(w,h,c,1));
            testCase.verifyEqual(b.length, 2);
            
            b.addFrames(zeros(w,h,c,5));
            testCase.verifyEqual(b.length, 7);
        end
        
        function testAddBlanksFailure(testCase)
            errValId = 'VisualStimulus:BarStim:invalidValue';
            errTypeId = 'VisualStimulus:BarStim:invalidType';
            w=8;h=12;c=3;
            b = BarStim([w h c]);
            
            % invalid values for numBlanks
            testCase.verifyError(@()b.addBlanks(0), errValId)
            testCase.verifyError(@()b.addBlanks(-3), errValId)
            testCase.verifyError(@()b.addBlanks(0.4), errTypeId)
            testCase.verifyError(@()b.addBlanks('s'), errTypeId)
            
            % invalid values for grayVal
            testCase.verifyError(@()b.addBlanks(4, -1), errValId)
            testCase.verifyError(@()b.addBlanks(8, 256), errValId)
            testCase.verifyError(@()b.addBlanks(1, 10.5), errTypeId)
            testCase.verifyError(@()b.addBlanks(3, 's'), errTypeId)
        end
        
        function testAddBlanksSuccess(testCase)
            w=8;h=12;c=3;
            b = BarStim([w h c]);
            
            % add black
            b.addBlanks(randi(7,1));
            testCase.verifyEqual(all(b.stim(:)==0), true)
            
            % add some grayscale value
            gray = randi(256,1) - 1;
            b.addBlanks(1, gray);
            last = b.stim(:,:,:,end);
            testCase.verifyEqual(all(last(:)==gray), true)
        end

        
        function testPlus(testCase)
            b = BarStim([2 3 1]);
            testCase.verifyClass(b, 'BarStim');
        end
        
        function testLength(testCase)
            obj = BarStim([12 12 1]);
            obj.setLength(4);
            
            actSolution = obj.length;
            expSolution = 4;
            testCase.verifyEqual(actSolution, expSolution);
        end
    end
    
    %% Test Case Teardown
    methods (TestMethodTearDown)
    end
end