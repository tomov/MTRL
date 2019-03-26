function pi_test_MF = test_MF(env, w_test, Q)

    % see what MF will do
    for s = 1:env.N
        [~, pi_test_MF(s)] = max(Q(s,:));
    end

