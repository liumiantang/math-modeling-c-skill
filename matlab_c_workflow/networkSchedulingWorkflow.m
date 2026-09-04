function result = networkSchedulingWorkflow(cost, supply, demand, cfg)
%NETWORKSCHEDULINGWORKFLOW Period-by-period minimum-cost flow scheduler.
% cost is nSource x nSink x T; supply and demand are source/sink x T.
if nargin<4, cfg=struct(); end
if ndims(cost)==2, cost=reshape(cost,size(cost,1),size(cost,2),1); end
if isvector(supply), supply=supply(:); end; if isvector(demand), demand=demand(:); end
[ns,nk,T]=size(cost); if size(supply,2)==1 && T>1, supply=repmat(supply,1,T); end; if size(demand,2)==1 && T>1, demand=repmat(demand,1,T); end
if ~isfield(cfg,'shortagePenalty'), cfg.shortagePenalty=max(cost(:))+100; end
if ~isfield(cfg,'routeCapacity'), cfg.routeCapacity=inf; end
flows=zeros(ns,nk,T); shortage=zeros(nk,T); period=cell(T,1); totalCost=0;
for t=1:T
    n=ns*nk+nk; ix=@(i,j)(j-1)*ns+i; iu=@(j)ns*nk+j; f=zeros(n,1);
    for j=1:nk, for i=1:ns, f(ix(i,j))=cost(i,j,t); end, f(iu(j))=cfg.shortagePenalty; end
    Aeq=zeros(nk,n); beq=demand(:,t); Aiq=zeros(ns,n); biq=supply(:,t);
    for j=1:nk, for i=1:ns, Aeq(j,ix(i,j))=1; end, Aeq(j,iu(j))=1; end
    for i=1:ns, for j=1:nk, Aiq(i,ix(i,j))=1; end, end
    lb=zeros(n,1); ub=inf(n,1);
    if isscalar(cfg.routeCapacity), ub(1:ns*nk)=cfg.routeCapacity; else, ub(1:ns*nk)=cfg.routeCapacity(:,:,min(t,size(cfg.routeCapacity,3))); end
    [x,obj,ef]=linprog(f,Aiq,biq,Aeq,beq,lb,ub,optimoptions('linprog','Display','off'));
    if isempty(x), error('Network LP infeasible at period %d.',t); end
    for j=1:nk, shortage(j,t)=x(iu(j)); for i=1:ns, flows(i,j,t)=x(ix(i,j)); end, end
    period{t}=struct('objective',obj,'exitflag',ef,'eqResidual',max(abs(Aeq*x-beq)),'capacityViolation',max(Aiq*x-biq)); totalCost=totalCost+obj;
end
result=struct('flows',flows,'shortage',shortage,'period',{period},'totalCost',totalCost,'totalShortage',sum(shortage(:)),'assumptions','Each period is solved independently; unmet demand is represented by a penalized shortage variable.');
fprintf('[network] periods=%d, total cost=%.4f, total shortage=%.4f.\n',T,totalCost,result.totalShortage);
end
