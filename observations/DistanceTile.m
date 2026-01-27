%% DistanceTile.m
% Purpose: Visualize Rosetta spacecraft distance from comet 67P/C-G during
%          perihelion approach and recession phases
% 
% Description:
%   This script creates a tiled plot showing the distance between the
%   Rosetta spacecraft's OSIRIS NAC camera and comet 67P/Churyumov-
%   Gerasimenko during three time periods around perihelion:
%   - Forward approach (6 months before perihelion)
%   - Near perihelion (32 days around perihelion, hourly intervals)
%   - Later recession (post-perihelion period)
%
% Dependencies:
%   - SPICE toolkit (NAIF/CSPICE) must be installed and accessible
%   - SPICE kernel file: ROS_OPS_V330_20200731_001.TM
%   - External variables: UTC_list, SCD (must be defined in workspace)
%
% Author: Rosetta Research Projects
% Last Modified: 2026-01-27
%%

% Clear workspace and close figures for clean start
close all;
clear;

%% SETUP - SPICE Kernel and Mission Parameters
% Initialize SPICE toolkit with mission kernel
% Note: Update path to match your local SPICE kernel installation
% workpath = 'C:\Users\12605\Documents\MATLAB\Rosetta\Shape_dealing\';
% shapefile = [workpath,'67P_shape_model_2M.mat']; 

% Load SPICE kernels for ephemeris data
cspice_furnsh('C:/Users/12605/Documents/Rosetta/SPICE/Kernels/kernels/mk/ROS_OPS_V330_20200731_001.TM')

% Define mission parameters
target = '67P/C-G';          % Target comet ID (67P/Churyumov-Gerasimenko)
CGframe = '67P/C-G_CK';      % Comet body-fixed coordinate system
camera = 'ROS_OSIRIS_NAC';   % OSIRIS Narrow Angle Camera identifier
format = 'ISOC';             % Time format: ISO Calendar
prec = 3;                    % Time precision: 3 decimal places for seconds

%% TIME PERIOD 1: Forward Approach (6 months before to perihelion)
% Define perihelion time and create time array
perihelion_t = '2015-08-13T02:03:00.0';  % Comet perihelion date/time
perihelio_et = cspice_str2et(perihelion_t);  % Convert to ephemeris time

% Create time array: 120 days before to 180 days after perihelion
i = -120:1:180;  % Days relative to perihelion
time = perihelio_et + i*60*60*24;  % Convert to ephemeris time (seconds)

% Forward period: days -120 to +31 (indices 1:152)
time_F = time(1:152);
% Get camera position relative to comet in CG frame
% Aberration correction: 'CN+S' (converged Newtonian with stellar aberration)
[cam_pos_F, ~] = cspice_spkezr(camera, time_F, CGframe, 'CN+S', target);
% Calculate distance in km (sqrt of sum of squared position components)
D_F = sqrt(sum((cam_pos_F(1:3,:)).^2, 1));
% Convert ephemeris time to UTC strings
xDtimestr_F = cspice_et2utc(time_F, format, prec);
% Convert to MATLAB datetime objects
t_F = datetime(xDtimestr_F, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS');

%% TIME PERIOD 2: Later Recession Phase
% Later period: days +64 to +180 (indices 185:301)
time_L = time(185:301);
% Get camera position and calculate distance
[cam_pos_L, ~] = cspice_spkezr(camera, time_L, CGframe, 'CN+S', target);
D_L = sqrt(sum((cam_pos_L(1:3,:)).^2, 1));
% Convert to datetime for plotting
xDtimestr_L = cspice_et2utc(time_L, format, prec);
t_L = datetime(xDtimestr_L, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS');

%% TIME PERIOD 3: Near Perihelion (High-Resolution Hourly Data)
% Create hourly time array for 32 days around perihelion
i_M = 0:1:(32*24);  % Hours: 0 to 768 (32 days * 24 hours)
M_et = time(152);   % Start time: end of forward period
time_M = M_et + i_M*60*60;  % Convert to ephemeris time (seconds)

% Get camera position and calculate distance
[cam_pos_M, ~] = cspice_spkezr(camera, time_M, CGframe, 'CN+S', target);
D_M = sqrt(sum((cam_pos_M(1:3,:)).^2, 1));
% Convert to datetime for plotting
xDtimestr_M = cspice_et2utc(time_M, format, prec);
t_M = datetime(xDtimestr_M, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS');

%% OBSERVATION DATA
% Convert observation UTC times to datetime objects
% Note: UTC_list must be defined in workspace before running this script
UTC_PO = datetime(UTC_list, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS');

%% PLOTTING - Create Tiled Layout with Three Time Periods
% Create figure with 1 row, 4 columns (tiles 2-3 merged for middle period)
t = tiledlayout(1, 4, 'TileSpacing', 'none');

%% TILE 1: Forward Approach Period
ax1 = nexttile;
% Plot distance vs time (dark red line)
plot(t_F', D_F, "Color", "#A2142F", 'LineWidth', 2)
% Mark perihelion location (at day 121 of forward period)
xline(t_F(121), '-.', 'Perihelion', 'LineWidth', 2, 'FontSize', 13);
% Configure y-axis
ax1.YAxisLocation = 'left';
ax1.YTick = [0, 200, 400, 600, 800, 1000, 1200, 1400, 1600];
% Configure x-axis: year-month format
xtickformat("yy-MM")
ax1.Box = 'off';
% Set axis limits (km for y-axis, dates for x-axis)
xlim([datetime("2015-04-15") datetime('2015-09-13 02:03:00')])
ylim([0 1600])
xtickangle(45)

hold on
% Plot first observation point
% Note: SCD (spacecraft-comet distance) must be defined in workspace
scatter(UTC_PO(1), SCD(1), 80, 'MarkerEdgeColor', "#0072BD", ...
              'MarkerFaceColor', "#D95319", ...
              'LineWidth', 1.5)

%% TILE 2-3: Near Perihelion Period (Merged tiles)
ax2 = nexttile([1 2]);  % Span 2 tiles
ax2.YTick = [];  % Hide y-axis tick marks
% Plot distance vs time with hourly resolution
plot(t_M', D_M, "Color", "#A2142F", 'LineWidth', 2)
% Mark 1.39 AU distance point (at hour 505)
xline(t_M(505), '--', '1.39au', 'LineWidth', 2, 'FontSize', 13);
% Configure x-axis: year-month-day format
xtickformat("yy-MM-dd")
xlim([datetime('2015-09-14 02:03:00') datetime('2015-10-15 02:03:00')])
xtickangle(45)
ylim([0 1600])
ax2.YAxis.Visible = 'off';
set(ax2, 'color', '#DAE3F3');  % Light blue background
ax2.Box = 'off';

hold on
% Plot observation points (circular and square markers)
scatter(UTC_PO(2), SCD(2), 80, 'MarkerEdgeColor', "#0072BD", ...
              'MarkerFaceColor', "#D95319", ...
              'LineWidth', 1.5)
scatter(UTC_PO([8 9 10]), SCD([8 9 10]), 80, "square", 'MarkerEdgeColor', "#0072BD", ...
              'MarkerFaceColor', "#D95319", ...
              'LineWidth', 1.5)
% Add x-axis label (shared across all tiles)
xlabel('Rosetta-Comet distance [km]', 'FontSize', 14, 'FontWeight', 'bold')

%% TILE 4: Later Recession Period
ax3 = nexttile;
% Plot distance vs time
plot(t_L', D_L, "Color", "#A2142F", 'LineWidth', 2)
% Configure x-axis: year-month format
xtickformat("yy-MM")
xlim([datetime("2015-10-16 02:03:00") datetime("2016-02-09")])
ylim([0 1600])
xtickangle(45)
% Configure y-axis on right side
ax3.YAxisLocation = 'right';
ax3.Box = 'off';

hold on
% Plot all observation points as squares
scatter(UTC_PO, SCD, 80, "square", 'MarkerEdgeColor', "#0072BD", ...
              'MarkerFaceColor', "#D95319", ...
              'LineWidth', 1.5)

%%
