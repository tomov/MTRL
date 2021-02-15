% init experimental environment
%
function env = init_env_v1_1l


env.N = 3;
env.S = 1:env.N;

env.A = 1:5;

% transitions T(s,a,s')
env.T = zeros(env.N, length(env.A), env.N);
env.T(1, 1, 2) = 1;
env.T(1, 2, 2) = 1;
env.T(1, 3, 2) = 1;
env.T(1, 4, 2) = 1;
env.T(1, 5, 2) = 1;
env.T(2, 1, 3) = 1;
env.T(2, 2, 3) = 1;
env.T(2, 3, 3) = 1;
env.T(2, 4, 3) = 1;
env.T(2, 5, 3) = 1;

% features phi(s)
% TODO make random choices when indifferent; currently order matters b/c of ties
env.phi{1, 1} = [2 0];
env.phi{1, 2} = [3 0];
env.phi{1, 3} = [1 1];
env.phi{1, 4} = [0 2];
env.phi{1, 5} = [0 1];
env.phi{2, 1} = [3 2];
env.phi{2, 2} = [5 1];
env.phi{2, 3} = [4 4];
env.phi{2, 4} = [1 6];
env.phi{2, 5} = [1 4];

% terminal states
env.terminal = zeros(1, env.N);
env.terminal(3) = 1;
