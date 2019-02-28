% analyze behavioral data from chunking experiment

%[data, Ts] = load_data('exp/results', 165); % for exp_v3_7 (mail delivery map aka exp 3 scaled up)
%[data, Ts] = load_data('exp/results', 105); % for exp_v3_8 (subway 18 map aka mail delivery scaled down)
%[data, Ts] = load_data('exp/results', 81); % for exp_v1_6 (subway 10 but no assoc)
%[data, Ts] = load_data('exp/results', 101); % for exp_v2_1 (subway 10 no adj, no assoc)
%[data, Ts, ~, durs] = load_data('exp/results', 205); % for exp_v2_2 (subway 18 no adj, no assoc)
%[data, Ts, ~, durs] = load_data('exp/results', 100); %  usfa_v1
load data.mat

%data = data(durs < 50, :);

sem = @(x) std(x) / sqrt(length(x));

r = [];
s = [];
g = {};
len = [];
group = [];
dir = []; % direction = 2nd state on path
ord = []; % ordinal of trial type within phase (e.g. "first 1->6", "second 1->6", etc)
subj_group = [];
subj_len = [];
s_id = [];
for subj = 1:size(data,1) % for each subject
    phase = 2; % training exp_v3_7, usually it's 2 = test
    for i = 1:length(data(subj, phase).s) % for each trial 
        which = find(data(subj, phase).s == data(subj, phase).s(i) & strcmp(data(subj, phase).g, data(subj, phase).g(i)));
        clear o;
        o(which) = find(which);
        ord = [ord; o(i)];
        r = [r; data(subj, phase).r(i)];
        s = [s; data(subj, phase).s(i)];
        g = [g; data(subj, phase).g(i)];
        len = [len; data(subj, phase).len(i)];
        dir = [dir; data(subj, phase).path{i}(2)];
        group = [group; data(subj, phase).group(i)];
        s_id = [s_id; subj];
    end
    subj_group = [subj_group; data(subj,1).group(1)];
    subj_len = [subj_len; mean(data(subj, 1).len)];
end


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
    which = strcmp(g, goals{t}); % ord is usually just 1
    rs{t} = r(which) / 100;

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
ylabel('total reward');
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
