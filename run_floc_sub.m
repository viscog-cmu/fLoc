
% convenience wrapper for main.m

function run_floc_sub(sub_num, run_num, at_scanner)

Screen('Preference', 'SkipSyncTests', 1)
Screen('Preference', 'TextRenderer', 0);

% hard-coded parameters
stim_set = 1;
total_runs = 5;
task_num = 1;
ecc_by_run = [0, 0, 0];

if at_scanner
    screen_id = 'bridge';
else
    screen_id = 'nick-mbp';
end

% we code subs by a number string, not initials, for privacy
sub = sprintf('sub-%02d', sub_num);

filepath = mfilename('fullpath');
[dirpath, ~, ~] = fileparts(filepath);
cd(dirpath)

main(sub, 0, stim_set, total_runs, task_num, run_num, ecc_by_run, at_scanner, screen_id)

