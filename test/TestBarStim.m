classdef TestBarStim < matlab.unittest.TestCase
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