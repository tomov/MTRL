function [pi_test_SF] = test_SFGPI(env, w_test, gamma, beta, psi)

    % based on psi{training task}{state}; 
    % NOT psi{training task}{state, action} (as in paper);
    % we used this in Tomov et. al (2021) NHB

    % see what SF will do on each test task
    for t = 1:length(w_test)
        % compute Vmax
        Vmax{t} = zeros(1, env.N);
        for tt = 1:length(psi) % loop over training tasks
            for s = 1:env.N
                Vmax{t}(s) = max(Vmax{t}(s), psi{tt}{s} * w_test{t}');
            end
        end
        
        % compute policies
        for s = 1:env.N
            best = -Inf;

            Q = [];
            for a = env.A
                tmp = sum(squeeze(env.T(s, a, :))' .* (gamma * Vmax{t}));
                Q = [Q, tmp];
            end

            P = exp(Q * beta);
            P = P / sum(P);
            pi_test_SF{t}{s} = P;
        end
    end


