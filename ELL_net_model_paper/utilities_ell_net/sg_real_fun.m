function data = sg_real_fun(v_eq,varargin)

p = inputParser;
addRequired(p,'v_eq',@isnumeric);
addParameter(p,'r_eq',1.5);
addParameter(p,'r_stim_mult',3);
addParameter(p,'v_stim_mult',2);
addParameter(p,'stim',1);
addParameter(p,'w_stim',1);
addParameter(p,'w_initial_use',1);
addParameter(p,'w_propo',false);
addParameter(p,'add_stim',true);
addParameter(p,'rate_delay',1);
addParameter(p,'input_shap',1);
addParameter(p,'alpha',1e-9);
addParameter(p,'dt',1e-3);
addParameter(p,'nr_trials',2000);
addParameter(p,'nr_trials_bl',200);
addParameter(p,'sigm',false);
addParameter(p,'which_to_omit',[]);
addParameter(p,'nr_sg_cells',20);
addParameter(p,'stim_self',[]);
addParameter(p,'init_learn',false);
addParameter(p,'r_max_mult',120);
addParameter(p,'ratio_gca',1/26);

parse(p,v_eq,varargin{:});
r_eq = p.Results.r_eq;
r_stim_mult = p.Results.r_stim_mult;
v_stim_mult = p.Results.v_stim_mult;
stim = p.Results.stim;
w_stim = p.Results.w_stim;
w_initial_use = p.Results.w_initial_use;
w_propo = p.Results.w_propo;
add_stim = p.Results.add_stim;
rate_delay = p.Results.rate_delay;
input_shap = p.Results.input_shap;
alpha = p.Results.alpha;
nr_trials = p.Results.nr_trials;
nr_trials_bl = p.Results.nr_trials_bl;
dt = p.Results.dt;
sigm = p.Results.sigm;
which_to_omit = p.Results.which_to_omit;
nr_sg_cells = p.Results.nr_sg_cells;
stim_self = p.Results.stim_self;
init_learn = p.Results.init_learn;
r_max_mult = p.Results.r_max_mult;
ratio_gca = p.Results.ratio_gca;

data = struct;
nr_units = size(input_shap,1);
length_sim = size(input_shap,2);

%%
beta = alpha*dt/r_eq;

[func_sigm, slop, bia] = sigm_lin_fi(v_eq,'r_eq',r_eq,'r_max',r_max_mult*r_eq,...
    'r_stim_mult',r_stim_mult,'v_stim_mult',v_stim_mult);
alpha_increase = alpha*sum(rate_delay,2)';
%%
% perc_inclu = ratio_gca*ones(1,nr_sg_cells);
if nr_sg_cells == 1
    perc_inclu = ratio_gca;
else
    % min_perc = 0.05;
    % max_perc = 0.5;
    % perc_inclu = min_perc+max_perc*rand(1,nr_sg_cells);
    perc_inclu = ratio_gca*2*rand(1,nr_sg_cells);
end
nr_omissions = round((1-perc_inclu)*nr_units);

v_all_sg_cells = zeros(nr_trials,length_sim);
v_all_gc_cells = zeros(nr_trials,length_sim);
v_all_sg_cells_end = zeros(nr_sg_cells,length_sim);
r_all_sg_cells_bspk = zeros(nr_trials,length_sim);
w_all_sg_cells = zeros(nr_sg_cells,nr_units);

for sgnr = 1:nr_sg_cells
    which_to_omit = randperm(nr_units,nr_omissions(sgnr));

    vec_mult = ones(1,nr_units);
    vec_mult(which_to_omit) = 0;

    w_input = w_initial_use';

    if init_learn
        % options = optimoptions('lsqlin','Algorithm','interior-point');
        % w_initial_use_canc = lsqlin(input_shap(logical(vec_mult),:)',-w_stim*stim_self);
        w_initial_use_canc = pinv(input_shap(logical(vec_mult),:)')*(-w_stim*stim_self');
        w_input(logical(vec_mult)) = w_input(logical(vec_mult))+w_initial_use_canc';
    end

    v_all = nan(nr_trials,length_sim);
    r_all = nan(nr_trials,length_sim);
    w_all = nan(nr_trials,nr_units);
    v_all_gc = nan(nr_trials,length_sim);

    for ii = 1:nr_trials
        if size(stim,1) == 1
            if ii > nr_trials_bl && add_stim
                Vm = w_input*input_shap+w_stim*stim;
            else
                Vm = w_input*input_shap;
            end
        else
            Vm = w_input*input_shap+w_stim*stim(ii,:);
        end
        if sigm
            rm = func_sigm(Vm);
        else
            rm = slop*Vm+bia;
        end
        rm(rm<0) = 0;

        v_all(ii,:) = Vm;
        r_all(ii,:) = rm;
        w_all(ii,:) = w_input;
        v_all_gc(ii,:) = w_input*input_shap;

        if w_propo
            w_input = w_input - beta*(input_shap*rm')'.*w_initial_use'.*vec_mult;
            w_input = w_input + alpha_increase.*w_initial_use'.*vec_mult;
        else
            w_input = w_input - beta*(input_shap*rm')'.*vec_mult;
            w_input = w_input + alpha_increase.*vec_mult;
        end

    end
    v_all_sg_cells = v_all_sg_cells+v_all;
    v_all_gc_cells = v_all_gc_cells+v_all_gc;
    v_all_sg_cells_end(sgnr,:) = v_all(end,:);
    r_all_sg_cells_bspk = r_all_sg_cells_bspk+r_all;
    w_all_sg_cells(sgnr,:) = w_all(end,:);
end
v_all_sg_cells = v_all_sg_cells./nr_sg_cells;
r_all_sg_cells_bspk = r_all_sg_cells_bspk./nr_sg_cells;
v_all_gc_cells = v_all_gc_cells./nr_sg_cells;

data.v_all = v_all_sg_cells;
data.r_all = r_all_sg_cells_bspk;
data.w_all = w_all_sg_cells;
data.slop = slop;
data.v_all_gc = v_all_gc_cells;
data.v_all_end = v_all_sg_cells_end;
end

