clear all;
close all;

%env = init_env_sfgpi_v1_1a;
%filename = 'demo_sfgpi_v1_1a.mat'; 
env = init_env_sfgpi_v1_1e;
filename = 'demo_sfgpi_v1_1e.mat'; 
action_paths = { ...
    '[1 1 1]', ...
    '[1 1 2]', ...
    '[1 1 3]', ...
    '[1 2 1]', ...
    '[1 2 2]', ...
    '[1 2 3]', ...
    '[1 3 1]', ...
    '[1 3 2]', ...
    '[1 3 3]', ...
    '[2 1 1]', ...
    '[2 1 2]', ...
    '[2 1 3]', ...
    '[2 2 1]', ...
    '[2 2 2]', ...
    '[2 2 3]', ...
    '[2 3 1]', ...
    '[2 3 2]', ...
    '[2 3 3]'};

w_train = {[1 0], [0 1]};
%w_train = {[1 0]};
w_test = {[1 1]};  

params = init_params();
%params.beta = 1;
N = 60;

%
% train models
%

for subj = 1:N

    %UVFA{subj} = train_UVFA(env, w_train, params.gamma, 100);

    psi{subj} = train_SFGPI(env, w_train, params.gamma, params.beta);

    Q{subj} = train_MF(env, w_train, params.gamma, params.alpha, params.eps);

    Q2{subj} = train_MF2(env, w_train, params.gamma, params.alpha, params.eps);
end


save(filename);

%load(filename);



%
% eval perf on train tasks
%

for subj = 1:N

    % compute test policies
    %pi_train_UVFA = test_UVFA(env, w_train, params.gamma, params.beta, UVFA{subj});
    pi_train_SF = test_SFGPI(env, w_train, params.gamma, params.beta, psi{subj});
    pi_train_MB = test_MB(env, w_train, params.gamma, params.beta);
    pi_train_MF = test_MF(env, w_train, params.beta, Q{subj});
    pi_train_MF2 = test_MF2(env, w_train, params.beta, Q2{subj}, w_train);

    for t = 1:length(w_train)

        % test UVFA
        %[r, s, as] = test_perf(env, pi_train_UVFA{t}, w_train{t});
        %as_train{t, 1, subj} = action_path_to_str(as);
        %term_s_train(t, 1, subj) = s;
        %tot_r_train(t, 1, subj) = r;

        % test SF 
        [r, s, as] = test_perf(env, pi_train_SF{t}, w_train{t});
        as_train{t, 2, subj} = action_path_to_str(as);
        term_s_train(t, 2, subj) = s;
        tot_r_train(t, 2, subj) = r;

        % test MB 
        [r, s, as] = test_perf(env, pi_train_MB{t}, w_train{t});
        as_train{t, 3, subj} = action_path_to_str(as);
        term_s_train(t, 3, subj) = s;
        tot_r_train(t, 3, subj) = r;

        % test MF 
        [r, s, as] = test_perf(env, pi_train_MF, w_train{t});
        as_train{t, 4, subj} = action_path_to_str(as);
        term_s_train(t, 4, subj) = s;
        tot_r_train(t, 4, subj) = r;

        % test MF2
        [r, s, as] = test_perf(env, pi_train_MF2{t}, w_train{t});
        as_train{t, 5, subj} = action_path_to_str(as);
        term_s_train(t, 5, subj) = s;
        tot_r_train(t, 5, subj) = r;
    end

end


%
% eval perf on test tasks
%

for subj = 1:N

    % compute test policies
    %pi_test_UVFA = test_UVFA(env, w_test, params.gamma, params.beta, UVFA{subj});
    pi_test_SF = test_SFGPI(env, w_test, params.gamma, params.beta, psi{subj});
    pi_test_MB = test_MB(env, w_test, params.gamma, params.beta);
    pi_test_MF = test_MF(env, w_test, params.beta, Q{subj});
    pi_test_MF2 = test_MF2(env, w_test, params.beta, Q2{subj}, w_train);

    for t = 1:length(w_test)

        % test UVFA
        %[r, s, as] = test_perf(env, pi_test_UVFA{t}, w_test{t});
        %as_test{t, 1, subj} = action_path_to_str(as);
        %term_s_test(t, 1, subj) = s;
        %tot_r_test(t, 1, subj) = r;

        % test SF 
        [r, s, as] = test_perf(env, pi_test_SF{t}, w_test{t});
        as_test{t, 2, subj} = action_path_to_str(as);
        term_s_test(t, 2, subj) = s;
        tot_r_test(t, 2, subj) = r;

        % test MB 
        [r, s, as] = test_perf(env, pi_test_MB{t}, w_test{t});
        as_test{t, 3, subj} = action_path_to_str(as);
        term_s_test(t, 3, subj) = s;
        tot_r_test(t, 3, subj) = r;

        % test MF 
        [r, s, as] = test_perf(env, pi_test_MF, w_test{t});
        as_test{t, 4, subj} = action_path_to_str(as);
        term_s_test(t, 4, subj) = s;
        tot_r_test(t, 4, subj) = r;

        % test MF2
        [r, s, as] = test_perf(env, pi_test_MF2{t}, w_test{t});
        as_test{t, 5, subj} = action_path_to_str(as);
        term_s_test(t, 5, subj) = s;
        tot_r_test(t, 5, subj) = r;
    end
end

save(filename);


%load(filename);

model_names = {'UVFA', 'SF&GPI', 'MB', 'MF', 'MF2'};

%plot_perf(env, w_train, tot_r_train, model_names); % <-- boring

%plot_final_states(env, w_train, term_s_train, model_names);

plot_action_paths(env, w_train, as_train, action_paths, model_names);




plot_perf(env, w_test, tot_r_test, model_names);

%plot_final_states(env, w_test, term_s_test, model_names);

plot_action_paths(env, w_test, as_test, action_paths, model_names);

