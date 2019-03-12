% init experimental environment
%
function env = init_env_v1_1

env.N = 15;
env.S = 1:env.N;

env.A = 1:3;

% transitions T(s,a,s')
env.T = zeros(env.N, length(env.A), env.N);
env.T(1, 1, 2) = 1;
env.T(1, 2, 3) = 1;
env.T(2, 1, 4) = 1;
env.T(2, 2, 5) = 1;
env.T(3, 1, 6) = 1;
env.T(3, 2, 7) = 1;
env.T(4, 1, 8) = 1;
env.T(5, 1, 9) = 1;
env.T(5, 2, 10) = 1;
env.T(5, 3, 11) = 1;
env.T(6, 1, 12) = 1;
env.T(6, 2, 13) = 1;
env.T(7, 1, 14) = 1;
env.T(7, 2, 15) = 1;

% features phi(s)
% TODO make random choices when indifferent; currently order matters b/c of ties
env.phi{1} = [0 0 0 0];
env.phi{2} = [0 0 0 0];
env.phi{3} = [0 0 0 0];
env.phi{4} = [0 0 0 0];
env.phi{5} = [0 0 0 0];
env.phi{6} = [0 0 0 0];
env.phi{7} = [0 0 0 0];
env.phi{8} = [1 0 1.5 0];
env.phi{9} = [0.9 0 0 0];
env.phi{10} = [0.8 0.8 0 0];
env.phi{11} = [0 0.9 0 0];
env.phi{12} = [0.5 0 0 0];
env.phi{13} = [0 0.5 0 1.5];
env.phi{14} = [0 0 0 0];
env.phi{15} = [0 1 0 0];

% terminal states
env.terminal = zeros(1, env.N);
env.terminal(8:end) = 1;
