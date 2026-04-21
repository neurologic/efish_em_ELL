function [gc_input_rate,rate_conv_gc,epsc_gc,cell_type,kernel_gc] = generate_gc_input(dt,varargin)


p = inputParser;
addRequired(p,'dt',@isnumeric);
addParameter(p,'t_before', 0.01);
addParameter(p,'use_real_gc', true);
addParameter(p,'time_after_command',0.15);
addParameter(p,'percentage_of_cells_used',0.5);
addParameter(p,'tau_v',0.01);
addParameter(p,'tau_gc',0.005);
addParameter(p,'shift_time',0.005);


parse(p,dt,varargin{:});
t_before = p.Results.t_before;
time_after_command = p.Results.time_after_command;
percentage_of_cells_used = p.Results.percentage_of_cells_used;
use_real_gc = p.Results.use_real_gc;
tau_v = p.Results.tau_v;
tau_gc = p.Results.tau_gc;
shift_time = p.Results.shift_time;

if use_real_gc
    
    pth_gc_input = 'data_ell_net';
    file_name = 'generated_GCs';
    shift_gc = floor(shift_time/dt);
    
    
    [gc_input_rate, cell_type,~] = gc_input(pth_gc_input,file_name,dt,t_before,'time_after_command',time_after_command,'sort_by_type',true);
    gc_input_rate = circshift(gc_input_rate,shift_gc,2);
    
    if percentage_of_cells_used<1
        nr_cells_used = ceil(percentage_of_cells_used*size(gc_input_rate,1));
        which_cells = randperm(size(gc_input_rate,1),nr_cells_used);
        gc_input_rate = gc_input_rate(which_cells,:);
        cell_type = cell_type(which_cells);
    end
else
    gaussian_delay = false;
    gap_between_gc = 1e-3/dt;
    variance = 2;
    rate_probability = 500*1e-3;
    nr_gc_per_time = 1;
    
    [gc_input_rate] = delay_line_basis(floor((time_after_command_initial+t_before)/dt),'gaussian_delay',gaussian_delay,...
        'gap_between_gc',gap_between_gc,'variance',variance,'rate_probability',rate_probability,...
        'nr_gc_per_time',nr_gc_per_time);
end
[kernel_gc,~,rate_conv_gc,epsc_gc,integral_kernel_gc] = kernel_convolved('dt',dt,...
    'input',gc_input_rate,'tau_output',tau_v,'tau_input',tau_gc);
end

