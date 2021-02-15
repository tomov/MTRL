function [pi_test_SF] = test_SFGPI(env, w_test, gamma, beta, psi)

    % see what SF will do 
    for t = 1:length(w_test)
        % compute Q (eq. 7 from PNAS paper)
        Q{t} = nan(env.N, length(env.A));
        for tt = 1:length(psi)
            for s = 1:env.N
                for a = 1:length(env.A)
                    Q{t}(s,a) = psi{tt}{s,a} * w_test{t}';
                end
            end
        end
        
        % compute policies
        Qmax = zeros(env.N,length(env.A));
        for s = 1:env.N
            for a = env.A
                for tt = 1:length(psi)
                    Qmax(s,a) = max(Qmax(s,a), Q{tt}(s,a)); % eq. 8 from PNAS paper
                end
            end

            P = exp(Qmax(s,:) * beta);
            P = P / sum(P);
            pi_test_SF{t}{s} = P;
        end
    end


