function pi_test_MF2 = test_MF2(env, w_test, beta, Q, w_train)

    for t = 1:length(w_test)
        % find closest training task
        tr_closest = NaN;
        for tr = 1:length(w_train)
            if immse(w_train{tr}, w_test{t}) < 1e-9  % TODO kernel?
                tr_closest = tr;
            end
        end

        % if none found, choose at random
        if isnan(tr_closest)
            tr_closest = randi(length(w_train));
        end

        % see what MF will do
        for s = 1:env.N
            P = exp(Q{tr_closest}(s,:) * beta);
            P = P / sum(P);
            pi_test_MF2{t}{s} = P;
        end

    end
