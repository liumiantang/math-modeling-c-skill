function report = validateSolution(x, Aeq, beq, Aineq, bineq, lb, ub, f, customChecks)
%VALIDATESOLUTION Unified feasibility and objective audit.
if nargin < 2 || isempty(Aeq), Aeq = zeros(0,numel(x)); end
if nargin < 3 || isempty(beq), beq = zeros(0,1); end
if nargin < 4 || isempty(Aineq), Aineq = zeros(0,numel(x)); end
if nargin < 5 || isempty(bineq), bineq = zeros(0,1); end
if nargin < 6 || isempty(lb), lb = -inf(size(x)); end
if nargin < 7 || isempty(ub), ub = inf(size(x)); end
if nargin < 8, f = []; end
if nargin < 9, customChecks = {}; end
tol = 1e-7;
eqResidual = 0; ineqViolation = 0; lowerViolation = 0; upperViolation = 0;
if ~isempty(Aeq), eqResidual = max(abs(Aeq*x-beq(:))); end
if ~isempty(Aineq), ineqViolation = max(Aineq*x-bineq(:)); end
if ~isempty(x), lowerViolation = max(lb(:)-x(:)); upperViolation = max(x(:)-ub(:)); end
eqResidual=max(eqResidual,0); ineqViolation=max(ineqViolation,0); lowerViolation=max(lowerViolation,0); upperViolation=max(upperViolation,0);
customPass = true; customValues = nan(1,numel(customChecks));
for k=1:numel(customChecks)
    value = customChecks{k}(x); customValues(k)=value; customPass = customPass && value <= tol;
end
report = struct('eqResidual',eqResidual,'ineqViolation',ineqViolation,'lowerViolation',lowerViolation,'upperViolation',upperViolation,'customValues',customValues,'isFeasible',eqResidual<=tol && ineqViolation<=tol && lowerViolation<=tol && upperViolation<=tol && customPass);
if isempty(f), report.objective=[]; else, report.objective=f(:)'*x(:); end
fprintf('[validate] eq=%.3e, ineq=%.3e, lb=%.3e, ub=%.3e, pass=%d.\n',eqResidual,ineqViolation,lowerViolation,upperViolation,report.isFeasible);
end
