function [pi_test_UVFA, pi_test_SF, V, V_test_UVFA, psi, Vmax, pi_test_MB, pi_test_MF] = simul(env, w_train, w_test)


    gamma = 0.99;


    % value iteration -- V{t}(s) = value f'n for task t, state s
    %
    for t = 1:length(w_train)
        fprintf('t = %d\n', t);

        [V{t}, pi{t}] = value_iteration(env, w_train{t}, gamma);
    end


    % train UVFA

    X = [];
    y = [];
    for t = 1:length(w_train)
        for s = env.S
            s_onehot = zeros(1, env.N);
            s_onehot(s) = 1;
            x = [s_onehot w_train{t}];
            X = [X; x];
            y = [y; V{t}(s)];
        end
    end
    X = repmat(X, 10, 1);
    y = repmat(y, 10, 1);
    X = X'; % UGH matlab
    y = y'; 

    UVFA = fitnet(10);
    UVFA = train(UVFA, X, y);

    yy = UVFA(X);
    perf = perform(UVFA, yy, y);
    perf



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


    % get SFs using iteration

    for t = 1:length(w_train)
        fprintf('t = %d\n', t);

        % important to init at least terminal states
        for s = 1:env.N
            psi{t}{s} = env.phi{s};
        end

        threshold = 0.01;
        while true
            delta = 0;
            for s = env.S
                fprintf('   s = %d\n', s);
                old = psi{t}{s};

                a = pi{t}(s);

                psi{t}{s} = env.phi{s};
                for s_new = 1:env.N
                    psi{t}{s} = psi{t}{s} + env.T(s, a, s_new) * gamma * psi{t}{s_new};
                    fprintf('          a = %d, s_new = %d, T(s,a,s_new) = %f, psi{t}{s_new} = [%f %f %f %f]\n', a, s_new, env.T(s, a, s_new), psi{t}{s_new});
                end

                delta = max(delta, norm(old - psi{t}{s}));
            end

            if delta < threshold
                break;
            end
        end
    end


    % see what SF will do 
    for t = 1:length(w_test)
        % compute Vmax
        Vmax{t} = zeros(1, env.N);
        for tt = 1:length(w_train)
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
                if best <= tmp % TODO make random choices when indifferent; currently order matters b/c of ties
                    best = tmp;
                    pi_test_SF{t}(s) = a;
                end
            end
        end
    end


    % see what MB will do
    for t = 1:length(w_test)
        % value iteration -- V{t}(s) = value f'n for task t, state s
        %
        fprintf('test t = %d\n', t);

        [V_test_MB{t}, pi_test_MB{t}] = value_iteration(env, w_test{t}, gamma);
    end


    % train MF (Q-learning)
    %

    % unroll training tasks
    ws = [];
    for t = 1:length(w_train)
        for i = 1:50
            ws = [ws; w_train{t}];
        end
    end
    ws = ws(randperm(size(ws, 1)));

    % Q-learn
    Q = rand(env.N, length(env.A)); % to break ties initially
    eps = 0.9;
    alpha = 0.1;
    for i = 1:size(ws,1)
        r = 0;
        s = 1;
        while true 
            if env.terminal(s)
                break
            end

            % eps-greedy
            [~, a] = max(Q(s,:));
            if rand < 1 - eps
                a = randsample([1:a-1 a+1:length(env.A)], 1);
            end

            % next state and reward
            s_new = find(mnrnd(1, squeeze(env.T(s, a, :))));
            r = env.phi{s_new} * w_test{t}';

            [~, a_new] = max(Q(s_new,:)); % best next action

            Q(s,a) = Q(s,a) + alpha * (r + gamma * Q(s_new,a_new) - Q(s,a));
        end
    end

    % see what MF will do
    for s = 1:env.N
        [~, pi_test_MF(s)] = max(Q(s,:));
    end

end


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
