function [pi_test_UVFA, pi_test_SF, V, V_test, psi, Vmax] = sim(env, w_train, w_test)


gamma = 0.99;


% value iteration -- V{t}(s) = value f'n for task t, state s
%
for t = 1:length(w_train)
    V{t} = zeros(1, env.N);
    pi{t} = zeros(1, env.N);

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
                if best < tmp
                    best = tmp;
                    pi{t}(s) = a;
                end
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
    V_test{t} = zeros(1, env.N);
    for s = 1:env.N
        s_onehot = zeros(1, env.N);
        s_onehot(s) = 1;
        x = [s_onehot w_test{t}];
        V_test{t}(s) = UVFA(x');
    end

    % compute policies
    for s = 1:env.N
        best = -Inf;
        pi_test_UVFA{t}(s) = NaN;
        for a = env.A
            tmp = r + sum(squeeze(env.T(s, a, :))' .* (gamma * V_test{t}));
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
            tmp = r + sum(squeeze(env.T(s, a, :))' .* (gamma * Vmax{t}));
            if best <= tmp % TODO make random choices when indifferent; currently order matters b/c of ties
                best = tmp;
                pi_test_SF{t}(s) = a;
            end
        end
    end
end

save shit.mat
