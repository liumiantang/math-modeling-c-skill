function result = rollingBacktest(y, fitPredictFcn, cfg)
%ROLLINGBACKTEST Expanding-window, time-ordered forecast evaluation.
% fitPredictFcn(train,horizon) must return a horizon-by-1 forecast.
if nargin < 3, cfg = struct(); end
if ~isfield(cfg,'initialWindow'), cfg.initialWindow = max(5, floor(numel(y)*0.5)); end
if ~isfield(cfg,'horizon'), cfg.horizon = 1; end
if ~isfield(cfg,'step'), cfg.step = cfg.horizon; end
y = y(:); n=numel(y); starts=cfg.initialWindow:cfg.step:(n-cfg.horizon);
nEval=numel(starts)*cfg.horizon; predictions=nan(nEval,1); actual=nan(nEval,1); origins=nan(nEval,1); ptr=0; failures=0;
for s=starts
    train=y(1:s); truth=y(s+1:s+cfg.horizon);
    try
        pred=fitPredictFcn(train,cfg.horizon); pred=pred(:);
        if numel(pred)~=cfg.horizon, error('Forecast length mismatch.'); end
    catch
        pred=nan(cfg.horizon,1); failures=failures+1;
    end
    ix=ptr+(1:cfg.horizon); predictions(ix)=pred; actual(ix)=truth; origins(ix)=s; ptr=ptr+cfg.horizon;
end
mask=isfinite(predictions)&isfinite(actual); e=predictions(mask)-actual(mask);
result=struct('origins',origins,'actual',actual,'predictions',predictions,'failures',failures,'nEvaluated',nnz(mask),'MAE',mean(abs(e)),'RMSE',sqrt(mean(e.^2)),'MAPE',mean(abs(e)./max(abs(actual(mask)),eps))*100);
fprintf('[backtest] windows=%d, failures=%d, MAE=%.4f, RMSE=%.4f, MAPE=%.2f%%.\n',numel(starts),failures,result.MAE,result.RMSE,result.MAPE);
end
