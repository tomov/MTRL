function [V, pi] = value_iteration(env, w, gamma)

    V = zeros(1, env.N);
    pi = zeros(1, env.N);

    % important to init at least terminal states
    for s = env.S
        V(s) = env.phi{s} * w';
    end

    threshold = 0.01;
    while true
        delta = 0;
        for s = env.S
            fprintf('   s = %d\n', s);
            v = V(s);

            r = env.phi{s} * w';

            best = -Inf;
            for a = env.A
                tmp = r + sum(squeeze(env.T(s, a, :))' .* (gamma * V));
                fprintf('           a = %d, tmp = %f\n', s, tmp);
                if best < tmp
                    best = tmp;
                    pi(s) = a;
                end
            end
            V(s) = best;

            delta = max(delta, abs(v - best));
        end

        if delta < threshold
            break;
        end
    end
end
