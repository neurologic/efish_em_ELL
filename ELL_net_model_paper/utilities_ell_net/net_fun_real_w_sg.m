function data = net_fun_real_w_sg(v_eq,varargin)

% this function simulates rate of cancellation in the entire network, MG
% and output cells. Inputs are weights from MG to output cells and
% recurrent MG weights.

p = inputParser;
addRequired(p,'v_eq',@isnumeric);
addParameter(p,'dt',1e-3);
addParameter(p,'r_eq_mg',1.5);
addParameter(p,'r_eq_sg',1);
addParameter(p,'r_eq_op',20);
addParameter(p,'r_stim_mult_mg',13);
addParameter(p,'r_stim_mult_op',8);
addParameter(p,'r_stim_mult_sg',3);
addParameter(p,'v_stim_mult',1);
addParameter(p,'stim',1);
addParameter(p,'w_stim',1);
addParameter(p,'w_mg_recurrent',0.5);
addParameter(p,'w_op_mg',0.5);
addParameter(p,'alpha',1.5e-9); %3.9e-8
addParameter(p,'mult_alpha_op',1);
addParameter(p,'rate_delay',1);
addParameter(p,'input_shap',1);
addParameter(p,'gc_units_op_to_mg',1/3.06);
addParameter(p,'nr_trials',2000);
addParameter(p,'nr_trials_bl',200);
addParameter(p,'sigm_mg',false);
addParameter(p,'sigm_op',false);
addParameter(p,'sigm_sg',false);
addParameter(p,'nr_sg_cells',20);
addParameter(p,'gen_sg',true);
addParameter(p,'w_learn_sg_m',0.5);
addParameter(p,'w_learn_sg_p',0.5);
addParameter(p,'w_stim_canc_sg_m',0);
addParameter(p,'w_stim_canc_sg_p',0);
addParameter(p,'sg_m',[]);
addParameter(p,'sg_p',[]);
addParameter(p,'output_learning',true);
addParameter(p,'op_alone',false);
addParameter(p,'stim_self',[]);
addParameter(p,'init_learn',false);
addParameter(p,'reverse_mg_op',false);
addParameter(p,'random_mg_op',false);
addParameter(p,'reverse_mg_recurr',false);
addParameter(p,'random_mg_recurr',false);
addParameter(p,'w_recur_to_bspk',0);
addParameter(p,'w_sensory_to_bspk',1);
addParameter(p,'delay_from_mg',0.0); %s
addParameter(p,'r_max_mult_mg', 120);
addParameter(p,'r_max_mult_op', 16);
addParameter(p,'r_max_mult_sg', 120);


parse(p,v_eq,varargin{:});
dt = p.Results.dt;
r_eq_mg = p.Results.r_eq_mg;
r_eq_sg = p.Results.r_eq_sg;
r_eq_op = p.Results.r_eq_op;
r_stim_mult_mg = p.Results.r_stim_mult_mg;
r_stim_mult_op = p.Results.r_stim_mult_op;
r_stim_mult_sg = p.Results.r_stim_mult_sg;
v_stim_mult = p.Results.v_stim_mult;
stim = p.Results.stim;
w_stim = p.Results.w_stim;
w_mg_recurrent = p.Results.w_mg_recurrent;
alpha = p.Results.alpha;
mult_alpha_op = p.Results.mult_alpha_op;
w_op_mg = p.Results.w_op_mg;
rate_delay = p.Results.rate_delay;
input_shap = p.Results.input_shap;
gc_units_op_to_mg = p.Results.gc_units_op_to_mg;
nr_trials = p.Results.nr_trials;
nr_trials_bl = p.Results.nr_trials_bl;
sigm_mg = p.Results.sigm_mg;
sigm_op = p.Results.sigm_op;
sigm_sg = p.Results.sigm_sg;
nr_sg_cells = p.Results.nr_sg_cells;
w_learn_sg_m = p.Results.w_learn_sg_m;
w_learn_sg_p = p.Results.w_learn_sg_p;
w_stim_canc_sg_m = p.Results.w_stim_canc_sg_m;
w_stim_canc_sg_p = p.Results.w_stim_canc_sg_p;
gen_sg = p.Results.gen_sg;
sg_m_op = p.Results.sg_m;
sg_p_op = p.Results.sg_p;
output_learning = p.Results.output_learning;
op_alone = p.Results.op_alone;
stim_self = p.Results.stim_self;
init_learn = p.Results.init_learn;
reverse_mg_op = p.Results.reverse_mg_op;
random_mg_op = p.Results.random_mg_op;
reverse_mg_recurr = p.Results.reverse_mg_recurr;
random_mg_recurr = p.Results.random_mg_recurr;
w_recur_to_bspk = p.Results.w_recur_to_bspk;
w_sensory_to_bspk = p.Results.w_sensory_to_bspk;
delay_from_mg = p.Results.delay_from_mg;
r_max_mult_mg = p.Results.r_max_mult_mg;
r_max_mult_op = p.Results.r_max_mult_op;
r_max_mult_sg = p.Results.r_max_mult_sg;

if init_learn && w_mg_recurrent>0
    delay_from_mg_dt = 0;
else
    delay_from_mg_dt = round(delay_from_mg/dt);
end

data = struct;
nr_units = size(input_shap,1);
length_sim = size(input_shap,2);

alpha_sg = alpha;
% options = optimoptions('lsqlin','Algorithm','interior-point');
% w_initial_use = lsqlin(input_shap',v_eq*(ones(1,length_sim)));
w_initial_use = pinv(input_shap')*(v_eq*(ones(length_sim,1)));

nr_units_op = round(gc_units_op_to_mg*nr_units);
rng(0)
which_cells = randperm(nr_units,nr_units_op);
rng('shuffle')
input_shap_op = input_shap(which_cells,:);
rate_delay_op = rate_delay(which_cells,:);

w_initial_use_op = pinv(input_shap_op')*(v_eq*(ones(length_sim,1)));
% lsqlin(input_shap_op',v_eq*(ones(1,length_sim)));
 
if gen_sg
    ratio_gca = 1/10.7;
    rng(0)
    data_sg_m = sg_real_fun(v_eq,'r_eq',r_eq_sg,'r_stim_mult',r_stim_mult_sg,...
        'v_stim_mult',v_stim_mult,'stim',stim,'w_stim',-w_stim,...
        'w_initial_use',w_initial_use_op,'nr_sg_cells',nr_sg_cells,...
        'rate_delay',rate_delay_op,'input_shap',input_shap_op,'alpha',alpha_sg,...
        'nr_trials',nr_trials,'nr_trials_bl',nr_trials_bl,'sigm',sigm_sg,...
        'stim_self',stim_self,'init_learn',init_learn,'r_max_mult',r_max_mult_sg,...
        'ratio_gca',ratio_gca);

    r_all_sg_m = data_sg_m.r_all;
    v_all_sg_m_gc = data_sg_m.v_all_gc;
    w_all_sg_m = data_sg_m.w_all;

    bl_sg_m_op = w_learn_sg_m*v_eq;
    sg_m_op = w_learn_sg_m*v_all_sg_m_gc;
    if size(stim,1) == 1
        sg_m_op(nr_trials_bl+1:end,:) = sg_m_op(nr_trials_bl+1:end,:) + (1-w_stim_canc_sg_m)*repmat(-w_stim*stim,nr_trials-nr_trials_bl,1);
    else
        sg_m_op(nr_trials_bl+1:end,:) = sg_m_op(nr_trials_bl+1:end,:) + (1-w_stim_canc_sg_m)*-w_stim*stim(nr_trials_bl+1:end,:);
    end
    sg_m_op = sg_m_op-bl_sg_m_op;

    rng(0)
    data_sg_p = sg_real_fun(v_eq,'r_eq',r_eq_sg,'r_stim_mult',r_stim_mult_sg,...
        'v_stim_mult',v_stim_mult,'stim',stim,'w_stim',w_stim,...
        'w_initial_use',w_initial_use_op,'nr_sg_cells',nr_sg_cells,...
        'rate_delay',rate_delay_op,'input_shap',input_shap_op,'alpha',alpha,...
        'nr_trials',nr_trials,'nr_trials_bl',nr_trials_bl,'sigm',sigm_sg,...
        'stim_self',stim_self,'init_learn',init_learn,'r_max_mult',r_max_mult_mg,...
        'ratio_gca',ratio_gca);

    r_all_sg_p = data_sg_p.r_all;
    v_all_sg_p_gc = data_sg_p.v_all_gc;
    w_all_sg_p = data_sg_p.w_all;

    bl_sg_p_op = w_learn_sg_p*v_eq;
    sg_p_op = w_learn_sg_p*v_all_sg_p_gc;
    if size(stim,1) == 1
        sg_p_op(nr_trials_bl+1:end,:) = sg_p_op(nr_trials_bl+1:end,:) + (1-w_stim_canc_sg_p)*repmat(w_stim*stim,nr_trials-nr_trials_bl,1);
    else
        sg_p_op(nr_trials_bl+1:end,:) = sg_p_op(nr_trials_bl+1:end,:) + (1-w_stim_canc_sg_p)*w_stim*stim(nr_trials_bl+1:end,:);
    end
    sg_p_op = sg_p_op-bl_sg_p_op;
end
if isempty(sg_m_op) && isempty(sg_p_op) && size(stim,1)==1
    sg_m_op = repmat(-w_stim*stim,nr_trials,1);
    sg_p_op = repmat(w_stim*stim,nr_trials,1);
    sg_m_op(1:nr_trials_bl,:) = 0;
    sg_p_op(1:nr_trials_bl,:) = 0;
elseif isempty(sg_m_op) && isempty(sg_p_op) && size(stim,1)>1
    sg_m_op = -w_stim*stim;
    sg_p_op = w_stim*stim; 
end
%% MG
if w_op_mg>0
beta_mg = dt*alpha/r_eq_mg;

[func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_mg,'r_max',r_max_mult_mg*r_eq_mg,...
    'r_stim_mult',r_stim_mult_mg,'v_stim_mult',v_stim_mult);

alpha_increase = alpha*sum(rate_delay,2)';

if init_learn
    recurr_coef = 1-w_mg_recurrent;
    if gen_sg
        w_input_bsP = (pinv(input_shap')*(v_eq*(ones(length_sim,1))+w_learn_sg_m*(v_all_sg_m_gc(1,:)-v_eq)'-recurr_coef*w_stim*stim_self'))';
        w_input_bsM = (pinv(input_shap')*(v_eq*(ones(length_sim,1))+w_learn_sg_p*(v_all_sg_p_gc(1,:)-v_eq)'+recurr_coef*w_stim*stim_self'))';
    else
        w_input_bsP = (pinv(input_shap')*(v_eq*(ones(length_sim,1))-recurr_coef*w_stim*stim_self'))';
        w_input_bsM = (pinv(input_shap')*(v_eq*(ones(length_sim,1))+recurr_coef*w_stim*stim_self'))';
    end
else
    w_input_bsP = w_initial_use';
    w_input_bsM = w_initial_use';
end

v_all_bsP = nan(nr_trials,length_sim);
r_all_bsP = nan(nr_trials,length_sim);
w_all_bsP = nan(nr_trials,nr_units);

v_all_bsM = nan(nr_trials,length_sim);
r_all_bsM = nan(nr_trials,length_sim);
w_all_bsM = nan(nr_trials,nr_units);

v_gc_bsP = zeros(nr_trials,length_sim);
v_gc_bsM = zeros(nr_trials,length_sim);

recurr_to_bsP = zeros(nr_trials,length_sim);
recurr_to_bsM = zeros(nr_trials,length_sim);

output_bsP = zeros(nr_trials,length_sim);
output_bsM = zeros(nr_trials,length_sim);

P_output_prior = zeros(1,length_sim);
M_output_prior = zeros(1,length_sim);

for ii = 1:nr_trials
    if ii > nr_trials_bl

        
%%%%%%%%%%%%%%%%%%%%%%
        % w_recurr_to_bspk = w_recur_to_bspk*w_mg_recurrent;
        % stim_gca_P = w_input_bsP*input_shap-sg_m_op(ii,:);
        % stim_gca_M = w_input_bsM*input_shap-sg_p_op(ii,:);
        % if reverse_mg_recurr
        %     VmP = stim_gca_P-w_mg_recurrent*P_output_prior;
        %     VmM = stim_gca_M-w_mg_recurrent*M_output_prior; 
        % 
        %     recurr_to_bspk_P = w_recurr_to_bspk*P_output_prior;
        %     recurr_to_bspk_M = w_recurr_to_bspk*M_output_prior;
        % elseif random_mg_recurr
        %     VmP = stim_gca_P-0.5*w_mg_recurrent*P_output_prior-0.5*w_mg_recurrent*M_output_prior;
        %     VmM = stim_gca_M-0.5*w_mg_recurrent*P_output_prior-0.5*w_mg_recurrent*M_output_prior; 
        % 
        %     recurr_to_bspk_P = 0.5*w_recurr_to_bspk*M_output_prior+0.5*w_recurr_to_bspk*P_output_prior;
        %     recurr_to_bspk_M = 0.5*w_recurr_to_bspk*M_output_prior+0.5*w_recurr_to_bspk*P_output_prior;
        % else
        %     VmP = stim_gca_P-w_mg_recurrent*M_output_prior;
        %     VmM = stim_gca_M-w_mg_recurrent*P_output_prior;
        % 
        %     recurr_to_bspk_P = w_recurr_to_bspk*M_output_prior;
        %     recurr_to_bspk_M = w_recurr_to_bspk*P_output_prior;
        % end
        % 
        % v_bl_plus_spec_bsP = w_sensory_to_bspk*-sg_m_op(ii,:)-recurr_to_bspk_P+v_eq;
        % v_bl_plus_spec_bsM = w_sensory_to_bspk*-sg_p_op(ii,:)-recurr_to_bspk_M+v_eq;
        % 
        % output_bsP(ii,:) = VmP - v_bl_plus_spec_bsP;
        % output_bsM(ii,:) = VmM - v_bl_plus_spec_bsM;
        % 
        % P_output_prior = circshift(output_bsP(ii,:),delay_from_mg_dt);
        % M_output_prior = circshift(output_bsM(ii,:),delay_from_mg_dt);


%%%%%%%%%%%%%%%
%         %  
%         w_recurr_to_bspk = w_recur_to_bspk*w_mg_recurrent;
%         stim_gca_P = w_input_bsP*input_shap-sg_m_op(ii,:);
%         stim_gca_M = w_input_bsM*input_shap-sg_p_op(ii,:);
%         if reverse_mg_recurr
%             VmP_orig = stim_gca_P-w_mg_recurrent*P_output_prior;
%             VmM_orig = stim_gca_M-w_mg_recurrent*M_output_prior; 
% 
%             recurr_to_bspk_P = w_recurr_to_bspk*P_output_prior;
%             recurr_to_bspk_M = w_recurr_to_bspk*M_output_prior;
%         elseif random_mg_recurr
%             VmP_orig = stim_gca_P-0.5*w_mg_recurrent*P_output_prior-0.5*w_mg_recurrent*M_output_prior;
%             VmM_orig = stim_gca_M-0.5*w_mg_recurrent*P_output_prior-0.5*w_mg_recurrent*M_output_prior; 
% 
%             recurr_to_bspk_P = 0.5*w_recurr_to_bspk*M_output_prior+0.5*w_recurr_to_bspk*P_output_prior;
%             recurr_to_bspk_M = 0.5*w_recurr_to_bspk*M_output_prior+0.5*w_recurr_to_bspk*P_output_prior;
%         else
%             VmP_orig = stim_gca_P-w_mg_recurrent*M_output_prior;
%             VmM_orig = stim_gca_M-w_mg_recurrent*P_output_prior;
% 
%             recurr_to_bspk_P = w_recurr_to_bspk*M_output_prior;
%             recurr_to_bspk_M = w_recurr_to_bspk*P_output_prior;
%         end
%         v_bl_plus_spec_bsP = w_sensory_to_bspk*-sg_m_op(ii,:)-recurr_to_bspk_P+v_eq;
%         v_bl_plus_spec_bsM = w_sensory_to_bspk*-sg_p_op(ii,:)-recurr_to_bspk_M+v_eq;
% 
%         P_output = VmP_orig-v_bl_plus_spec_bsP;
%         M_output = VmM_orig-v_bl_plus_spec_bsM;
% 
%         P_output = circshift(P_output,delay_from_mg_dt);
%         M_output = circshift(M_output,delay_from_mg_dt);
% 
%         if reverse_mg_recurr
%             VmP = stim_gca_P - w_mg_recurrent*P_output;
%             VmM = stim_gca_M - w_mg_recurrent*M_output;
% 
%             recurr_to_bspk_P = w_recurr_to_bspk*P_output;
%             recurr_to_bspk_M = w_recurr_to_bspk*M_output;
%         elseif random_mg_recurr
%             VmP = stim_gca_P - 0.5*w_mg_recurrent*M_output- 0.5*w_mg_recurrent*P_output;
%             VmM = stim_gca_M - 0.5*w_mg_recurrent*P_output- 0.5*w_mg_recurrent*M_output;
% 
%             recurr_to_bspk_P = 0.5*w_recurr_to_bspk*M_output+0.5*w_recurr_to_bspk*P_output;
%             recurr_to_bspk_M = 0.5*w_recurr_to_bspk*M_output+0.5*w_recurr_to_bspk*P_output;
% 
%         else
%             VmP = stim_gca_P - w_mg_recurrent*M_output;
%             VmM = stim_gca_M - w_mg_recurrent*P_output;
% 
%             recurr_to_bspk_P = w_recurr_to_bspk*M_output;
%             recurr_to_bspk_M = w_recurr_to_bspk*P_output;
% 
%         end
% 
%         v_bl_plus_spec_bsP = w_sensory_to_bspk*-sg_m_op(ii,:)-recurr_to_bspk_P+v_eq;
%         v_bl_plus_spec_bsM = w_sensory_to_bspk*-sg_p_op(ii,:)-recurr_to_bspk_M+v_eq;
%         output_bsP(ii,:) = VmP - v_bl_plus_spec_bsP;
%         output_bsM(ii,:) = VmM - v_bl_plus_spec_bsM;
% 
%         P_output_prior = output_bsP(ii,:);
%         M_output_prior = output_bsM(ii,:);
% 
%%%%%%%%%%%%%%%
        %  
        w_recurr_to_bspk = w_recur_to_bspk*w_mg_recurrent;
        stim_gca_P = w_input_bsP*input_shap-sg_m_op(ii,:);
        stim_gca_M = w_input_bsM*input_shap-sg_p_op(ii,:);
        P_output = P_output_prior;
        M_output = M_output_prior;

        for oo = 1:25
            if reverse_mg_recurr
                VmP_orig = stim_gca_P-w_mg_recurrent*P_output;
                VmM_orig = stim_gca_M-w_mg_recurrent*M_output;

                recurr_to_bspk_P = w_recurr_to_bspk*P_output;
                recurr_to_bspk_M = w_recurr_to_bspk*M_output;
            elseif random_mg_recurr
                VmP_orig = stim_gca_P-0.5*w_mg_recurrent*P_output-0.5*w_mg_recurrent*M_output;
                VmM_orig = stim_gca_M-0.5*w_mg_recurrent*P_output-0.5*w_mg_recurrent*M_output;

                recurr_to_bspk_P = 0.5*w_recurr_to_bspk*M_output+0.5*w_recurr_to_bspk*P_output;
                recurr_to_bspk_M = 0.5*w_recurr_to_bspk*M_output+0.5*w_recurr_to_bspk*P_output;
            else
                VmP_orig = stim_gca_P-w_mg_recurrent*M_output;
                VmM_orig = stim_gca_M-w_mg_recurrent*P_output;

                recurr_to_bspk_P = w_recurr_to_bspk*M_output;
                recurr_to_bspk_M = w_recurr_to_bspk*P_output;
            end
            v_bl_plus_spec_bsP = w_sensory_to_bspk*-sg_m_op(ii,:)-recurr_to_bspk_P+v_eq;
            v_bl_plus_spec_bsM = w_sensory_to_bspk*-sg_p_op(ii,:)-recurr_to_bspk_M+v_eq;

            P_output = VmP_orig-v_bl_plus_spec_bsP;
            M_output = VmM_orig-v_bl_plus_spec_bsM;

            P_output = circshift(P_output,delay_from_mg_dt);
            M_output = circshift(M_output,delay_from_mg_dt);
        end
        VmP = VmP_orig;
        VmM = VmM_orig;

        output_bsP(ii,:) = VmP - v_bl_plus_spec_bsP;
        output_bsM(ii,:) = VmM - v_bl_plus_spec_bsM;

        P_output_prior = P_output;
        M_output_prior = M_output;

%%%%%%%%%%%%%%%
    else
        VmP = w_input_bsP*input_shap;
        VmM = w_input_bsM*input_shap;
    end
    if sigm_mg
        rmP = func_sigm(VmP);
        rmM = func_sigm(VmM);
    else
        rmP = slop*VmP+bia;
        rmM = slop*VmM+bia;
    end
    rmP(rmP<0) = 0;
    rmM(rmM<0) = 0;

    v_all_bsP(ii,:) = VmP;
    r_all_bsP(ii,:) = rmP;
    w_all_bsP(ii,:) = w_input_bsP;

    v_all_bsM(ii,:) = VmM;
    r_all_bsM(ii,:) = rmM;
    w_all_bsM(ii,:) = w_input_bsM;

    v_gc_bsP(ii,:) = w_input_bsP*input_shap;
    v_gc_bsM(ii,:) = w_input_bsM*input_shap;

    w_input_bsP = w_input_bsP - beta_mg*(input_shap*rmP')';
    w_input_bsP = w_input_bsP + alpha_increase;

    w_input_bsM = w_input_bsM - beta_mg*(input_shap*rmM')';
    w_input_bsM = w_input_bsM + alpha_increase;
end
else
    v_all_bsP = zeros(nr_trials,length_sim);
    r_all_bsP = nan(nr_trials,length_sim);
    w_all_bsP = nan(nr_trials,nr_units);
    
    v_all_bsM = zeros(nr_trials,length_sim);
    r_all_bsM = nan(nr_trials,length_sim);
    w_all_bsM = nan(nr_trials,nr_units);
    
    recurr_to_bsP = zeros(nr_trials,length_sim);
    recurr_to_bsM = zeros(nr_trials,length_sim);

    output_bsP = zeros(nr_trials,length_sim);
    output_bsM = zeros(nr_trials,length_sim);

    v_gc_bsP = zeros(nr_trials,length_sim);
    v_gc_bsM = zeros(nr_trials,length_sim);

end
%% output
[func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq_op,'r_max',r_max_mult_op*r_eq_op,...
    'r_stim_mult',r_stim_mult_op,'v_stim_mult',v_stim_mult);
alpha_op = mult_alpha_op*alpha;
beta_op = alpha_op*dt/r_eq_op;

%%
add_noise = false;
alpha_increase_op = alpha_op*sum(rate_delay_op,2)';
if add_noise
    noise_coeff = 0.1*tau_input;
    noise_orig = noise_coeff*randn(nr_trials,length_sim);
    noise_f = reshape(noise_orig,1,[]);
    noise_f_len = length(noise_f);
    noise_f_conv = conv2(noise_f,kernel_epsc);
    noise_f_conv(noise_f_len+1:end) = [];
    noise = reshape(noise_f_conv,length_sim,nr_trials)';
end
%
if init_learn && output_learning

    % here I assume sensory selectivity to Bspk = 1, so output_bs(1,:) is
    % just g-cell input.
    if gen_sg
        inE_1 = - w_op_mg*circshift(w_stim*stim_self-w_learn_sg_m*(v_all_sg_p_gc(1,:)-v_eq),delay_from_mg_dt);
        inI_1 = - w_op_mg*circshift(-w_stim*stim_self-w_learn_sg_m*(v_all_sg_m_gc(1,:)-v_eq),delay_from_mg_dt);
        w_input_opE = (pinv(input_shap_op')*(v_eq*(ones(length_sim,1))+w_learn_sg_m*(v_all_sg_m_gc(1,:)-v_eq)'-w_stim*stim_self'-inE_1'))';
        w_input_opI = (pinv(input_shap_op')*(v_eq*(ones(length_sim,1))+w_learn_sg_p*(v_all_sg_p_gc(1,:)-v_eq)'+w_stim*stim_self'-inI_1'))';
    else
        inE_1 = - w_op_mg*circshift(w_stim*stim_self,delay_from_mg_dt);
        inI_1 = - w_op_mg*circshift(-w_stim*stim_self,delay_from_mg_dt);
        w_input_opE = (pinv(input_shap_op')*(v_eq*(ones(length_sim,1))-w_stim*stim_self'-inE_1'))';
        w_input_opI = (pinv(input_shap_op')*(v_eq*(ones(length_sim,1))+w_stim*stim_self'-inI_1'))';
    end

else
    w_input_opE = w_initial_use_op';
    w_input_opI = w_initial_use_op';
end

v_all_opE = nan(nr_trials,length_sim);
r_all_opE = nan(nr_trials,length_sim);
w_all_opE = nan(nr_trials,nr_units_op);

v_all_opI = nan(nr_trials,length_sim);
r_all_opI = nan(nr_trials,length_sim);
w_all_opI = nan(nr_trials,nr_units_op);

v_gc_E = zeros(nr_trials,length_sim);
v_gc_I = zeros(nr_trials,length_sim);

for ii = 1:nr_trials

    if ii > nr_trials_bl
        
        input_P = circshift(output_bsP(ii,:),delay_from_mg_dt);
        input_M = circshift(output_bsM(ii,:),delay_from_mg_dt);

        if reverse_mg_op
            VmE = w_input_opE*input_shap_op-sg_m_op(ii,:) - w_op_mg*input_P;
            VmI = w_input_opI*input_shap_op-sg_p_op(ii,:) - w_op_mg*input_M;
        elseif random_mg_op
            VmE = w_input_opE*input_shap_op-sg_m_op(ii,:) - 0.5*w_op_mg*input_M - 0.5*w_op_mg*input_P;
            VmI = w_input_opI*input_shap_op-sg_p_op(ii,:) - 0.5*w_op_mg*input_P- 0.5*w_op_mg*input_M;
        else
            VmE = w_input_opE*input_shap_op-sg_m_op(ii,:) - w_op_mg*input_M;
            VmI = w_input_opI*input_shap_op-sg_p_op(ii,:) - w_op_mg*input_P;
        end
        v_gc_E(ii,:) = w_input_opE*input_shap_op;
        v_gc_I(ii,:) = w_input_opI*input_shap_op;
    else
        VmE = w_input_opE*input_shap_op;
        VmI = w_input_opI*input_shap_op;
    end
    if add_noise
        VmE = VmE+noise(ii,:);
        VmI = VmI+noise(ii,:);
    end
    if sigm_op
        rmE = func_sigm(VmE);
        rmI = func_sigm(VmI);
    else
        rmE = slop*VmE+bia;
        rmI = slop*VmI+bia;
    end
    rmE(rmE<0) = 0;
    rmI(rmI<0) = 0;

    v_all_opE(ii,:) = VmE;
    r_all_opE(ii,:) = rmE;
    w_all_opE(ii,:) = w_input_opE;

    v_all_opI(ii,:) = VmI;
    r_all_opI(ii,:) = rmI;
    w_all_opI(ii,:) = w_input_opI;

    if output_learning
        w_input_opE = w_input_opE - beta_op*(input_shap_op*rmE')';
        w_input_opE = w_input_opE + alpha_increase_op;

        w_input_opI = w_input_opI - beta_op*(input_shap_op*rmI')';
        w_input_opI = w_input_opI + alpha_increase_op;
    end
end

data.v_all_bsP = v_all_bsP;
data.r_all_bsP = r_all_bsP;
data.w_all_bsP = w_all_bsP;

data.v_all_bsM = v_all_bsM;
data.r_all_bsM = r_all_bsM;
data.w_all_bsM = w_all_bsM;

data.v_all_opE = v_all_opE;
data.r_all_opE = r_all_opE;
data.w_all_opE = w_all_opE;

data.v_all_opI = v_all_opI;
data.r_all_opI = r_all_opI;
data.w_all_opI = w_all_opI;

data.v_gc_E = v_gc_E;
data.v_gc_I = v_gc_I;

data.v_gc_bsP = v_gc_bsP;
data.v_gc_bsM = v_gc_bsM;

data.input_bsP = output_bsP;
data.input_bsM = output_bsM;

data.recurr_to_bsP = recurr_to_bsP;
data.recurr_to_bsM = recurr_to_bsM;

if gen_sg
    data.r_all_sg_m = r_all_sg_m;
    data.r_all_sg_p = r_all_sg_p;

    data.sg_m_op = sg_m_op;
    data.sg_p_op = sg_p_op;

    data.w_sg_p = w_all_sg_p;
    data.w_sg_m = w_all_sg_m;

    data.v_all_sg_m_gc = v_all_sg_m_gc;
    data.v_all_sg_p_gc = v_all_sg_p_gc;
end
%%
if op_alone
    if size(stim,1) == 1
        sg_m_op = repmat(-w_stim*stim,nr_trials,1);
        sg_p_op = repmat(w_stim*stim,nr_trials,1);
        sg_m_op(1:nr_trials_bl,:) = 0;
        sg_p_op(1:nr_trials_bl,:) = 0;
    else
        sg_m_op = -w_stim*stim;
        sg_p_op = w_stim*stim;
    end
    if init_learn && output_learning
        w_input_opE = (pinv(input_shap_op')*(v_eq*(ones(length_sim,1))-w_stim*stim_self'))';
        w_input_opI = (pinv(input_shap_op')*(v_eq*(ones(length_sim,1))+w_stim*stim_self'))';
    else
        w_input_opE = w_initial_use_op';
        w_input_opI = w_initial_use_op';
    end

    v_all_opE = nan(nr_trials,length_sim);
    r_all_opE = nan(nr_trials,length_sim);
    w_all_opE = nan(nr_trials,nr_units_op);

    v_all_opI = nan(nr_trials,length_sim);
    r_all_opI = nan(nr_trials,length_sim);
    w_all_opI = nan(nr_trials,nr_units_op);

    v_gc_E = zeros(nr_trials,length_sim);
    v_gc_I = zeros(nr_trials,length_sim);

    for ii = 1:nr_trials

        if ii > nr_trials_bl

            VmE = w_input_opE*input_shap_op-sg_m_op(ii,:);
            VmI = w_input_opI*input_shap_op-sg_p_op(ii,:);

            v_gc_E(ii,:) = w_input_opE*input_shap_op;
            v_gc_I(ii,:) = w_input_opI*input_shap_op;

        else
            VmE = w_input_opE*input_shap_op;
            VmI = w_input_opI*input_shap_op;
        end
        if add_noise
            VmE = VmE+noise(ii,:);
            VmI = VmI+noise(ii,:);
        end
        if sigm_op
            rmE = func_sigm(VmE);
            rmI = func_sigm(VmI);
        else
            rmE = slop*VmE+bia;
            rmI = slop*VmI+bia;
        end
        rmE(rmE<0) = 0;
        rmI(rmI<0) = 0;

        if output_learning
            w_input_opE = w_input_opE - beta_op*(input_shap_op*rmE')';
            w_input_opE = w_input_opE + alpha_increase_op;

            w_input_opI = w_input_opI - beta_op*(input_shap_op*rmI')';
            w_input_opI = w_input_opI + alpha_increase_op;
        end
        v_all_opE(ii,:) = VmE;
        r_all_opE(ii,:) = rmE;
        w_all_opE(ii,:) = w_input_opE;

        v_all_opI(ii,:) = VmI;
        r_all_opI(ii,:) = rmI;
        w_all_opI(ii,:) = w_input_opI;
    end
    data.v_all_opE_alone = v_all_opE;
    data.r_all_opE_alone = r_all_opE;
    data.w_all_opE_alone = w_all_opE;

    data.v_all_opI_alone = v_all_opI;
    data.r_all_opI_alone = r_all_opI;
    data.w_all_opI_alone = w_all_opI;

    data.v_gc_E_alone = v_gc_E;
    data.v_gc_I_alone = v_gc_I;
end
end
