function [output] = sem(data,varargin)

p = inputParser;
p.addRequired('data',@isnumeric);
p.addParameter('weighted_sem',false);
p.addParameter('weights',[]);
p.addParameter('use_mat',false);

parse(p,data,varargin{:});
weighted_sem = p.Results.weighted_sem;
weights = p.Results.weights;
use_mat = p.Results.use_mat;

if ismatrix(data) && use_mat % defining sem of each column
    output = nan(1,size(data,2));
    for ii = 1:size(data,2)
        output(ii) = std(data(:,ii),'omitnan')/(sqrt(nnz(~isnan(data(:,ii)))));
    end
else
    length_nnz_data = nnz(~isnan(data));
    if weighted_sem
        sum_weights = sum(weights,'omitnan');
        weighted_mean = sum(weights.*data,'omitnan')/(sum_weights);
        weighted_std = sqrt(sum(weights.*(data-weighted_mean).^2,'omitnan')/(sum_weights*(length_nnz_data-1)/length_nnz_data));
        output = weighted_std/(sqrt(length_nnz_data));
    else
        output = std(data,'omitnan')/(sqrt(length_nnz_data));
    end
    
end
end
