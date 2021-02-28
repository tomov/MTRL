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
            for a = 1:length(env.A)
                psi{t}{s,a} = env.phi{s,a};
            end
        end

        %disp(w_train{t});

        while true
            delta = 0;
            for s = env.S
                %fprintf('   s = %d\n', s);
                if env.terminal(s)
                    continue
                end
                for a = 1:length(env.A)
                    old = psi{t}{s,a};

                    psi{t}{s,a} = env.phi{s,a};
                    assert(abs(sum(pi{t}{s}) - 1) < 1e-12);
                    for s_new = 1:env.N
                        for a_new = env.A
                            psi{t}{s,a} = psi{t}{s,a} + pi{t}{s}(a) * env.T(s, a, s_new) * gamma * pi{t}{s_new}(a_new) * psi{t}{s_new,a_new};
                            %fprintf('          s = %d, a = %d, s_new = %d, a_new = %d, T(s,a,s_new) = %f, psi{t}{s_new} = [%f %f]\n', s, a, s_new, a_new, env.T(s, a, s_new), psi{t}{s_new, a_new});
% pi{t}{s}(a)
%pi{t}{s_new}(a_new) 
                        end
                    end

                    delta = max(delta, norm(old - psi{t}{s,a}));
                end
            end

            if delta < threshold
                break;
            end
        end
    end

        %save('temp2.mat');
