function pi_test_MB = test_MB(env, w_test, gamma, beta)

    % see what MB will do
    for t = 1:length(w_test)
        % value iteration -- V{t}(s) = value f'n for task t, state s
        %

        [V_test_MB{t}, pi_test_MB{t}] = value_iteration(env, w_test{t}, gamma, beta);
    end

