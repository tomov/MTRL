clear all;

env = init_env;

w_train = {[1 0 0], [0 1 0]};
w_test = {[1 1 0]};

[pi_test_UVFA, pi_test_SF, V, V_test, psi, Vmax] = sim(env, w_train, w_test);

