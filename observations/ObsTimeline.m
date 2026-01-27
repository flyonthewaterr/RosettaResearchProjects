%% ObsTimeline.m
% Purpose: Generate observation timeline data for Rosetta mission at comet 67P/C-G
%
% Description:
%   This script calculates and visualizes key observation parameters over
%   the Rosetta mission timeline, centered on perihelion passage:
%   - Spacecraft-comet distance (NAC camera to comet center)
%   - Sun-comet distance
%   - Camera spatial resolution
%   - Subsolar latitude on comet surface
%
% Time Range: 365 days before to 366 days after perihelion (2014-08-13 to 2016-08-13)
% Time Step: 1 day (86400 seconds)
%
% Outputs:
%   - CSV file: OBStimeline.csv containing all calculated parameters
%   - Multi-axis plot showing distance and latitude variations
%
% Dependencies:
%   - SPICE toolkit (NAIF/CSPICE) must be installed and accessible
%   - SPICE kernel file: ROS_OPS_V330_20200731_001.TM
%   - multiplotyyy.m function for triple y-axis plotting
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

%% TIME TAG GENERATION
% Create time array centered on perihelion
% Analysis covers thermal insolation period: 2014-05-17 to 2015-10-03
% Extended range: -365 to +366 days relative to perihelion

% Create day indices array
id = -365:366;  % Days relative to perihelion (732 days total)

% Convert perihelion time to ephemeris time and create time array
% Perihelion: 2015-08-13 02:03:00 UTC
et = cspice_str2et('2015-08-13T02:03:00.0') + (-365:366)*86400;  % 86400 sec/day

% Convert ephemeris times to UTC strings
xDtimestr = cspice_et2utc(et, format, prec);

% Convert to MATLAB datetime objects for easier handling
t = datetime(xDtimestr, 'InputFormat', 'uuuu-MM-dd''T''HH:mm:ss.SSS');

%% INITIALIZE OUTPUT ARRAYS
% Pre-allocate arrays for calculated parameters (improves performance)
d_sun = zeros(size(et));     % Sun-comet distance [AU]
d_nac = zeros(size(et));     % NAC-comet distance [km]
res_nac = zeros(size(et));   % NAC spatial resolution [m/pixel]
lat_sub = zeros(size(et));   % Latitude of subsolar point [degrees]

%% CALCULATE OBSERVATION PARAMETERS
% Get camera position for all time steps
% cspice_spkezr returns state vector (position + velocity)
% Aberration correction: 'CN+S' (converged Newtonian with stellar aberration)
[cam_pos, ~] = cspice_spkezr(camera, et, CGframe, 'CN+S', target);

% Calculate NAC-comet distance [km]
% cam_pos(1:3,:) contains [x, y, z] position components
d_nac = sqrt(sum((cam_pos(1:3,:)).^2, 1));

% Calculate sun position and subsolar point for each time step
for i = 1:size(et, 2)
    sun_list(i, :) = sun_fun(et(i));  % Returns [longitude, latitude, distance]
end

% Extract sun parameters
sun_km = sun_list(:, 3)';        % Sun-comet distance [km]
d_sun = cspice_convrt(sun_km, 'KM', 'AU');  % Convert to Astronomical Units
lat_sub = sun_list(:, 2)';       % Subsolar latitude [degrees]

%% CALCULATE SPATIAL RESOLUTION
% NAC pixel size specification
pxsize = 18.6e-6;  % Pixel size [meters] = 18.6 micrometers

% Calculate spatial resolution at comet surface [meters/pixel]
% Resolution = distance × pixel_size × 1000 (km to m conversion)
res_nac = d_nac * pxsize * 1000;

%% SAVE DATA TO CSV FILE
% Prepare data for output
DN = d_nac';      % NAC-comet distance [km]
DS = d_sun';      % Sun-comet distance [AU]
LS = lat_sub';    % Subsolar latitude [degrees]
RES = res_nac';   % Spatial resolution [m/pixel]
ID = id';         % Day index relative to perihelion

% Define column names for output table
datacolumns = {'id', 'datet', 'dn', 'ds', 'ls', 'res'};

% Create table with all calculated parameters
data = table(ID, t, DN, DS, LS, RES, 'VariableNames', datacolumns);

% Write table to CSV file
% Note: Update path to match your desired output location
writetable(data, 'C:\Users\12605\Documents\Rosetta\Doc\Timeline\OBStimeline.csv');

%% not plotyyyy

% % Create a figure with two y-axes using yyaxis function
% figure
% 
% % Activate and plot into left side
% yyaxis left
% 
% % Plot sun-comet distance as a blue solid line
% % plot(et,d_sun,'b-')
% 
% % Hold on to plot more data on left side
% hold on
% 
% % Plot NAC-comet distance as a red dashed line
% plot(et,d_nac,'r--')
% 
% % Add ylabel for left side
% ylabel('Distance (km)')
% 
% % Release hold on left side
% % hold off
% 
% % Activate and plot into right side
% % yyaxis right
% 
% % Plot NAC resolution as a green dotted line
% % plot(et,res_nac,'g:')
% 
% % Hold on to plot more data on right side
% hold on
% 
% % Plot latitude of subsolar point as a magenta dash-dotted line
% plot(et,lat_sub,'m-.')
% 
% % Add ylabel for right side
% ylabel('Latitude (deg)') %Resolution (mrad) or 
% 
% % Release hold on right side
% hold off
% 
% % Add title and xlabel for the figure
% title('Plots with Different y-Scales')
% xlabel('Ephemeris time')


%% VISUALIZATION - Triple Y-Axis Plot
% Prepare data series for multi-axis plotting
x1 = t;         % Time axis (datetime)
y1 = d_nac;     % NAC-comet distance [km]
y2 = d_sun;     % Sun-comet distance [AU]
y3 = lat_sub;   % Subsolar latitude [degrees]

% Define y-axis labels
ylabels{1} = 'Space Distance (km)';
ylabels{2} = 'Solar Distance (AU)';
ylabels{3} = 'Subsolar Latitude (deg)';

% Create triple y-axis plot
% multiplotyyy creates a plot with three y-axes for different scales
[ax, hlines] = multiplotyyy({x1, y1}, {x1, y2}, {x1, y3}, ylabels);

% Format x-axis: display as year-month
xtickformat("yy-MM")

% Mark perihelion location
% Day 454 corresponds to index in time array (365 + 89 = 2015-08-13)
xline(t(454), '-.', 'Perihelion');

%% ========================================================================
%  HELPER FUNCTIONS
%% ========================================================================

%%
% sun_fun - Calculate sun position and subsolar point on comet
%
% INPUTS:
%   et - Ephemeris time [seconds since J2000 epoch]
%
% OUTPUTS:
%   sun_info - 1x3 array containing:
%              [1] Subsolar longitude [degrees, 0-360]
%              [2] Subsolar latitude [degrees, -90 to +90]
%              [3] Sun-comet distance [km]
%
% DESCRIPTION:
%   Computes the position of the Sun relative to comet 67P/C-G at the
%   specified ephemeris time. Uses SPICE toolkit to:
%   - Get Sun's position vector in comet body-fixed frame
%   - Calculate Sun-comet distance
%   - Find subsolar point (where Sun is directly overhead)
%   - Convert subsolar point to latitude/longitude coordinates
%
function sun_info = sun_fun(et)
    % Define comet parameters
    target = '67P/C-G';          % Target comet ID
    CGframe = '67P/C-G_CK';      % Comet body-fixed coordinate system
    
    % Get Sun's state vector (position + velocity) relative to comet
    % Aberration correction: 'CN+S' (converged Newtonian with stellar aberration)
    [state_sun, ~] = cspice_spkezr('Sun', et, CGframe, 'CN+S', target);
    
    % Calculate Sun-comet distance [km]
    sun_dis = sqrt(sum((state_sun(1:3)).^2, 1));
    
    % Find subsolar point on comet surface
    % 'Intercept/DSK/Unprioritized' method uses digital shape kernel
    [sunp, ~, ~] = cspice_subslr('Intercept/DSK/Unprioritized', target, et, ...
                                  CGframe, 'CN+S', target);
    
    % Convert Cartesian coordinates to latitude/longitude
    [sunlon, sunlat] = sunrec2lat(sunp);
    
    % Return results as array
    sun_info = [sunlon, sunlat, sun_dis];
end

%%
% sunrec2lat - Convert Cartesian coordinates to latitude/longitude
%
% INPUTS:
%   sunp - 3x1 vector of Cartesian coordinates [x, y, z] in km
%
% OUTPUTS:
%   sunlon - Longitude [degrees, 0-360]
%   sunlat - Latitude [degrees, -90 to +90]
%
% DESCRIPTION:
%   Converts 3D Cartesian coordinates to spherical coordinates
%   (longitude and latitude). Longitude is adjusted to range [0, 360].
%
function [sunlon, sunlat] = sunrec2lat(sunp)
    % Convert Cartesian to spherical coordinates
    % cart2sph returns: azimuth (lon), elevation (lat), radius
    [sunlon, sunlat] = cart2sph(sunp(1), sunp(2), sunp(3));
    
    % Convert from radians to degrees
    sunlon = sunlon / pi * 180;
    sunlat = sunlat / pi * 180;
    
    % Ensure longitude is in range [0, 360]
    if sunlon < 0
        sunlon = sunlon + 360;
    end
end