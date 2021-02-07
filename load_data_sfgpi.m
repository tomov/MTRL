function [data, Ts, filenames] = load_data(dirname, expected_number_of_rows)

    if ~exist('dirname', 'var')
        dirname = 'exp/results/sfgpi_v1_1a'; 
        %bad_dirname = 'exp/results/bad';
    end

    if ~exist('expected_number_of_rows', 'var')
        expected_number_of_rows = 210;
    end

    files = dir(dirname);
    subj = 1;
    durs = [];
    for idx = 1:length(files)
        if ~endsWith(files(idx).name, 'csv') || startsWith(files(idx).name, 'bonus')
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

        % see if cheated
        [fpath,fname,fext] = fileparts(filepath);
        extra_filepath = fullfile(fpath, [fname, '_extra.csv']);
        try
            Textra = readtable(extra_filepath, 'Delimiter', ',', 'ReadVariableNames',false);
            cheated = Textra{1,3}{1};
            if ~strcmp(cheated, 'no')
                fprintf('Skipping %s: cheated (%s)\n', files(idx).name, cheated);
                %continue
            end
        catch e
            fprintf('Error reading file %s\n', extra_filepath);
            disp(e);
        end

        Ts{subj} = T;

        disp(files(idx).name);

        for i = 1:length(T.Properties.VariableNames)
            data(subj).(T.Properties.VariableNames{i}) = T.(T.Properties.VariableNames{i});
        end
        %if ~ismember('trial', T.Properties.VariableNames) do this regardless because we log trials ffrom the test stage starting from zero
        data(subj).trial = mod(0:length(data(subj).block-1), 21);
        %end

        dur = T.timestamp(end) - T.timestamp(1);
        durs = [durs, dur];
        fprintf('             duration = %.2f mins\n', dur / 60);
        
        filenames{subj} = filepath;

        subj = subj + 1;
    end

    durs = durs / 60;
    fprintf('avg duration = %.2f +- %.2f mins\n', mean(durs), std(durs)/sqrt(length(durs)));

    save('data.mat', 'data', 'Ts', 'filenames');
