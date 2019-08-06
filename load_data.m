function [data, Ts, f_chunk, durs, RT_all, RT_new, avg_rew, filenames] = load_data(dirname, expected_number_of_rows)

    if ~exist('dirname', 'var')
        dirname = 'exp/results/'; 
        %bad_dirname = 'exp/results/bad';
    end

    if ~exist('expected_number_of_rows', 'var')
        expected_number_of_rows = 100;
    end

    %dirname = 'exp/results/subway10_map';  % expected = 81 <---------- MONEY
    %dirname = 'exp/results/subway6';  % expected = 83
    %dirname = 'exp/results/subway9';  % expected = 81  <------------- MONEY!!
    %dirname = 'exp/results/subway9_control';  % expected = 81
    %dirname = 'exp/results/ARCHIVE/subway9_control_batch1';  % expected = 81
    %dirname = 'exp/results/subway12';  % expected = 82
    %dirname = 'exp/results/subway8_randsg';  % expected = 103
    %dirname = 'exp/results/subway8';  % expected = 83
    %dirname = 'exp/results/subway10_repro';  % expected = 83 <---------- MONEY
    %dirname = 'exp/results/subway10'; % expected # rows = 100
    %dirname = 'exp/results/subway10_noadj'; % expected # rows = 110
    %dirname = 'exp/results/subway_10_randsg_WRONG'; % expected # rows = 116

    %dirname = 'exp/results/ARCHIVE/subway_10_noadj_batch2'; % expected # rows = 110
    %dirname = 'exp/results/ARCHIVE/subway10_batch2'; % expected # rows = 110

    files = dir(dirname);
    subj = 1;
    durs = [];
    f_chunk = [];
    RT_all = [];
    RT_new = [];
    for idx = 1:length(files)
        if ~endsWith(files(idx).name, 'csv')
            continue;
        end

        filepath = fullfile(dirname, files(idx).name);
        try
            T = readtable(filepath, 'Delimiter', ',');
        catch
            fprintf('Error reading file %s\n', files(idx).name);
            if exist('bad_dirname', 'var')
                movefile(filepath, bad_dirname);
            end
            continue;
        end
        if size(T, 1) ~= expected_number_of_rows
            fprintf('Skipping %s: it has only %d rows\n', files(idx).name, size(T,1));
            if exist('bad_dirname', 'var')
                movefile(filepath, bad_dirname);
            end
            continue;
        end
        Ts{subj} = T;

        disp(files(idx).name);

        skip_subj = false;

        % TODO dedupe with init_D_from_csv.m
        RT_chunk = [];
        RT_nonchunk = [];
        max_RT = 0;
        phase = 1;
        j = 1; % idx within phase


        for i = 1:size(T,1)
            stage = strip(T.stage{i});
            switch phase
                case 1
                    if strcmp(stage, 'test')
                        phase = 2;
                        j = 1;
                    end
                case 2
                    if strcmp(stage, 'training')
                        phase = 3;
                        j = 1;
                    end
                case 3
                    if strcmp(stage, 'test')
                        phase = 4;
                        j = 1;
                    end
            end

            r = T.reward(i);
            s = T.start(i);
            if iscell(s)
                s = str2num(s{1});
            end
            if isempty(s)
                s = 0;
            end
            g = T.goal(i);
            if iscell(g)
                g = g{1};
            end
            if isempty(g)
                g = 0;
            end
            RTs = str2num(T.RTs{i});
            max_RT = max(max_RT, max(RTs));
            path = str2num(T.path{i});
            assert(length(path) == T.length(i));
            group = strip(T.group{i});
            RT_tot = T.RT_tot(i);
            keys = str2num(T.keys{i});
            switch group
                case 'A'
                    group = 1;
                case 'B'
                    group = 2;
                otherwise
                    assert(false);
            end
            id = T.subj_id(i);
            check_fails = T.check_fails(i);

            % skip subjects with unrealistically long paths
            %{
            if length(path) > 25
                fprintf('Skipping %s: trial %d has path length %d\n', files(idx).name, i, length(path));
                skip_subj = true;
                break;
            end
            %}

            data(subj, phase).r(j) = r;
            data(subj, phase).s(j) = s;
            data(subj, phase).g{j} = g;
            data(subj, phase).path{j} = path;
            data(subj, phase).len(j) = length(path);
            data(subj, phase).group(j) = group;
            data(subj, phase).id = id;
            data(subj, phase).check_fails = check_fails;
            data(subj, phase).RTs{j} = RTs;
            data(subj, phase).RT_tot(j) = RT_tot;
            data(subj, phase).keys{j} = keys;

            j = j + 1;
        end

        %{
        % skip subjects that didn't improve over time
        if ~skip_subj
            l = data(subj,1).len;
            first = l(1:round(length(l) * 0.10));
            last = l(end-round(length(l) * 0.10):end);
            [h, p, ci, stat] = ttest2(first, last, 'tail', 'right');
            if p > 0.1
                fprintf('Skipping %s: no improvement in path length (p = %.3f, first 20 = %.2f, last 20 = %.2f)\n', files(idx).name, p, mean(first), mean(last));
                skip_subj = true;
            end
        end
        %}

        fprintf('         max RT = %.2f s, total RT = %.2f min,  avg chunk RT = %.2f sec;   avg nonchunk RT = %.2f sec\n', max_RT / 1000, sum(T.RT_tot) / 1000 / 60, mean(RT_chunk) / 1000, mean(RT_nonchunk) / 1000);
        f_chunk = [f_chunk mean(RT_nonchunk) / mean(RT_chunk)]; % factor by which chunking improves RTs
        RT_all = [RT_all sum(RT_chunk) + sum(RT_nonchunk)]; % Total RT
        RT_new = [RT_new 4 * sum(RT_nonchunk)]; % Total RT if nonchunk trials only

        if ismember('timestamp', T.Properties.VariableNames)
            dur = T.timestamp(end) - T.timestamp(1);
            durs = [durs, dur];
            fprintf('             duration = %.2f mins\n', dur / 60);
        end
        avg_rew(subj) = mean(data(subj, 1).r);
        filenames{subj} = filepath;

        if ~skip_subj
            subj = subj + 1;
        else
            if size(data,1) >= subj
                data(subj,:) = [];
            end
        end
    end

    durs = durs / 60;
    fprintf('avg duration = %.2f +- %.2f mins\n', mean(durs), std(durs)/sqrt(length(durs)));

    save('data.mat', 'data', 'Ts', 'durs', 'avg_rew');
