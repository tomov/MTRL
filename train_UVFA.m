function [UVFA, V] = train_UVFA(env, w_train, gamma, niters)

    if ~exist('niters', 'var')
        niters = 10;
    end
    beta = 50; % doesn't matter

    % value iteration -- V{t}(s) = value f'n for task t, state s
    %
    for t = 1:length(w_train)
        %fprintf('t = %d\n', t);

        [V{t}, ~] = value_iteration(env, w_train{t}, gamma, beta);
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
    X = repmat(X, niters, 1);
    y = repmat(y, niters, 1);

    % shuffle 'em
    idx = randperm(size(X,1));
    X = X(idx,:);
    y = y(idx,:);

    X = X'; % UGH matlab
    y = y'; 

    UVFA = fitnet(10);
    UVFA = train(UVFA, X, y);

    yy = UVFA(X);
    perf = perform(UVFA, yy, y);

