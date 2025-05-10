
# 🛫 Air Traffic Simulation Framework

This MATLAB-based simulation framework is an open-source, modular toolkit for testing automated Air Traffic Control (ATC) algorithms in both real and simulated environments. It is designed to support realistic and repeatable evaluation of ATC automation technologies using real-world ADS-B data.

---

## 🧠 Key Features

- **Two-layer architecture**:
  - *Simulation Layer*: loads, predicts, and simulates traffic data.
  - *Control Layer*: handles pilot-controller interactions and control logic.
  
- **Real-world traffic data integration**:
  - Supports historical and real-time ADS-B sources (e.g., [ADS-B Exchange](https://www.adsbexchange.com)).

- **Traffic prediction using simplified motion models**.

- **Operational modes**:
  1. *Data Collection* – record raw ADS-B data.
  2. *Traffic Estimation* – forecast sector load and flow.
  3. *Control Mode* – simulate controlled airspace with ATC logic.

- **Research applications**:
  - Sectorization
  - Flow management
  - Controller workload estimation
  - Safety impact analysis

---

## 🛠️ Requirements

- MATLAB (Recommended: R2021b or later)
- **Toolboxes**:
  - Mapping Toolbox
  - Aerospace Toolbox

---

## 📁 Project Structure

```text
air-traffic-simulation/
├── data/             # ADS-B data (.mat, .geojson)
├── src/              # MATLAB scripts and core functions
└── README.md
```

---

## 🚀 Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/username/repo-name.git
   cd repo-name
   ```

2. **Prepare input data:**
   - Download historical ADS-B data from [ADS-B Exchange](https://www.adsbexchange.com) as `.mat` using loadHistorical function.
   - Or use live API with API_request function.

3. **Run the simulation in MATLAB:**
   - Open `src/simulation.m` or `src/script_one_iteration.m`.
   - Execute the script in MATLAB.

---

## 📈 Case Study Example

As featured in the article:
- Date: April 1, 2025 (06:56–12:11 GMT)
- Data source: ADS-B Exchange (archived)
- Airspace: Hungarian FIR
- Resolution: 5 seconds
- Controller logic:
  - Accepts all pilot requests.
  - Horizontal conflict: apply 30° left turn.
  - Vertical conflict: instruct upper aircraft to climb.

**Measured KPIs:**
- Number of separation minima infringements.
- Number of ATC instructions issued.
- Total aircraft count within the sector.

---

## 🧩 Extensibility

The framework is fully modular and extensible:
- Custom control algorithms can be integrated via defined interfaces.
- Aircraft motion models can be refined.
- Machine learning and random traffic generators are supported.

---

## 📚 Citation

> Rebeka Anna Jáger, Géza Szabó (2024): *Air Traffic Simulation Framework for Testing Automated Air Traffic Control Solutions*. Applied Sciences. [DOI]

---

## 📜 License

MIT License
