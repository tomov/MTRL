function s = action_path_to_str(as)
    s = sprintf(' %d', as);
    s = sprintf('[%s]', s(2:end));
