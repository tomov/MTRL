clear all;

env = init_env;
w_train = {[1 0 0], [0 1 0]};
w_test = {[1 1 0], [0 0 1]};

%for iter = 1:10

%[pi_test_UVFA, pi_test_SF, V, V_test, psi, Vmax] = sim(env, w_train, w_test);
load demo.mat

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
    tot_r(t, 1) = r;

    % test SF 
    r = 0;
    s = 1;
    while true 
        r = r + env.phi{s} * w_test{t}';
        if env.terminal(s)
            break
        end
        a = pi_test_SF{t}(s);
        s = find(mnrnd(1, squeeze(env.T(s, a, :))));
    end
    tot_r(t, 2) = r;
end

%end

figure;

% plot performance on test tasks
for t = 1:length(w_test)
    subplot(2, length(w_test), t);
    bar([1 2], tot_r(t,:));
    xticklabels({'UVFA', 'SF'});
    ylabel('total reward');
    title(sprintf('test w = [%.1f %.1f %.1f]', w_test{t}));
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

subplot(2, 1, 2);
h = plot(G);
for s = 1:env.N
    labelnode(h, s, sprintf('phi(%d) = [%.1f %.1f %.1f]', s, env.phi{s}));
end
ylim([-0.5 4]);
xlim([0.5 11]);
set(gca, 'xtick', []);
set(gca, 'ytick', []);
