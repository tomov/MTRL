function [pi_test_SF] = test_SFGPI2(env, w_test, gamma, beta, psi)

    % Following from Barreto et al. 2020 PNAS more closely

    % see what SF will do on each test task
    for t = 1:length(w_test)
        % compute Q (eq. 7 from Barreto et al. 2020 PNAS)
        clear Q;
        for tt = 1:length(psi) % loop over training tasks
            Q{tt} = nan(env.N, length(env.A));
            for s = 1:env.N
                for a = 1:length(env.A)
                    Q{tt}(s,a) = psi{tt}{s,a} * w_test{t}';
                end
            end
        end
        
        % compute policies
        Qmax = -inf(env.N,length(env.A));
        for s = 1:env.N
            for a = env.A
                for tt = 1:length(psi) % loop over training tasks
                    Qmax(s,a) = max(Qmax(s,a), Q{tt}(s,a)); % eq. 8 from PNAS paper
                end
            end

            P = exp(Qmax(s,:) * beta);
            P = P / sum(P);
            pi_test_SF{t}{s} = P;
        end
    end


