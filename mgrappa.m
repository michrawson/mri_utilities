function [rot_image, grappa_rot_image, grappa_rot_image_fixed_calib] = mgrappa(...
ChannelImage, ChannelImage_rot, partition_mode_squared, calibration_offset, Lf_thresh, theta_deg, x_offset, y_offset, imrot_algo, extrapolate_thresh, extrapolate_mode, beta, alpha)

N = size(ChannelImage,1);
channel_len = size(ChannelImage,3);

%signal data
s = zeros(N,N,channel_len);
for icha = 1:channel_len %parfor
    s(:,:,icha)=fftshift(fft2((ChannelImage(:,:,icha))));
end

%calibration data
c = zeros(N,2*calibration_offset,channel_len);
% c = zeros(N,N,channel_len);
for icha = 1:channel_len % parfor
%     c(:,(N/2-calibration_offset+1):(N/2+calibration_offset),icha)...
%     =s(:,(N/2-calibration_offset+1):(N/2+calibration_offset),icha);
    c(:,:,icha) = s(:,(N/2-calibration_offset+1):(N/2+calibration_offset),icha);
end

%lowpass of signal
Ls = zeros(N,N,channel_len);
for icha = 1:channel_len %parfor
    Ls(:,:,icha) = lowpass2D(s(:,:,icha),N,calibration_offset);
end

% calculate approx lowpass of brain
Lf = zeros(N,N);
for icha = 1:channel_len
    if partition_mode_squared
        Lf = Lf + (abs(ifft2(ifftshift(Ls(:,:,icha))))).^2;
    else
        Lf = Lf + (abs(ifft2(ifftshift(Ls(:,:,icha)))));
    end
end

if partition_mode_squared
    Lf = sqrt(Lf);
end

P = zeros(N,N,channel_len); % profile approx
rot_s_true = zeros(N,N,channel_len);
rot_s_approx = zeros(N,N,channel_len);

%             Lf_x_y = translate_x_y(Lf, x_offset, y_offset);

%             if x_offset==10
%                 figure;imshow(abs(Lf_x_y),[0,max(max(abs(Lf_x_y)))])
%             end

for icha = 1:channel_len % parfor

    %true rot signal data
    rot_s_true(:,:,icha) = fftshift(fft2(squeeze(ChannelImage_rot(:,:,icha))));

        P0 = ifft2(ifftshift(Ls(:,:,icha)))./...
                            (Lf+Lf_thresh*max(max(abs(Lf))));

    % Rotate profile
    if theta_deg ~= 0
        P1 = imrotate(P0,theta_deg,imrot_algo,'crop');                    
    else
        P1 = P0;
    end

    % Translate profile
    P2 = translate_x_y(P1, x_offset, y_offset);
%                     
%                     if icha==1 && (y_offset==10 || x_offset==10)
%                         figure; imshowSc(P1);
%                         figure; imshowSc(P2);
%                     end

    if false % x_offset==0 && y_offset==0
        P3 = P2;
    else
        P3 = extrapolate_profile(P2,extrapolate_thresh,extrapolate_mode);
    end

%                     if icha==1 && (y_offset==10 || x_offset==10)
%                         figure; imshowSc(P3);
%                     end

    if false % icha == 1 && x_offset==10
%                     max(max(abs(P1)))
%                     figure;imshow(abs(P1),[0,max(max(abs(P1)))])
%                     title(sprintf('P1 mode=%d,x offset=%d,thresh=%2.2f',...
%                         extrapolate_mode,x_offset,extrapolate_thresh))

%                     max(max(abs(P3)))
        figure;imshowSc(P3);
        title(sprintf('Profile Approx mode=%d,x offset=%d,thresh=%2.2f',...
            extrapolate_mode,x_offset,extrapolate_thresh))

%                     figure;imshow(abs(P3.*Lf_x_y),[0,max(max(abs(P3.*Lf_x_y)))]);
    end

    P(:,:,icha) = (P3);

    rot_s_approx(:,:,icha) = fftshift(fft2(((P(:,:,icha).*Lf))));
end

%calibration data
rot_c_approx = zeros(N,2*calibration_offset,channel_len);
for icha = 1:channel_len % parfor
    rot_c_approx(:,:,icha) = rot_s_approx(:,...
        (N/2-calibration_offset+1):(N/2+calibration_offset),icha);
end

%subsample signal data
subsample_rot_s_true = rot_s_true;
for icha = 1:channel_len % parfor
    for k = 1:2:N
        subsample_rot_s_true(:,k,icha) = 0;
    end
end

rot_image = proot(beta,sum(abs(ifft2c(rot_s_true)),3));
rot_image = rot_image/vnorm(rot_image,alpha);

res=DoGrappa(subsample_rot_s_true,rot_c_approx); % MGRAPPA

grappa_rot_image_fixed_calib = proot(beta,sum(abs(ifft2c(res)),3));
grappa_rot_image_fixed_calib = grappa_rot_image_fixed_calib ...
    /vnorm(grappa_rot_image_fixed_calib,alpha);

res_bad_c=DoGrappa(subsample_rot_s_true,c); % GRAPPA

% abs_grappa_input_data{abs_grappa_input_counter} ...
%     = {W1, S1, T1, W2, S2, T2};
% 
% abs_grappa_input_counter = abs_grappa_input_counter + 1;

grappa_rot_image = proot(beta,sum(abs(ifft2c(res_bad_c)),3));
grappa_rot_image = grappa_rot_image ...
    /vnorm(grappa_rot_image,alpha);

% grappa_rot_image_fixed_calib_resid = rot_image - grappa_rot_image_fixed_calib;

% grappa_rot_image_resid = rot_image - grappa_rot_image;
