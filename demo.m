clear all;

env.N = 13;
env.S = 1:env.N;
env.A = 1:3;
env.T = zeros(env.N, length(env.A), env.N);
env.T(1, 1, 2) = 1;
env.T(1, 2, 3) = 1;
env.T(1, 3, 4) = 1;
env.T(2, 1, 5) = 1;
env.T(2, 2, 6) = 1;
env.T(2, 3, 7) = 1;
env.T(3, 1, 8) = 1;
env.T(3, 2, 9) = 1;
env.T(3, 3, 10) = 1;
env.T(4, 1, 11) = 1;
env.T(4, 2, 12) = 1;
env.T(4, 3, 13) = 1;
env.phi{1} = [0 0 0];
env.phi{2} = [0 0 0];
env.phi{3} = [0 0 0];
env.phi{4} = [0 0 0];
env.phi{5} = [0 0 0];
env.phi{6} = [1 0 0];
env.phi{7} = [0 0 0];
env.phi{8} = [0 0 0];
env.phi{9} = [0.8 0.8 0];
env.phi{10} = [0 0 0];
env.phi{11} = [0 0 0];
env.phi{12} = [0 1 0];
env.phi{13} = [0 0 0];


w_train = {[1 0 0], [0 1 0]};

w_test = {[1 1 0]};

gamma = 0.99;

% value iteration -- V{t}(s) = value f'n for task t, state s
%
for t = 1:length(w_train)
    V{t} = zeros(1, env.N);

    fprintf('t = %d\n', t);

    % important to init at least terminal states
    for s = env.S
        V{t}(s) = env.phi{s} * w_train{t}';
    end

    threshold = 0.01;
    while true
        delta = 0;
        for s = env.S
            fprintf('   s = %d\n', s);
            v = V{t}(s);

            r = env.phi{s} * w_train{t}';

            best = -Inf;
            for a = env.A
                tmp = r + sum(squeeze(env.T(s, a, :))' .* (gamma * V{t}));
                fprintf('           a = %d, tmp = %f\n', s, tmp);
                best = max(best, tmp);
            end
            V{t}(s) = best;

            delta = max(delta, abs(v - best));
        end

        if delta < threshold
            break;
        end
    end
end


% train UVFA
%
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



% see what it will do
%
V_test = zeros(1, env.N);
for s = 2:4
    s_onehot = zeros(1, env.N);
    s_onehot(s) = 1;
    x = [s_onehot w_test{1}];
    V_test(s) = UVFA(x');
end
