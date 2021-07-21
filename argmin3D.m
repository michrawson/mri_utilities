function [x,y,z] = argmin3D(A)

[M,~] = min(A(:));
[x,~] = find(A==M);

[y,z] = find(reshape(A(x,:),size(A,2),size(A,3))==M);


assert(A(x,y,z) == M);

