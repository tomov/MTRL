close all;
clear all;

%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1a', 210);
%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1b', 210);
%[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1c', 210);
[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1d', 205);

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
plot_training_reward_over_time(data);

subplot(2,2,2);
plot_training_reward_split_by_block(data);

subplot(2,2,3);
plot_training_reward_over_blocks(data);

subplot(2,2,4);
plot_test_reward_over_blocks(data);


figure;

subplot(1,3,1);
plot_action_path_counts(data, '[1 0]');

subplot(1,3,2);
plot_action_path_counts(data, '[0 1]');

subplot(1,3,3);
plot_action_path_counts(data, '[1 1]');



function [rb, rse, leg] = training_reward_split_by_block(data)
    rb = nan(10,20);
    for b = 1:10
        rs = nan(length(data),20);
        for s = 1:length(data)
            r = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
            rs(s,:) = r;
        end
        rb(b,:) = mean(rs,1);
        rse(b,:) = std(rs,1)/sqrt(size(rs,1));
        leg{b} = ['block ', num2str(b)];
    end
end

function [r, rse] = training_reward_over_time(data)
    rs = nan(length(data), 20);
    for s = 1:length(data)
        rb = nan(10,20);
        for b = 1:10
            rb(b,:) = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
        end
        rs(s,:) = mean(rb,1);
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end

function [r, rse] = training_reward_over_blocks(data)
    rs = nan(length(data), 10);
    for s = 1:length(data)
        rb = nan(10,20);
        for b = 1:10
            rb(b,:) = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
        end
        rs(s,:) = mean(rb,2);
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end

function [c, cse, action_paths] = action_path_counts(data, goal)
    action_paths = {'1 1', '1 2', '1 3', '2 1', '2 2', '2 3'};
    counts = nan(length(data), length(action_paths));
    for i = 1:length(action_paths)
        for s = 1:length(data)
            which = strcmp(data(s).goal_original, goal) & strcmp(data(s).action_path, action_paths{i});
            counts(s,i) = sum(which);
        end
    end
    c = mean(counts,1);
    cse = std(counts,1)/sqrt(size(counts,1));
end

function [r, rse] = test_reward_over_blocks(data)
    rs = nan(length(data), 10);
    for s = 1:length(data)
        rs(s,:) = data(s).reward(strcmp(data(s).stage, 'test'));
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end

function plot_action_path_counts(data, goal)
    [c, cse, action_paths] = action_path_counts(data, goal);

    bar(c);
    hold on;
    errorbar(c, cse, 'color', [0 0 0], 'linestyle', 'none');
    xticklabels(action_paths);
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


function plot_training_reward_over_time(data)
    [r, rse] = training_reward_over_time(data);
    errorbar(r, rse);
    xlabel('trial');
    ylabel('reward');
    title('Training performance');
end


function plot_training_reward_split_by_block(data)
    [rb, rse, leg] = training_reward_split_by_block(data);
    errorbar(rb, rse);
    legend(leg);
    xlabel('trial');
    ylabel('reward');
    title('Training performance by block');
end

function plot_test_reward_over_blocks(data)
    [r, rse] = test_reward_over_blocks(data)
    errorbar(r, rse);
    xlabel('block');
    ylabel('reward');
    title('Test performance');
end

function plot_training_reward_over_blocks(data)
    [r, rse] = training_reward_over_blocks(data)
    errorbar(r, rse);
    xlabel('block');
    ylabel('reward');
    title('Training performance');
end
