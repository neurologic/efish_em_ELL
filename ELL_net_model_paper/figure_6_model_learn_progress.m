% This code produces Figure 6 & S6 showing cancellation progression in the
% model using the real granule cell basis set. You need to make sure that
% 'data_ell_net' and 'utilities_ell_net' are in the pathway.


fs = 8;
font_name = 'Arial';
%%
params_real
nr_trials_bl = 100;
nr_trials_learning = 4*60*4+nr_trials_bl;
nr_trials_extra_learning = 2.5*60*4+nr_trials_learning;
nr_trials_recovery = 4*60*4;
nr_trials = nr_trials_learning+nr_trials_extra_learning+nr_trials_recovery;
stim_orig = stim;
stim_all = zeros(nr_trials,length_sim);
stim_all(nr_trials_bl+1:nr_trials_extra_learning,:) = repmat(stim,nr_trials_extra_learning-nr_trials_bl,1);
stim = stim_all;
%
data_net_with_recurr = net_fun_real_w_sg(v_eq,'r_eq_mg',r_eq_mg,'r_eq_op',r_eq_op,...
    'r_eq_sg',r_eq_sg,'r_stim_mult_mg',r_stim_mult_mg,'r_stim_mult_op',r_stim_mult_op,...
    'r_stim_mult_sg',r_stim_mult_sg,'v_stim_mult',v_stim_mult,'delay_from_mg',delay_from_mg,...
    'stim',stim,'w_stim',w_stim,'rate_delay',rate_delay,'input_shap',input_shap,...
    'nr_trials',nr_trials,'nr_trials_bl',nr_trials_bl,'sigm_mg',sigm_mg,...
    'sigm_op',sigm_op,'sigm_sg',sigm_sg,'w_mg_recurrent',w_mg_recurrent,'w_op_mg',w_op_mg,...
    'alpha',alpha,'output_learning',true,'gen_sg',false,'op_alone',true,...
    'w_sensory_to_bspk',w_sensory_to_bspk,'w_recur_to_bspk',w_recur_to_bspk,...
    'r_max_mult_mg',r_max_mult_mg,'r_max_mult_op',r_max_mult_op,...
    'r_max_mult_sg',r_max_mult_sg);

r_all_opE_w_recur = data_net_with_recurr.r_all_opE;
r_all_opI_w_recur = data_net_with_recurr.r_all_opI;

v_all_opE_w_recur = data_net_with_recurr.v_all_opE;
v_all_opI_w_recur = data_net_with_recurr.v_all_opI;

v_gc_E_w_recur = data_net_with_recurr.v_gc_E;
v_gc_I_w_recur = data_net_with_recurr.v_gc_I;

input_bsP_w_recur = data_net_with_recurr.input_bsP;
input_bsM_w_recur = data_net_with_recurr.input_bsM;

r_all_bsP_w_recur = data_net_with_recurr.r_all_bsP;
r_all_bsM_w_recur = data_net_with_recurr.r_all_bsM;

v_all_bsP_w_recur = data_net_with_recurr.v_all_bsP;
v_all_bsM_w_recur = data_net_with_recurr.v_all_bsM;

v_trial_opE_w_recur = v_all_opE_w_recur(nr_trials_bl+1:nr_trials_learning,:);
var_v_opE_w_recur = var(v_trial_opE_w_recur,1,2);

v_trial_opI_w_recur = v_all_opI_w_recur(nr_trials_bl+1:nr_trials_learning,:);
var_v_opI_w_recur = var(v_trial_opI_w_recur,1,2);

v_all_opE_alone = data_net_with_recurr.v_all_opE_alone;
v_all_opI_alone = data_net_with_recurr.v_all_opI_alone;

r_all_opE_alone = data_net_with_recurr.r_all_opE_alone;
r_all_opI_alone = data_net_with_recurr.r_all_opI_alone;

v_gc_E_alone = data_net_with_recurr.v_gc_E_alone;
v_gc_I_alone = data_net_with_recurr.v_gc_I_alone;

v_trial_opE_alone = v_all_opE_alone(nr_trials_bl+1:nr_trials_learning,:);
var_v_opE_alone = var(v_trial_opE_alone,1,2);

v_trial_opI_alone = v_all_opI_alone(nr_trials_bl+1:nr_trials_learning,:);
var_v_opI_alone = var(v_trial_opI_alone,1,2);

%
nspk_bl = 40;
lw = 1;

nr_cmnds_during = 4;
base_map = jet(256);

plot_every_e = nr_cmnds_during*round(6*4/nr_cmnds_during)+round(nr_cmnds_during/2); %floor(nr_trials/50);
avg_e = round(plot_every_e/3)+round(nr_cmnds_during/2);

plot_every_i = nr_cmnds_during*round(18*4/nr_cmnds_during)+round(nr_cmnds_during/2);
avg_i = round(plot_every_i/3)+round(nr_cmnds_during/2);

trials_to_plot_e = nr_trials_bl+1:plot_every_e:nr_trials_learning-avg_e;
trials_to_plot_i = nr_trials_bl+1:plot_every_i:nr_trials_learning-avg_i;

first_e = nr_cmnds_during-1;
first_i = avg_i-1;

plot_every_e_cmnd = plot_every_i;
avg_e_cmnd = avg_i;

plot_every_i_cmnd = plot_every_e;
avg_i_cmnd = avg_e;

trials_to_plot_e_cmnd = nr_trials_extra_learning+1:plot_every_e_cmnd:nr_trials-avg_e_cmnd;
trials_to_plot_i_cmnd = nr_trials_extra_learning+1:plot_every_i_cmnd:nr_trials-avg_i_cmnd;

first_e_cmnd = avg_e_cmnd-1;
first_i_cmnd = nr_cmnds_during-1;

tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
%%
x_label = 'time (ms)';
member_lim = [];
for mm = 1:5
    if mm == 1
        data_e = r_all_opE_alone;
        data_i = r_all_opE_alone;
        data_e2 = v_all_opE_alone-v_eq;
        data_i2 = v_all_opI_alone-v_eq;
        tit_le = 'output alone';
        y_label_1 = 'Sspk rate (Hz)';
        y_label_2 = 'Vm';
    elseif mm == 2
        data_e = r_all_opE_w_recur;
        data_i = r_all_opI_w_recur;
        data_e2 = r_all_opE_w_recur;
        data_i2 = r_all_opI_w_recur;
        tit_le = 'output with net spk';
        y_label_1 = 'Sspk rate (Hz)';
        y_label_2 = 'Sspk rate (Hz)';
        y_lim_e = [10 147];
        y_lim_i = [0 25];
        member_lim = [member_lim mm];
    elseif mm == 3
        data_e = v_all_opE_w_recur-v_eq;
        data_i = v_all_opI_w_recur-v_eq;
        data_e2 = v_all_opE_w_recur-v_eq;
        data_i2 = v_all_opI_w_recur-v_eq;
        tit_le = 'output with net volt';
        y_label_1 = 'Vm';
        y_label_2 = 'Vm';
        y_lim_e = [-0.5 2.25];
        y_lim_i = [-2.25 1.5];
        member_lim = [member_lim mm];
    elseif mm == 4
        data_e = r_all_bsP_w_recur;
        data_i = r_all_bsM_w_recur;
        data_e2 = r_all_bsP_w_recur;
        data_i2 = r_all_bsM_w_recur;
        tit_le = 'MG';
        y_label_1 = 'Bspk rate (Hz)';
        y_label_2 = 'Bspk rate (Hz)';
        y_lim_e = [0 65];
        y_lim_i = [0 3.5];
        member_lim = [member_lim mm];
    elseif mm == 5
        data_e = 10*input_bsP_w_recur+nspk_bl;
        data_i = 10*input_bsM_w_recur+nspk_bl;
        data_e2 = 10*input_bsP_w_recur+nspk_bl;
        data_i2 = 10*input_bsM_w_recur+nspk_bl;
        tit_le = 'MG Nspk';
        y_label_1 = 'Nspk rate (Hz)';
        y_label_2 = 'Nspk rate (Hz)';
    end
    if mm == 1
        trials_e2 = trials_to_plot_e; 
        trials_i2 = trials_to_plot_i;
        one_e2 = first_e;
        one_i2 = first_i;
        mean_e2 = avg_e;
        mean_i2 = avg_i;
    else
        trials_e2 = trials_to_plot_e_cmnd; 
        trials_i2 = trials_to_plot_i_cmnd;
        one_e2 = first_e_cmnd;
        one_i2 = first_i_cmnd;
        mean_e2 = avg_e_cmnd;
        mean_i2 = avg_i_cmnd;
    end
    h = figure('units','inches','position',[2,4.5,5,5]);

    all_axes(1) = subplot(2,2,1);
    map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_to_plot_e)));
    cmap = colormap(map1); 

    idx = 1;
    for ll = trials_to_plot_e
        if idx == 1
            plot(tt,mean(data_e(ll:ll+first_e,:),1),'linewidth',lw,'color',cmap(idx,:));
        else
            plot(tt,mean(data_e(ll-avg_e:ll+avg_e-1,:),1),'linewidth',lw,'color',cmap(idx,:));
        end
        hold on
        idx = idx+1;
    end
    xlabel(x_label)
    ylabel(y_label_1)
    axis tight
    if ismember(mm,member_lim)
        ylim(y_lim_e)
    end
    set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
    box off

    all_axes(2) = subplot(2,2,2);
    map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_to_plot_i)));
    cmap = colormap(map1); 

    idx = 1;
    for ll = trials_to_plot_i
        if idx == 1
            plot(tt,mean(data_i(ll:ll+first_i,:),1),'linewidth',lw,'color',cmap(idx,:));
        else
            plot(tt,mean(data_i(ll-avg_i:ll+avg_i-1,:),1),'linewidth',lw,'color',cmap(idx,:));
        end
        hold on
        idx = idx+1;
    end
    xlabel(x_label)
    axis tight
    if ismember(mm,member_lim)
        ylim(y_lim_i)
    end
    set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
    box off
    % linkaxes([all_axes(1) all_axes(2)]);

    map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_e2)));
    cmap = colormap(map1); 

    all_axes(1) = subplot(2,2,3);
    idx = 1;
    for ll = trials_e2
        if idx == 1
            plot(tt,mean(data_e2(ll:ll+one_e2,:),1),'linewidth',lw,'color',cmap(idx,:));
        else
            plot(tt,mean(data_e2(ll-mean_e2:ll+mean_e2-1,:),1),'linewidth',lw,'color',cmap(idx,:));
        end
        hold on
        idx = idx+1;
    end
    % hold on
    % plot(tt,-w_stim*stim,'k--','linewidth',1.5)
    xlabel(x_label)
    ylabel(y_label_2)
    axis tight
    if ismember(mm,member_lim)
        ylim(y_lim_i)
    end
    set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
    box off

    map1 = interp1(linspace(0,1,256), base_map, linspace(0,1,length(trials_i2)));
    cmap = colormap(map1); 

    all_axes(2) = subplot(2,2,4);
    idx = 1;
    for ll = trials_i2
        if idx == 1
            plot(tt,mean(data_i2(ll:ll+one_i2,:),1),'linewidth',lw,'color',cmap(idx,:));
        else
            plot(tt,mean(data_i2(ll-mean_i2:ll+mean_i2-1,:),1),'linewidth',lw,'color',cmap(idx,:));
        end
        hold on
        idx = idx+1;
    end    % hold on
    % plot(tt,w_stim*stim,'k--','linewidth',1.5)
    xlabel(x_label)
    axis tight
    if ismember(mm,member_lim)
        ylim(y_lim_e)
    end
    set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
    box off
    if ismember(mm,2:5)
        sgtitle({tit_le; ' top row = learning, bottom row = negative image)'})
    else
        sgtitle({tit_le; ' top row = rate, bottom row = voltage)'})
    end
end

%% 4min decay (inset plot)
LF_color = [254, 39, 18]./255;
LG_color = [2, 71, 254]./255;
MGm_color = [0, 203, 255]./255;
MGp_color = [251, 153, 2]./255;

var_r_opE_w_recur = var(r_all_opE_w_recur(nr_trials_bl+1:nr_trials_learning,:),[],2);
var_r_bsP_w_recur = var(r_all_bsP_w_recur(nr_trials_bl+1:nr_trials_learning,:),[],2);

max_stim_op = max(var_r_opE_w_recur);
max_stim_mg = max(var_r_bsP_w_recur);
lw = 1.5;
x_label_min = (1:nr_trials_learning-nr_trials_bl)/(60*4);

h = figure('units','inches','position',[6,5,5,4]);
x_lim = [0 4];
y_lim = [-.25 1];
subplot(2,2,1)
plot(x_label_min,var_r_bsP_w_recur./max_stim_mg,'-','linewidth',lw,'color',MGp_color)
hold on
plot(x_label_min,var_r_opE_w_recur./max_stim_op,'-','linewidth',lw,'color',LF_color)
hold on
plot(x_lim,[0 0],'k--','LineWidth',.75)
axis tight
xlim(x_lim)
ylim(y_lim)
legend('MG+','ON','location','best','FontSize',8)
legend('boxoff')
ylabel('variance (mV)^2')
xlabel('time (min)')

set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
box off

