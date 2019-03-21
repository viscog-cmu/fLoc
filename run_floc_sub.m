
% convenience wrapper for main.m

function run_floc_sub(sub_num, run_num)

Screen('Preference', 'SkipSyncTests', 1)

% hard-coded parameters
stim_set = 1;
total_runs = 3;
task_num = 1;
ecc_by_run = [-6, 0, 6];

% we code subs by a number string, not initials, for privacy
sub = sprintf('sub-%02d', sub_num);

filepath = mfilename('fullpath');
[dirpath, ~, ~] = fileparts(filepath);
cd(dirpath)

main(sub, 0, stim_set, total_runs, task_num, run_num, ecc_by_run)

