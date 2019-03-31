function pi_test_MF = test_MF(env, w_test, beta, Q)

    % see what MF will do
    for s = 1:env.N

        P = exp(Q(s,:) * beta);
        P = P / sum(P);
        pi_test_MF{s} = P;
    end

