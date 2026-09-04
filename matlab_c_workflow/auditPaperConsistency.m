
function result = auditPaperConsistency(paperPath, manifestPath, outputPath, cfg)
%AUDITPAPERCONSISTENCY Compare paper numbers with a MATLAB result manifest.
% The paper input should be UTF-8 Markdown or extracted plain text. A DOCX/PDF
% must first be converted to text by the document/PDF workflow.
% Manifest columns: key, value; optional tolerance, mustAppear, source.

if nargin < 3 || isempty(outputPath)
    outputPath = fullfile(fileparts(paperPath), 'paper_consistency_audit.csv');
end
if nargin < 4 || isempty(cfg)
    cfg = struct();
end
if ~isfield(cfg, 'defaultTolerance'), cfg.defaultTolerance = 1e-6; end
if ~isfield(cfg, 'forbiddenPhrases'), cfg.forbiddenPhrases = string.empty(0,1); end

if ~isfile(paperPath), error('Paper text file not found: %s', paperPath); end
if ~isfile(manifestPath), error('Result manifest not found: %s', manifestPath); end
[~,~,ext] = fileparts(paperPath);
if ~ismember(lower(ext), {'.md','.txt','.text'})
    error('Use Markdown or extracted plain text as paperPath; received %s.', ext);
end
paperText = fileread(paperPath);
paperNumbers = extractNumbers(paperText);
manifest = readtable(manifestPath, 'TextType', 'string');
required = ["key","value"];
if ~all(ismember(required, string(manifest.Properties.VariableNames)))
    error('Manifest must contain key and value columns.');
end
if ~ismember("tolerance", string(manifest.Properties.VariableNames))
    manifest.tolerance = repmat(cfg.defaultTolerance, height(manifest), 1);
end
if ~ismember("mustAppear", string(manifest.Properties.VariableNames))
    manifest.mustAppear = true(height(manifest), 1);
end
if ~ismember("source", string(manifest.Properties.VariableNames))
    manifest.source = repmat("", height(manifest), 1);
end

n = height(manifest);
key = string(manifest.key);
value = double(manifest.value);
tol = double(manifest.tolerance);
mustAppear = logical(manifest.mustAppear);
found = false(n,1);
difference = nan(n,1);
status = strings(n,1);
for k = 1:n
    if ~isfinite(value(k))
        status(k) = "invalid_manifest_value";
        continue;
    end
    if isempty(paperNumbers)
        status(k) = "not_found";
        continue;
    end
    diffs = abs(paperNumbers - value(k));
    [difference(k),~] = min(diffs);
    found(k) = difference(k) <= tol(k) * max(1, abs(value(k)));
    if found(k)
        status(k) = "pass";
    elseif mustAppear(k)
        status(k) = "fail";
    else
        status(k) = "optional_missing";
    end
end

forbidden = string(cfg.forbiddenPhrases(:));
forbiddenFound = false(numel(forbidden),1);
for k = 1:numel(forbidden)
    forbiddenFound(k) = contains(lower(string(paperText)), lower(forbidden(k)));
end
if any(forbiddenFound)
    warning('Forbidden phrases found in paper text.');
end

audit = table(key, value, tol, mustAppear, found, difference, status, string(manifest.source), ...
    'VariableNames', {'key','value','tolerance','mustAppear','found','absoluteDifference','status','source'});
outDir = fileparts(outputPath);
if ~isempty(outDir) && ~isfolder(outDir), mkdir(outDir); end
writetable(audit, outputPath);
result = struct();
result.audit = audit;
result.paperPath = paperPath;
result.manifestPath = manifestPath;
result.outputPath = outputPath;
result.forbiddenPhrases = forbidden;
result.forbiddenFound = forbiddenFound;
result.pass = all(~mustAppear | found) && ~any(forbiddenFound);
fprintf('[paper-audit] checked=%d, required_failures=%d, forbidden=%d, pass=%d\n', ...
    n, nnz(mustAppear & ~found), nnz(forbiddenFound), result.pass);
end

function numbers = extractNumbers(text)
tokens = regexp(text, '(?<![A-Za-z_])[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', 'match');
if isempty(tokens)
    numbers = zeros(0,1);
else
    numbers = str2double(tokens(:));
    numbers = numbers(isfinite(numbers));
end
end
