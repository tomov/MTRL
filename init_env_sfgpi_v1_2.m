% init experimental environment
%
function env = init_env_v1_1l


env.N = 4;
env.S = 1:env.N;

env.A = 1:4;

% transitions T(s,a,s')
env.T = zeros(env.N, length(env.A), env.N);
env.T(1, 1, 2) = 1;
env.T(1, 2, 2) = 1;
env.T(1, 3, 3) = 1; % heck to make this work because the implementation assumes that all actions are available in Allstate
env.T(1, 4, 3) = 1;
env.T(2, 1, 4) = 1;
env.T(2, 2, 4) = 1;
env.T(2, 3, 4) = 1;
env.T(2, 4, 4) = 1;
env.T(3, 1, 4) = 1;
env.T(3, 2, 4) = 1;
env.T(3, 3, 4) = 1;
env.T(3, 4, 4) = 1; %Heck

% features phi(s,a)
% TODO make random choices when indifferent; currently order matters b/c of ties
env.phi{1, 1} = [5 1];
env.phi{1, 2} = [1 2];
env.phi{1, 3} = [1 0]; 
env.phi{1, 4} = [0 1];
env.phi{2, 1} = [3 1];
env.phi{2, 2} = [10 1];
env.phi{2, 3} = [1 12];
env.phi{2, 4} = [-1000 -1000];
env.phi{3, 1} = [11 1];
env.phi{3, 2} = [10 9];
env.phi{3, 3} = [1 10];
env.phi{3, 4} = [-1000 -1000];
env.phi{4, 1} = [0 0];
env.phi{4, 2} = [0 0];
env.phi{4, 3} = [0 0];
env.phi{4, 4} = [0 0];

% terminal states
env.terminal = zeros(1, env.N);
env.terminal(4) = 1;
