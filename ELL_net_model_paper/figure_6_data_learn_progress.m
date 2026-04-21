% this code generates the data part of figure 6 & S6, looking at progression of
% cancellation in MG and output cells. To look at MG data, set 'use_MG =
% true'. For output data set 'use_MG = false'. To study output voltage data
% set 'input_type = 'voltage'', for analyzing spike response set
% 'input_type = 'simple'';
% To look at MG cell you need first to load 'all_short_mg.mat' from
% 'data_ell_net', and for output you need to upload both,
% 'all_short_output_extra.mat' and 'all_short_op_intra.mat'.
%
% You need to make sure that 'data_ell_net' and 'utilities_ell_net' are in 
% the pathway.
% Analysis of output cells may take a few minutes.

use_MG = true;
input_type = 'voltage';

addpath(genpath(pwd))
%%
fs_text = 8;
font_name = 'Arial';
Font_weight = 'Normal';
dt = 1e-3;
t_before = 0.01;
length_event_to_analyze = .15; %s time after command to analyze
smoothing = true;

nr_commands_to_analyze_during = 4;
periods = {'pairing','command_alone'};

analyze_intra = true;
if use_MG
    input_type = 'broad';
end
%%
if use_MG
    smoothing_broad = 0.01;
    for jj=1:length(periods)
        all_short_mg_all = avg_during_period(all_short_mg_all,length_event_to_analyze,...
            'nr_commands_to_analyze',nr_commands_to_analyze_during,'input_type',input_type,...
            'which_epoch',periods{jj},'smoothing',smoothing,'Hz',true,'smoothing_broad',smoothing_broad);
    end
else
    for jj=1:length(periods)
        if strcmp(input_type,'simple')
            all_short_output_extra = avg_during_period(all_short_output_extra,length_event_to_analyze,...
                'nr_commands_to_analyze',nr_commands_to_analyze_during,'input_type','simple',...
                'which_epoch',periods{jj},'smoothing',smoothing,'Hz',true);

            if analyze_intra
                all_short_output_intra = avg_during_period(all_short_output_intra,length_event_to_analyze,...
                    'nr_commands_to_analyze',nr_commands_to_analyze_during,'input_type','simple',...
                    'which_epoch',periods{jj},'smoothing',smoothing,'Hz',true);
            end
        end
        if strcmp(input_type,'voltage')
            all_short_output_intra = avg_during_period(all_short_output_intra,length_event_to_analyze,...
                'nr_commands_to_analyze',nr_commands_to_analyze_during,'input_type','voltage',...
                'which_epoch',periods{jj},'smoothing',smoothing,'Hz',true);
        end
    end
end
%%
nr_cols = 1300;
min_nr_periods = 5;
norm_var = true;
analyze_cmnd = true;
analyze_response = true;
analyze_progression = true;
if ~use_MG
    pre_pairing_avg = round(12/nr_commands_to_analyze_during);
else
    pre_pairing_avg = round(80/nr_commands_to_analyze_during);
end
max_allowed = Inf;
if use_MG
    nr_rows = 2;
    if norm_var
        max_allowed = 3;
    end
    output_data = progression_analysis(all_short_mg_all,'nr_cols',nr_cols,...
        'max_allowed',max_allowed,'input_type',input_type,'MG',true,...
        'analyze_cmnd',analyze_cmnd,'norm_var',norm_var,...
        'analyze_response',analyze_response,'analyze_progression',analyze_progression,...
        'pre_pairing_avg',pre_pairing_avg);
    e_name = 'BS+';
    i_name = 'BS-';
    title_name = 'MG';
elseif ~use_MG && strcmp(input_type,'simple')
    nr_cols = ceil(24108/nr_commands_to_analyze_during);
    nr_rows = 2;
    if norm_var
        max_allowed = 3;
    end
    output_data = progression_analysis(all_short_output_extra,'nr_cols',nr_cols,...
        'max_allowed',max_allowed,'input_type',input_type,'MG',false,...
        'analyze_cmnd',analyze_cmnd,'norm_var',norm_var,...
        'analyze_response',analyze_response,'analyze_progression',analyze_progression,...
        'pre_pairing_avg',pre_pairing_avg);
    e_name = 'ON';
    i_name = 'OFF';
    title_name = 'output';
elseif ~use_MG && strcmp(input_type,'voltage')
    nr_rows = 1;
    if norm_var
        max_allowed = 2;
    end
    output_data = progression_analysis(all_short_output_intra,'nr_cols',nr_cols,...
        'max_allowed',max_allowed,'input_type',input_type,'MG',false,...
        'analyze_cmnd',analyze_cmnd,'norm_var',norm_var,...
        'analyze_response',analyze_response,'analyze_progression',analyze_progression,...
        'pre_pairing_avg',pre_pairing_avg);
    e_name = 'ON';
    i_name = 'OFF';
    title_name = 'output';
end
var_all_E = output_data.var_all_E;
var_all_I = output_data.var_all_I;
var_bl_E = output_data.var_bl_E;
var_bl_I = output_data.var_bl_I;
if analyze_cmnd
    var_all_cmnd_E = output_data.var_all_cmnd_E;
    var_all_cmnd_I = output_data.var_all_cmnd_I;
end
if analyze_response
    pairing_response_E = output_data.pairing_response_E;
    pairing_response_I = output_data.pairing_response_I;
    pre_pairing_response_E = output_data.pre_pairing_response_E;
    pre_pairing_response_I = output_data.pre_pairing_response_I;
end
if analyze_progression
    progression_E = output_data.progression_E;
    progression_I = output_data.progression_I;
    nr_trials_E = output_data.nr_trials_E;
    nr_trials_I = output_data.nr_trials_I;
    if analyze_cmnd
        progression_cmnd_E = output_data.progression_cmnd_E;
        progression_cmnd_I = output_data.progression_cmnd_I;
        progression_cmnd_sem_E = output_data.progression_cmnd_sem_E;
        progression_cmnd_sem_I = output_data.progression_cmnd_sem_I;
        nr_trials_cmnd_E = output_data.nr_trials_cmnd_E;
        nr_trials_cmnd_I = output_data.nr_trials_cmnd_I;
    end
end

if ~use_MG && strcmp(input_type,'simple') && analyze_intra
    output_data = progression_analysis(all_short_output_intra,'nr_cols',nr_cols,...
        'max_allowed',max_allowed,'input_type',input_type,'MG',false,...
        'analyze_cmnd',analyze_cmnd,'norm_var',norm_var,...
        'analyze_response',analyze_response,'analyze_progression',analyze_progression);

    var_all_E = [var_all_E;output_data.var_all_E];
    var_all_I = [var_all_I;output_data.var_all_I];
    var_bl_E = [var_bl_E;output_data.var_bl_E];
    var_bl_I = [var_bl_I;output_data.var_bl_I];
    if analyze_cmnd
        var_all_cmnd_E = [var_all_cmnd_E;output_data.var_all_cmnd_E];
        var_all_cmnd_I = [var_all_cmnd_I;output_data.var_all_cmnd_I];
    end
    if analyze_response
        pairing_response_E = [pairing_response_E;output_data.pairing_response_E];
        pairing_response_I = [pairing_response_I;output_data.pairing_response_I];
        pre_pairing_response_E = [pre_pairing_response_E;output_data.pre_pairing_response_E];
        pre_pairing_response_I = [pre_pairing_response_I;output_data.pre_pairing_response_I];
    end
    if analyze_progression % sem for intra is not done...
        nr_trials_E = nr_trials_E+output_data.nr_trials_E;
        nr_trials_I = nr_trials_I+output_data.nr_trials_I;

        E_nan_idx = find(isnan(progression_E(:,1))& nr_trials_E>0);
        progression_E(E_nan_idx,:) = 0;
        I_nan_idx = find(isnan(progression_I(:,1))& nr_trials_I>0);
        progression_I(I_nan_idx,:) = 0;

        progression_E_data = output_data.progression_E;
        E_nan_idx = find(isnan(progression_E_data(:,1))& nr_trials_E>0);
        progression_E_data(E_nan_idx,:) = 0;
        progression_I_data = output_data.progression_I;
        I_nan_idx = find(isnan(progression_I_data(:,1))& nr_trials_I>0);
        progression_I_data(I_nan_idx,:) = 0;


        weighted_sum_ext_E = nr_trials_E./(nr_trials_E+output_data.nr_trials_E);
        weighted_sum_ext_I = nr_trials_I./(nr_trials_I+output_data.nr_trials_I);
        weighted_sum_int_E = output_data.nr_trials_E./(nr_trials_E+output_data.nr_trials_E);
        weighted_sum_int_I = output_data.nr_trials_I./(nr_trials_I+output_data.nr_trials_I);
        progression_E = bsxfun(@times, weighted_sum_ext_E,progression_E)+...
            bsxfun(@times, weighted_sum_int_E,progression_E_data);
        progression_I = bsxfun(@times, weighted_sum_ext_I,progression_I)+...
            bsxfun(@times, weighted_sum_int_I,progression_I_data);
        if analyze_cmnd
            nr_trials_cmnd_E = nr_trials_cmnd_E+output_data.nr_trials_cmnd_E;
            nr_trials_cmnd_I = nr_trials_cmnd_I+output_data.nr_trials_cmnd_I;

            E_nan_idx = find(isnan(progression_cmnd_E(:,1))& nr_trials_cmnd_E>0);
            progression_cmnd_E(E_nan_idx,:) = 0;
            I_nan_idx = find(isnan(progression_cmnd_I(:,1))& nr_trials_cmnd_I>0);
            progression_cmnd_I(I_nan_idx,:) = 0;
    
            progression_cmnd_E_data = output_data.progression_cmnd_E;
            E_nan_idx = find(isnan(progression_cmnd_E_data(:,1))& nr_trials_cmnd_E>0);
            progression_cmnd_E_data(E_nan_idx,:) = 0;
            progression_cmnd_I_data = output_data.progression_cmnd_I;
            I_nan_idx = find(isnan(progression_cmnd_I_data(:,1))& nr_trials_cmnd_I>0);
            progression_cmnd_I_data(I_nan_idx,:) = 0;

            weighted_sum_ext_cmnd_E = nr_trials_cmnd_E./(nr_trials_cmnd_E+output_data.nr_trials_cmnd_E);
            weighted_sum_ext_cmnd_I = nr_trials_cmnd_I./(nr_trials_cmnd_I+output_data.nr_trials_cmnd_I);
            weighted_sum_int_cmnd_E = output_data.nr_trials_cmnd_E./(nr_trials_cmnd_E+output_data.nr_trials_cmnd_E);
            weighted_sum_int_cmnd_I = output_data.nr_trials_cmnd_I./(nr_trials_cmnd_I+output_data.nr_trials_cmnd_I);
            progression_cmnd_E = bsxfun(@times, weighted_sum_ext_cmnd_E,progression_cmnd_E)+...
                bsxfun(@times, weighted_sum_int_cmnd_E,progression_cmnd_E_data);
            progression_cmnd_I = bsxfun(@times, weighted_sum_ext_cmnd_I,progression_cmnd_I)+...
                bsxfun(@times, weighted_sum_int_cmnd_I,progression_cmnd_I_data);
        end
    end
end
%%
fs = 8;
x_lim = [0 4];
y_lim = [0 1];
y_label = [input_type ' variance norm.'];
t_min = (0:nr_cols-1)*(nr_commands_to_analyze_during/(60*4));
idx_skip = 3;
t_min = t_min(1:idx_skip:end);
h = figure('Units','inches','Position',[1.5 5 5 nr_rows*2]);
if sum(var_all_E(:,1),'omitnan')>=min_nr_periods
    subplot(nr_rows,2,1)
    mean_data = mean(var_all_E,1,'omitnan');
    mean_data = mean_data(1:idx_skip:end);
    sem_var = sem(var_all_E,'use_mat',true);
    sem_var = sem_var(1:idx_skip:end);
    mean_bl = mean(var_bl_E,'omitnan');
    sem_bl = sem(var_bl_E);
    plot(t_min,mean_data,'k','LineWidth',1)
    % hold on
    % plot(t_min,mean_data,'k.','markersize',10)
    hold on
    plot(t_min,mean_data+sem_var,'k','LineWidth',.75)
    hold on
    plot(t_min,mean_data-sem_var,'k','LineWidth',.75)
    hold on
    plot(x_lim,[mean_bl mean_bl],'k--','LineWidth',1)
    hold on
    plot(x_lim,[mean_bl+sem_bl mean_bl+sem_bl],'k--','LineWidth',.5)
    hold on
    plot(x_lim,[mean_bl-sem_bl mean_bl-sem_bl],'k--','LineWidth',.5)
    xlim(x_lim)
    ylim(y_lim)
    ylabel(y_label)
    xlabel('time (min)')
    title(e_name)
    set(gca, 'FontSize', fs,'FontName','Arial','Color', 'none')
    box off
end

if sum(var_all_I(:,1),'omitnan')>=min_nr_periods
    subplot(nr_rows,2,2)
    mean_data = mean(var_all_I,1,'omitnan');
    mean_data = mean_data(1:idx_skip:end);
    sem_var = sem(var_all_I,'use_mat',true);
    sem_var = sem_var(1:idx_skip:end);
    mean_bl = mean(var_bl_I,'omitnan');
    sem_bl = sem(var_bl_I);
    plot(t_min,mean_data,'k','LineWidth',1.5)
    % hold on
    % plot(t_min,mean_data,'k.','markersize',10)
    hold on
    plot(t_min,mean_data+sem_var,'k','LineWidth',.75)
    hold on
    plot(t_min,mean_data-sem_var,'k','LineWidth',.75)
    hold on
    plot(x_lim,[mean_bl mean_bl],'k--','LineWidth',1)
    hold on
    plot(x_lim,[mean_bl+sem_bl mean_bl+sem_bl],'k--','LineWidth',.5)
    hold on
    plot(x_lim,[mean_bl-sem_bl mean_bl-sem_bl],'k--','LineWidth',.5)
    xlim(x_lim)
    % ylim(y_lim)
    xlabel('time (min)')
    title(i_name)
    set(gca, 'FontSize', fs,'FontName','Arial','Color', 'none')
    box off
end
if analyze_cmnd
    if sum(var_all_cmnd_E(:,1),'omitnan')>=min_nr_periods && analyze_cmnd
        subplot(nr_rows,2,3)
        mean_data = mean(var_all_cmnd_E,1,'omitnan');
        mean_data = mean_data(1:idx_skip:end);
        sem_var = sem(var_all_cmnd_E,'use_mat',true);
        sem_var = sem_var(1:idx_skip:end);
        plot(t_min,mean_data,'k','LineWidth',2)
        % hold on
        % plot(t_min,mean_data,'k.','markersize',20)
        hold on
        plot(t_min,mean_data+sem_var,'k','LineWidth',.75)
        hold on
        plot(t_min,mean_data-sem_var,'k','LineWidth',.75)
        if ~norm_var
            mean_bl = mean([var_bl_E;var_bl_I],'omitnan');
            sem_bl = sem([var_bl_E;var_bl_I]);
            hold on
            plot(x_lim,[mean_bl mean_bl],'k--','LineWidth',1)
            hold on
            plot(x_lim,[mean_bl+sem_bl mean_bl+sem_bl],'k--','LineWidth',.5)
            hold on
            plot(x_lim,[mean_bl-sem_bl mean_bl-sem_bl],'k--','LineWidth',.5)
        end
        xlim(x_lim)
        ylim(y_lim)
        ylabel(y_label)
        xlabel('time (min)')
        title(['recovery from ' i_name])
        set(gca, 'FontSize', fs,'FontName','Arial','Color', 'none')
        box off
    end

    if sum(var_all_cmnd_I(:,1),'omitnan')>=min_nr_periods && analyze_cmnd
        subplot(nr_rows,2,4)
        mean_data = mean(var_all_cmnd_I,1,'omitnan');
        mean_data = mean_data(1:idx_skip:end);
        sem_var = sem(var_all_cmnd_I,'use_mat',true);
        sem_var = sem_var(1:idx_skip:end);
        plot(t_min,mean_data,'k','LineWidth',2)
        % hold on
        % plot(t_min,mean_data,'k.','markersize',20)
        hold on
        plot(t_min,mean_data+sem_var,'k','LineWidth',.75)
        hold on
        plot(t_min,mean_data-sem_var,'k','LineWidth',.75)
        if ~norm_var
            mean_bl = mean([var_bl_E;var_bl_I],'omitnan');
            sem_bl = sem([var_bl_E;var_bl_I]);
            hold on
            plot(x_lim,[mean_bl mean_bl],'k--','LineWidth',1)
            hold on
            plot(x_lim,[mean_bl+sem_bl mean_bl+sem_bl],'k--','LineWidth',.5)
            hold on
            plot(x_lim,[mean_bl-sem_bl mean_bl-sem_bl],'k--','LineWidth',.5)
        end
        xlim(x_lim)
        % ylim(y_lim)
        xlabel('time (min)')
        title(['recovery from ' e_name])
        set(gca, 'FontSize', fs,'FontName','Arial','Color', 'none')
        box off
    end
end
sgtitle([title_name ' - time of each sample = ' num2str(nr_commands_to_analyze_during/4) 's'],'FontSize',fs)

%%
if analyze_response
    tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
    h = figure('units','inches','position',[2,4.5,10,5]);
    subplot(1,2,1)
    plot(tt,mean(pairing_response_E,1,'omitnan'),'linewidth',2)
    hold on
    plot(tt,mean(pre_pairing_response_E,1,'omitnan'),'linewidth',2)
    legend('response','pre response','autoupdate','off')
    legend('boxoff')

    mean_data = mean(pairing_response_E,1,'omitnan');
    sem_data = sem(pairing_response_E,'use_mat',true);
    hold on
    plot(tt,mean_data+sem_data,'k','LineWidth',.75)
    hold on
    plot(tt,mean_data-sem_data,'k','LineWidth',.75)

    mean_pre = mean(pre_pairing_response_E,'omitnan');
    sem_pre = sem(pre_pairing_response_E,'use_mat',true);
    hold on
    plot(tt,mean_pre+sem_pre,'k--','LineWidth',.5)
    hold on
    plot(tt,mean_pre-sem_pre,'k--','LineWidth',.5)

    axis tight
    xlabel('time (ms)')
    ylabel(input_type)
    % title([title_name ' E response'])
    set(gca, 'FontSize', 12,'FontName','Arial','Color', 'none')
    box off

    subplot(1,2,2)
    plot(tt,mean(pairing_response_I,1,'omitnan'),'linewidth',2)
    hold on
    plot(tt,mean(pre_pairing_response_I,1,'omitnan'),'linewidth',2)
    legend('response','pre response','autoupdate','off')
    legend('boxoff')

    mean_data = mean(pairing_response_I,1,'omitnan');
    sem_data = sem(pairing_response_I,'use_mat',true);
    hold on
    plot(tt,mean_data+sem_data,'k','LineWidth',.75)
    hold on
    plot(tt,mean_data-sem_data,'k','LineWidth',.75)

    mean_pre = mean(pre_pairing_response_I,'omitnan');
    sem_pre = sem(pre_pairing_response_I,'use_mat',true);
    hold on
    plot(tt,mean_pre+sem_pre,'k--','LineWidth',.5)
    hold on
    plot(tt,mean_pre-sem_pre,'k--','LineWidth',.5)

    axis tight
    xlabel('time (ms)')
    ylabel(input_type)
    % title([title_name ' E response'])
    set(gca, 'FontSize', 12,'FontName','Arial','Color', 'none')
    box off

    sgtitle([title_name ' - time of each sample = ' num2str(nr_commands_to_analyze_during/4) 's'])
end
%%
if analyze_progression
    base_map = jet(256);  % Full resolution colormap

    h = figure('units','inches','position',[2,4.5,5,5]);
    min_4 = round(4*4*60/nr_commands_to_analyze_during);

    plot_every_e = round(6*4/nr_commands_to_analyze_during); %floor(nr_trials/50);
    avg_e = round(plot_every_e/3);

    plot_every_i = round(18*4/nr_commands_to_analyze_during);
    avg_i = round(plot_every_i/3);

    nr_cols_analyze_E = min(min_4,find(nr_trials_E>=min_nr_periods,1,'last'));%find(nr_trials_E>=8,1,'last'); %
    nr_cols_analyze_I = min(min_4,find(nr_trials_I>=min_nr_periods,1,'last'));%find(nr_trials_I>=8,1,'last'); %

    trials_to_plot_E = 1:plot_every_e:nr_cols_analyze_E-avg_e;
    trials_to_plot_I = 1:plot_every_i:nr_cols_analyze_I-avg_i;
    
    tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);

    all_axes(1) = subplot(2,2,1);
    map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_to_plot_E)));
    cmap = colormap(map1); %jet(length(trials_to_plot_E));
    idx = 1;
    for ll = trials_to_plot_E
        if ll==1
            plot(tt,progression_E(ll,:),'linewidth',1,'color',cmap(idx,:));
        else
            plot(tt,mean(progression_E(ll-avg_e:ll+avg_e,:),1),'linewidth',1,'color',cmap(idx,:));
        end
        hold on
        idx = idx+1;
    end
    if analyze_response 
        mean_pre = mean(pre_pairing_response_E,'omitnan');
        sem_pre = sem(pre_pairing_response_E,'use_mat',true);
        hold on
        plot(tt,mean_pre,'linewidth',1,'color','k');
        hold on
        plot(tt,mean_pre+sem_pre,'k--','LineWidth',.5)
        hold on
        plot(tt,mean_pre-sem_pre,'k--','LineWidth',.5)

    end
    axis tight
    xlabel('time (ms)')
    ylabel([input_type ' ' e_name])

    ax = gca;
    y_lim = ax.YLim;
    if contains(input_type,{'broad'})
        ylim([0 65])
    elseif contains(input_type,{'simple'}) && ~use_MG
        ylim([5 147])
    end

    title(['progression over ' num2str(nr_cols_analyze_E*nr_commands_to_analyze_during/(4*60)) 'min'])
    set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
    box off
    % colormap(cmap)
    % cbr = colorbar('Ticks',[0.1 .9]);
    % cbr.TickLabels = {'early','late'};
    % cbr.Ruler.TickLabelRotation=90;

    map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_to_plot_I)));
    cmap = colormap(map1); %jet(length(trials_to_plot_E));
    all_axes(2) = subplot(2,2,2);
    idx = 1;
    for ll = trials_to_plot_I
        if ll==1
            plot(tt,mean(progression_I(ll:ll+avg_i,:),1),'linewidth',1,'color',cmap(idx,:));
        else
            plot(tt,mean(progression_I(ll-avg_i:ll+avg_i,:),1),'linewidth',1,'color',cmap(idx,:));
        end
        hold on
        idx = idx+1;
    end
    if analyze_response %&& ~use_MG
        mean_pre = mean(pre_pairing_response_I,'omitnan');
        sem_pre = sem(pre_pairing_response_I,'use_mat',true);
        hold on
        plot(tt,mean_pre,'linewidth',1,'color','k');
        hold on
        plot(tt,mean_pre+sem_pre,'k--','LineWidth',.5)
        hold on
        plot(tt,mean_pre-sem_pre,'k--','LineWidth',.5)

    end
    axis tight
    xlabel('time (ms)')
    ylabel([input_type ' ' i_name])
    ax = gca;
    y_lim = ax.YLim;
    if contains(input_type,{'broad'})
        ylim([0 5])
    elseif contains(input_type,{'simple'}) && ~use_MG
        ylim([0 35])
    elseif contains(input_type,{'voltage'})
        ylim([-2.25 1.5])
    end
    title(['progression over ' num2str(nr_cols_analyze_I*nr_commands_to_analyze_during/(60*4)) 'min'])
    set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
    box off
    % colormap(cmap)
    % cbr = colorbar('Ticks',[0.1 .9]);
    % cbr.TickLabels = {'early','late'};
    % cbr.Ruler.TickLabelRotation=90;

    if analyze_cmnd
        if ~use_MG && strcmp(input_type,'simple')
            progression_cmnd_I_bl = mean(progression_cmnd_I(:,1:10),2);
            progression_cmnd_I_bl_subtract = bsxfun(@minus,progression_cmnd_I,progression_cmnd_I_bl)+21;
        else
            progression_cmnd_I_bl_subtract = progression_cmnd_I;
        end
        nr_cols_analyze_E = min(min_4,find(nr_trials_cmnd_E>=min_nr_periods,1,'last'));%find(nr_trials_E>=8,1,'last'); %
        nr_cols_analyze_I = min(min_4,find(nr_trials_cmnd_I>=min_nr_periods,1,'last'));%find(nr_trials_I>=8,1,'last'); %

        trials_to_plot_E = 1:plot_every_e:nr_cols_analyze_E-avg_e;
        trials_to_plot_I = 1:plot_every_i:nr_cols_analyze_I-avg_i;

        map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_to_plot_E)));
        cmap = colormap(map1); %jet(length(trials_to_plot_E));
        all_axes(1) = subplot(2,2,4);
        idx = 1;
        for ll = trials_to_plot_E
            if ll==1
                plot(tt,progression_cmnd_E(ll,:),'linewidth',1,'color',cmap(idx,:));
            else
                plot(tt,mean(progression_cmnd_E(ll-avg_e:ll+avg_e,:),1),'linewidth',1,'color',cmap(idx,:));
            end
            hold on
            idx = idx+1;
        end
        axis tight
        xlabel('time (ms)')
        ylabel([input_type ' ' i_name])
        ax = gca;
        y_lim = ax.YLim;
        if contains(input_type,{'broad'})
            ylim([0 65])
        elseif contains(input_type,{'simple'}) && ~use_MG
            ylim([5 147])
        end
        title(['recovery over ' num2str(nr_cols_analyze_E*nr_commands_to_analyze_during/(4*60)) 'min'])
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off

        % colormap(cmap)
        % cbr = colorbar('Ticks',[0.1 .9]);
        % cbr.TickLabels = {'early','late'};
        % cbr.Ruler.TickLabelRotation=90;

        map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_to_plot_I)));
        cmap = colormap(map1);
        all_axes(2) = subplot(2,2,3);
        idx = 1;
        for ll = trials_to_plot_I
            if ll==1
                plot(tt,mean(progression_cmnd_I_bl_subtract(ll:ll+avg_i,:),1),'linewidth',1,'color',cmap(idx,:));
            else
                plot(tt,mean(progression_cmnd_I_bl_subtract(ll-avg_i:ll+avg_i,:),1),'linewidth',1,'color',cmap(idx,:));
            end
            hold on
            idx = idx+1;
        end
        axis tight
        xlabel('time (ms)')
        ylabel([input_type ' ' e_name])
        ax = gca;
        y_lim = ax.YLim;
        if contains(input_type,{'broad'})
            ylim([0 5])
        elseif contains(input_type,{'simple'}) && ~use_MG
            ylim([0 35])
        end
        title(['recovery over ' num2str(nr_cols_analyze_I*nr_commands_to_analyze_during/(60*4)) 'min'])
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off
        % colormap(cmap)
        % cbr = colorbar('Ticks',[0.1 .9]);
        % cbr.TickLabels = {'early','late'};
        % cbr.Ruler.TickLabelRotation=90;
    end
    sgtitle([title_name ' - time of first sample = ' num2str(nr_commands_to_analyze_during/4) 's'],'FontSize', 8)
end
%%
ON_color = [254, 39, 18]./255;
OFF_color = [2, 71, 254]./255;
MGm_color = [0, 203, 255]./255;
MGp_color = [251, 153, 2]./255;

if analyze_progression && use_MG
    h = figure('units','inches','position',[2,4.5,5,5]);
    tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);

    subplot(2,2,1)
    plot(tt,progression_cmnd_E(1,:),'linewidth',2,'color',MGm_color)
    hold on
    plot(tt,progression_cmnd_E(1,:)+progression_cmnd_sem_E(1,:),'linewidth',.75,'color',MGm_color)
    hold on
    plot(tt,progression_cmnd_E(1,:)-progression_cmnd_sem_E(1,:),'linewidth',.75,'color',MGm_color)
    ylim([0 65])
    xlim([tt(1) tt(end)])
    ylabel('broad spike rate (Hz)')
    xlabel('time (ms)')
    set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
    box off
    sgtitle([title_name ' - time of first sample = ' num2str(nr_commands_to_analyze_during/4) 's'],'FontSize', 8)
end
%% This snippet generates the supplementary plot showing the ratio of initial responses of MG+:Output-ON
% to generate the plot, you need to run MG first and Output second.
ON_color = [254, 39, 18]./255;
OFF_color = [2, 71, 254]./255;
MGm_color = [0, 203, 255]./255;
MGp_color = [251, 153, 2]./255;

if analyze_response
    idx_analyze = 10:60;
    max_E = max(pairing_response_E(:,idx_analyze),[],2);
    bl_E_all = mean(pre_pairing_response_E(:,[1:10 100:150]),2,'omitnan');
    bl_E = mean(bl_E_all,'omitnan');
    bl_E_all(bl_E_all < 0.2) = nan;

    tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
    if use_MG
        h_mx_plot = figure('units','inches','position',[2,4.5,5,5]);
        subplot(2,2,1)
        plot(tt,(pairing_response_E),'linewidth',1)
        axis tight
        xlabel('time (ms)')
        ylabel([input_type ' ' e_name])
        title(['ratio of peak to bl = ' num2str(mean(max_E./bl_E,'omitnan'))])
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off
        
        max_mg = max_E;
        bl_mg = bl_E;
        subplot(2,2,3)
        hBar = bar(mean(max_E./bl_E,'omitnan'),'FaceColor',[0.5 .5 .5],'EdgeColor',[0.5 .5 .5],'LineWidth',1.5);
        hold on
        width_scatter = .25;
        color_dots = MGp_color;
        MS = 10;
        x = -width_scatter+(2*width_scatter)*rand(1,length(max_E));
        plot(1+x,max_E./bl_E,'.','MarkerSize',MS,'color',color_dots)
        xlabel('BS+ (broad)')
        ylabel('max response (Hz)/baseline')
        title(['mean = ' num2str(mean(max_E./bl_E,'omitnan'))])
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off
    elseif strcmp(input_type,'simple')

        figure(h_mx_plot);
        subplot(2,2,2)
        plot(tt,(pairing_response_E),'linewidth',1)
        axis tight
        xlabel('time (ms)')
        ylabel([input_type ' ' e_name])
        title(['ratio of peak to bl = ' num2str(mean(max_E./bl_E,'omitnan'))])
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off

        max_op = max_E;
        bl_op = bl_E;

        subplot(2,2,4)
        hBar = bar(mean(max_E./bl_E,'omitnan'),'FaceColor',[0.5 .5 .5],'EdgeColor',[0.5 .5 .5],'LineWidth',1.5);
        hold on
        width_scatter = .25;
        color_dots = ON_color;
        MS = 10;
        x = -width_scatter+(2*width_scatter)*rand(1,length(max_E));
        plot(1+x,max_E./bl_E,'.','MarkerSize',MS,'color',color_dots)
        xlabel('Output ON')
        ylabel(['max ' input_type ' ' e_name '/baseline'])
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off

%%
        h = figure('units','inches','position',[2,4.5,1,2]);
        mean_data = [mean(max_mg./bl_mg,'omitnan') mean(max_op./bl_op,'omitnan')];
        hBar = bar(mean_data,'FaceColor',[0.5 .5 .5],'EdgeColor',[0.5 .5 .5],'LineWidth',1.5);
        ax = gca;
        ax.XTickLabel = {'MG+','ON'};
        
        width_scatter = .25;
        MS = 5;

        hold on
        x = -width_scatter+(2*width_scatter)*rand(1,length(max_mg));
        plot(1+x,max_mg./bl_mg,'.','MarkerSize',MS,'color',MGp_color)
        hold on
        x = -width_scatter+(2*width_scatter)*rand(1,length(max_op));
        plot(2+x,max_op./bl_op,'.','MarkerSize',MS,'color',ON_color)
        
        ylabel('max response (Hz)/baseline')
        set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
        box off
    end
end