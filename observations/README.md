# Rosetta Observation Conditions Analysis

## Purpose
This directory contains MATLAB scripts for analyzing observation conditions during the Rosetta spacecraft mission to comet 67P/Churyumov-Gerasimenko.

## Contents

### Scripts

1. **ObsTimeline.m**
   - Generates comprehensive observation timeline data
   - Calculates key parameters: spacecraft distance, solar distance, spatial resolution, subsolar latitude
   - Time range: 365 days before to 366 days after perihelion (2014-08-13 to 2016-08-13)
   - Outputs: CSV file with all parameters, multi-axis visualization plot

2. **DistanceTile.m**
   - Creates tiled visualization of spacecraft-comet distance during perihelion passage
   - Three time periods:
     * Forward approach (120 days before perihelion, daily intervals)
     * Near perihelion (32 days around perihelion, hourly intervals)
     * Later recession (post-perihelion period, daily intervals)
   - Outputs: Figure with three panels showing distance vs. time

## Requirements

### Software Dependencies
- MATLAB (tested with R2020a or later)
- NAIF SPICE Toolkit for MATLAB (CSPICE)
- multiplotyyy.m function (for ObsTimeline.m triple y-axis plotting)

### Data Dependencies
- SPICE kernel file: ROS_OPS_V330_20200731_001.TM
  * Contains spacecraft ephemeris, pointing, and planetary data
  * Required path: C:/Users/12605/Documents/Rosetta/SPICE/Kernels/kernels/mk/
  * Update path in scripts to match your local installation

### External Variables (for DistanceTile.m)
- UTC_list: Cell array of UTC time strings for observation times
- SCD: Array of spacecraft-comet distances at observation times
- These must be defined in workspace before running DistanceTile.m

## Usage

### Running ObsTimeline.m
```matlab
% Ensure SPICE kernels are loaded and accessible
run('ObsTimeline.m')
% Output: OBStimeline.csv and multi-axis plot
```

### Running DistanceTile.m
```matlab
% Define observation data first
UTC_list = {'2015-09-01T12:00:00.000', ...};
SCD = [150, 160, ...];

% Run script
run('DistanceTile.m')
% Output: Tiled distance plot
```

## Key Parameters

### Mission Constants
- Target comet: 67P/Churyumov-Gerasimenko (ID: '67P/C-G')
- Coordinate frame: 67P/C-G_CK (comet body-fixed)
- Camera: ROS_OSIRIS_NAC (OSIRIS Narrow Angle Camera)
- Perihelion: 2015-08-13 02:03:00 UTC

### Calculated Values
- Distances: km (spacecraft-comet), AU (sun-comet)
- Spatial resolution: m/pixel (based on 18.6 μm pixel size)
- Angles: degrees (latitude/longitude)

## Output Files

### OBStimeline.csv
Columns:
- id: Day index relative to perihelion
- datet: Date/time (ISO format)
- dn: NAC-comet distance [km]
- ds: Sun-comet distance [AU]
- ls: Subsolar latitude [degrees]
- res: Spatial resolution [m/pixel]

## Notes

### Coordinate Systems
- All positions calculated in comet body-fixed frame (67P/C-G_CK)
- Aberration correction: 'CN+S' (converged Newtonian + stellar aberration)

### Time Systems
- Input: UTC (human-readable)
- Internal: Ephemeris time (seconds since J2000 epoch)
- Output: ISO Calendar format (YYYY-MM-DDTHH:MM:SS.SSS)

### Boundaries and Limits
- Time range: -365 to +366 days from perihelion
- Distance range: 0-1600 km (typical for plotted periods)
- Solar distance: ~1.2-3.6 AU during mission
- Resolution: depends on spacecraft distance (typically meters to tens of meters per pixel)

## References
- NAIF SPICE Toolkit: https://naif.jpl.nasa.gov/naif/toolkit.html
- Rosetta Mission: https://www.esa.int/Science_Exploration/Space_Science/Rosetta

## Author
Rosetta Research Projects
Last Updated: 2026-01-27
