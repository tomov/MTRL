% init experimental environment
%
function env = init_env_v1_1l


env.N = 3;
env.S = 1:env.N;

env.A = 1:3;

% transitions T(s,a,s')
env.T = zeros(env.N, length(env.A), env.N);
env.T(1, 1, 2) = 1;
env.T(1, 2, 2) = 1;
env.T(1, 3, 2) = 1; % heck to make this work because the implementation assumes that all actions are available in Allstate
env.T(2, 1, 3) = 1;
env.T(2, 2, 3) = 1;
env.T(2, 3, 3) = 1;

% features phi(s)
% TODO make random choices when indifferent; currently order matters b/c of ties
env.phi{1, 1} = [2 0];
env.phi{1, 2} = [0 1];
env.phi{1, 3} = [-1000 -1000]; % Hector make this work because implementation assumes that all states cap all actions
env.phi{2, 1} = [3 0];
env.phi{2, 2} = [2 3];
env.phi{2, 3} = [0 4];
env.phi{3, 1} = [0 0];
env.phi{3, 2} = [0 0];
env.phi{3, 3} = [0 0];

% terminal states
env.terminal = zeros(1, env.N);
env.terminal(3) = 1;
