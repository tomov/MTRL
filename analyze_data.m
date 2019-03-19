% analyze behavioral data from chunking experiment

clear all;

%[data, Ts, ~, durs] = load_data('exp/results/usfa_v1_prelim', 100); %  usfa_v1
load data.mat

%data = data(durs < 50, :);

sem = @(x) std(x) / sqrt(length(x));

tbl = data2table(data);
N = size(data, 1);


% show learning
%

figure;
ms = [];
es = [];
for t = 1:length(data(1,1).r)
    rs = [];
    for subj = 1:size(data,1)
        rs = [rs data(subj,1).r(t)];
    end
    m = mean(rs);
    e = sem(rs);
    ms = [ms m];
    es = [es e];
end

errorbar(ms, es);
xlabel('training trial');
ylabel('reward');
title('learning');




% show test choices
%

goals = {'[1 1 0]', '[0 0 1]'};

figure;

ms = [];
sems = [];
rs = {};
for t = 1:length(goals)
    which = strcmp(tbl.g, goals{t}); % ord is usually just 1
    rs{t} = tbl.r(which) / 100;

    ms = [ms mean(rs{t})];
    sems = [sems sem(rs{t})];

end

hold on;
bar(ms);
errorbar(ms, sems, 'color', [0 0 0], 'linestyle', 'none');
plot([0 3], [1 1], '--', 'color', [0.4 0.4 0.4]);
xticks(1:length(ms));

xticklabels(goals);
xtickangle(40);
ylabel('test reward');
title(sprintf('Humans (N = %d)', size(data, 1)));
xlabel('test task');


%
% ----------- specific for usfa_v1
%


% UVFA baseline for usfa_v1
UVFA_null = 1;
[h, p, ci, stat] = ttest(rs{1}, UVFA_null);
fprintf('t-test of rewards on [1 1 0] against (generous) expectation under randomly picking one of the two training policies (%.3f): t(%d) = %.4f, p = %.4f\n', UVFA_null, stat.df, stat.tstat, p);

UVFA_null = (1.6 + 1 * 2 + 0.9 * 2) / 9;
[h, p, ci, stat] = ttest(rs{2}, UVFA_null);
fprintf('t-test of rewards on [1 1 0] against (less generous) expectation under random policy (%.3f): t(%d) = %.4f, p = %.4f\n', UVFA_null, stat.df, stat.tstat, p);

fprintf('\n');

% SF baseline for usfa_v1
SF_null = (1.5 + 0.9) / 2;
[h, p, ci, stat] = ttest(rs{2}, SF_null);
fprintf('t-test of rewards on [0 0 1] against (generous) expectation under randomly picking one of the two training policies (%.3f): t(%d) = %.4f, p = %.4f\n', SF_null, stat.df, stat.tstat, p);

SF_null = (1.5 + 0.9 * 8) / 9;
[h, p, ci, stat] = ttest(rs{2}, SF_null);
fprintf('t-test of rewards on [0 0 1] against (less generous) expectation under random policy (%.3f): t(%d) = %.4f, p = %.4f\n', SF_null, stat.df, stat.tstat, p);


%
% histogram of final test states
%
figure;

fprintf('\n\n Are the optimal test states chosen more frequently than chance?  \n');

test_optim = [9, 12];
train_optim = [6, 12];
for t = 1:length(goals)
    cnt{t} = [];
    for i = 5:13 % TODO hardcoded
        which = tbl.c2 == i & strcmp(tbl.g, goals{t});
        cnt{t}(i) = sum(which); % # of visits to terminal state i during test task t
    end

    subplot(1, length(goals), t);
    bar(cnt{t});
    title(sprintf('w = %s', goals{t}));
    xticks(5:13);
    xlim([4.5 13.5]);
    xlabel('final state');
    ylabel('# subjects');

    fprintf('\nw = %s\n', goals{t});

    % generous test -- assume null = random walk
    c = cnt{t}(test_optim(t));
    p = myBinomTest(c, N, 1/9);
    fprintf('(generous) two-tailed binomial test (%d out of %d subjects went to optimal state %d; chance is ~%d): p = %.6f\n', c, N, test_optim(t), round(N/9), p);

    % conservative test -- assume null = random of test optimal & training optimal policies
    c = cnt{t}(test_optim(t));
    finals = unique([test_optim(t) train_optim]);
    p = myBinomTest(c, sum(cnt{t}(finals)), 1/length(finals));
    fprintf('(conservative) two-tailed binomial (%d out of %d subjects went to optimal state %d; chance is ~%d): p = %.6f\n', c, sum(cnt{t}(finals)), test_optim(t), round(mean(cnt{t}(finals))), p);
end

%
% does P(find test state) depend on # visits to that state during training?
%

figure;

fprintf('\n\n  Do subjects that find the optimal test state also happened to have visited that state more often during training?  \n\n');

for t = 1:length(goals)
    f = [];
    test_c2 = [];
    for subj = 1:N
        which = tbl.s_id == subj & tbl.c2 == test_optim(t) & tbl.phase == 1;
        f = [f; sum(which)]; % # of visits to test_optimal terminal state for test task t during training
        test_c2 = [test_c2; tbl.c2(tbl.s_id == subj & strcmp(goals{t}, tbl.g))]; % the subject's terminal state for test task t
    end
    f1 = f(test_c2 == test_optim(t));
    f2 = f(test_c2 ~= test_optim(t));
    ms = [mean(f1) mean(f2)];
    sems = [sem(f1) sem(f2)];

    subplot(1, length(goals), t);
    bar(ms);
    hold on;
    errorbar(ms, sems, 'color', [0 0 0], 'linestyle', 'none');
    xticklabels({'optimal', 'suboptimal'});
    xlabel('subjects split by final test state');
    ylabel('# visits to optimal test state during training');
    title(sprintf('w = %s', goals{t}));

    [h, p, ci, stats] = ttest2(f1, f2);
    fprintf('two-tailed two-sample t-test: t(%d) = %.4f, p = %.4f\n', stats.df, stats.tstat, p);
end


%
% histogram of final training states
%

figure;

fprintf('\n\n  For subjects that find the optimal test state, which states do they visit during training? What about the suboptimal subjects?  \n\n');

for t = 1:length(goals)
    ms = {[], []};
    sems = {[], []};
    for i = 5:13 % TODO hardcoded
        f = [];
        test_c2 = [];
        for subj = 1:N
            which = tbl.s_id == subj & tbl.c2 == i & tbl.phase == 1;
            f = [f; sum(which)]; % # of visits to terminal state i for test task t during training
            test_c2 = [test_c2; tbl.c2(tbl.s_id == subj & strcmp(goals{t}, tbl.g))]; % the subject's terminal state for test task t
        end
        f1 = f(test_c2 == test_optim(t));
        f2 = f(test_c2 ~= test_optim(t));

        ms{1} = [ms{1} mean(f1)];
        ms{2} = [ms{2} mean(f2)];
        sems{1} = [sems{1} sem(f1)];
        sems{2} = [sems{2} sem(f2)];
    end

    labels = {sprintf('optimal on %s', goals{t}), sprintf('suboptimal on %s', goals{t})};
    for i = 1:2
        subplot(length(goals), 2, (i-1)*2 + t);
        bar(5:13, ms{i});
        hold on;
        errorbar(5:13, ms{i}, sems{i}, 'color', [0 0 0], 'linestyle', 'none');
        title(labels{i});
        xticks(5:13);
        xlim([4.5 13.5]);
        xlabel('final state');
        ylabel('# visits during training');
    end

end


%
% is # visits to (0.8 0.8) same as # visits to 
%
