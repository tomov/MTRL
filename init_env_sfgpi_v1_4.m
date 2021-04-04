% init experimental environment
%
function env = init_env_v1_1l


env.N = 10;
env.S = 1:env.N;

env.A = 1:3;

% transitions T(s,a,s')
env.T = zeros(env.N, length(env.A), env.N);
env.T(1, 1, 2) = 1;
env.T(1, 2, 2) = 1;
env.T(1, 3, 6) = 1;
env.T(2, 1, 3) = 1;
env.T(2, 2, 4) = 1;
env.T(2, 3, 5) = 1;
env.T(3, 1, 2) = 1;
env.T(4, 1, 2) = 1;
env.T(5, 1, 2) = 1;
env.T(3, 2, 10) = 1;
env.T(4, 2, 10) = 1;
env.T(5, 2, 10) = 1;
env.T(3, 3, 10) = 1;
env.T(4, 3, 10) = 1;
env.T(5, 3, 10) = 1;
env.T(6, 1, 7) = 1;
env.T(6, 2, 8) = 1;
env.T(6, 3, 9) = 1;
env.T(7, 1, 10) = 1;
env.T(7, 2, 10) = 1;
env.T(7, 3, 10) = 1;
env.T(8, 1, 10) = 1;
env.T(8, 2, 10) = 1;
env.T(8, 3, 10) = 1;
env.T(9, 1, 10) = 1;
env.T(9, 2, 10) = 1;
env.T(9, 3, 10) = 1;

% features phi(s,a)
% TODO make random choices when indifferent; currently order matters b/c of ties
env.phi{1, 1} = [4 0];
env.phi{1, 2} = [0 2];
env.phi{1, 3} = [0 1];
env.phi{2, 1} = [0 0]; 
env.phi{2, 2} = [0 0];
env.phi{2, 3} = [0 0];
env.phi{3, 1} = [0 0];
env.phi{4, 1} = [0 0];
env.phi{5, 1} = [0 0];
env.phi{3, 2} = [7 0];
env.phi{4, 2} = [2 1];
env.phi{5, 2} = [0 8];
env.phi{3, 3} = [1 2];
env.phi{4, 3} = [1 0];
env.phi{5, 3} = [0 1];
env.phi{10, 1} = [0 0];
env.phi{10, 2} = [0 0];
env.phi{10, 3} = [0 0];
env.phi{6, 1} = [4 2];
env.phi{6, 2} = [3 0];
env.phi{6, 3} = [1 5];
env.phi{7, 1} = [1 1];
env.phi{7, 2} = [0 1];
env.phi{7, 3} = [2 0];
env.phi{8, 1} = [2 1];
env.phi{8, 2} = [4 6];
env.phi{8, 3} = [3 1];
env.phi{9, 1} = [1 1];
env.phi{9, 2} = [0 1];
env.phi{9, 3} = [1 0];

% terminal states
env.terminal = zeros(1, env.N);
env.terminal(10) = 1;
