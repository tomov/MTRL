% analyze behavioral data from chunking experiment

clear all;

[data, Ts, ~, durs] = load_data('exp/results/usfa_v1_1h', 101);
%[data, Ts, ~, durs] = load_data('exp/results/usfa_v1_1g_long', 119);
%load data.mat

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

test_goals = {'[1 1 1]'};
train_goals = {'[1 0 0]', '[0 1 0]'};

figure;

ms = [];
sems = [];
rs = {};
for t = 1:length(test_goals)
    which = strcmp(tbl.g, test_goals{t}); % ord is usually just 1
    rs{t} = tbl.r(which);

    ms = [ms mean(rs{t})];
    sems = [sems sem(rs{t})];

end

hold on;
bar(ms);
errorbar(ms, sems, 'color', [0 0 0], 'linestyle', 'none');
plot([0 3], [1 1], '--', 'color', [0.4 0.4 0.4]);
xticks(1:length(ms));

xticklabels(test_goals);
xtickangle(40);
ylabel('test reward');
title(sprintf('Humans (N = %d)', size(data, 1)));
xlabel('test task');


%
% ----------- specific for usfa_v1
%


% UVFA baseline for usfa_v1
%{
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
%}


%
% histogram of final test states
%
figure;

fprintf('\n\n Are the optimal test states chosen more frequently than chance?  \n');

interesting_test_states{1} = {[7], [9], [12], [5 6 8 10 11 13]}; % test task 1

final_states = 5:13;
test_optim = [7];
train_optim = [6, 12];
for t = 1:length(test_goals)
    cnt{t} = [];
    for i = final_states 
        which = tbl.c2 == i & strcmp(tbl.g, test_goals{t});
        cnt{t}(i) = sum(which); % # of visits to terminal state i during test task t
    end

    subplot(1, length(test_goals), t);
    bar(cnt{t});
    title(sprintf('w = %s', test_goals{t}));
    xticks(final_states);
    xlim([4.5 13.5]);
    xlabel('final state');
    ylabel('# subjects');

    fprintf('\nw = %s\n', test_goals{t});

    % generous test -- assume null = random walk
    for j = 1:length(interesting_test_states{t})
        if length(interesting_test_states{t}{j}) == 1
            s = interesting_test_states{t}{j};
            c = cnt{t}(s);
            p = myBinomTest(c, N, 1/9);
            fprintf('(generous) two-tailed binomial test (%d out of %d subjects went to state %d; chance is ~%d): p = %.6f\n', c, N, s, round(N/9), p);
        end
    end

    % conservative test -- assume null = random of test optimal & training optimal policies
    for j = 1:length(interesting_test_states{t})
        if length(interesting_test_states{t}{j}) == 1
            s = interesting_test_states{t}{j};
            c = cnt{t}(s);
            finals = unique([s train_optim]);
            p = myBinomTest(c, sum(cnt{t}(finals)), 1/length(finals));
            fprintf('(conservative) two-tailed binomial (%d out of %d subjects went to optimal state %d; chance is ~%d): p = %.6f\n', c, sum(cnt{t}(finals)), s, round(mean(cnt{t}(finals))), p);
        end
    end

    fprintf('\n');

    states = final_states;
    N_left = N;
    for j = 1:length(interesting_test_states{t})
        expected = repmat(N_left/length(states), 1, length(states));
        observed = cnt{t}(states);
        nparams = 0;
        [h, p, stats] = chi2gof(1:length(states), 'freq', observed, 'expected', expected, 'ctrs', 1:length(states), 'nparams', nparams);

        fprintf('Did the test choice counts for task %s states [%s] happen by chance? chi2(%d) = %.4f, p = %.4f\n', test_goals{t}, sprintf('%d ', states), stats.df, stats.chi2stat, p);

        % exclude interesting state
        states(ismember(states, interesting_test_states{t}{j})) = [];
        N_left = N_left - sum(cnt{t}(interesting_test_states{t}{j}));
    end

end





%
% does P(find test state) depend on # visits to that state during training?
%

figure;

fprintf('\n\n  Do subjects that find the optimal test state also happened to have visited that state more often during training?  \n\n');

for t = 1:length(test_goals)
    f = [];
    test_c2 = [];
    for subj = 1:N
        which = tbl.s_id == subj & tbl.c2 == test_optim(t) & tbl.phase == 1;
        f = [f; sum(which)]; % # of visits to test_optimal terminal state for test task t during training
        test_c2 = [test_c2; tbl.c2(tbl.s_id == subj & strcmp(test_goals{t}, tbl.g))]; % the subject's terminal state for test task t
    end
    f1 = f(test_c2 == test_optim(t));
    f2 = f(test_c2 ~= test_optim(t));
    ms = [mean(f1) mean(f2)];
    sems = [sem(f1) sem(f2)];

    subplot(1, length(test_goals), t);
    bar(ms);
    hold on;
    errorbar(ms, sems, 'color', [0 0 0], 'linestyle', 'none');
    xticklabels({'optimal', 'suboptimal'});
    xlabel('subjects split by final test state');
    ylabel('# visits to optimal test state during training');
    title(sprintf('w = %s', test_goals{t}));

    [h, p, ci, stats] = ttest2(f1, f2);
    fprintf('two-tailed two-sample t-test: t(%d) = %.4f, p = %.4f\n', stats.df, stats.tstat, p);
end


%
% histogram of training states
%

clear ms;
clear sems;
for t = 1:length(train_goals)
    cnt{t} = [];
    for i = final_states 
        f = [];
        for subj = 1:N
            which = tbl.s_id == subj & tbl.c2 == i & strcmp(tbl.g, train_goals{t});
            f = [f; sum(which)]; % # of visits to terminal state i for test task t during training
        end

        ms{t}(i) = mean(f);
        sems{t}(i) = sem(f);
    end

    subplot(1, length(train_goals), t);
    bar(ms{t});
    hold on;
    errorbar(ms{t}, sems{t}, 'color', [0 0 0], 'linestyle', 'none');
    title(sprintf('w = %s', train_goals{t}));
    xticks(final_states);
    xlim([4.5 13.5]);
    xlabel('final state');
    ylabel('# visits');

    fprintf('\nw = %s\n', train_goals{t});
end


%
% histogram of training states, split by test choices
%

figure;

fprintf('\n\n  For subjects that find the optimal test state, which states do they visit during training? What about the suboptimal subjects?  \n\n');

for t = 1:length(test_goals)

    ms = {};
    sems = {};
    for j = 1:length(interesting_test_states{t})
        ms = [ms, {[]}];
        sems = [sems, {[]}];
    end
    for i = final_states
        f = [];
        test_c2 = [];
        for subj = 1:N
            which = tbl.s_id == subj & tbl.c2 == i & tbl.phase == 1;
            f = [f; sum(which)]; % # of visits to terminal state i for test task t during training
            test_c2 = [test_c2; tbl.c2(tbl.s_id == subj & strcmp(test_goals{t}, tbl.g))]; % the subject's terminal state for test task t
        end

        for j = 1:length(interesting_test_states{t})
            ff = f(ismember(test_c2, interesting_test_states{t}{j}));
            ms{j} = [ms{j} mean(ff)];
            sems{j} = [sems{j} sem(ff)];
        end
    end

    for i = 1:length(interesting_test_states{t})
        subplot(length(interesting_test_states{t}), length(test_goals), (i-1)*length(test_goals) + t);
        bar(final_states, ms{i});
        hold on;
        errorbar(final_states, ms{i}, sems{i}, 'color', [0 0 0], 'linestyle', 'none');

        title(sprintf('went to one of [%s] on %s', sprintf('%d ', interesting_test_states{t}{i}), test_goals{t}));
        xticks(final_states);
        xlim([4.5 13.5]);
        xlabel('final state');
        ylabel('# visits during training');
    end

end

%{

%
% split training histograms (prev plot) by optimal vs. suboptimal on [1 1 0] vs. [0 0 1]
%

ms = {[], []; [], []};
sems = {[], []; [], []};

for i = final_states 
    f = [];
    test_c2_1 = [];
    test_c2_2 = [];
    for subj = 1:N
        which = tbl.s_id == subj & tbl.c2 == i & tbl.phase == 1;
        f = [f; sum(which)]; % # of visits to terminal state i for test task t during training
        test_c2_1 = [test_c2_1; tbl.c2(tbl.s_id == subj & strcmp(test_goals{1}, tbl.g))]; % the subject's terminal state for test task 1
        test_c2_2 = [test_c2_2; tbl.c2(tbl.s_id == subj & strcmp(test_goals{2}, tbl.g))]; % the subject's terminal state for test task 2
    end
    f11 = f(test_c2_1 == test_optim(1) & test_c2_2 == test_optim(2));
    f12 = f(test_c2_1 ~= test_optim(1) & test_c2_2 == test_optim(2));
    f21 = f(test_c2_1 == test_optim(1) & test_c2_2 ~= test_optim(2));
    f22 = f(test_c2_1 ~= test_optim(1) & test_c2_2 ~= test_optim(2));

    ms{1,1} = [ms{1,1} mean(f11)];
    ms{1,2} = [ms{1,2} mean(f12)];
    ms{2,1} = [ms{2,1} mean(f21)];
    ms{2,2} = [ms{2,2} mean(f22)];

    sems{1,1} = [sems{1,1} sem(f11)];
    sems{1,2} = [sems{1,2} sem(f12)];
    sems{2,1} = [sems{2,1} sem(f21)];
    sems{2,2} = [sems{2,2} sem(f22)];
end

n(1,1) = numel(f11);
n(1,2) = numel(f12);
n(2,1) = numel(f21);
n(2,2) = numel(f22);

figure;

labels = {sprintf('optimal on %s, optimal on %s', test_goals{1}, test_goals{2}), sprintf('suboptimal on %s, optimal on %s', test_goals{1}, test_goals{2}); sprintf('optimal on %s, suboptimal on %s', test_goals{1}, test_goals{2}), sprintf('suboptimal on %s, suboptimal on %s', test_goals{1}, test_goals{2})};

for r = 1:2
    for c = 1:2
        subplot(2, 2, (r-1)*2 + c);

        bar(final_states, ms{r,c});
        hold on;
        errorbar(final_states, ms{r,c}, sems{r,c}, 'color', [0 0 0], 'linestyle', 'none');
        xticks(final_states);
        xlim([4.5 13.5]);
        xlabel('final state');
        ylabel('# visits during training');
        title(labels{r,c});
        if r == 2 && c == 1
            text(6, 45, sprintf('N = %d', n(r,c)));
        else
            text(8, 25, sprintf('N = %d', n(r,c)));
        end
    end
end

p1 = (n(1,1) + n(2,1)) / N; % empirical P(optimal on task 1)
p2 = (n(1,1) + n(1,2)) / N; % empirical P(optimal on task 2)
observed = [n(1,1) n(1,2) n(2,1) n(2,2)]; % observed frequencies
expected = [p1*p2  (1-p1)*p2 p1*(1-p2) (1-p1)*(1-p2)] * N; % expected frequencies
nparams = 2; % p1 and p2

[h, p, stats] = chi2gof([1 2 3 4], 'freq', observed, 'expected', expected, 'ctrs', [1 2 3 4], 'nparams', nparams);

fprintf('\nAre the subject counts consistent with performance on the two test tasks being independent? chi2(%d) = %.4f, p = %.4f\n', stats.df, stats.chi2stat, p);

%
% is # visits to (0.8 0.8) same as # visits to where we plan to put the model-based test?
%

states = [9, 7];

f = {[], []};

for i = 1:2
    for subj = 1:N
        which = tbl.s_id == subj & tbl.c2 == states(i) & tbl.phase == 1;
        f{i} = [f{i}; sum(which)];
    end
end

ms = [mean(f{1}) mean(f{2})];
sems = [sem(f{1}) sem(f{2})];

figure;

bar(ms);
hold on;
errorbar(ms, sems, 'color', [0 0 0], 'linestyle', 'none');
xticklabels(states);
xlabel('final state');
ylabel('# visits during training');

[h, p, ci, stats] = ttest2(f{1}, f{2});
fprintf('\nAre the # of visits to the compromise state (9) more than the less interesting state (7) (that we could use to test model-based)? t(%d) = %.4f, p = %.4f\n', stats.df, stats.tstat, p);

%}


%
% does training score track test score?
%

r_train = [];
r_test = [];
for subj = 1:N
    r_train = [r_train; sum(tbl.r(tbl.s_id == subj & tbl.phase == 1))];
    r_test = [r_test; sum(tbl.r(tbl.s_id == subj & tbl.phase == 2))];
end

coef1 = polyfit(r_train, r_test, 1);
coef2 = polyfit(r_train, r_test, 2);

figure;
scatter(r_train, r_test);
hold on;
plot(sort(r_train), polyval(coef2, sort(r_train)));
title('training perf vs test perf');
ylabel('cumulative test reward');
xlabel('cumulative training reward');

[r, p] = corr(r_train, r_test);
fprintf('Are training and test perf correlated? r = %.4f, p = %.4f (N = %d)\n', r, p, N);

%}
