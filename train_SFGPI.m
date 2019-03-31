function [psi] = train_SFGPI(env, w_train, gamma, beta, threshold)

    if ~exist('threshold', 'var')
        threshold = 0.01;
    end

    % value iteration -- V{t}(s) = value f'n for task t, state s
    %
    for t = 1:length(w_train)
        %fprintf('t = %d\n', t);

        [V{t}, pi{t}] = value_iteration(env, w_train{t}, gamma, beta);
    end

    % get SFs using iteration

    for t = 1:length(w_train)
        %fprintf('t = %d\n', t);

        % important to init at least terminal states
        for s = 1:env.N
            psi{t}{s} = env.phi{s};
        end

        while true
            delta = 0;
            for s = env.S
                %fprintf('   s = %d\n', s);
                old = psi{t}{s};

                psi{t}{s} = env.phi{s};
                for s_new = 1:env.N
                    assert(abs(sum(pi{t}{s}) - 1) < 1e-12);
                    for a = env.A
                        psi{t}{s} = psi{t}{s} + pi{t}{s}(a) * env.T(s, a, s_new) * gamma * psi{t}{s_new};
                        %fprintf('          a = %d, s_new = %d, T(s,a,s_new) = %f, psi{t}{s_new} = [%f %f %f %f]\n', a, s_new, env.T(s, a, s_new), psi{t}{s_new});
                    end
                end

                delta = max(delta, norm(old - psi{t}{s}));
            end

            if delta < threshold
                break;
            end
        end
    end

