function params = init_params()

    params.gamma = 0.99; % discount rate
    params.alpha = 0.1; % Q-learning rate
    params.eps = 0.9; % eps-greedy 
    params.beta = 20; % softmax inverse temperature
