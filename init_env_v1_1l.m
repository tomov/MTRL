% init experimental environment
%
function env = init_env_v1_1l


env.N = 13;
env.S = 1:env.N;

env.A = 1:3;

% transitions T(s,a,s')
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

% features phi(s)
% TODO make random choices when indifferent; currently order matters b/c of ties
env.phi{1} = [0 0 0];
env.phi{2} = [0 0 0];
env.phi{3} = [0 0 0];
env.phi{4} = [0 0 0];
env.phi{5} = [0 1 0];
env.phi{6} = [10 0 0 ];
env.phi{7} = [4 4 13];
env.phi{8} = [9 0 0];
env.phi{9} = [10 10 0];
env.phi{10} = [0 9 0 ];
env.phi{11} = [0 0 1 ];
env.phi{12} = [0 10 6];
env.phi{13} = [1 0 0 ];

% terminal states
env.terminal = zeros(1, env.N);
env.terminal(5:end) = 1;
