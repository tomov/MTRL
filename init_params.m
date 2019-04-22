function params = init_params()

    params.gamma = 0.99; % discount rate
    params.alpha = 0.1; % Q-learning rate
    params.eps = 0.9; % eps-greedy 
    params.beta = 7; % softmax inverse temperature, set to e.g. 50 for max instead of softmax
