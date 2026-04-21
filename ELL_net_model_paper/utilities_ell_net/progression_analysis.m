function output_data = progression_analysis(data,varargin)

p = inputParser;
addRequired(p,'data',@isstruct); % struct containing data
addParameter(p,'nr_cols',1000);
addParameter(p,'max_allowed',4);
addParameter(p,'input_type','broad');
addParameter(p,'MG',false);
addParameter(p,'analyze_cmnd',true)
addParameter(p,'norm_var',true);
addParameter(p,'analyze_response',true);
addParameter(p,'analyze_progression',true);
addParameter(p,'pre_pairing_avg',1);
addParameter(p,'use_uncor',false);
addParameter(p,'min_nr_cols',1);

parse(p,data,varargin{:});
nr_cols = p.Results.nr_cols;
max_allowed = p.Results.max_allowed;
input_type = p.Results.input_type;
MG = p.Results.MG;
analyze_cmnd = p.Results.analyze_cmnd;
norm_var = p.Results.norm_var;
analyze_response = p.Results.analyze_response;
analyze_progression = p.Results.analyze_progression;
pre_pairing_avg = p.Results.pre_pairing_avg;
use_uncor = p.Results.use_uncor;
min_nr_cols = p.Results.min_nr_cols;

undesired_type = {'hyp','dep','duplicate','ms','eliminate','short','wide','current','-I','-i','0pa','local','delay'};
output_data = struct;
if MG
    e_name = 'bs_e';
    i_name = 'bs_i';
else
    e_name = 'E';
    i_name = 'I';
end

var_all_E = nan(2*length(data),nr_cols);
var_all_I = nan(2*length(data),nr_cols);
var_bl_E = nan(2*length(data),1);
var_bl_I = nan(2*length(data),1);
pairing_response_E = nan(2*length(data),160);
pairing_response_I = nan(2*length(data),160);
pre_pairing_response_E = nan(2*length(data),160);
pre_pairing_response_I = nan(2*length(data),160);
idx_E = 1;
idx_I = 1;

for ii = 1:length(data)
    for jj = 1:length(data(ii).epochs)
        field_name = ['pairing_epochs_' num2str(jj) '_'  input_type '_during_period_avg'];
        bl_field_name = ['command_alone_epochs_' num2str(jj-1) '_'  input_type '_during_period_avg'];
        pairing_during = [];
        pre_pairing = [];
        if isfield(data,field_name)
            pairing_during = data(ii).(field_name);
            if isfield(data,bl_field_name) && ~contains(data(ii).epochs{jj-1},undesired_type)
                pre_pairing = data(ii).(bl_field_name);
            end
        end
        if ~isfield(data,field_name) || contains(data(ii).epochs{jj},undesired_type)
            continue
        end

        if ~isempty(pairing_during) && size(pairing_during,1) >= min_nr_cols %&& any(~isnan(pairing_during(:)))
            if strcmp(input_type,'voltage')
                bl_volt = mean(pairing_during(:,1:10),2);
                pairing_during = bsxfun(@minus,pairing_during,bl_volt);
            end
            var_1 = var(pairing_during,[],2,'omitnan');
            var_first = var_1(1);
            if norm_var && var_first == 0
                var_first = nan;
            end
            if norm_var
                var_1 = var_1./var_first;
            end
            if ~isempty(pre_pairing)
                if strcmp(input_type,'voltage')
                    bl_volt = mean(pre_pairing(:,1:10),2);
                    pre_pairing = bsxfun(@minus,pre_pairing,bl_volt);
                end
                var_bl = var(pre_pairing(end,:),'omitnan');
                if norm_var
                    var_bl = var_bl./var_first;
                end
            end

            if (contains(data(ii).cell_type,e_name) && ...
                    contains(data(ii).epochs{jj},'-')) || ...
                    (contains(data(ii).cell_type,i_name) && ...
                    ~contains(data(ii).epochs{jj},'-'))
                if max(var_1)<max_allowed
                    var_all_E(idx_E,1:min(nr_cols,length(var_1))) = var_1(1:min(nr_cols,length(var_1)));
                    if ~isempty(pre_pairing)&& var_bl<max_allowed
                        var_bl_E(idx_E) = var_bl;
                        if analyze_response
                            pre_pairing_response_E(idx_E,:) = mean(pre_pairing(end-pre_pairing_avg+1:end,:),1);
                        end
                    end
                    if analyze_response
                        pairing_response_E(idx_E,:) = pairing_during(1,:);
                    end
                    idx_E = idx_E+1;
                end
            elseif (contains(data(ii).cell_type,e_name) && ...
                    ~contains(data(ii).epochs{jj},'-')) || ...
                    (contains(data(ii).cell_type,i_name) && ...
                    contains(data(ii).epochs{jj},'-'))
                var_all_I(idx_I,1:min(nr_cols,length(var_1))) = var_1(1:min(nr_cols,length(var_1)));
                if ~isempty(pre_pairing) %&& var_bl<max_allowed
                    var_bl_I(idx_I) = var_bl;
                    if analyze_response
                        pre_pairing_response_I(idx_I,:) = mean(pre_pairing(end-min(pre_pairing_avg,size(pre_pairing,1))+1:end,:),1);
                    end
                end
                if analyze_response
                    pairing_response_I(idx_I,:) = pairing_during(1,:);
                end
                idx_I = idx_I+1;
            end
        end
    end
end
output_data.var_all_E = var_all_E;
output_data.var_all_I = var_all_I;
output_data.var_bl_E = var_bl_E;
output_data.var_bl_I = var_bl_I;
output_data.pairing_response_E = pairing_response_E;
output_data.pairing_response_I = pairing_response_I;
output_data.pre_pairing_response_E = pre_pairing_response_E;
output_data.pre_pairing_response_I = pre_pairing_response_I;

if analyze_cmnd
    var_all_cmnd_E = nan(2*length(data),nr_cols);
    var_all_cmnd_I = nan(2*length(data),nr_cols);
    idx_cmnd_E = 1;
    idx_cmnd_I = 1;

    for ii = 1:length(data)
        for jj = 1:length(data(ii).epochs)
            field_name_cmnd = ['command_alone_epochs_' num2str(jj) '_'  input_type '_during_period_avg'];
            field_name_pre_cmnd = ['pairing_epochs_' num2str(jj-1) '_'  input_type '_during_period_avg'];
            command_during = [];
            if isfield(data,field_name_cmnd) && isfield(data,field_name_pre_cmnd) ...
                    && ~isempty(data(ii).(field_name_pre_cmnd)) && ~isempty(data(ii).(field_name_cmnd)) ...
                    && ~contains(data(ii).epochs{jj-1},undesired_type)
                command_during = data(ii).(field_name_cmnd);
            end
            if ~isfield(data,field_name_cmnd) || contains(data(ii).epochs{jj},undesired_type)
                continue
            end

            if ~isempty(command_during) && size(command_during,1) >= min_nr_cols
                var_1 = var(command_during,[],2,'omitnan');
                var_first = var_1(1);
                if norm_var && var_first == 0
                    var_first = nan;
                end

                if norm_var
                    var_1 = var_1./var_first;
                end

                if (contains(data(ii).cell_type,e_name) && ...
                        contains(data(ii).epochs{jj-1},'-')) || ...
                        (contains(data(ii).cell_type,i_name) && ...
                        ~contains(data(ii).epochs{jj-1},'-'))
                    var_all_cmnd_I(idx_cmnd_I,1:min(nr_cols,length(var_1))) = var_1(1:min(nr_cols,length(var_1)));
                    idx_cmnd_I = idx_cmnd_I+1;
                elseif (contains(data(ii).cell_type,e_name) && ...
                        ~contains(data(ii).epochs{jj-1},'-')) || ...
                        (contains(data(ii).cell_type,i_name) && ...
                        contains(data(ii).epochs{jj-1},'-'))
                    if max(var_1)<max_allowed
                        var_all_cmnd_E(idx_cmnd_E,1:min(nr_cols,length(var_1))) = var_1(1:min(nr_cols,length(var_1)));
                        idx_cmnd_E = idx_cmnd_E+1;
                    end
                end

            end
        end
    end
    output_data.var_all_cmnd_E = var_all_cmnd_E;
    output_data.var_all_cmnd_I = var_all_cmnd_I;
end

if analyze_progression

    progression_E = nan(nr_cols,160);
    progression_I = nan(nr_cols,160);
    nr_trials_cmnd_E = zeros(nr_cols,1);
    nr_trials_cmnd_I = zeros(nr_cols,1);
    for mm = 1:nr_cols
        temp_E = [];
        temp_I = [];
        for ii = 1:length(data)
            for jj = 1:length(data(ii).epochs)
                if use_uncor
                    field_name = ['uncor_epochs_' num2str(jj) '_'  input_type '_during_period_avg'];
                else
                    field_name = ['pairing_epochs_' num2str(jj) '_'  input_type '_during_period_avg'];
                end
                pairing_during = [];

                if isfield(data,field_name) && ~isempty(data(ii).(field_name))
                    pairing_during = data(ii).(field_name);
                    if strcmp(input_type,'voltage')
                        bl_volt = mean(pairing_during(:,1:10),2);
                        pairing_during = bsxfun(@minus,pairing_during,bl_volt);
                    end
                    % if MG && strcmp(input_type,'simple')
                    %     pairing_during = pairing_during-mean(pairing_during(1:2,:),1,'omitnan');
                    % end

                    var_1 = var(pairing_during,[],2,'omitnan');
                    var_first = var_1(1);
                    if norm_var && var_first == 0
                        var_first = nan;
                    end
                    if norm_var
                        var_1 = var_1./var_first;
                    end
                end
                if ~isfield(data,field_name) || contains(data(ii).epochs{jj},undesired_type)
                    continue
                end
                if ~isempty(pairing_during) && size(pairing_during,1)>=mm && size(pairing_during,1)>=min_nr_cols
                    if (contains(data(ii).cell_type,e_name) && ...
                            contains(data(ii).epochs{jj},'-')) || ...
                            (contains(data(ii).cell_type,i_name) && ...
                            ~contains(data(ii).epochs{jj},'-'))
                        if max(var_1)<max_allowed
                            temp_E = [temp_E;pairing_during(mm,:)];
                        end
                    elseif (contains(data(ii).cell_type,e_name) && ...
                            ~contains(data(ii).epochs{jj},'-')) || ...
                            (contains(data(ii).cell_type,i_name) && ...
                            contains(data(ii).epochs{jj},'-'))
                        temp_I = [temp_I;pairing_during(mm,:)];
                    end
                end
            end
        end
        if ~isempty(temp_E)
            progression_E(mm,:) = mean(temp_E,1,'omitnan');
            nr_trials_cmnd_E(mm) = sum(~isnan(temp_E(:,1)));
        end
        if ~isempty(temp_I)
            progression_I(mm,:) = mean(temp_I,1,'omitnan');
            nr_trials_cmnd_I(mm) = sum(~isnan(temp_I(:,1)));
        end
    end
    output_data.progression_E = progression_E;
    output_data.progression_I = progression_I;
    output_data.nr_trials_E = nr_trials_cmnd_E;
    output_data.nr_trials_I = nr_trials_cmnd_I;
end

if analyze_cmnd && analyze_progression
    progression_cmnd_E = nan(nr_cols,160);
    progression_cmnd_I = nan(nr_cols,160);
    progression_cmnd_sem_E = nan(nr_cols,160);
    progression_cmnd_sem_I = nan(nr_cols,160);
    nr_trials_cmnd_E = zeros(nr_cols,1);
    nr_trials_cmnd_I = zeros(nr_cols,1);
    for mm = 1:nr_cols
        temp_E = [];
        temp_I = [];
        for ii = 1:length(data)
            for jj = 1:length(data(ii).epochs)
                field_name_cmnd = ['command_alone_epochs_' num2str(jj) '_'  input_type '_during_period_avg'];
                field_name_pre_cmnd = ['pairing_epochs_' num2str(jj-1) '_'  input_type '_during_period_avg'];
                command_during = [];
                if isfield(data,field_name_cmnd) && isfield(data,field_name_pre_cmnd) ...
                        && ~isempty(data(ii).(field_name_pre_cmnd)) && ~isempty(data(ii).(field_name_cmnd)) ...
                        && ~contains(data(ii).epochs{jj-1},undesired_type)
                    command_during = data(ii).(field_name_cmnd);
                    if strcmp(input_type,'voltage')
                        bl_volt = mean(command_during(:,1:10),2); 
                        command_during = bsxfun(@minus,command_during,bl_volt);
                    end
                    var_1 = var(command_during,[],2,'omitnan');
                    var_first = var_1(1);
                    if norm_var && var_first == 0
                        var_first = nan;
                    end

                    if norm_var
                        var_1 = var_1./var_first;
                    end
                end

                if ~isfield(data,field_name_cmnd) || contains(data(ii).epochs{jj},undesired_type)
                    continue
                end

                if ~isempty(command_during) && size(command_during,1)>=mm && size(command_during,1)>=min_nr_cols
                    if (contains(data(ii).cell_type,e_name) && ...
                            contains(data(ii).epochs{jj-1},'-')) || ...
                            (contains(data(ii).cell_type,i_name) && ...
                            ~contains(data(ii).epochs{jj-1},'-'))
                        temp_I = [temp_I;command_during(mm,:)];

                    elseif (contains(data(ii).cell_type,e_name) && ...
                            ~contains(data(ii).epochs{jj-1},'-')) || ...
                            (contains(data(ii).cell_type,i_name) && ...
                            contains(data(ii).epochs{jj-1},'-'))
                        if max(var_1)<max_allowed
                            temp_E = [temp_E;command_during(mm,:)];
                        end
                    end
                end
            end
            if ~isempty(temp_E)
                progression_cmnd_E(mm,:) = mean(temp_E,1,'omitnan');
                progression_cmnd_sem_E(mm,:) = sem(temp_E,'use_mat',true);
                nr_trials_cmnd_E(mm) = sum(~isnan(temp_E(:,1)));
            end
            if ~isempty(temp_I)
                progression_cmnd_I(mm,:) = mean(temp_I,1,'omitnan');
                progression_cmnd_sem_I(mm,:) = sem(temp_I,'use_mat',true);
                nr_trials_cmnd_I(mm) = sum(~isnan(temp_I(:,1)));
            end
        end
        output_data.progression_cmnd_E = progression_cmnd_E;
        output_data.progression_cmnd_I = progression_cmnd_I;
        output_data.progression_cmnd_sem_E = progression_cmnd_sem_E;
        output_data.progression_cmnd_sem_I = progression_cmnd_sem_I;
        output_data.nr_trials_cmnd_E = nr_trials_cmnd_E;
        output_data.nr_trials_cmnd_I = nr_trials_cmnd_I;
    end
end