function result = predictionDecisionWorkflow(data, cfg)
%PREDICTIONDECISIONWORKFLOW Time-series model competition plus decision map.
% data.y is the observed response. Models are structs with name and a
% fitPredictFcn(train,horizon) function handle.
if nargin < 2, cfg=struct(); end
y=data.y(:); n=numel(y); if n<10, error('At least 10 observations are required.'); end
if ~isfield(cfg,'trainRatio'), cfg.trainRatio=.60; end
if ~isfield(cfg,'validRatio'), cfg.validRatio=.20; end
if ~isfield(cfg,'models')
    models(1).name='last-value'; models(1).fitPredictFcn=@(z,h)repmat(z(end),h,1);
    models(2).name='training-mean'; models(2).fitPredictFcn=@(z,h)repmat(mean(z),h,1);
else, models=cfg.models; end
trEnd=max(2,floor(n*cfg.trainRatio)); vaEnd=max(trEnd+1,floor(n*(cfg.trainRatio+cfg.validRatio))); vaEnd=min(vaEnd,n-1);
Ytr=y(1:trEnd); Yva=y(trEnd+1:vaEnd); Yte=y(vaEnd+1:end); results=cell(numel(models),1);
for k=1:numel(models)
    pv=models(k).fitPredictFcn(Ytr,numel(Yva)); pv=pv(:); ev=pv-Yva;
    bt=struct('initialWindow',max(5,floor(numel(Ytr)*.5)),'horizon',1,'step',1);
    if isfield(cfg,'backtest'), bt=cfg.backtest; end
    rb=rollingBacktest(Ytr,models(k).fitPredictFcn,bt);
    pt=models(k).fitPredictFcn(y(1:vaEnd),numel(Yte)); pt=pt(:); et=pt-Yte;
    results{k}=struct('name',models(k).name,'validationPrediction',pv,'testPrediction',pt,'validationMAE',mean(abs(ev)),'validationRMSE',sqrt(mean(ev.^2)),'testMAE',mean(abs(et)),'testRMSE',sqrt(mean(et.^2)),'rollingBacktest',rb);
end
vr=zeros(numel(results),1); for k=1:numel(results), vr(k)=results{k}.validationRMSE; end; [~,best]=min(vr);
result=struct('modelResults',{results},'bestIndex',best,'bestModel',models(best).name,'split',struct('trainEnd',trEnd,'validEnd',vaEnd,'testStart',vaEnd+1),'testActual',Yte,'assumptions','Time order is preserved; model selection uses validation only; test data are used once for final evaluation.');
if isfield(cfg,'decisionFcn'), [result.decision,result.decisionOutput]=cfg.decisionFcn(results{best}.testPrediction,Ytr); else, result.decision=[]; result.decisionOutput=[]; end
fprintf('[prediction] best=%s, validation RMSE=%.4f, test RMSE=%.4f.\n',result.bestModel,results{best}.validationRMSE,results{best}.testRMSE);
end
