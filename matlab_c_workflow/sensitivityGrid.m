function result = sensitivityGrid(parameterValues, evaluateFcn)
%SENSITIVITYGRID Evaluate a model over a Cartesian parameter grid.
if ~iscell(parameterValues) || isempty(parameterValues), error('parameterValues must be a nonempty cell array.'); end
p=numel(parameterValues); grids=cell(1,p); [grids{:}]=ndgrid(parameterValues{:}); n=numel(grids{1}); outputs=cell(n,1); params=cell(n,1);
for k=1:n
    params{k}=cell(1,p); for j=1:p, params{k}{j}=grids{j}(k); end
    outputs{k}=evaluateFcn(params{k});
end
result=struct('parameters',{params},'outputs',{outputs},'count',n);
fprintf('[sensitivity] evaluated %d parameter combinations.\n',n);
end
