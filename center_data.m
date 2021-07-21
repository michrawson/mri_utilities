function A = center_data(A,N,channel_len)
% Takes 3D matrix size N x N x channel_len. Center x,y slices, so fft max
% is at zero of first slice.

s = zeros(N,N,channel_len);

% switch to fft domain 
for icha = 1:channel_len
    s(:,:,icha)=fftshift(fft2(A(:,:,icha)));
end

s(:,:,1) = fftshift(s(:,:,1));
[m,x,y] = maxArgs2D(abs(s(:,:,1)));
s(:,:,1) = ifftshift(s(:,:,1));

% center data in fft space
for icha = 1:channel_len
    s(:,:,icha) = fftshift(s(:,:,icha));
    s(:,:,icha) = s([x:N 1:x-1],[y:N 1:y-1],icha);
    s(:,:,icha) = ifftshift(s(:,:,icha));
end

for icha = 1:channel_len
    A(:,:,icha)=ifft2(ifftshift(s(:,:,icha)));
end

