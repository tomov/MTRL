function [r, s] = test_perf(env, pi, w)

    % test performance on environment env, policy pi, task w
    % s = terminal state
    % r = total reward
    %

    r = 0;
    s = 1;
    while true
        if env.terminal(s)
            break
        end
        a = find(mnrnd(1, pi{s}));
        r = r + env.phi{s,a} * w';
        s = find(mnrnd(1, squeeze(env.T(s, a, :))));
    end
    
