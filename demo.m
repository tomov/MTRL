clear all;

env.N = 13;
env.S = 1:env.N;
env.A = 1:3;
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
env.phi(1) = [0 0 0];
env.phi(2) = [0 0 0];
env.phi(3) = [0 0 0];
env.phi(4) = [0 0 0];
env.phi(5) = [0 0 0];
env.phi(6) = [1.0 0 0];
env.phi(7) = [0 0 0];
env.phi(8) = [0 0 0];
env.phi(9) = [0.8 0.8 0];
env.phi(10) = [0 0 0];
env.phi(11) = [0 0 0];
env.phi(12) = [0 1.0 0];
env.phi(13) = [0 0 0];


w_train = [
1 0 0;
0 1 0
];

w_test = [
1 1 0
];

for t = 1:
