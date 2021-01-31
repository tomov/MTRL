
[data, Ts, filenames] = load_data_sfgpi('exp/results/sfgpi_v1_1a', 210);

s = 1;
figure;
plot(data(s).reward);
xlabel('trial');
ylabel('reward');
title(['Subject ', num2str(s)]);



[r, rse] = training_reward(data);
figure;
errorbar(r, rse);
xlabel('trial');
ylabel('reward');



[rb, rse] = training_reward_split_by_block(data);
figure;
errorbar(rb, rse);
legend(leg);
xlabel('trial');
ylabel('reward');


function [rb, rse] = training_reward_split_by_block(data)
    rb = nan(10,20);
    for b = 1:10
        rs = nan(length(data),20);
        for s = 1:length(data)
            r = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
            rs(s,:) = r;
        end
        rb(b,:) = mean(rs,1);
        rse(b,:) = std(rs,1)/sqrt(size(rs,1));
        leg{b} = ['block ', num2str(b)];
    end
end

function [r, rse] = training_reward(data)
    rs = nan(length(data), 20);
    for s = 1:length(data)
        rb = nan(10,20);
        for b = 1:10
            rb(b,:) = data(s).reward(data(s).block == b-1 & strcmp(data(s).stage, 'train'));
        end
        rs(s,:) = mean(rb,1);
    end
    r = mean(rs,1);
    rse = std(rs,1)/sqrt(size(rs,1));
end
