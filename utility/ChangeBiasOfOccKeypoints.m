function model = ChangeBiasOfOccKeypoints(model, occ_coef)
% Changes bias of the model twoard predicting more (less) occluded 
% configurations, by increasing (decreasing) the bias of the occluded leaves.

for m = 1 : length(model.components)
    parts = model.components{m};
    for p = 11 : length(parts)
        for j = 1 : size(parts(p).biasid, 2)
            if(parts(p).occfilter(j) == 0)
                continue;
            end
            for i = 1 : size(parts(p).biasid, 1)
                bid = parts(p).biasid(i, j);
                if(bid ~= 0)
                    ov = model.bias(bid).w;
                    model.bias(bid).w = ov + abs(ov) * occ_coef;
                end
            end
        end
        
    end
end


