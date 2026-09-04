
function tests = test_c_workflow_core
%TEST_C_WORKFLOW_CORE Unit tests for the reusable C-question workflow.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
tests = functiontests(localfunctions);
end

function testAuditData(testCase)
X = [1 NaN; 3 0];
r = auditData(X, 'unit');
verifyEqual(testCase, r.missingCount, 1);
verifyEqual(testCase, r.zeroCount, 1);
verifyFalse(testCase, r.isClean);
end

function testRollingBacktest(testCase)
y = (1:10)';
cfg = struct('initialWindow',4,'horizon',1,'step',1);
r = rollingBacktest(y, @(train,h) repmat(train(end),h,1), cfg);
verifyEqual(testCase, r.nEvaluated, 6);
verifyEqual(testCase, r.failures, 0);
verifyEqual(testCase, r.MAE, 1, 'AbsTol', 1e-12);
end

function testValidateSolution(testCase)
x = [1;2];
r = validateSolution(x, [1 1], 3, [], [], [0;0], [3;3], [1;1], {});
verifyTrue(testCase, r.isFeasible);
verifyEqual(testCase, r.eqResidual, 0, 'AbsTol', 1e-12);
end

function testSensitivityGrid(testCase)
r = sensitivityGrid({[1 2],[10 20]}, @(p) p{1}+p{2});
verifyEqual(testCase, r.count, 4);
values = cellfun(@(x) x, r.outputs);
verifyEqual(testCase, sort(values(:)), [11;12;21;22]);
end

function testPassportAndPaperAudit(testCase)
base = tempname;
mkdir(base);
cleanup = onCleanup(@() rmdir(base,'s'));
key_numbers = table("mean_rmse", 1.2345, 1e-4, true, "results.csv", ...
    'VariableNames', {'key','value','tolerance','mustAppear','source'});
meta = struct('problem_id','demo','question_id','Q1', ...
    'data_source','demo.csv','estimand','test metric', ...
    'assumptions',{{'demo assumption'}}, ...
    'variables',{{'x: unit'}},'objective','min RMSE', ...
    'constraints',{{'none'}},'script_path','run_workflow.m', ...
    'validation','unit test','sensitivity','none', ...
    'outputs',{{'result.csv'}},'limitations','demo only', ...
    'status','verified','key_numbers',key_numbers);
p = generateModelPassport(meta, fullfile(base,'model_passport.md'));
verifyEmpty(testCase, p.missingFields);
verifyTrue(testCase, isfile(p.manifestPath));
paper = fullfile(base,'paper.md');
fid = fopen(paper,'w','n','UTF-8');
fprintf(fid, '# Demo\n\nThe verified RMSE is 1.2345.\n');
fclose(fid);
a = auditPaperConsistency(paper, p.manifestPath, fullfile(base,'audit.csv'));
verifyTrue(testCase, a.pass);
verifyEqual(testCase, a.audit.status(1), "pass");
end

function testPaperAuditRejectsMissingNumber(testCase)
base = tempname;
mkdir(base);
cleanup = onCleanup(@() rmdir(base,'s'));
manifest = table("missing_metric", 9.87, 1e-4, true, "result.csv", ...
    'VariableNames', {'key','value','tolerance','mustAppear','source'});
manifestPath = fullfile(base,'manifest.csv');
writetable(manifest, manifestPath);
paper = fullfile(base,'paper.md');
fid = fopen(paper,'w','n','UTF-8');
fprintf(fid, 'The paper reports 1.23.\n');
fclose(fid);
a = auditPaperConsistency(paper, manifestPath, fullfile(base,'audit.csv'));
verifyFalse(testCase, a.pass);
verifyEqual(testCase, a.audit.status(1), "fail");
end
