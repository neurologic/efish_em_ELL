function [func_sigm, slop, bia] = sigm_lin_fi(v_eq,varargin)

% this function defines the f-i function from voltage to firing rate,
% giving a linear and sigmoidal possibilities.

p = inputParser;
addRequired(p,'v_eq',@isnumeric);
addParameter(p,'r_eq',1);
addParameter(p,'r_max',1);
addParameter(p,'r_stim_mult',1);
addParameter(p,'v_stim_mult',1);

parse(p,v_eq,varargin{:});
r_eq = p.Results.r_eq;
r_max = p.Results.r_max;
r_stim_mult = p.Results.r_stim_mult;
v_stim_mult = p.Results.v_stim_mult;
%%
log_1 = log(r_max/r_eq-1);
log_2 = log(r_max/r_stim_mult-1);
theta_sigm = (log_2*v_eq-log_1*(v_stim_mult+v_eq))/(log_2-log_1);
if abs(v_eq-theta_sigm)<1e-3
    error('theta_sigm equals v_equ')
end
alpha_sigm = log_1/(theta_sigm-v_eq);
func_sigm = @(v) r_max./(1+exp(-alpha_sigm*(v-theta_sigm)));

slop = (r_stim_mult - r_eq)/(v_stim_mult);
bia = r_eq - slop*v_eq;

end

