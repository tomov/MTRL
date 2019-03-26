function [pi_test_SF] = test_SFGPI(env, w_test, gamma, psi)

    % see what SF will do 
    for t = 1:length(w_test)
        % compute Vmax
        Vmax{t} = zeros(1, env.N);
        for tt = 1:length(psi)
            for s = 1:env.N
                Vmax{t}(s) = max(Vmax{t}(s), psi{tt}{s} * w_test{t}');
            end
        end
        
        % compute policies
        for s = 1:env.N
            best = -Inf;
            pi_test_SF{t}(s) = NaN;
            for a = env.A
                tmp = sum(squeeze(env.T(s, a, :))' .* (gamma * Vmax{t}));
                if best < tmp || (best == tmp && rand < 0.5) % TODO break ties better 
                    best = tmp;
                    pi_test_SF{t}(s) = a;
                end
            end
        end
    end

