
function result = generateModelPassport(meta, outputPath)
%GENERATEMODELPASSPORT Generate a human- and machine-readable model passport.
% meta is a struct containing assumptions, variables, objective, constraints,
% validation, sensitivity, outputs, limitations and optional key_numbers.
% key_numbers may be a table with columns key, value, tolerance, mustAppear,
% and source. The generated manifest is consumed by auditPaperConsistency.

if nargin < 1 || ~isstruct(meta)
    error('meta must be a struct.');
end
if nargin < 2 || isempty(outputPath)
    outputPath = fullfile(pwd, 'model_passport.md');
end
outputPath = char(outputPath);
outDir = fileparts(outputPath);
if ~isempty(outDir) && ~isfolder(outDir)
    mkdir(outDir);
end

required = {'problem_id','question_id','data_source','estimand','assumptions', ...
    'variables','objective','constraints','script_path','validation', ...
    'sensitivity','outputs','limitations','status'};
missingFields = required(~isfield(meta, required));
if ~isfield(meta, 'status')
    meta.status = 'draft';
end
if ~isfield(meta, 'created_at')
    meta.created_at = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
end

fid = fopen(outputPath, 'w', 'n', 'UTF-8');
if fid < 0
    error('Cannot open passport output: %s', outputPath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '# Model Passport\n\n');
fprintf(fid, '该文件由 MATLAB 自动生成，用于追溯模型、验证与论文数字。\n\n');
fields = fieldnames(meta);
for k = 1:numel(fields)
    name = fields{k};
    value = serializeValue(meta.(name));
    fprintf(fid, '- **%s**: %s\n', name, value);
end
if isempty(missingFields)
    fprintf(fid, '\n## Required fields check\n\nPASS: all required fields are present.\n');
else
    fprintf(fid, '\n## Required fields check\n\nMISSING: %s\n', strjoin(missingFields, ', '));
end
fprintf(fid, '\n## Status meaning\n\n');
fprintf(fid, '- verified: independent checks passed.\n');
fprintf(fid, '- conditionally_verified: result depends on stated assumptions or scenarios.\n');
fprintf(fid, '- blocked: an audit failed; do not use the result as a final conclusion.\n');

jsonPath = [erase(outputPath, '.md') '.json'];
jsonText = jsonencode(meta);
fidJson = fopen(jsonPath, 'w', 'n', 'UTF-8');
if fidJson < 0
    error('Cannot open JSON output: %s', jsonPath);
end
fwrite(fidJson, unicode2native(jsonText, 'UTF-8'), 'uint8');
fclose(fidJson);

manifestPath = '';
if isfield(meta, 'key_numbers') && istable(meta.key_numbers)
    manifestPath = [erase(outputPath, '.md') '_result_manifest.csv'];
    writetable(meta.key_numbers, manifestPath);
end
result = struct('markdownPath', outputPath, 'jsonPath', jsonPath, ...
    'manifestPath', manifestPath, 'missingFields', {missingFields}, ...
    'status', meta.status);
fprintf('[passport] markdown=%s\n', outputPath);
fprintf('[passport] json=%s\n', jsonPath);
if ~isempty(manifestPath)
    fprintf('[passport] manifest=%s\n', manifestPath);
end
end

function text = serializeValue(value)
if ischar(value) || (isstring(value) && isscalar(value))
    text = char(value);
elseif isstring(value)
    text = strjoin(cellstr(value(:)), '; ');
elseif iscell(value)
    parts = cell(size(value));
    for i = 1:numel(value)
        parts{i} = serializeValue(value{i});
    end
    text = strjoin(parts, '; ');
elseif isnumeric(value) || islogical(value)
    if isempty(value)
        text = '[]';
    else
        text = mat2str(value);
    end
elseif isstruct(value)
    text = jsonencode(value);
else
    text = class(value);
end
text = strrep(text, newline, ' ');
end
