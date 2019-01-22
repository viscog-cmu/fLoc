
% convenience wrapper for runme.m

function run_floc_sub(sub_num, run_num)

% hard-coded parameters
stim_set = 1;
total_runs = 3;
task_num = 1;

% we code subs by a number string, not initials, for privacy
sub = sprintf('%02d', sub_num);

filepath = mfilename('fullpath');
[dirpath, ~, ~] = fileparts(filepath);
cd(dirpath)

 runme(sub, 0, stim_set, total_runs, task_num, run_num)

