
function R = source_coding(cfg, outDir)
%SOURCE_CODING Entropy and illustrative Huffman code lengths.

p = cfg.symbolProbabilities(:);
if numel(p) ~= numel(cfg.symbolNames) || any(p < 0) || abs(sum(p)-1) > 1e-12
    error('Source probabilities must be nonnegative, match the symbols, and sum to one.');
end

% Calculate source entropy
positive=p>0; H = -sum(p(positive) .* log2(p(positive)));

% Huffman codewords for the configured probabilities [0.4 0.3 0.2 0.1].
if numel(p)~=4 || any(abs(p-[.4;.3;.2;.1])>1e-12)
    error('The supplied Huffman codewords are defined for probabilities [0.4 0.3 0.2 0.1].');
end
codewords = {'0';'10';'110';'111'};
lens = cellfun(@numel,codewords);

% Calculate average code length and coding efficiency
avg = sum(p .* lens);
eff = H / avg;
informationRate=H*cfg.sourceSymbolRate_Hz;
codedRate=avg*cfg.sourceSymbolRate_Hz;

% Create results table
R = table(cfg.symbolNames(:), p, codewords, lens, ...
    'VariableNames', {'Symbol', 'Probability', 'HuffmanCodeword','CodeLength_bits'});

% Save symbol-level results
writetable(R, fullfile(outDir, 'Source_Coding_Results.csv'));

% Store summary values separately
summary = table(cfg.sourceSymbolRate_Hz,H,informationRate,avg,codedRate,eff, ...
    'VariableNames', {'SourceSymbolRate_Hz','Entropy_bits_per_symbol', ...
    'InformationRate_bits_per_second','AverageCodeLength_bits_per_symbol', ...
    'HuffmanEncodedRate_bits_per_second','Efficiency'});

writetable(summary, fullfile(outDir, 'Source_Coding_Summary.csv'));

% Return both results
R = struct('SymbolResults', R, ...
    'Entropy_bits_per_symbol', H, ...
    'InformationRate_bits_per_second', informationRate, ...
    'AverageCodeLength_bits', avg, ...
    'HuffmanEncodedRate_bits_per_second', codedRate, ...
    'Efficiency', eff);

end
