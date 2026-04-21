% This code produces Figure 6 showing cancellation values through 20 minutes 
% of learning (6D) as a function of the different connectivey parameters. 
% This code also produces figure 6C and S3F and S3H. You need to make sure that 
% 'data_ell_net' and 'utilities_ell_net' are in the pathway.

fs = 8;
font_name = 'Arial';
%%
params_real

nr_trials_bl = 100;
nr_trials = 20*60*4+nr_trials_bl;

use_sg = false;
%%
data_net_wo_recurr = net_fun_real_w_sg(v_eq,'r_eq_mg',r_eq_mg,'r_eq_op',r_eq_op,...
    'r_eq_sg',r_eq_sg,'r_stim_mult_mg',r_stim_mult_mg,'r_stim_mult_op',r_stim_mult_op,...
    'r_stim_mult_sg',r_stim_mult_sg,'v_stim_mult',v_stim_mult,'delay_from_mg',delay_from_mg,...
    'stim',stim,'w_stim',w_stim,'rate_delay',rate_delay,'input_shap',input_shap,...
    'nr_trials',nr_trials,'nr_trials_bl',nr_trials_bl,'sigm_mg',sigm_mg,...
    'sigm_op',sigm_op,'sigm_sg',sigm_sg,'w_mg_recurrent',0,'w_op_mg',w_op_mg,...
    'alpha',alpha,'output_learning',true,'gen_sg',false,'op_alone',false,...
    'r_max_mult_mg',r_max_mult_mg,'r_max_mult_op',r_max_mult_op,...
    'r_max_mult_sg',r_max_mult_sg);

r_all_opE_wo_recur = data_net_wo_recurr.r_all_opE;
r_all_opI_wo_recur = data_net_wo_recurr.r_all_opI;

v_all_opE_wo_recur = data_net_wo_recurr.v_all_opE;
v_all_opI_wo_recur = data_net_wo_recurr.v_all_opI;

v_gc_E_wo_recur = data_net_wo_recurr.v_gc_E;
v_gc_I_wo_recur = data_net_wo_recurr.v_gc_I;

v_trial_opE_wo_recur = v_all_opE_wo_recur(nr_trials_bl+1:nr_trials,:);
var_v_opE_wo_recur = var(v_trial_opE_wo_recur,1,2);

v_trial_opI_wo_recur = v_all_opI_wo_recur(nr_trials_bl+1:nr_trials,:);
var_v_opI_wo_recur = var(v_trial_opI_wo_recur,1,2);

%%
data_net_with_recurr = net_fun_real_w_sg(v_eq,'r_eq_mg',r_eq_mg,'r_eq_op',r_eq_op,...
    'r_eq_sg',r_eq_sg,'r_stim_mult_mg',r_stim_mult_mg,'r_stim_mult_op',r_stim_mult_op,...
    'r_stim_mult_sg',r_stim_mult_sg,'v_stim_mult',v_stim_mult,'delay_from_mg',delay_from_mg,...
    'stim',stim,'w_stim',w_stim,'rate_delay',rate_delay,'input_shap',input_shap,...
    'nr_trials',nr_trials,'nr_trials_bl',nr_trials_bl,'sigm_mg',sigm_mg,...
    'sigm_op',sigm_op,'sigm_sg',sigm_sg,'w_mg_recurrent',w_mg_recurrent,'w_op_mg',w_op_mg,...
    'alpha',alpha,'output_learning',true,'gen_sg',false,'op_alone',true,...
    'r_max_mult_mg',r_max_mult_mg,'r_max_mult_op',r_max_mult_op,...
    'r_max_mult_sg',r_max_mult_sg);


r_all_opE_w_recur = data_net_with_recurr.r_all_opE;
r_all_opI_w_recur = data_net_with_recurr.r_all_opI;

v_all_opE_w_recur = data_net_with_recurr.v_all_opE;
v_all_opI_w_recur = data_net_with_recurr.v_all_opI;

v_gc_E_w_recur = data_net_with_recurr.v_gc_E;
v_gc_I_w_recur = data_net_with_recurr.v_gc_I;

r_all_bsP_w_recur = data_net_with_recurr.r_all_bsP;
r_all_bsM_w_recur = data_net_with_recurr.r_all_bsM;

input_bsP_w_recur = data_net_with_recurr.input_bsP;
input_bsM_w_recur = data_net_with_recurr.input_bsM;

v_trial_opE_w_recur = v_all_opE_w_recur(nr_trials_bl+1:nr_trials,:);
var_v_opE_w_recur = var(v_trial_opE_w_recur,1,2);

v_trial_opI_w_recur = v_all_opI_w_recur(nr_trials_bl+1:nr_trials,:);
var_v_opI_w_recur = var(v_trial_opI_w_recur,1,2);

v_all_opE_alone = data_net_with_recurr.v_all_opE_alone;
v_all_opI_alone = data_net_with_recurr.v_all_opI_alone;

r_all_opE_alone = data_net_with_recurr.r_all_opE_alone;
r_all_opI_alone = data_net_with_recurr.r_all_opI_alone;

v_gc_E_alone = data_net_with_recurr.v_gc_E_alone;
v_gc_I_alone = data_net_with_recurr.v_gc_I_alone;

v_trial_opE_alone = v_all_opE_alone(nr_trials_bl+1:nr_trials,:);
var_v_opE_alone = var(v_trial_opE_alone,1,2);

v_trial_opI_alone = v_all_opI_alone(nr_trials_bl+1:nr_trials,:);
var_v_opI_alone = var(v_trial_opI_alone,1,2);
%%
if use_sg
    data_net_with_sg = net_fun_real_w_sg(v_eq,'r_eq_mg',r_eq_mg,'r_eq_op',r_eq_op,...
        'r_eq_sg',r_eq_sg,'r_stim_mult_mg',r_stim_mult_mg,'r_stim_mult_op',r_stim_mult_op,...
        'r_stim_mult_sg',r_stim_mult_sg,'v_stim_mult',v_stim_mult,'delay_from_mg',delay_from_mg,...
        'stim',stim,'w_stim',w_stim,'rate_delay',rate_delay,'input_shap',input_shap,...
        'nr_trials',nr_trials,'nr_trials_bl',nr_trials_bl,'sigm_mg',sigm_mg,...
        'sigm_op',sigm_op,'sigm_sg',sigm_sg,'w_mg_recurrent',w_mg_recurrent,'w_op_mg',w_op_mg,...
        'gen_sg',true,'output_learning',true,...
        'alpha',alpha,'nr_sg_cells',nr_sg_cells,'r_max_mult_mg',r_max_mult_mg,...
        'r_max_mult_op',r_max_mult_op,'r_max_mult_sg',r_max_mult_sg);
    v_all_opE_sg = data_net_with_sg.v_all_opE;
    v_all_opI_sg = data_net_with_sg.v_all_opI;

    r_all_opE_sg = data_net_with_sg.r_all_opE;
    r_all_opI_sg = data_net_with_sg.r_all_opI;

    r_all_bsP_sg = data_net_with_sg.r_all_bsP;
    r_all_bsM_sg = data_net_with_sg.r_all_bsM;

    v_trial_opE_with_sg = v_all_opE_sg(nr_trials_bl+1:nr_trials,:);
    var_v_opE_with_sg = var(v_trial_opE_with_sg,1,2);

    v_trial_opI_with_sg = v_all_opI_sg(nr_trials_bl+1:nr_trials,:);
    var_v_opI_with_sg = var(v_trial_opI_with_sg,1,2);

    v_all_input_bsP_sg = data_net_with_sg.input_bsP;
    v_all_input_bsM_sg = data_net_with_sg.input_bsM;

    v_gc_E_sg = data_net_with_sg.v_gc_E;
    v_gc_I_sg = data_net_with_sg.v_gc_I;

    sg_m_op = data_net_with_sg.sg_m_op;
    sg_p_op = data_net_with_sg.sg_p_op;

    v_all_sg_m_gc = data_net_with_sg.v_all_sg_m_gc;
    v_all_sg_p_gc = data_net_with_sg.v_all_sg_p_gc;
end
%% decay lines

ON_color = [254, 39, 18]./255;
OFF_color = [2, 71, 254]./255;
MGm_color = [0, 203, 255]./255;
MGp_color = [251, 153, 2]./255;
sg1_color = [178, 215, 50]./255;
sg2_color = [252, 204, 26]./255;
sp_color = [134, 1, 175]./255;
grc_color = [254, 254, 51]./255;
g_cell_color = 'k';
aff_color = [255, 192, 203]./255;

max_stim = max(var_v_opE_alone);
lw = 1.5;
x_label_min = (1:nr_trials-nr_trials_bl)/(60*4);

h = figure('units','inches','position',[6,5,5,2]);
x_lim = [0 20];
y_lim = [0 1];
subplot(1,2,1)
plot(x_label_min,var_v_opE_alone./max_stim,':','linewidth',lw,'color',ON_color)
hold on
plot(x_label_min,var_v_opE_wo_recur./max_stim,'--','linewidth',lw,'color',ON_color)
hold on
plot(x_label_min,var_v_opE_w_recur./max_stim,'linewidth',lw,'color',ON_color)
% hold on
% plot(x_label_min,var_v_opE_with_sg./max_stim,'linewidth',lw,'color',sg1_color)

axis tight
xlim(x_lim)
ylim(y_lim)
legend('autonomous','+ feed f. MG','+ MG recurr.','location','best','FontSize',8)
legend('boxoff')
ylabel('variance (mV)^2','Interpreter','none')
xlabel('time (min)')
title('ON')

ax = gca;
% ax.XTick = [];
set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
box off

subplot(1,2,2)
plot(x_label_min,var_v_opI_alone./max_stim,':','linewidth',lw,'color',OFF_color)
hold on
plot(x_label_min,var_v_opI_wo_recur./max_stim,'--','linewidth',lw,'color',OFF_color)
hold on
plot(x_label_min,var_v_opI_w_recur./max_stim,'linewidth',lw,'color',OFF_color)
% hold on
% plot(x_label_min,var_v_opI_with_sg./max_stim,'linewidth',lw,'color',sg2_color)
legend('autonomous','+ feed f. MG','+ MG recurr.','location','best','FontSize',8)
legend('boxoff')

axis tight
xlim(x_lim)
ylim(y_lim)
xlabel('time (min)')
title('OFF')

ax = gca;
% ax.XTick = [];
set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
box off
% sgtitle(sprintf(['w-op-mg = ' num2str(w_op_mg)]))
%% ni paper
h = figure('units','inches','position',[6,5,5,2]);
tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
min_4 = round(4*60*4)+nr_trials_bl;

subplot(1,2,1)
cell_ni = v_gc_E_w_recur(min_4,:)-v_gc_E_w_recur(nr_trials_bl+1,:);
net_ni = -w_op_mg*input_bsM_w_recur(end,:);
plot(tt,net_ni,'linewidth',2,'color','k')
hold on
plot(tt,cell_ni+net_ni,'linewidth',2,'color',ON_color)
axis tight
legend('network only','all','location','best')
legend('boxoff')
ylabel('$\Delta$ mV','Interpreter','latex')
set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
box off

subplot(1,2,2)
cell_ni = v_gc_I_w_recur(min_4,:)-v_gc_I_w_recur(nr_trials_bl+1,:);
net_ni = -w_op_mg*input_bsP_w_recur(end,:);
% plot(tt,-v_all_opI_w_recur(nr_trials_bl+1,:)+v_eq,'--','linewidth',1.5,'color',[0.5 0.5 0.5])
% hold on
plot(tt,net_ni,'linewidth',2,'color','k')
hold on
plot(tt,cell_ni+net_ni,'linewidth',2,'color',OFF_color)
axis tight
legend('network only','all','location','best')
legend('boxoff')
set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
box off

%% rate at different times
min_rel = round(4*60*4)+nr_trials_bl;
lw = 1;
tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);

h = figure('units','inches','position',[0,3,3.5,2]);
subplot(1,2,1)
plot(tt,v_all_opE_alone(min_rel,:)-v_eq,':','color',ON_color,'linewidth',lw)
hold on
plot(tt,v_all_opE_wo_recur(min_rel,:)-v_eq,'--','color',ON_color,'linewidth',lw)
hold on
plot(tt,v_all_opE_w_recur(min_rel,:)-v_eq,'-','color',ON_color,'linewidth',lw)
hold on
plot(tt,w_stim*stim,'-','color','k')

axis tight
ylabel('mV')
xlabel('time (ms)')
set(gca, 'FontSize', 8,'FontName',font_name,'Color', 'none')
box off

subplot(1,2,2)
plot(tt,v_all_opI_alone(min_rel,:)-v_eq,':','color',OFF_color,'linewidth',lw)
hold on
plot(tt,v_all_opI_wo_recur(min_rel,:)-v_eq,'--','color',OFF_color,'linewidth',lw)
hold on
plot(tt,v_all_opI_w_recur(min_rel,:)-v_eq,'-','color',OFF_color,'linewidth',lw)
hold on
plot(tt,-w_stim*stim,'-','color','k')
axis tight
xlabel('time (ms)')
set(gca, 'FontSize', 8,'FontName',font_name,'Color', 'none')
box off

%%
tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
min_4 = round(4*60*4)+nr_trials_bl;

h = figure('units','inches','position',[0,3,9,9]);
subplot(2,2,1)
plot(tt,r_all_opE_alone(nr_trials_bl+1,:),'linewidth',2,'color','k')
axis tight
ylabel('mV')
title('E cell')
ylabel('stim rate (Hz)')
set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
box off

subplot(2,2,2)
plot(tt,r_all_opI_alone(nr_trials_bl+1,:),'linewidth',2,'color','k')
axis tight
title('I cell')
set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
box off

subplot(2,2,3)
cell_ni = v_gc_E_w_recur(min_4,:)-v_gc_E_w_recur(nr_trials_bl+1,:);
net_ni = -w_op_mg*input_bsM_w_recur(end,:);
plot(tt,-v_all_opE_w_recur(nr_trials_bl+1,:)+v_eq,'--','linewidth',1.5,'color',[0.5 0.5 0.5])
hold on
plot(tt,net_ni,'linewidth',2,'color','c')
hold on
plot(tt,cell_ni+net_ni,'linewidth',2,'color','k')
axis tight
legend('stim','neg. imag. net. only','neg. imag. net+output')
legend('boxoff')
ylabel('CD (post-pre) (mV)')
set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
box off

subplot(2,2,4)
cell_ni = v_gc_I_w_recur(min_4,:)-v_gc_I_w_recur(nr_trials_bl+1,:);
net_ni = -w_op_mg*input_bsP_w_recur(end,:);
plot(tt,-v_all_opI_w_recur(nr_trials_bl+1,:)+v_eq,'--','linewidth',1.5,'color',[0.5 0.5 0.5])
hold on
plot(tt,net_ni,'linewidth',2,'color','m')
hold on
plot(tt,cell_ni+net_ni,'linewidth',2,'color','k')
axis tight
legend('stim','neg. imag. net. only','neg. imag. net+output')
legend('boxoff')
set(gca, 'FontSize', fs,'FontName',font_name,'Color', 'none')
box off

%% 4min decay
var_r_opE_w_recur = var(r_all_opE_w_recur(nr_trials_bl+1:end,:),[],2);
var_r_bsP_w_recur = var(r_all_bsP_w_recur(nr_trials_bl+1:end,:),[],2);

max_stim_op = max(var_r_opE_w_recur);
max_stim_mg = max(var_r_bsP_w_recur);
lw = 1.5;
x_label_min = (1:nr_trials-nr_trials_bl)/(60*4);

h = figure('units','inches','position',[6,5,2,2]);
x_lim = [0 4];
y_lim = [0 1];
plot(x_label_min,var_r_bsP_w_recur./max_stim_mg,'-','linewidth',lw,'color',MGp_color)
hold on
plot(x_label_min,var_r_opE_w_recur./max_stim_op,'-','linewidth',lw,'color',ON_color)

axis tight
xlim(x_lim)
ylim(y_lim)
legend('MG+','ON','location','best','FontSize',8)
legend('boxoff')
ylabel('variance (mV)^2')
xlabel('time (min)')
ax = gca;
% ax.XTick = [];
set(gca, 'FontSize', 8,'FontName','Arial','Color', 'none')
box off
