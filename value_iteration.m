function [V, pi] = value_iteration(env, w, gamma, beta)

    V = zeros(1, env.N);

    threshold = 0.01;
    % compute values
    while true
        delta = 0;
        for s = env.S
            %fprintf('   s = %d\n', s);
            v = V(s);

            Q = zeros(1, length(env.A));
            for a = env.A
                r = env.phi{s,a} * w';

                tmp = r + sum(squeeze(env.T(s, a, :))' .* (gamma * V));
                Q(a) = tmp;
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

