function [V, pi] = value_iteration(env, w, gamma, beta)

    V = zeros(1, env.N);

    % important to init at least terminal states
    for s = env.S
        V(s) = env.phi{s} * w';
    end

    threshold = 0.01;
    % compute values
    while true
        delta = 0;
        for s = env.S
            %fprintf('   s = %d\n', s);
            v = V(s);

            r = env.phi{s} * w';

            Q = [];
            for a = env.A
                tmp = r + sum(squeeze(env.T(s, a, :))' .* (gamma * V));
                Q = [Q, tmp];
            end
            V(s) = max(Q);

            P = exp(Q * beta);
            P = P / sum(P);
            pi{s} = P;

            delta = max(delta, abs(v - V(s)));
        end

        if delta < threshold
            break;
        end
    end
end

