# Digital Elevation Model (DEM) Algorithm Framework

This document describes the DEM algorithm framework used in this Rosetta research project for analyzing comet 67P/Churyumov-Gerasimenko.

## Overview

The DEM (Digital Elevation Model) framework in this repository integrates SPICE/DSK (Digital Shape Kernel) data with observational geometry calculations to support terrain analysis of comet 67P. The framework enables:

- Shape model representation and manipulation
- Surface point calculations
- Observation geometry computation
- Distance and resolution analysis

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEM Algorithm Framework                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ SPICE Kernel │    │ Shape Model  │    │ Observation  │       │
│  │   Loading    │───▶│  Processing  │───▶│  Geometry    │       │
│  │              │    │   (DSK)      │    │ Calculation  │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                   │                │
│         ▼                   ▼                   ▼                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Ephemeris   │    │   Surface    │    │  Timeline    │       │
│  │    Data      │    │ Intercepts   │    │  Analysis    │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. SPICE Kernel Integration

The framework uses NASA's SPICE toolkit via MATLAB's `cspice` interface:

```matlab
cspice_furnsh('ROS_OPS_V330_20200731_001.TM')
```

**Meta-kernel contents include:**
- SPK (Spacecraft and Planet Kernel): Ephemeris data
- CK (C-Kernel): Orientation data
- DSK (Digital Shape Kernel): 67P shape model
- FK (Frame Kernel): Reference frame definitions
- PCK (Planetary Constants Kernel): Physical constants

### 2. Coordinate Systems

| Frame Name | Description |
|------------|-------------|
| `67P/C-G_CK` | Body-fixed coordinate system centered on comet 67P |
| `J2000` | Inertial reference frame |
| `ROS_OSIRIS_NAC` | OSIRIS Narrow Angle Camera frame |

### 3. Shape Model Processing

The 67P shape model (`67P_shape_model_2M.mat`) is a triangulated mesh representing the comet's surface:

```
Shape Model Structure:
├── Vertices: 3D coordinates of mesh nodes
├── Faces: Triangular facet definitions
├── Normals: Surface normal vectors per facet
└── Properties: Area, centroid per facet
```

**Resolution:** Approximately 2 million facets for high-fidelity surface representation.

## Algorithm Details

### Distance Calculation Algorithm

The framework computes spacecraft-to-comet distances using SPICE ephemeris:

```matlab
% Get camera position relative to comet in body-fixed frame
[cam_pos, ~] = cspice_spkezr(camera, et, CGframe, 'CN+S', target);

% Calculate Euclidean distance
D = sqrt(sum((cam_pos(1:3,:)).^2, 1));
```

**Light-time correction:** `CN+S` (Converged Newtonian + Stellar aberration)

### Subsolar Point Algorithm

Surface intercept calculations use DSK for terrain-aware computations:

```matlab
[sunp, ~, ~] = cspice_subslr('Intercept/DSK/Unprioritized', target, et, CGframe, 'CN+S', target);
```

**Algorithm steps:**
1. Compute Sun-to-comet vector at specified epoch
2. Trace ray from Sun toward comet center
3. Find first intersection with DSK surface model
4. Return subsolar point coordinates in body-fixed frame

### Coordinate Conversion

Conversion from Cartesian to planetographic coordinates:

```matlab
function [sunlon, sunlat] = sunrec2lat(sunp)
    [sunlon, sunlat] = cart2sph(sunp(1), sunp(2), sunp(3));
    sunlon = sunlon / pi * 180;  % Convert to degrees
    sunlat = sunlat / pi * 180;
    if sunlon < 0
        sunlon = sunlon + 360;   % Normalize longitude [0, 360]
    end
end
```

### Resolution Calculation

Image resolution is derived from distance and camera parameters:

```matlab
pxsize = 18.6e-6;  % OSIRIS NAC pixel size (m)
res_nac = d_nac * pxsize * 1000;  % Resolution (m/px)
```

## Data Flow

```
Input Data                    Processing                     Output
───────────────────────────────────────────────────────────────────
SPICE Kernels ───────────┐
                         ├──▶ Ephemeris Query ──▶ Position/Velocity
Shape Model  ────────────┤
                         ├──▶ DSK Intercept  ──▶ Surface Points
Time Range   ────────────┤
                         └──▶ Timeline Gen   ──▶ CSV/Plots
```

## Time Domain Analysis

The framework supports multi-resolution temporal analysis:

| Period | Interval | Purpose |
|--------|----------|---------|
| Pre-perihelion | 1 day | Long-term approach monitoring |
| Perihelion ± 1 month | 1 hour | High-cadence activity monitoring |
| Post-perihelion | 1 day | Long-term recession monitoring |

**Perihelion reference:** 2015-08-13T02:03:00.0 UTC

## Output Products

### 1. Distance Timeline
- Spacecraft-comet distance over mission duration
- Temporal resolution: configurable (hour/day)

### 2. Solar Geometry
- Sun-comet distance (AU)
- Subsolar latitude evolution

### 3. Image Resolution
- Per-pixel ground sampling distance
- Function of spacecraft altitude

### 4. Visualization
- Tiled layout for comprehensive timeline view
- Perihelion markers and event annotations

## File Structure

```
observations/
├── DistanceTile.m     # Distance visualization with perihelion context
├── ObsTimeline.m      # Complete observation parameter timeline
└── readme.txt         # Module description
```

## Dependencies

| Component | Version | Purpose |
|-----------|---------|---------|
| MATLAB | R2019b+ | Execution environment |
| MICE (SPICE) | N66+ | Ephemeris computations |
| DSK Toolkit | 2.0+ | Shape model queries |

## Usage Example

```matlab
% 1. Load SPICE kernels
cspice_furnsh('kernels/mk/ROS_OPS.TM');

% 2. Define time range
et = cspice_str2et('2015-08-13T02:03:00.0') + (-365:366)*86400;

% 3. Query spacecraft position
[cam_pos, ~] = cspice_spkezr('ROS_OSIRIS_NAC', et, '67P/C-G_CK', 'CN+S', '67P/C-G');

% 4. Calculate distance
d_nac = sqrt(sum((cam_pos(1:3,:)).^2, 1));

% 5. Compute subsolar point for each epoch
for i = 1:length(et)
    [sunp, ~, ~] = cspice_subslr('Intercept/DSK/Unprioritized', '67P/C-G', et(i), ...
                                  '67P/C-G_CK', 'CN+S', '67P/C-G');
    [lon(i), lat(i)] = cart2sph(sunp(1), sunp(2), sunp(3));
end
```

## Future Extensions

1. **DEM Generation Pipeline**
   - Stereophotogrammetry from OSIRIS images
   - Shape-from-shading enhancement
   - Multi-resolution mesh generation

2. **Terrain Analysis**
   - Slope and aspect calculation
   - Surface roughness metrics
   - Viewshed analysis for observation planning

3. **Thermal Modeling Integration**
   - Cumulative insolation computation
   - Surface temperature estimation
   - Volatile outgassing prediction

## References

1. SPICE Toolkit Documentation: https://naif.jpl.nasa.gov/naif/toolkit.html
2. Rosetta SPICE Kernels: ESA PSA Archive
3. 67P Shape Model: Preusker et al. (2017), A&A 607, L1
