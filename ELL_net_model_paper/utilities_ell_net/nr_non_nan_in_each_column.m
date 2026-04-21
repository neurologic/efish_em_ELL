function nr_non_nan = nr_non_nan_in_each_column(matrix,varargin)

which_non_nan = ~isnan(matrix);
nr_non_nan = sum(which_non_nan,1);

end