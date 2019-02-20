clear all;

env = init_env;
w_train = {[1 0 0], [0 1 0]};
w_test = {[1 1 0], [0 0 1]};

%for iter = 1:10

[pi_test_UVFA, pi_test_SF, V, V_test, psi, Vmax] = sim(env, w_train, w_test);

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
