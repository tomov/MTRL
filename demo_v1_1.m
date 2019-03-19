clear all;

%env = init_env_v1_2;
env = init_env_v1_1b;
filename = 'demo_v1_1b.mat';

w_train = {[1 0 0 0], [0 1 0 0]};
w_test = {[1 1 0 0], [0 0 1 0], [0 0 0 1]};

for iter = 1:60

    [pi_test_UVFA, pi_test_SF, V, V_test_UVFA, psi, Vmax, pi_test_MB] = simul(env, w_train, w_test);

    for t = 1:length(w_test)

        % test UVFA
        r = 0;
        s = 1;
        while true
            r = r + env.phi{s} * w_test{t}';
            if env.terminal(s)
                break
            end
            a = pi_test_UVFA{t}(s);
            s = find(mnrnd(1, squeeze(env.T(s, a, :))));
        end
        tot_r(t, 1, iter) = r;

        % test SF 
        r = 0;
        s = 1;
        while true 
            r = r + env.phi{s} * w_test{t}';
            if env.terminal(s)
                break
            end
            a = pi_test_SF{t}(s);
            s
            a
            s = find(mnrnd(1, squeeze(env.T(s, a, :))));
        end
        tot_r(t, 2, iter) = r;

        % test MB 
        r = 0;
        s = 1;
        while true 
            r = r + env.phi{s} * w_test{t}';
            if env.terminal(s)
                break
            end
            a = pi_test_MB{t}(s);
            s = find(mnrnd(1, squeeze(env.T(s, a, :))));
        end
        tot_r(t, 3, iter) = r;
    end

end


save(filename);

%load(filename);

figure;

sem = @(x) std(x) / sqrt(length(x));

% plot performance on test tasks, fig for each test task
for t = 1:length(w_test)
    subplot(3, length(w_test), t);

    for i = 1:2
        r = squeeze(tot_r(t, i, :));
        m(i) = mean(r);
        se(i) = sem(r);
    end

    hold on;
    bar([1 3], m);
    errorbar([1 3], m, se, 'color', [0 0 0], 'linestyle', 'none');
    xticks([1 3]);
    xticklabels({'UVFA', 'SF&GPI', 'MB'});
    ylabel('test reward');
    title(sprintf('test w = [%.0f %.0f %.0f %.0f]', w_test{t}));
end

% plot performance on test tasks, fig for each algo
labels = {};
for t = 1:length(w_test)
    labels{t} = sprintf('w = [%.0f %.0f %.0f %.0f]', w_test{t});
end
titles = {'UVFA', 'SF&GPI', 'MB'};
for i = 1:3
    subplot(3, 3, 3 + i);

    for t = 1:length(w_test)
        r = squeeze(tot_r(t, i, :));
        m(t) = mean(r);
        se(t) = sem(r);
    end

    hold on;
    bar(m);
    errorbar(m, se, 'color', [0 0 0], 'linestyle', 'none');
    xticks(1:length(m));

    xticklabels(labels);
    xtickangle(40);
    ylabel('test reward');
    title(titles{i});
    xlabel('test task');
end

% plot MDP as graph
E = zeros(env.N, env.N);
for s = 1:env.N
    for s_new = 1:env.N
        if sum(squeeze(env.T(s,:,s_new))) > 0
            E(s, s_new) = 1;
        end
    end
end
G = digraph(E);

subplot(3, 1, 3);
h = plot(G);
for s = 1:env.N
    labelnode(h, s, sprintf('phi(%d) = [%.0f %.0f %.0f %.0f]', s, env.phi{s} * 10));
end
ylim([-0.5 4]);
xlim([0.5 11]);
set(gca, 'xtick', []);
set(gca, 'ytick', []);
title('MDP');
xlabel('note: all features x 10 (for vizualization)');
