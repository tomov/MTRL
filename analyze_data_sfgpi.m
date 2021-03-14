close all;
clear all;

% v1_1 a,b,c
%design_params.n_blocks = 10;
%design_params.n_train_trials = 20;
%design_params.n_trials_per_block = 21;
%design_params.action_paths = {'1 1', '1 2', '1 3', '2 1', '2 2', '2 3'};

% v1_1 d
design_params.n_blocks = 5;
design_params.n_train_trials = 40;
design_params.n_trials_per_block = 41;
design_params.action_paths = {'1 1', '1 2', '1 3', '1 4', '1 5', ...
                              '2 1', '2 2', '2 3', '2 4', '2 5', ...
                              '3 1', '3 2', '3 3', '3 4', '3 5', ...
                              '4 1', '4 2', '4 3', '4 4', '4 5', ...
                              '5 1', '5 2', '5 3', '5 4', '5 5'};

% v1_1e
design_params.n_blocks = 3;
design_params.n_train_trials = 70;
design_params.n_trials_per_block = 71;
design_params.action_paths = { ...
    '1 1 1', ...
    '1 1 2', ...
    '1 1 3', ...
    '1 2 1', ...
    '1 2 2', ...
    '1 2 3', ...
    '1 3 1', ...
    '1 3 2', ...
    '1 3 3', ...
    '2 1 1', ...
    '2 1 2', ...
    '2 1 3', ...
    '2 2 1', ...
    '2 2 2', ...
    '2 2 3', ...
    '2 3 1', ...
    '2 3 2', ...
    '2 3 3'};
%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1a', design_params);
%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1b', design_params);
%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1c', design_params);
%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1d', design_params);
[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1e_v1', design_params);


figure;

subplot(2,1,1);
s = 1;
plot(data(s).reward);
xlabel('trial');
ylabel('reward');
title(['Subject ', num2str(s)]);

subplot(2,2,3);
plot_subject_histogram(data);


figure;

subplot(2,2,1);
plot_training_reward_over_time(data, design_params);

subplot(2,2,2);
plot_training_reward_split_by_block(data, design_params);

subplot(2,2,3);
plot_training_reward_over_blocks(data, design_params);

subplot(2,2,4);
plot_test_reward_over_blocks(data, design_params);


figure;

subplot(1,3,1);
plot_action_path_counts(data, '[1 0]', design_params);

subplot(1,3,2);
plot_action_path_counts(data, '[0 1]', design_params);

subplot(1,3,3);
plot_action_path_counts(data, '[1 1]', design_params);



function [rb, rse, leg] = training_reward_split_by_block(data, design_params)
    rb = nan(design_params.n_blocks, design_params.n_train_trials);
    for b = 1:design_params.n_blocks
        rs = nan(length(data),design_params.n_train_trials);
        for s = 1:length(data)
            r = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
            rs(s,:) = r;
        end
        rb(b,:) = mean(rs,1);
        rse(b,:) = std(rs,1)/sqrt(size(rs,1));
        leg{b} = ['block ', num2str(b)];
    end
end

function [r, rse] = training_reward_over_time(data, design_params)
    rs = nan(length(data), design_params.n_train_trials);
    for s = 1:length(data)
        rb = nan(design_params.n_blocks,design_params.n_train_trials);
        for b = 1:design_params.n_blocks
            rb(b,:) = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
        end
        rs(s,:) = mean(rb,1);
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end

function [r, rse] = training_reward_over_blocks(data, design_params)
    rs = nan(length(data), design_params.n_blocks);
    for s = 1:length(data)
        rb = nan(design_params.n_blocks,design_params.n_train_trials);
        for b = 1:design_params.n_blocks
            rb(b,:) = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
        end
        rs(s,:) = mean(rb,2);
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end

function [c, cse] = action_path_counts(data, goal, design_params)
    counts = nan(length(data), length(design_params.action_paths));
    for i = 1:length(design_params.action_paths)
        for s = 1:length(data)
            which = strcmp(data(s).goal_original, goal) & strcmp(data(s).action_path, design_params.action_paths{i});
            counts(s,i) = sum(which);
        end
    end
    c = mean(counts,1);
    cse = std(counts,1)/sqrt(size(counts,1));
end

function [r, rse] = test_reward_over_blocks(data, design_params)
    rs = nan(length(data), design_params.n_blocks);
    for s = 1:length(data)
        rs(s,:) = data(s).reward(strcmp(data(s).stage, 'test'));
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end

function plot_action_path_counts(data, goal, design_params)
    [c, cse] = action_path_counts(data, goal, design_params);

    bar(c);
    hold on;
    errorbar(c, cse, 'color', [0 0 0], 'linestyle', 'none');
    set(gca, 'xtick', 1:length(design_params.action_paths), 'xticklabel', design_params.action_paths);
    %xticklabels(design_params.action_paths);
    xtickangle(40);
    title(['Task ', goal]);
    ylabel('# trials per subject');
    xlabel('action sequence');
end


function plot_subject_histogram(data)
    r = nan(1,length(data));
    for s = 1:length(data)
        r(s) = sum(data(s).reward);
    end
    hist(r);
    xlabel('total reward');
    ylabel('# subjects');
    title('Subject performance histogram');
end


function plot_training_reward_over_time(data, design_params)
    [r, rse] = training_reward_over_time(data, design_params);
    errorbar(r, rse);
    xlabel('trial');
    ylabel('reward');
    title('Training performance');
end


function plot_training_reward_split_by_block(data, design_params)
    [rb, rse, leg] = training_reward_split_by_block(data, design_params);
    errorbar(rb, rse);
    legend(leg);
    xlabel('trial');
    ylabel('reward');
    title('Training performance by block');
end

function plot_test_reward_over_blocks(data, design_params)
    [r, rse] = test_reward_over_blocks(data, design_params)
    errorbar(r, rse);
    xlabel('block');
    ylabel('reward');
    title('Test performance');
end

function plot_training_reward_over_blocks(data, design_params)
    [r, rse] = training_reward_over_blocks(data, design_params)
    errorbar(r, rse);
    xlabel('block');
    ylabel('reward');
    title('Training performance');
end
