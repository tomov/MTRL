function [pi_test_SF] = test_SFGPI1(env, w_test, w_train, gamma, beta, psi)

    % argmax over policies, not all actions
    % see commentary after Eq. 8 in Barreto et al. 2020 PNAS
    % goes with train_SFGPI.m
    
    % recover training policies
    pi_train_SF = test_SFGPI(env, w_train, gamma, beta, psi);

    % see what SF will do on each test task
    for t = 1:length(w_test)
        
        % for each state
        for s = 1:env.N
            best_value = -Inf;
            best_policy = nan(1, length(env.A));
            
            for tt = 1:length(psi) % loop over training tasks
                value = psi{tt}{s} * w_test{t}';
                if value > best_value
                    % TODO tiebreaking or softmax over policies
                    best_value = value;
                    best_policy = pi_train_SF{tt}{s};
                end
            end

            pi_test_SF{t}{s} = best_policy;
        end
    end


