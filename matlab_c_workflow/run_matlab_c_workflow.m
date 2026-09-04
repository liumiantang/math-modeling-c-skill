function result = run_matlab_c_workflow(kind, varargin)
%RUN_MATLAB_C_WORKFLOW Unified dispatcher for the three C-question types.
% Examples:
%   run_matlab_c_workflow('prediction', data, cfg)
%   run_matlab_c_workflow('network', cost, supply, demand, cfg)
%   run_matlab_c_workflow('robust', scenarios, solveFcn, evaluateFcn, cfg)
if nargin<1, error('Specify prediction, network or robust.'); end
switch lower(char(kind))
    case {'prediction','prediction-decision'}
        result=predictionDecisionWorkflow(varargin{:});
    case {'network','network-scheduling'}
        result=networkSchedulingWorkflow(varargin{:});
    case {'robust','uncertainty','uncertainty-optimization'}
        result=robustOptimizationWorkflow(varargin{:});
    otherwise
        error('Unknown workflow type: %s',char(kind));
end
end
