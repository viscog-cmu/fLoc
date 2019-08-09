classdef fLocSession

    properties
        name      % participant initials or id string
        date      % session date
        trigger   % option to trigger scanner (0 = no, 1 = yes)
        num_runs  % number of runs in experiment
        sequence  % session fLocSequence object
        responses % behavioral response data structure
        parfiles  % paths to vistasoft-compatible parfiles
        elapsed_times % num_runs long vector recording time from trigger to close
        ecc_by_run % runwise eccentricity in degrees (an array)
        screen_id
        viewdist_mm
        screenwidth_mm
        screenwidth_pix
        eyetracking
    end

    properties (Hidden)
        stim_set  % stimulus set/s (1 = standard, 2 = alternate, 3 = both)
        task_num  % task number (1 = 1-back, 2 = 2-back, 3 = oddball)
        input     % device number of input used for resonse collection
        keyboard  % device number of native computer keyboard
        atscanner % whether we are at SIBR
        hit_cnt   % number of hits per run
        fa_cnt    % number of false alarms per run
        stim_size_pix
    end

    properties (Constant)
        count_down = 4; % pre-experiment countdown (secs)
        stim_size_deg = 5; % size to display images
    end

    properties (Constant, Hidden)
        task_names = {'1back' '2back' 'oddball'};
        exp_dir = fileparts(fileparts(which(mfilename, 'class')));
        fix_color = [255 0 0]; % fixation marker color (RGB)
        text_color = 255;      % instruction text color (grayscale)
        blank_color = 128;     % baseline screen color (grayscale)
        wait_dur = 1;          % seconds to wait for response
        trig_key = KbName('t');
    end

    properties (Dependent)
        id        % session-specific id string
        task_name % descriptor for each task number
    end

    properties (Dependent, Hidden)
        hit_rate     % proportion of task probes detected in each run
        instructions % task-specific instructions for participant
    end

    methods

        % class constructor
        function session = fLocSession(name, trigger, stim_set, num_runs, task_num, ecc_by_run, atscanner, screen_id)
            session.name = deblank(name);
            session.trigger = trigger;
            if nargin < 3
                session.stim_set = 3;
            else
                session.stim_set = stim_set;
            end
            if nargin < 4
                session.num_runs = 4;
            else
                session.num_runs = num_runs;
            end
            if nargin < 5
                session.task_num = 3;
            else
                session.task_num = task_num;
            end
            if nargin < 6
                session.ecc_by_run = zeros(num_runs,1);
            else
                session.ecc_by_run = ecc_by_run;
            end
            if nargin < 7
                session.atscanner = 0;
            else
                session.atscanner = atscanner;
            end
            if nargin < 8
                session.screen_id = 'nick-mbp';
            else
                session.screen_id = screen_id;
            end
            session.date = date;
            session.hit_cnt = zeros(1, session.num_runs);
            session.fa_cnt = zeros(1, session.num_runs);
            session.elapsed_times = zeros(1, session.num_runs);
        end

        % get session-specific id string
        function id = get.id(session)
            par_str = [session.name '_' session.date];
            exp_str = [session.task_name '_' num2str(session.num_runs) 'runs'];
            id = [par_str '_' exp_str];
        end

        % get name of task
        function task_name = get.task_name(session)
            task_name = session.task_names{session.task_num};
        end

        % get hit rate for task
        function hit_rate = get.hit_rate(session)
            num_probes = sum(session.sequence.task_probes);
            hit_rate = session.hit_cnt ./ num_probes;
        end

        % get instructions for participant given task
        function instructions = get.instructions(session)
            if session.task_num == 1
                instructions = 'Fixate. Press a button when an image repeats on sequential trials.';
            elseif session.task_num == 2
                instructions = 'Fixate. Press a button when an image repeats with one intervening image.';
            else
                instructions = 'Fixate. Press a button when a scrambled image appears.';
            end
        end

        % get screen calibration properties
        function session = get_screen_properties(session)
           switch session.screen_id
               case 'nick-mbp'
                   session.screenwidth_pix = 2560;
                   session.screenwidth_mm = 298;
                   session.viewdist_mm = 500;
                   session.eyetracking = 0;
               case 'sibr-boldscreen'
                   session.screenwidth_pix = 1920;
                   session.screenwidth_mm = 518;
                   session.viewdist_mm = 1260;
                   session.eyetracking = 1;
               case 'sibr-proj'
                   session.screenwidth_pix = 1024;
                   session.screenwidth_mm = 370;
                   session.viewdist_mm = 1000;
                   session.eyetracking = 1;
               case 'bridge'
                   session.screenwidth_pix = 1920;
                   session.screenwidth_mm = 698.4;
                   session.viewdist_mm = 1310;
                   session.eyetracking = 0;
           end
        end

        % define/load stimulus sequences for this session
        function session = load_seqs(session)
            fname = [session.id '_fLocSequence.mat'];
            fpath = fullfile(session.exp_dir, 'data', session.id, fname);
            % make stimulus sequences if not already defined for session
            if ~exist(fpath, 'file')
                seq = fLocSequence(session.stim_set, session.num_runs, session.task_num);
                seq = make_runs(seq);
                mkdir(fileparts(fpath));
                save(fpath, 'seq', '-v7.3');
            else
                load(fpath);
            end
            session.sequence = seq;
        end

        % register input devices
        function session = find_inputs(session)
            laptop_key = get_keyboard_num;
            button_key = get_box_num;
            if session.trigger == 1 && button_key ~= 0
                session.keyboard = laptop_key;
                session.input = button_key;
            else
                session.keyboard = laptop_key;
                session.input = laptop_key;
            end
            %for UMass HMRC we cannot specify keyboard. record from all
%             session.keyboard = [];
%             session.input = [];
        end

        % execute a run of the experiment
        function session = run_exp(session, run_num)
            % get timing information and initialize response containers
            session = find_inputs(session); k = session.input;
            session = get_screen_properties(session);
            session.stim_size_pix = deg2pix(session.stim_size_deg, session.viewdist_mm, ...
                session.screenwidth_mm, session.screenwidth_pix);
            sdc = session.sequence.stim_duty_cycle;
            stim_dur = session.sequence.stim_dur;
            isi_dur = session.sequence.isi_dur;
            stim_names = session.sequence.stim_names(:, run_num);
            stim_dir = fullfile(session.exp_dir, 'new_stimuli');
            tcol = session.text_color; bcol = session.blank_color; fcol = session.fix_color;
            resp_keys = {}; resp_press = zeros(length(stim_names), 1);
            % setup screen and load all stimuli in run
            [window_ptr, center] = do_screen;
            % setup eyetracker if tracking
            if session.eyetracking
                [windowPtr_cal, rect_cal] = Screen('OpenWindow', window,[],[320,256,960,768]);
                el=EyelinkInitDefaults(window);
                if ~EyelinkInit(0, 1)
                    fprintf('Eyelink Init aborted.\n');
                    cleanup;  % cleanup function
                    return;
                end
                [v vs]=Eyelink('GetTrackerVersion');
                fprintf('Running experiment on a ''%s'' tracker.\n', vs );
                % make sure that we get gaze data from the Eyelink
                Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
                EyelinkDoTrackerSetup(el);
                Screen('Close', windowPtr_cal);
                eyelink_tmp_fn = sprintf('%d.edf', run_num);
                eyelink_fn = sprintf('%s/eyelink_run-%02d.edf',session.id,run_num);
                Eyelink('openfile', eyelink_tmp_fn)
                Eyelink('StartRecording');
            end
            % compute stimulus eccentricity in pix
            shift_x = deg2pix(session.ecc_by_run(run_num)); 
            center_x = center(1) + shift_x; center_y = center(2); s = session.stim_size_pix / 2;
            stim_rect = [center_x - s center_y - s center_x + s center_y + s];
            img_ptrs = [];
            for ii = 1:length(stim_names)
                if strcmp(stim_names{ii}, 'baseline')
                    img_ptrs(ii) = 0;
                else
                    cat_dir = stim_names{ii}(1:find(stim_names{ii} == '-') - 1);
                    img = imread(fullfile(stim_dir, cat_dir, stim_names{ii}));
                    img_ptrs(ii) = Screen('MakeTexture', window_ptr, img);
                end
            end
            % start experiment triggering scanner if applicable
            if session.trigger == 0
                Screen('FillRect', window_ptr, bcol);
                Screen('Flip', window_ptr);
                DrawFormattedText(window_ptr, session.instructions, 'center', 'center', tcol);
                Screen('Flip', window_ptr);
                if session.atscanner == 1
                    keyCodes = zeros(256,1);
                    while keyCodes(session.trig_key)==0
                          [keyPressed, secs, keyCodes] = KbCheck;
                    end
                else
                    KbStrokeWait;
                end

            elseif session.trigger == 1
                Screen('FillRect', window_ptr, bcol);
                Screen('Flip', window_ptr);
                DrawFormattedText(window_ptr, session.instructions, 'center', 'center', tcol); % 'flipHorizontal', 1);
                Screen('Flip', window_ptr);
                while 1
                    get_key('g');
                    [status, ~] = start_scan;
                    if status == 0
                        break
                    else
                        message = 'Trigger failed.';
                        DrawFormattedText(window_ptr, message, 'center', 'center', fcol);
                        Screen('Flip', window_ptr);
                    end
                end
            end
            if session.eyetracking
                Eyelink('Message', 'countdown_start');
            end
            % display countdown numbers
            beg_time = GetSecs;
            [cnt_time, rem_time] = deal(session.count_down + beg_time);
            cnt = session.count_down;
            while rem_time > 0
                if floor(rem_time) <= cnt
                    DrawFormattedText(window_ptr, num2str(cnt), 'center', 'center', tcol);
                    Screen('Flip', window_ptr);
                    cnt = cnt - 1;
                end
                rem_time = cnt_time - GetSecs;
            end
            if session.eyetracking
                Eyelink('Message', 'exp_start');
            end
            % main display loop
            start_time = GetSecs;
            for ii = 1:length(stim_names)
                if session.eyetracking
                    % record start of blocks in eyelink file
                    if ~ mod(ii-1,session.sequence.stim_per_block)
                       EyeLink('Message', sprintf('block_start-%s',strtok(stim_names{ii},'-')))
                    end
                end
                % display blank screen if baseline and image if stimulus
                if strcmp(stim_names{ii}, 'baseline')
                    Screen('FillRect', window_ptr, bcol);
                    draw_fixation(window_ptr, center, fcol);
                else
                    Screen('DrawTexture', window_ptr, img_ptrs(ii), [], stim_rect);
                    draw_fixation(window_ptr, center, fcol);
                end
                Screen('Flip', window_ptr);
                % collect responses
%                 check_keys = [KbName('1'):KbName('1')+5, KbName('1!'):KbName('1!')+5];
                check_keys = [KbName('b'),KbName('y')];
                ii_press = []; ii_keys = [];
                [keys, ie] = record_keys(start_time + (ii - 1) * sdc, stim_dur, k, check_keys);
                ii_keys = [ii_keys keys]; ii_press = [ii_press ie];
                % display ISI if necessary
                if isi_dur > 0
                    Screen('FillRect', window_ptr, bcol);
                    draw_fixation(window_ptr, center, fcol);
                    Screen('Flip', window_ptr);
                    [keys, ie] = record_keys(start_time + (ii - 1) * sdc + stim_dur, isi_dur, k, check_keys);
                    ii_keys = [ii_keys keys]; ii_press = [ii_press ie];
                end
                resp_keys{ii} = ii_keys;
                if any(ii_press==0)
                    resp_press(ii) = 1;
                else
                    resp_press(ii) = 0;
                end
            end
            if session.eyetracking
                EyeLink('Message', 'end_stim_loop')
            end
            % store responses
            session.responses(run_num).keys = resp_keys;
            session.responses(run_num).press = resp_press;
            fname = [session.id '_backup_run' num2str(run_num) '.mat'];
            fpath = fullfile(session.exp_dir, 'data', session.id, fname);
            save(fpath, 'resp_keys', 'resp_press', '-v7.3');
            % analyze response data and display performance
            session = score_task(session, run_num);
            num_probes = num2str(sum(session.sequence.task_probes(:, run_num)));
            hit_cnt = num2str(session.hit_cnt(run_num));
            fa_cnt = num2str(session.fa_cnt(run_num));
            hit_rate = num2str(session.hit_rate(run_num) * 100);
            hit_str = ['Hits: ' hit_cnt '/' num_probes ' (' hit_rate '%)'];
            fa_str = ['False alarms: ' fa_cnt];
            Screen('FillRect', window_ptr, bcol);
            Screen('Flip', window_ptr);
            score_str = [hit_str '\n' fa_str];
            WaitSecs(8);
            session.elapsed_times(run_num) = GetSecs - beg_time;
            if session.eyetracking
                EyeLink('Message', 'end_exp_and_show_perf')
                Eyelink('StopRecording');
                Eyelink('CloseFile');
                EyeLink('ReceiveFile', eyelink_tmp_fn)
                movefile(eyelink_tmp_fn, eyelink_fn);
            end
            % get_key('g1234678', session.keyboard);
            DrawFormattedText(window_ptr, score_str, 'center', 'center', tcol);
            Screen('Flip', window_ptr);
            WaitSecs(2)
            ShowCursor;
            Screen('CloseAll');
        end

        % quantify performance in stimulus task
        function session = score_task(session, run_num)
            sdc = session.sequence.stim_duty_cycle;
            fpw = session.wait_dur / sdc;
            % get response time windows for task probes
            resp_presses = session.responses(run_num).press;
            resp_correct = session.sequence.task_probes(:, run_num);
            probe_idxs = find(resp_correct);
            hit_windows = zeros(size(resp_correct));
            for ww = 1:ceil(fpw)
                hit_windows(probe_idxs + ww - 1) = 1;
            end
            hit_resp_windows = resp_presses(hit_windows == 1);
            fa_resp_windows = resp_presses(hit_windows == 0);
            % count hits and false alarms
            session.hit_cnt(run_num) = sum(max(reshape(hit_resp_windows, fpw, [])));
            session.fa_cnt(run_num) = sum(fa_resp_windows);
        end

        % write vistasoft-compatible parfile for each run
        function session = write_parfiles(session)
            session.parfiles = cell(1, session.num_runs);
            % list of conditions and plotting colors
            conds = ['Baseline' session.sequence.stim_conds];
            cols = {[1 1 1] [0 0 1] [0 0 0] [1 0 0] [.8 .8 0] [0 1 0]};
            % write information about each block on a separate line
            for rr = 1:session.num_runs
                block_onsets = session.sequence.block_onsets(:, rr);
                block_conds = session.sequence.block_conds(:, rr);
                cond_names = conds(block_conds + 1);
                cond_cols = cols(block_conds + 1);
                fname = [session.id '_fLoc_run' num2str(rr) '.par'];
                fpath = fullfile(session.exp_dir, 'data', session.id, fname);
                fid = fopen(fpath, 'w');
                for bb = 1:length(block_onsets)
                    fprintf(fid, '%d \t %d \t', block_onsets(bb), block_conds(bb));
                    fprintf(fid, '%s \t', cond_names{bb});
                    fprintf(fid, '%i %i %i \n', cond_cols{bb});
                end
                fclose(fid);
                session.parfiles{rr} = fpath;
            end
        end

    end

end
