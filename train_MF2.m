function Q = train_MF2(env, w_train, gamma, alpha, eps)

    % train MF (Q-learning), one for each task
    %

    % unroll training tasks
    for t = 1:length(w_train)
        ws = [];
        for i = 1:200
            ws = [ws; w_train{t}];
        end
        ws = ws(randperm(size(ws, 1)), :);

        % Q-learn
        Q{t} = rand(env.N, length(env.A)) * 0.00001; % to break ties initially
        eps = 0.9;
        alpha = 0.1;
        for i = 1:size(ws,1)
            r = 0;
            s = 1;
            while true 
                if env.terminal(s)
                    break
                end

                % eps-greedy ; note we use it here to ensure convergence, but for test, we use softmax
                [~, a] = max(Q{t}(s,:));
                if rand < 1 - eps
                    a = randsample([1:a-1 a+1:length(env.A)], 1);
                end

                % next state and reward
                s_new = find(mnrnd(1, squeeze(env.T(s, a, :))));

                r = env.phi{s_new} * ws(i,:)';

                [~, a_new] = max(Q{t}(s_new,:)); % best next action

                Q{t}(s,a) = Q{t}(s,a) + alpha * (r + gamma * Q{t}(s_new,a_new) - Q{t}(s,a));

                s = s_new;
            end
        end
    end

