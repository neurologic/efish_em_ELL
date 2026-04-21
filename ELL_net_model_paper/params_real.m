%%
dt = 1e-3;
t_before = 0.01;
shift_time = 0.005;
if ~exist('rate_conv_gc','var')
    [gc_input_rate,rate_conv_gc,epsc_gc,cell_type,kernel_gc] = generate_gc_input(dt,'t_before',t_before,...
    'time_after_command',0.15,'percentage_of_cells_used',1,...
    'tau_v',0.01,'tau_gc',0.005,'shift_time',shift_time);
    %'tau_v',0.01,'tau_gc',0.005

    idx_elim = find(sum(gc_input_rate,2)==0);
    gc_input_rate(idx_elim,:) = [];
    rate_conv_gc(idx_elim,:) = [];
    epsc_gc(idx_elim,:) = [];
    cell_type(idx_elim,:) = [];
end

rate_delay = gc_input_rate;
input_shap = rate_conv_gc;
nr_units = size(input_shap,1);
length_sim = size(input_shap,2);
length_sim_s = length_sim*dt;
time_pre_command = t_before;
%%
Amp = 1;
alp = 70; %90
nr_patting_before = round(t_before/dt+0.01/dt);
nr_patting_after = round(0.04/dt); %0.06/dt
nr_patting = nr_patting_before+nr_patting_after;
t = 0:dt:length_sim_s-(nr_patting+1)*dt;
period = length_sim_s-(nr_patting+1)*dt;
omega = 2*pi/period;
stim = Amp*exp(-alp*t).*sin(omega*t);
stim = [zeros(1,nr_patting_before) stim zeros(1,nr_patting_after)];

% center_stim = floor((time_pre_command+0.04)/dt);
% sigma = 8e-5; %s
% stim = 1/(sqrt(2*pi)*sigma)*exp(-(dt*((1:length_sim) - center_stim)/(sqrt(2*sigma))).^2);

%%
gc_units_op_to_mg = 1/3.06; %1/2.25
w_sensory_to_bspk = 1;
w_recur_to_bspk = 0;
delay_from_mg = 0.001;

alpha = 1.5e-9; %1e-9
mult_alpha_op = 1;

v_eq = 1.5;

w_mg_recurrent = 0.85;
w_op_mg = 0.5; % 0.5

mult_mg = 60; %60 this is a crucial parameter...!!
mult_op_rel_mg = 1/7.5; % 1/7.5 this is a crucial parameter...!!!!!

r_eq_mg = 1.05; %Hz, this is background (base_line) rate, (actual value is not important) 
r_stim_mult_mg = mult_mg*r_eq_mg;

r_eq_op = 17.75; %Hz, this is background (base_line) rate, 
r_stim_mult_op = mult_op_rel_mg*mult_mg*r_eq_op;
 
r_eq_sg = r_eq_mg; %Hz, this is background (base_line) rate, 
r_stim_mult_sg = mult_mg*r_eq_sg; %r_stim_mult_mg;

w_learn_sg_m = 0.5; % describes how much learning sensory input undergoes (values are from 0 to 1, where 1 is full learning)
w_stim_canc_sg_m = 0*w_learn_sg_m; % describes the separation of broad and narrow spikes. Where 0 means no separation and 1 means full separation - i.e. mg cells.

w_learn_sg_p = 0.5; 
w_stim_canc_sg_p = 0*w_learn_sg_p;

sigm_mg = true;
sigm_sg = sigm_mg;
sigm_op = sigm_mg;

r_max_mult_mg = 1.25*mult_mg; %1.05
r_max_mult_op = 1.25*r_stim_mult_op/r_eq_op; 
r_max_mult_sg = r_max_mult_mg;

v_stim_mult = 2.25; %2.5
pk_stim = 1;
w_stim = abs(pk_stim*v_stim_mult/max(stim));

nr_sg_cells = 1; 
