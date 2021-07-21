function [x,y] = argmin2D(A)

[M,~] = min(A(:));
[x,y] = find(A==M);

assert(A(x,y) == M);

