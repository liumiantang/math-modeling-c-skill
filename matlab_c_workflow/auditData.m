function report = auditData(X, name)
%AUDITDATA Basic, reproducible input audit for modeling data.
if nargin < 2, name = 'data'; end
if ~isnumeric(X), error('auditData currently expects a numeric array.'); end
report = struct();
report.name = name;
report.size = size(X);
report.class = class(X);
report.missingCount = nnz(isnan(X(:)));
report.infiniteCount = nnz(isinf(X(:)));
report.negativeCount = nnz(X(:) < 0);
report.zeroCount = nnz(X(:) == 0);
report.min = min(X(:), [], 'omitnan');
report.max = max(X(:), [], 'omitnan');
report.mean = mean(X(:), 'omitnan');
report.median = median(X(:), 'omitnan');
report.isClean = report.missingCount == 0 && report.infiniteCount == 0 && report.negativeCount == 0;
fprintf('[audit] %s: %dx%d, NaN=%d, Inf=%d, negative=%d.\n', name, size(X,1), size(X,2), report.missingCount, report.infiniteCount, report.negativeCount);
end
