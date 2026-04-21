function data = interpolation(data,varargin)        
        
        
        x = find(~isnan(data));
        v = data(x);
        xq = find(isnan(data));
        if nargin>1
            vq = interp1(x,v,xq,varargin{1});
        else
            vq = interp1(x,v,xq);
        end
        data = zeros(size(data));
        data(x) = v;
        data(xq) = vq;
end