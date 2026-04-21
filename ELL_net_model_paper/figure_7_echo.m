% this code generates figure 7B&C, looking at retnetion of learned cancellation 
% in the presence of noise. 
% To add the data traces you need first to load 'output_cells_avg.mat' from
% 'data_ell_net', and mg_plus and mg_minus.
%
% You need to make sure that 'data_ell_net' and 'utilities_ell_net' are in 
% the pathway.

%%
fs = 16;
fs_text = 16;
fs_paper = 12;
font_name = 'Arial';

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
%%
params_real
w_op_mg_orig = w_op_mg;
r_stim_mult_op_orig = r_stim_mult_op;
use_stim_self = false;

use_peak_spk = false;

test_recur = false;
test_learning_rates = false;

w_stim_noise = 1;
add_data = false;
tic
echo_stim = true; % if false this tests random noise
one_sided_echo = false; % if true, the echo has one polarity
if echo_stim % && ~one_sided_echo
    w_stim_noise = 0.75;
    if ~one_sided_echo
        add_data = true;
    end
end

output_learning = true;
if use_stim_self
    stim_self_orig = stim;
    delay_from_mg = 0;
    stim_self = stim;
    init_learn = true;
else
    stim_self_orig = stim;
    stim_self = zeros(size(stim));
    init_learn = false;
    % delay_from_mg = 0;
end
%
nr_trials_first_self = 25;
nr_trials_uncor = round(10*60*4);
nr_trials_noise = nr_trials_first_self+nr_trials_uncor; %5
nr_trials_self = round(0.25*60*4); % to test for longer, change this parameter.
nr_trials = nr_trials_noise+nr_trials_self;

idx_shift_self = nr_trials_noise+nr_trials_self;

nr_simul_context =  10;
track_pos_stim = zeros(nr_trials,nr_simul_context);

if test_recur
    nr_params_context = 10;
    params_all = linspace(0,.9,nr_params_context);
    add_data = false;
elseif test_learning_rates
    nr_params_context = 11;
    params_all = linspace(0.5,3,nr_params_context);
        
    % nr_params_context = 2;
    % params_all = linspace(1,2,nr_params_context);
else
    % nr_params_context = 12;
    % params_all = linspace(0,1,nr_params_context-1);
    % analyze_mg_alone = true;

    % nr_params_context = 2;
    % params_all = linspace(0.5,1,nr_params_context);
    % analyze_mg_alone = false;
    
    nr_params_context = 2;
    params_all = w_op_mg;
    analyze_mg_alone = true;
end
E_mean_self = zeros(nr_params_context,nr_simul_context);
I_mean_self = zeros(nr_params_context,nr_simul_context);

r_opE_shift = zeros(nr_params_context,length_sim);
r_opI_shift = zeros(nr_params_context,length_sim);

r_bsP_shift = zeros(1,length_sim);
r_bsM_shift = zeros(1,length_sim);

v_gc_bsP = zeros(nr_trials,length_sim);
v_gc_bsM = zeros(nr_trials,length_sim);

r_bsP = zeros(nr_trials,length_sim);
r_bsM = zeros(nr_trials,length_sim);

v_gc_opE = zeros(nr_trials,length_sim);
v_gc_opI = zeros(nr_trials,length_sim);

op_bsP = zeros(nr_trials,length_sim);
op_bsM = zeros(nr_trials,length_sim);

v_opE_wo_noise = zeros(nr_trials,length_sim);
v_opI_wo_noise = zeros(nr_trials,length_sim);

v_opE_mg_only_wo_noise = zeros(nr_trials,length_sim);
v_opI_mg_only_wo_noise = zeros(nr_trials,length_sim);

actuall_stim = zeros(nr_trials,length_sim);
which_context = ones(1,nr_trials);
which_context(nr_trials_noise+1:end) = 2;
which_context(1:nr_trials_first_self) = 2;
actuall_stim(which_context == 2,:) = repmat(stim_self,nr_trials_self+nr_trials_first_self,1);
if echo_stim
    nr_rnd_eod = 1;
else
    nr_rnd_eod = 4;
end

tic
rng(0)
for kk = 1:nr_simul_context
    for ii = nr_trials_first_self+1:nr_trials_noise   

        stim_noise = zeros(size(stim_self));
        if echo_stim
            % new_amp = 2*rand(1,nr_rnd_eod)-1;
            if one_sided_echo
                new_amp = 1;
            else
                new_amp = rand(1);

                if new_amp>0.5
                    new_amp = 1;
                    track_pos_stim(ii,kk) = 1;
                else
                    new_amp = -1;
                end
                
            end
            new_amp = w_stim_noise*new_amp;
            % if rand(1)<1.1
            for bb = 1:nr_rnd_eod
                stim_noise = stim_noise+new_amp(bb)*circshift(stim_self_orig,12);
            end
            % end
        else
            new_amp = 2*rand(1,nr_rnd_eod)-1;
            new_amp = w_stim_noise*new_amp;
            for bb = 1:nr_rnd_eod
                stim_noise = stim_noise+new_amp(bb)*circshift(stim_self_orig,randi(length_sim));
            end
        end

        actuall_stim(ii,:) = stim_self+stim_noise;
    end

    for mm = 1:nr_params_context
        idx_real = 0;
        idx_test = 0;
        if test_recur
            % w_op_mg = 1;
            % output_learning = false;
            w_mg_recurrent = params_all(mm);
        elseif test_learning_rates
            r_stim_mult_op = params_all(mm)*r_stim_mult_op_orig;
            r_max_mult_op = 1.25*r_stim_mult_op/r_eq_op;
            % mult_alpha_op = params_all(mm);
        else
            if analyze_mg_alone && mm == nr_params_context
                w_op_mg = 1;
                output_learning = false;
            else
                w_op_mg = params_all(mm);
                output_learning = true;
            end
        end
        if nr_params_context == 2
            if mm == 2
                idx_test = 1;
            elseif mm == 1
                idx_real = 1;
            end
        end
        
    %
    data_net_mg_op = net_fun_real_w_sg(v_eq,'r_eq_mg',r_eq_mg,'r_eq_op',r_eq_op,...
        'r_eq_sg',r_eq_sg,'r_stim_mult_mg',r_stim_mult_mg,'r_stim_mult_op',r_stim_mult_op,...
        'r_stim_mult_sg',r_stim_mult_sg,'v_stim_mult',v_stim_mult,'delay_from_mg',delay_from_mg,...
        'stim',actuall_stim,'w_stim',w_stim,'rate_delay',rate_delay,'input_shap',input_shap,...
        'nr_trials',nr_trials,'nr_trials_bl',0,'sigm_mg',sigm_mg,'alpha',alpha,...
        'sigm_op',sigm_op,'sigm_sg',sigm_sg,'w_mg_recurrent',w_mg_recurrent,'w_op_mg',w_op_mg,...
        'output_learning',output_learning,'gen_sg',false,'op_alone',false,'stim_self',stim_self,...
        'init_learn',init_learn,'r_max_mult_mg',r_max_mult_mg,'r_max_mult_op',r_max_mult_op,...
        'r_max_mult_sg',r_max_mult_sg,'mult_alpha_op',mult_alpha_op);


    r_all_opE_mg_op = data_net_mg_op.r_all_opE;
    r_all_opI_mg_op = data_net_mg_op.r_all_opI;

    v_all_opE_mg_op = data_net_mg_op.v_all_opE;
    v_all_opI_mg_op = data_net_mg_op.v_all_opI;

    output_bsP_mg_op = data_net_mg_op.input_bsP;
    output_bsM_mg_op = data_net_mg_op.input_bsM;

    v_gc_bsP_mg_op = data_net_mg_op.v_gc_bsP;
    v_gc_bsM_mg_op = data_net_mg_op.v_gc_bsM;

    v_gc_E_mg_op = data_net_mg_op.v_gc_E;
    v_gc_I_mg_op = data_net_mg_op.v_gc_I;

    var_v_opE_mg_op = var(v_all_opE_mg_op,1,2);
    var_v_opI_mg_op = var(v_all_opI_mg_op,1,2);

    max_r_opE_mg_op = max(abs(r_all_opE_mg_op-r_eq_op),[],2);
    max_r_opI_mg_op = max(abs(r_all_opI_mg_op-r_eq_op),[],2);
    
    if use_peak_spk
        E_mean_self(mm,kk) = mean(max_r_opE_mg_op(nr_trials_noise+1:end));
        I_mean_self(mm,kk) = mean(max_r_opI_mg_op(nr_trials_noise+1:end));
    else
        E_mean_self(mm,kk) = mean(var_v_opE_mg_op(nr_trials_noise+1:end));
        I_mean_self(mm,kk) = mean(var_v_opI_mg_op(nr_trials_noise+1:end));
    end

    r_opE_shift(mm,:) = r_opE_shift(mm,:)+r_all_opE_mg_op(idx_shift_self,:);
    r_opI_shift(mm,:) = r_opI_shift(mm,:)+r_all_opI_mg_op(idx_shift_self,:);

    if idx_real == 1
        v_gc_bsP = v_gc_bsP+data_net_mg_op.v_gc_bsP;
        v_gc_bsM = v_gc_bsM+data_net_mg_op.v_gc_bsM;

        r_bsP = r_bsP+data_net_mg_op.r_all_bsP;
        r_bsM = r_bsM+data_net_mg_op.r_all_bsM;

        r_bsP_shift = r_bsP_shift+data_net_mg_op.r_all_bsP(idx_shift_self,:);
        r_bsM_shift = r_bsM_shift+data_net_mg_op.r_all_bsM(idx_shift_self,:);
        
        op_bsP = op_bsP+data_net_mg_op.input_bsP;
        op_bsM = op_bsM+data_net_mg_op.input_bsM;
    
        v_gc_opE = v_gc_opE+data_net_mg_op.v_gc_E;
        v_gc_opI = v_gc_opI+data_net_mg_op.v_gc_I;

        v_opE_wo_noise = v_opE_wo_noise+data_net_mg_op.v_all_opE-w_stim*actuall_stim;
        v_opI_wo_noise = v_opI_wo_noise+data_net_mg_op.v_all_opI+w_stim*actuall_stim;
    elseif idx_test
        v_opE_mg_only_wo_noise = v_opE_mg_only_wo_noise+data_net_mg_op.v_all_opE-w_stim*actuall_stim;
        v_opI_mg_only_wo_noise = v_opI_mg_only_wo_noise+data_net_mg_op.v_all_opI+w_stim*actuall_stim;
    end
    end
    kk
end
r_opE_shift = r_opE_shift./nr_simul_context;
r_opI_shift = r_opI_shift./nr_simul_context;

v_gc_bsP = v_gc_bsP./nr_simul_context;
v_gc_bsM = v_gc_bsM./nr_simul_context;

r_bsP = r_bsP./nr_simul_context;
r_bsM = r_bsM./nr_simul_context;

r_bsP_shift = r_bsP_shift./nr_simul_context;
r_bsM_shift = r_bsM_shift./nr_simul_context;

op_bsP = op_bsP./nr_simul_context;
op_bsM = op_bsM./nr_simul_context;

v_gc_opE = v_gc_opE./nr_simul_context;
v_gc_opI = v_gc_opI./nr_simul_context;

v_opE_wo_noise = v_opE_wo_noise./nr_simul_context;
v_opI_wo_noise = v_opI_wo_noise./nr_simul_context;

v_opE_mg_only_wo_noise = v_opE_mg_only_wo_noise./nr_simul_context;
v_opI_mg_only_wo_noise = v_opI_mg_only_wo_noise./nr_simul_context;

toc
%%
if add_data
    output_data = load([pwd '/data_ell_net/output_cells_avg.mat']);
end
lw = 2;
h = figure('units','inches','position',[3,4.5,8,4.5]);
if test_recur
    x_label = 'w-recurr.';
elseif test_learning_rates
    x_label = 'Output lr:default';
else
    x_label = 'w-op-mg';
end

E_self = E_mean_self;
E_self = E_self./mean(E_self(end,:));
var_E_self = mean(E_self,2);
sem_E_self = sem(E_self','use_mat',true)';

I_self = I_mean_self;
I_self = I_self./mean(I_self(end,:));
var_I_self = mean(I_self,2);
sem_I_self = sem(I_self','use_mat',true)';

subplot(2,2,1)
bar_data = var_E_self;
b = bar(bar_data);
errors = sem_E_self;
hold on
errorbar(1:length(errors), bar_data, errors, 'k', 'linestyle', 'none')
axis tight
xticks(1:length(errors)); % one tick for each row
if test_recur
    xticklabels({num2str(params_all',2)}); % your custom labels    
else
    xticklabels({num2str(params_all',2),'MG-alone'}); % your custom labels
end
xtickangle(45)
b.FaceColor = 'flat';
b.CData = cool(length(errors));
ylabel('Modulation (norm.)','Interpreter','none');
xlabel(x_label)
title('ON')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

subplot(2,2,2)
bar_data = var_I_self;
b = bar(bar_data);
errors = sem_I_self;
hold on
errorbar(1:length(errors), bar_data, errors, 'k', 'linestyle', 'none')
axis tight
xticks(1:length(errors)); % one tick for each row
if test_recur
    xticklabels({num2str(params_all',2)}); % your custom labels    
else
    xticklabels({num2str(params_all',2),'MG-alone'}); % your custom labels
end
xtickangle(45)
b.FaceColor = 'flat';
b.CData = cool(length(errors));
xlabel(x_label)
title('OFF')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off
%
tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);

all_axes(1) = subplot(2,2,3);
plot(tt,r_opE_shift','linewidth',lw)
colororder(cool(size(r_opE_shift,1)))
if add_data
    hold on
    tt_data = 1e3*output_data.on_time;
    plot(tt_data,output_data.on_value+r_eq_op,'k','linewidth',lw)
    hold on
    fill([tt_data fliplr(tt_data)], [output_data.on_value+r_eq_op+output_data.on_sd...
    fliplr(output_data.on_value+r_eq_op-output_data.on_sd)], ...
    'k', 'EdgeColor','none', 'FaceAlpha',0.2);
    legend('mg+op','mg alone','data')
    legend('boxoff')
end

xlabel('time (ms)')
ylabel('rate (Hz)')
title(['rate after ' num2str(nr_trials_self/(60*4)) 'min'])
axis tight
% ax.YLim = [0 ax.YLim(2)];
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

all_axes(2) = subplot(2,2,4);
plot(tt,r_opI_shift','linewidth',lw)
colororder(cool(size(r_opI_shift,1)))
if add_data
    hold on
    tt_data = 1e3*output_data.off_time;
    plot(tt_data,output_data.off_value+r_eq_op,'k','linewidth',lw)
    hold on
    fill([tt_data fliplr(tt_data)], [output_data.off_value+r_eq_op+output_data.off_sd...
    fliplr(output_data.off_value+r_eq_op-output_data.off_sd)], ...
    'k', 'EdgeColor','none', 'FaceAlpha',0.2);
    legend('mg+op','mg alone','data')
    legend('boxoff')
end
xlabel('time (ms)')
title(['rate after ' num2str(nr_trials_self/(60*4)) 'min'])
axis tight
ax = gca;
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off
linkaxes([all_axes(1) all_axes(2)]);
%%
figure
gc_sum = sum(rate_conv_gc,1);
gc_sum = gc_sum-min(gc_sum);
hold on
plot(tt,gc_sum./max(gc_sum))
title('sum gc')
%% plot MG neg_img progression
plot_every = round(.5*60*4); %floor(nr_trials/50);
idx_start = nr_trials_first_self+1;
trials_to_plot = idx_start:plot_every:nr_trials_noise;
cmap = jet(length(trials_to_plot));
tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);

h = figure('units','inches','position',[3,4.5,4,7]);
subplot(3,2,1)
idx = 1;
for ll = trials_to_plot
    plot(tt,r_bsP(ll,:)-r_eq_mg,'linewidth',1,'color',cmap(idx,:));
    hold on
    idx = idx+1;
end
hold on
plot(tt,r_bsP(idx_start,:)-r_eq_mg,'k','linewidth',2)
axis tight
ylabel('MG+, rate (Hz)')
xlabel('time (ms)')
title('MG+ progression in noise')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

subplot(3,2,2)
idx = 1;
for ll = trials_to_plot
    plot(tt,r_bsM(ll,:)-r_eq_mg,'linewidth',1,'color',cmap(idx,:));
    hold on
    idx = idx+1;
end
hold on
plot(tt,r_bsM(idx_start,:)-r_eq_mg,'k','linewidth',2)
axis tight
ylabel('MG-, rate (Hz)')
xlabel('time (ms)')
title('MG- progression in noise')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

subplot(3,2,3)
idx = 1;
for ll = trials_to_plot
    plot(tt,params_all*op_bsP(ll,:),'linewidth',1,'color',cmap(idx,:));
    hold on
    idx = idx+1;
end
hold on
plot(tt,params_all*op_bsP(idx_start,:),'k','linewidth',2)
axis tight
ylabel('MG+ output (mV)')
xlabel('time (ms)')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

subplot(3,2,4)
idx = 1;
for ll = trials_to_plot
    plot(tt,params_all*op_bsM(ll,:),'linewidth',1,'color',cmap(idx,:));
    hold on
    idx = idx+1;
end
hold on
plot(tt,params_all*op_bsM(idx_start,:),'k','linewidth',2)
axis tight
ylabel('MG- output (mV)')
xlabel('time (ms)')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off


subplot(3,2,5)
idx = 1;
for ll = trials_to_plot
    plot(tt,v_gc_opE(ll,:)-v_eq,'linewidth',1,'color',cmap(idx,:));
    hold on
    idx = idx+1;
end
hold on
plot(tt,v_gc_opE(idx_start,:)-v_eq,'k','linewidth',2)
axis tight
ylabel('GCA output ON (mV)')
xlabel('time (ms)')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

subplot(3,2,6)
idx = 1;
for ll = trials_to_plot
    plot(tt,v_gc_opI(ll,:)-v_eq,'linewidth',1,'color',cmap(idx,:));
    hold on
    idx = idx+1;
end
hold on
plot(tt,v_gc_opI(idx_start,:)-v_eq,'k','linewidth',2)
axis tight
ylabel('GCA output OFF (mV)')
xlabel('time (ms)')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

%% plot MG OP progression
idx_start = nr_trials_first_self+1;
trials_to_plot = idx_start+[0*4 30*4 300*4 600*4];

cmap = cool(length(trials_to_plot));
tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);

VmP = zeros(length(trials_to_plot),length(tt));
VmM = zeros(length(trials_to_plot),length(tt));
idx = 1;
for ii = trials_to_plot
    VmP(idx,:) = op_bsP(ii,:)+v_eq+w_stim_noise*w_stim*circshift(stim_self_orig,12)+w_stim*stim_self;
    VmM(idx,:) = op_bsM(ii,:)+v_eq+w_stim_noise*w_stim*circshift(stim_self_orig,12)-w_stim*stim_self;
    idx = idx+1;
end

[func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_mg,'r_max',r_max_mult_mg*r_eq_mg,...
    'r_stim_mult',r_stim_mult_mg,'v_stim_mult',v_stim_mult);

if sigm_mg
    rmP = func_sigm(VmP);
    rmM = func_sigm(VmM);
else
    rmP = slop*VmP+bia;
    rmM = slop*VmM+bia;
end
rmP(rmP<0) = 0;
rmM(rmM<0) = 0;
%%%%%%%
VmE = zeros(length(trials_to_plot),length(tt));
VmI = zeros(length(trials_to_plot),length(tt));
idx = 1;
for ii = trials_to_plot
    VmE(idx,:) = v_opE_wo_noise(ii,:)+w_stim_noise*w_stim*circshift(stim_self_orig,12)+w_stim*stim_self;
    VmI(idx,:) = v_opI_wo_noise(ii,:)+w_stim_noise*w_stim*circshift(stim_self_orig,12)-w_stim*stim_self;
    idx = idx+1;
end

[func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_op,'r_max',r_max_mult_op*r_eq_op,...
    'r_stim_mult',r_stim_mult_op,'v_stim_mult',v_stim_mult);

if sigm_op
    rmE = func_sigm(VmE);
    rmI = func_sigm(VmI);
else
    rmE = slop*VmE+bia;
    rmI = slop*VmI+bia;
end
rmE(rmE<0) = 0;
rmI(rmI<0) = 0;

h = figure('units','inches','position',[3,4.5,6,12]);
all_axes(1) = subplot(4,2,1);
idx = 1;
for ll = 1:length(trials_to_plot)
    plot(tt,rmP(idx,:),'linewidth',1,'color',cmap(idx,:),'linewidth',2);
    hold on
    idx = idx+1;
end
legend('10','30','300','600','Location','best')
legend('boxoff')
axis tight
ylabel('rate, MG+ (Hz)')
xlabel('time (ms)')
title('MG+ progression in noise')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

all_axes(2) = subplot(4,2,2);
idx = 1;
for ll = 1:length(trials_to_plot)
    plot(tt,rmM(idx,:),'linewidth',1,'color',cmap(idx,:),'linewidth',2);
    hold on
    idx = idx+1;
end

axis tight
ylabel('rate, , MG- (Hz)')
xlabel('time (ms)')
title('MG- progression in noise')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off
ylim([0 42])
linkaxes([all_axes(1),all_axes(2)])

tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
mean_r_bsP_shift = mean(r_bsP_shift,3);
all_axes(1) = subplot(4,2,3);
plot(tt,mean_r_bsP_shift','b','linewidth',2)
% colororder(cool(size(mean_r_opE_shift,1)))
xlabel('time (ms)')
ylabel('broad spike rate (Hz)')
title(['rate after ' num2str(nr_trials_self/(60*4)) 'min'])
axis tight
% ax.YLim = [0 ax.YLim(2)];
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

mean_r_bsM_shift = mean(r_bsM_shift,3);
all_axes(2) = subplot(4,2,4);
plot(tt,mean_r_bsM_shift','r','linewidth',2)
% colororder(cool(size(mean_r_opI_shift,1)))
xlabel('time (ms)')
ylabel('broad spike rate (Hz)')
title(['rate after ' num2str(nr_trials_self/(60*4)) 'min'])
axis tight
ax = gca;
% ax.YLim = [0 ax.YLim(2)];
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off
linkaxes([all_axes(1) all_axes(2)]);


subplot(4,2,5)
idx = 1;
for ll = 1:length(trials_to_plot)
    plot(tt,rmE(idx,:),'linewidth',1,'color',cmap(idx,:),'linewidth',2);
    hold on
    idx = idx+1;
end
axis tight
ylabel('Output ON (Hz)')
xlabel('time (ms)')
title('Output ON')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

subplot(4,2,6)
idx = 1;
for ll = 1:length(trials_to_plot)
    plot(tt,rmI(idx,:),'linewidth',1,'color',cmap(idx,:),'linewidth',2);
    hold on
    idx = idx+1;
end
axis tight
ylabel('Output OFF (Hz)')
xlabel('time (ms)')
title('Output OFF')
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off


tt = linspace(-0.01/1e-3,(0.15)/1e-3,160);
all_axes(1) = subplot(4,2,7);
plot(tt,r_opE_shift','linewidth',2)
colororder(cool(size(r_opE_shift,1)))
xlabel('time (ms)')
ylabel('rate (Hz)')
title(['rate after ' num2str(nr_trials_self/(60*4)) 'min'])
axis tight
% ax.YLim = [0 ax.YLim(2)];
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off

all_axes(2) = subplot(4,2,8);
plot(tt,r_opI_shift','linewidth',2)
colororder(cool(size(r_opI_shift,1)))
xlabel('time (ms)')
ylabel('rate (Hz)')
title(['rate after ' num2str(nr_trials_self/(60*4)) 'min'])
axis tight
ax = gca;
% ax.YLim = [0 ax.YLim(2)];
set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
box off
linkaxes([all_axes(1) all_axes(2)]);


%% progression through noise: 7D

use_pre_cal_resp = true;


tt_min = ((-nr_trials_first_self:nr_trials-nr_trials_first_self-1)/(60*4));
bsP_output = op_bsP;
bsM_output = op_bsM;

ON_output = v_opE_wo_noise-v_eq;
OFF_output = v_opI_wo_noise-v_eq;


if test_learning_rates
    r_max_mult_op = 1.25*r_stim_mult_op_orig/r_eq_op;
    [func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_op,'r_max',r_max_mult_op*r_eq_op,...
        'r_stim_mult',r_stim_mult_op_orig,'v_stim_mult',v_stim_mult);

    if sigm_op
        rmE = func_sigm(v_opE_wo_noise);
        rmI = func_sigm(v_opI_wo_noise);
    else
        rmE = slop*v_opE_wo_noise+bia;
        rmI = slop*v_opI_wo_noise+bia;
    end

    r_max_mult_op = 1.25*r_stim_mult_op/r_eq_op;
    [func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_op,'r_max',r_max_mult_op*r_eq_op,...
        'r_stim_mult',r_stim_mult_op,'v_stim_mult',v_stim_mult);
    if sigm_op
        rmE_mg_only = func_sigm(v_opE_mg_only_wo_noise);
        rmI_mg_only = func_sigm(v_opI_mg_only_wo_noise);
    else
        rmE_mg_only = slop*v_opE_mg_only_wo_noise+bia;
        rmI_mg_only = slop*v_opI_mg_only_wo_noise+bia;
    end

else
    [func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_op,'r_max',r_max_mult_op*r_eq_op,...
        'r_stim_mult',r_stim_mult_op,'v_stim_mult',v_stim_mult);

    if sigm_op
        rmE = func_sigm(v_opE_wo_noise);
        rmI = func_sigm(v_opI_wo_noise);

        rmE_mg_only = func_sigm(v_opE_mg_only_wo_noise);
        rmI_mg_only = func_sigm(v_opI_mg_only_wo_noise);
    else
        rmE = slop*v_opE_wo_noise+bia;
        rmI = slop*v_opI_wo_noise+bia;

        rmE_mg_only = slop*v_opE_mg_only_wo_noise+bia;
        rmI_mg_only = slop*v_opI_mg_only_wo_noise+bia;
    end
end

rmE(rmE<0) = 0;
rmI(rmI<0) = 0;
rmE_mg_only(rmE_mg_only<0) = 0;
rmI_mg_only(rmI_mg_only<0) = 0;

ON_gca = v_gc_opE-v_eq;
OFF_gca = v_gc_opI-v_eq;

if use_pre_cal_resp
    [~, i_m] = min(op_bsP,[],2);
else
    [~, i_m] = max(abs(op_bsP),[],2);
end
lin_idx = sub2ind(size(op_bsP), (1:nr_trials)', i_m);
max_bsP_all = op_bsP(lin_idx);

if use_pre_cal_resp
    if echo_stim && one_sided_echo
        [~, i_m] = max(op_bsM,[],2);
    else
        [~, i_m] = min(op_bsM,[],2);
    end
else
    [~, i_m] = max(abs(op_bsM),[],2);
end
lin_idx = sub2ind(size(op_bsM), (1:nr_trials)', i_m);
max_bsM_all = op_bsM(lin_idx);

[~, i_m] = max(abs(ON_output),[],2);
if use_pre_cal_resp && ~one_sided_echo
    [~, i_m(nr_trials_noise:end)] = min(ON_output(nr_trials_noise:end,:)-r_eq_op,[],2);
end
lin_idx = sub2ind(size(ON_output), (1:nr_trials)', i_m);
max_ON_all = ON_output(lin_idx);

[~, i_m] = max(abs(OFF_output),[],2);
if use_pre_cal_resp && ~one_sided_echo
    [~, i_m(nr_trials_noise:end)] = min(OFF_output(nr_trials_noise:end,:)-r_eq_op,[],2);
end
lin_idx = sub2ind(size(OFF_output), (1:nr_trials)', i_m);
max_OFF_all = OFF_output(lin_idx);

[~, i_m] = max(abs(rmE-r_eq_op),[],2);
if use_pre_cal_resp && ~one_sided_echo
    [~, i_m(nr_trials_noise:end)] = min(rmE(nr_trials_noise:end,:)-r_eq_op,[],2);
end
lin_idx = sub2ind(size(rmE), (1:nr_trials)', i_m);
max_rate_ON_all = rmE(lin_idx);

[~, i_m] = max(abs(rmI-r_eq_op),[],2);
if use_pre_cal_resp && ~one_sided_echo
    [~, i_m(nr_trials_noise:end)] = min(rmI(nr_trials_noise:end,:)-r_eq_op,[],2);
end
lin_idx = sub2ind(size(rmI), (1:nr_trials)', i_m);
max_rate_OFF_all = rmI(lin_idx);

[~, i_m] = max(abs(rmE_mg_only-r_eq_op),[],2);
if use_pre_cal_resp && ~one_sided_echo && ~analyze_mg_alone
    [~, i_m(nr_trials_noise:end)] = min(rmE_mg_only(nr_trials_noise:end,:)-r_eq_op,[],2);
end
lin_idx = sub2ind(size(rmE_mg_only), (1:nr_trials)', i_m);
max_rate_mg_only_ON_all = rmE_mg_only(lin_idx);

[~, i_m] = max(abs(rmI_mg_only-r_eq_op),[],2);
if use_pre_cal_resp && ~one_sided_echo && ~analyze_mg_alone
    [~, i_m(nr_trials_noise:end)] = min(rmI_mg_only(nr_trials_noise:end,:)-r_eq_op,[],2);
end
lin_idx = sub2ind(size(rmI_mg_only), (1:nr_trials)', i_m);
max_rate_mg_only_OFF_all = rmI_mg_only(lin_idx);

[~, i_m] = max(abs(ON_gca),[],2);
lin_idx = sub2ind(size(ON_gca), (1:nr_trials)', i_m);
max_ON_gca_all = ON_gca(lin_idx);

[~, i_m] = max(abs(OFF_gca),[],2);
lin_idx = sub2ind(size(OFF_gca), (1:nr_trials)', i_m);
max_OFF_gca_all = OFF_gca(lin_idx);

%
h = figure('units','inches','position',[3,4.5,5 5]);
all_axes(1) = subplot(2,2,1);

plot(tt_min,-w_op_mg_orig*max_bsM_all,'color',MGm_color,'linewidth',2)
hold on
plot(tt_min,max_ON_all,'color',ON_color,'linewidth',2)
hold on
plot(tt_min,max_ON_gca_all,'color','k','linewidth',2)
legend('MG- input','ON','ON-GCA','autoupdate','off','location','best')
legend('boxoff')
axis tight
ax = gca;
mx_y_ax = max(abs(ax.YLim));
ax.YLim = [-mx_y_ax mx_y_ax];

y_lim = ax.YLim;
hold on
plot([(nr_trials_noise-nr_trials_first_self-1)/(60*4) (nr_trials_noise-nr_trials_first_self-1)/(60*4)],y_lim,'--','color',[0.5 0.5 0.5],'linewidth',2)
x_lim = ax.XLim;
hold on
plot(x_lim,[0 0],'--','color',[0.5 0.5 0.5],'linewidth',2)
ylabel('peak modulation (mV)')
xlabel('time (min.)')
title('ON')
ax.FontSize =  fs_paper; ax.FontName = font_name; ax.Color = 'none';
ax.XColor = 'k'; ax.YColor = 'k'; ax.LineWidth = 1; ax.TickDir = 'out';
ax.TickLength = [0.03 0.03];
ax.Box = 'off';

all_axes(2) = subplot(2,2,2);
plot(tt_min,-w_op_mg_orig*max_bsP_all,'color',MGp_color,'linewidth',2)
hold on
plot(tt_min,max_OFF_all,'color',OFF_color,'linewidth',2)
hold on
plot(tt_min,max_OFF_gca_all,'color','k','linewidth',2)
legend('MG+ input','OFF','OFF-GCA','autoupdate','off','location','best')
legend('boxoff')

axis tight
ax = gca;
mx_y_ax = max(abs(ax.YLim));
ax.YLim = [-mx_y_ax mx_y_ax];
y_lim = ax.YLim;
hold on
plot([(nr_trials_noise-nr_trials_first_self-1)/(60*4) (nr_trials_noise-nr_trials_first_self-1)/(60*4)],y_lim,'--','color',[0.5 0.5 0.5],'linewidth',2)
x_lim = ax.XLim;
hold on
plot(x_lim,[0 0],'--','color',[0.5 0.5 0.5],'linewidth',2)
xlabel('time (min.)')
title('OFF')
ax.FontSize =  fs_paper; ax.FontName = font_name; ax.Color = 'none';
ax.XColor = 'k'; ax.YColor = 'k'; ax.LineWidth = 1; ax.TickDir = 'out';
ax.TickLength = [0.03 0.03];
ax.Box = 'off';
linkaxes([all_axes(1) all_axes(2)])

all_axes(1) = subplot(2,2,3);
plot(tt_min,max_rate_ON_all,'color',ON_color,'linewidth',2)
hold on
plot(tt_min,max_rate_mg_only_ON_all,'color','k','linewidth',2)
if test_learning_rates
    legend('OP lr:MG lr = 1',': = 2','autoupdate','off','location','best')
else
    % legend('full model','MG only','autoupdate','off','location','best')
    legend('w-op-mg = 0.5',': = 1','autoupdate','off','location','best')
end
legend('boxoff')

axis tight

ax = gca;
ax.YLim = [0 max(ax.YLim(2),2*r_eq_op)];
y_lim = ax.YLim;
hold on
plot([(nr_trials_noise-nr_trials_first_self-1)/(60*4) (nr_trials_noise-nr_trials_first_self-1)/(60*4)],y_lim,'--','color',[0.5 0.5 0.5],'linewidth',2)
x_lim = ax.XLim;
hold on
plot(x_lim,[r_eq_op r_eq_op],'--','color',[0.5 0.5 0.5],'linewidth',2)
ylabel('peak modulation (Sp/s)')
xlabel('time (min.)')
ax.FontSize =  fs_paper; ax.FontName = font_name; ax.Color = 'none';
ax.XColor = 'k'; ax.YColor = 'k'; ax.LineWidth = 1; ax.TickDir = 'out';
ax.TickLength = [0.03 0.03];
ax.Box = 'off';


all_axes(2) = subplot(2,2,4);
plot(tt_min,max_rate_OFF_all,'color',OFF_color,'linewidth',2)
hold on
plot(tt_min,max_rate_mg_only_OFF_all,'color','k','linewidth',2)
if test_learning_rates
    legend('OP lr:MG lr = 1',': = 2','autoupdate','off','location','best')
else
    % legend('full model','MG only','autoupdate','off','location','best')
    legend('w-op-mg = 0.5',': = 1','autoupdate','off','location','best')
end
legend('boxoff')

axis tight
ax = gca;
ax.YLim = [0 max(ax.YLim(2),2*r_eq_op)];
y_lim = ax.YLim;
hold on
plot([(nr_trials_noise-nr_trials_first_self-1)/(60*4) (nr_trials_noise-nr_trials_first_self-1)/(60*4)],y_lim,'--','color',[0.5 0.5 0.5],'linewidth',2)
x_lim = ax.XLim;
hold on
plot(x_lim,[r_eq_op r_eq_op],'--','color',[0.5 0.5 0.5],'linewidth',2)
xlabel('time (min.)')
ax.FontSize =  fs_paper; ax.FontName = font_name; ax.Color = 'none';
ax.XColor = 'k'; ax.YColor = 'k'; ax.LineWidth = 1; ax.TickDir = 'out';
ax.TickLength = [0.03 0.03];
ax.Box = 'off';
linkaxes([all_axes(1) all_axes(2)])

sgtitle('random echo')
save_figure = false;
if save_figure
    pth_save_figure = '~/Google Drive/My Drive/Why_figures/post_EM/';
        % print(h,[pth_save_figure 'real_noise_context_bar_recur.95.png'], '-dpng','-r0');
    exportgraphics(h,[pth_save_figure 'echo_over_long_time_diff_lr.pdf'],'ContentType','auto');
end
%% 7C
if add_data
    data_mg_plus = load([pwd '/data_ell_net/mg_plus.mat']);
    data_mg_minus = load([pwd '/data_ell_net/mg_minus.mat']);

    add_sem = false;

    h = figure('units','inches','position',[3,4.5,5,2]);
    all_axes(1) = subplot(1,2,1);
    colors = [MGp_color 0.4;MGp_color 0.6;MGp_color 0.8;MGp_color 1];

    tt_data = 1e3*data_mg_plus.mg10_avg(:,1);
    plot(tt_data,data_mg_plus.mg10_avg(:,2),'-','linewidth',2,'color',colors(1,:))
    hold on
    plot(tt_data,data_mg_plus.mg30_avg(:,2),'-.','linewidth',2,'color',colors(2,:))
    hold on
    plot(tt_data,data_mg_plus.mg300_avg(:,2),':','linewidth',2,'color',colors(3,:))
    hold on
    plot(tt_data,data_mg_plus.mg600_avg(:,2),'-','linewidth',2,'color',colors(4,:))
    ax = gca;

    legend('10s','30s','300s','600s','Location','best','autoupdate','off')
    legend('boxoff')
    axis tight
    ylabel('rate (Hz)')
    xlabel('time (ms)')
    % title('MG+ progression in noise (DATA)')
    ax.FontSize =  fs_paper; ax.FontName = font_name; ax.Color = 'none';
    ax.XColor = 'k'; ax.YColor = 'k'; ax.LineWidth = 1; ax.TickDir = 'out';
    ax.TickLength = [0.03 0.03]; 
    ax.Box = 'off';

    if add_sem
        cmap = jet(4);
        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_plus.mg10_avg(:,2)+data_mg_plus.mg10_avg(:,3)...
            fliplr(data_mg_plus.mg10_avg(:,2)-data_mg_plus.mg10_avg(:,3))], ...
            cmap(1,:), 'EdgeColor','none', 'FaceAlpha',0.1);

        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_plus.mg30_avg(:,2)+data_mg_plus.mg30_avg(:,3)...
            fliplr(data_mg_plus.mg30_avg(:,2)-data_mg_plus.mg30_avg(:,3))], ...
            cmap(2,:), 'EdgeColor','none', 'FaceAlpha',0.1);

        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_plus.mg300_avg(:,2)+data_mg_plus.mg300_avg(:,3)...
            fliplr(data_mg_plus.mg300_avg(:,2)-data_mg_plus.mg300_avg(:,3))], ...
            cmap(3,:), 'EdgeColor','none', 'FaceAlpha',0.1);

        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_plus.mg600_avg(:,2)+data_mg_plus.mg600_avg(:,3)...
            fliplr(data_mg_plus.mg600_avg(:,2)-data_mg_plus.mg600_avg(:,3))], ...
            cmap(4,:), 'EdgeColor','none', 'FaceAlpha',0.1);
    end

    all_axes(2) = subplot(1,2,2);
    colors = [MGm_color 0.4;MGm_color 0.6;MGm_color 0.8;MGm_color 1];
    plot(tt_data,data_mg_minus.mg10_avg(:,2),'-','linewidth',2,'color',colors(1,:))
    hold on
    plot(tt_data,data_mg_minus.mg30_avg(:,2),'-.','linewidth',2,'color',colors(2,:))
    hold on
    plot(tt_data,data_mg_minus.mg300_avg(:,2),':','linewidth',2,'color',colors(3,:))
    hold on
    plot(tt_data,data_mg_minus.mg600_avg(:,2),'-','linewidth',2,'color',colors(4,:))
    legend('10s','30s','300s','600s','Location','best','autoupdate','off')
    legend('boxoff')

    ax = gca;
    axis tight
    ylabel('rate (Hz)')
    xlabel('time (ms)')
    % title('MG- progression in noise (DATA)')
    ax.FontSize =  fs_paper; ax.FontName = font_name; ax.Color = 'none';
    ax.XColor = 'k'; ax.YColor = 'k'; ax.LineWidth = 1; ax.TickDir = 'out';
    ax.TickLength = [0.03 0.03]; 
    ax.Box = 'off';
    ylim([0 42])
    linkaxes([all_axes(1), all_axes(2)])

    if add_sem
        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_minus.mg10_avg(:,2)+data_mg_minus.mg10_avg(:,3)...
            fliplr(data_mg_minus.mg10_avg(:,2)-data_mg_minus.mg10_avg(:,3))], ...
            cmap(1,:), 'EdgeColor','none', 'FaceAlpha',0.1);

        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_minus.mg30_avg(:,2)+data_mg_minus.mg30_avg(:,3)...
            fliplr(data_mg_minus.mg30_avg(:,2)-data_mg_minus.mg30_avg(:,3))], ...
            cmap(2,:), 'EdgeColor','none', 'FaceAlpha',0.1);

        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_minus.mg300_avg(:,2)+data_mg_minus.mg300_avg(:,3)...
            fliplr(data_mg_minus.mg300_avg(:,2)-data_mg_minus.mg300_avg(:,3))], ...
            cmap(3,:), 'EdgeColor','none', 'FaceAlpha',0.1);

        hold on
        fill([tt_data fliplr(tt_data)], [data_mg_minus.mg600_avg(:,2)+data_mg_minus.mg600_avg(:,3)...
            fliplr(data_mg_minus.mg600_avg(:,2)-data_mg_minus.mg600_avg(:,3))], ...
            cmap(4,:), 'EdgeColor','none', 'FaceAlpha',0.1);
    end
end
%% 7A simulation of noise

plot_diagram = true;
if plot_diagram && ~echo_stim
    h = figure('Units','inches','Position',[6 3 4 2]);
    all_axes(1) = subplot(1,2,1);
    plot(tt,w_stim*stim_self_orig,'linewidth',2)
    xlabel('time (ms)')
    ylabel('mV')
    set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
    box off
    axis tight

    all_axes(2) = subplot(1,2,2);
    unique_stim = unique(actuall_stim(nr_trials_first_self+1:nr_trials_noise,:),'rows');
    stim_plot_idx = randperm(size(unique_stim,1),20);
    plot(tt,w_stim*(unique_stim(stim_plot_idx,:))','linewidth',1)
    xlabel('time (ms)')
    ylabel('mV')
    set(gca, 'FontSize', fs_paper,'FontName',font_name,'Color', 'none')
    box off
    axis tight
    linkaxes([all_axes(1) all_axes(2)])
end
