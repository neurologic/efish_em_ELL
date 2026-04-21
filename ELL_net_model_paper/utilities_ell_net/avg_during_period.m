function data = avg_during_period(data,length_event_to_analyze,varargin)

p = inputParser;
addRequired(p,'data',@isstruct);
addRequired(p,'length_event_to_analyze',@isnumeric);
addParameter(p,'nr_commands_to_analyze',100);
addParameter(p,'input_type','simple');
addParameter(p,'which_epoch','pairing_mimic');
addParameter(p,'smoothing',false); % if input_type is 'voltage' no smoothing happens.
addParameter(p,'smoothing_window','');
addParameter(p,'smoothing_broad',0.025);
addParameter(p,'standard_deviation',false);
addParameter(p,'Hz',false); % if input_type is 'voltage', Hz must be false
addParameter(p,'align_uncor_to_cmnd',false);

parse(p,data,length_event_to_analyze,varargin{:});
data = p.Results.data;
nr_commands_to_analyze = p.Results.nr_commands_to_analyze;
input_type = p.Results.input_type;
which_epoch = p.Results.which_epoch;
smoothing = p.Results.smoothing;
smoothing_window = p.Results.smoothing_window;
standard_deviation = p.Results.standard_deviation;
smoothing_broad = p.Results.smoothing_broad;
Hz = p.Results.Hz;
align_uncor_to_cmnd = p.Results.align_uncor_to_cmnd;

if isempty(smoothing_window)
    if strcmp(input_type,'simple')
        smoothing_window = 0.01;
    elseif strcmp(input_type,'broad')
        smoothing_window = smoothing_broad;
    elseif strcmp(input_type,'volage')
        smoothing_window = data(1).dt;
    end
end
dt = data(1).dt;
t_before = data(1).t_before;

smoothing_window_dt = floor(smoothing_window/dt);

for ii=1:length(data)
    
    length_to_analyze = ceil((length_event_to_analyze+t_before)/dt); %input of time after command in seconds.
    
    if strcmp(which_epoch,'pairing')
        period_epochs = find(~contains(data(ii).epochs,{'pre','post'}) & ...
            contains(data(ii).epochs,{'pairing'}));
        data_name = [input_type '_rel_command_matrix'];
        event_type = 'command';
    elseif strcmp(which_epoch,'pairing_mimic')
        period_epochs = find(~contains(data(ii).epochs,{'pre','post'}) & ...
            contains(data(ii).epochs,{'pairing_mimic'}));
        data_name = [input_type '_rel_command_matrix'];
        event_type = 'command';
    elseif strcmp(which_epoch,'command_alone')
        period_epochs = find(contains(data(ii).epochs,{'pre','post'}));
        data_name = [input_type '_rel_command_matrix'];
        event_type = 'command';
    elseif strcmp(which_epoch,'uncor')
        period_epochs = find(~contains(data(ii).epochs,{'pre','post','hyp','dep'}) & ...
            contains(data(ii).epochs,{'uncor'}));
        if align_uncor_to_cmnd
            data_name = [input_type '_rel_command_matrix'];
            event_type = 'command';
        else
            data_name = [input_type '_rel_stimulus_matrix'];
            event_type = 'stimulus';
        end
    else
        error('which_epoch is not recognized')
    end
    
    %     data(ii).([which_epoch '_epochs']) = period_epochs;
    %
    if isempty(data(ii).(data_name))
        continue;
    end
    
    
    for jj = 1:length(period_epochs)
        
        name = [which_epoch '_epochs_' num2str(period_epochs(jj)) '_' input_type '_during_period'];
        
        data(ii).([name '_avg']) = [];
        if standard_deviation
            data(ii).([name '_std']) = [];
        end
        data(ii).([name '_sem']) = [];
        data(ii).([name '_period_index']) = {};
        
        period_index = find(ismember(data(ii).([event_type '_epochs']),period_epochs(jj)));
        nr_period_times = floor(length(period_index)/nr_commands_to_analyze);
        index = 1;
        for kk = 1:nr_period_times
            if length(period_index(index:end))< nr_commands_to_analyze+1
                continue
            end
            rows_to_analyze = period_index(index:index+nr_commands_to_analyze-1);
            period_avg = nanmean(data(ii).(data_name)(rows_to_analyze,1:length_to_analyze),1);
            period_std = nanstd(data(ii).(data_name)(rows_to_analyze,1:length_to_analyze),1);
            
            nr_non_nans = nr_non_nan_in_each_column(data(ii).(data_name)(rows_to_analyze,1:length_to_analyze));
            period_sem = period_std./sqrt(nr_non_nans);
            
            if (strcmp(input_type,'simple') || (strcmp(data(ii).cell_name,'20160912_000') ...
                    && strcmp(input_type,'broad') && jj == 2)) &&~isempty(data(ii).stim_artifact) ...
                    && any(period_avg) && contains(data(ii).epochs(period_epochs(jj)),'pairing_mimic') ...
                    && ~contains(data(ii).epochs(period_epochs(jj)),{'pre','post'})
                t_before_dt = data(ii).t_before/dt;
                    if strcmp(data(ii).cell_name,'20181119_009') && contains(data(ii).epochs(period_epochs(jj)),'delay') ...
                        && ~contains(data(ii).epochs(period_epochs(jj)),{'pre','post'})  
                        time_eliminate = floor(t_before_dt+0.011/dt):floor(t_before_dt+0.013/dt);
                    elseif strcmp(data(ii).cell_name,'20181116_002') && contains(data(ii).epochs(period_epochs(jj)),'delay') ...
                        && ~contains(data(ii).epochs(period_epochs(jj)),{'pre','post'})    
                        time_eliminate = floor(t_before_dt+0.029/dt):floor(t_before_dt+0.031/dt);
                    else
                        time_eliminate = floor(t_before_dt+0.003/dt):floor(t_before_dt+0.006/dt);
                    end
                period_avg(time_eliminate) = nan; period_avg = interpolation(period_avg);
                period_std(time_eliminate) = nan; period_std = interpolation(period_std);
                period_sem(time_eliminate) = nan; period_sem = interpolation(period_sem);
            end
            
            if smoothing && ~strcmp(input_type,'voltage')
                period_avg = smoothdata(period_avg,2,'gaussian',smoothing_window_dt,'includenan');
                period_std = smoothdata(period_std,2,'gaussian',smoothing_window_dt,'includenan');
                period_sem = smoothdata(period_sem,2,'gaussian',smoothing_window_dt,'includenan');
            end
            
            if Hz && ~strcmp(input_type,'voltage')
                period_avg = 1/dt*period_avg;
                period_std = 1/dt*period_std;
                period_sem = 1/dt*period_sem;
            end
            
            %             name = [which_epoch '_epochs_' num2str(period_epochs(jj)) '_' input_type '_during_period'];
            
            data(ii).([name '_avg'])(kk,:) = period_avg;
            if standard_deviation
                data(ii).([name '_std'])(kk,:) = period_std;
            end
            data(ii).([name '_sem'])(kk,:) = period_sem;
            data(ii).([name '_period_index']){kk} = rows_to_analyze;
            
            index = index+nr_commands_to_analyze;
        end
    end
end
end