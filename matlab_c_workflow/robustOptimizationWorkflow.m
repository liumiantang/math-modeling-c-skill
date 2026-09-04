function result = robustOptimizationWorkflow(scenarios, solveFcn, evaluateFcn, cfg)
%ROBUSTOPTIMIZATIONWORKFLOW Scenario-based robust decision selector.
% solveFcn(scenario) creates one candidate decision; evaluateFcn(decision,
% scenario) returns [objective, violation]. Candidate decisions are tested
% against every scenario, so nominal performance and worst-case performance
% are separated explicitly.
if nargin<4, cfg=struct(); end
if ~iscell(scenarios), scenarios=num2cell(scenarios); end
if ~isfield(cfg,'sense'), cfg.sense='max'; end; if ~isfield(cfg,'tolerance'), cfg.tolerance=1e-7; end
S=numel(scenarios); candidates=cell(S,1); obj=zeros(S,S); vio=zeros(S,S);
for k=1:S, candidates{k}=solveFcn(scenarios{k}); for s=1:S, [obj(k,s),vio(k,s)]=evaluateFcn(candidates{k},scenarios{s}); end, end
if strcmpi(cfg.sense,'max'), worst=min(obj,[],2); regret=max(obj,[],1)-obj; else, worst=max(obj,[],2); regret=obj-min(obj,[],1); end
feasible=max(vio,[],2)<=cfg.tolerance; score=worst; if strcmpi(cfg.sense,'max'), score(~feasible)=-inf; [~,robustIndex]=max(score); else, score(~feasible)=inf; [~,robustIndex]=min(score); end
if ~isfinite(score(robustIndex)), [~,robustIndex]=min(max(vio,[],2)); end
result=struct('candidates',{candidates},'objectiveMatrix',obj,'violationMatrix',vio,'worstObjective',worst,'maxViolation',max(vio,[],2),'feasibleCandidates',feasible,'regretMatrix',regret,'robustIndex',robustIndex,'robustDecision',candidates{robustIndex},'assumptions','Robustness is evaluated only over the supplied finite scenario set; it is not distributionally robust outside that set.');
fprintf('[robust] scenarios=%d, robust candidate=%d, worst objective=%.4f, max violation=%.3e.\n',S,robustIndex,worst(robustIndex),max(vio(robustIndex,:)));
end
