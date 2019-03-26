function Q = train_MF(env, w_train, gamma, alpha, eps)

    % train MF (Q-learning)
    %

    % unroll training tasks
    ws = [];
    for t = 1:length(w_train)
        for i = 1:200
            ws = [ws; w_train{t}];
        end
    end
    ws = ws(randperm(size(ws, 1)), :);

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
            r = env.phi{s_new} * ws(i,:)';

            [~, a_new] = max(Q(s_new,:)); % best next action

            Q(s,a) = Q(s,a) + alpha * (r + gamma * Q(s_new,a_new) - Q(s,a));

            s = s_new;
        end
    end
