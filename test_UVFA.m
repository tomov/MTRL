function [pi_test_UVFA, V_test_UVFA] = test_UVFA(env, w_test, gamma, UVFA)

    % see what UVFA will do
    %
    for t = 1:length(w_test)
        % get values
        V_test_UVFA{t} = zeros(1, env.N);
        for s = 1:env.N
            s_onehot = zeros(1, env.N);
            s_onehot(s) = 1;
            x = [s_onehot w_test{t}];
            V_test_UVFA{t}(s) = UVFA(x');
        end

        % compute policies
        for s = 1:env.N
            best = -Inf;
            pi_test_UVFA{t}(s) = NaN;
            for a = env.A
                tmp = sum(squeeze(env.T(s, a, :))' .* (gamma * V_test_UVFA{t}));
                if best < tmp
                    best = tmp;
                    pi_test_UVFA{t}(s) = a;
                end
            end
        end
    end


