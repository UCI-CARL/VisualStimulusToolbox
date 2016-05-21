import matlab.unittest.TestSuite

% all test cases are contained in "test" folder
suite = TestSuite.fromFolder('test');
res = run(suite)