# 🫀 Mesure App

**Camera-based vitals monitoring for individuals with cognitive impairment**

A Flutter application that uses smartphone camera photoplethysmography (PPG) to non-invasively measure:
- ❤️ Heart Rate (BPM)
- 🩸 Blood Pressure (Systolic / Diastolic — estimated)
- 🫁 SpO2 / Blood Oxygen Saturation
- 📊 Heart Rate Variability (SDNN, RMSSD, pNN50, LF/HF ratio)

---

## 📱 How It Works

### PPG Principle
When you place your fingertip over the phone's rear camera with the flash/torch on, the light passes through your fingertip and is captured by the camera. Blood absorbs more red light when your heart contracts (systole) and less when it relaxes (diastole). This creates a measurable pulsatile variation in the red channel pixel intensity — the PPG signal.

### Signal Pipeline

```
Camera Frame (YUV420 / BGRA8888)
    ↓
ROI Extraction (60×60 central pixels)
    ↓
RGB Channel Averaging
    ↓
Bandpass Filter (0.5 – 4.0 Hz IIR)
    ↓
Adaptive Peak Detection (Pan-Tompkins inspired)
    ↓
RR Interval Series
    ↓
┌──────────────────┬──────────────┬─────────────────┬──────────┐
│  Heart Rate      │    HRV       │  Blood Pressure  │  SpO2    │
│  (BPM)           │  (ms/%)      │  (regression)    │  (RoR)   │
└──────────────────┴──────────────┴─────────────────┴──────────┘
```

---

## 🧮 Algorithms

### 1. Signal Filtering
- **High-pass IIR** (fc = 0.5 Hz): Removes DC offset and slow baseline drift
- **Low-pass IIR** (fc = 4.0 Hz): Removes noise above 240 BPM — clean physiological range

### 2. Peak Detection
Adaptive threshold based on:
```
threshold = mean + 0.4 × std_dev(signal)
```
With minimum inter-peak distance of 400 ms (prevents double-counting, max 150 BPM).

### 3. Heart Rate
```
HR (BPM) = 60,000 / mean(RR_intervals_ms)
```

### 4. HRV — Time Domain
| Metric | Formula | Normal Range |
|--------|---------|-------------|
| SDNN | √( Σ(RRᵢ − RR̄)² / N ) | 50–100 ms (good) |
| RMSSD | √( Σ(RRᵢ₊₁ − RRᵢ)² / (N−1) ) | > 20 ms |
| pNN50 | 100 × count(|ΔRR| > 50ms) / (N−1) | > 3% normal |

### 5. HRV — Frequency Domain (LF/HF)
RR series is resampled to 4 Hz via linear interpolation, then a discrete DFT is applied:
```
LF power = Σ |X(k)|² for k where freq ∈ [0.04, 0.15) Hz
HF power = Σ |X(k)|² for k where freq ∈ [0.15, 0.40] Hz
LF/HF ratio = LF / HF
```
- LF/HF < 1.5 → Parasympathetic dominance (calm/recovery)
- LF/HF 1.5–4 → Balanced autonomic state
- LF/HF > 4 → Sympathetic dominance (stress/activity)

### 6. Blood Pressure Estimation (Wellness Grade)
Based on PPG waveform feature regression (Elgendi 2019, Chowdhury 2020):

```
SI (Stiffness Index) = 170 cm / time_to_inflection_point (seconds)

SBP ≈ 0.5 × SI + 0.02 × HR − 0.1 × RMSSD + 95
DBP ≈ 0.3 × SI + 0.01 × HR − 0.05 × RMSSD + 60
```

**Important:** This is a wellness estimate, not a clinical measurement. Accurate cuffless BP measurement requires user-specific calibration.

### 7. SpO2 — Ratio-of-Ratios
Beer-Lambert approximation using red and blue channels:
```
R = (AC_red / DC_red) / (AC_blue / DC_blue)
SpO2 ≈ 110 − 25 × R
```
Empirical constants (A=110, B=25) from Nitzan et al.

### 8. Signal Quality Assessment
Coefficient of variation (CV) metric:
```
Quality = f(CV) × 0.6 + HR_physiological_score × 0.4
```
Results with quality < 50% show a warning. Measurements < 30% are discarded.

---

## 🏗️ Architecture

```
lib/
├── main.dart                  # App entry, camera init
├── utils/
│   └── app_theme.dart         # Design system, colors
├── services/
│   ├── ppg_processor.dart     # All signal processing & algorithms
│   └── history_service.dart   # SharedPreferences persistence
├── widgets/
│   ├── ppg_waveform_widget.dart  # Live animated PPG chart
│   └── vital_card.dart           # Vital display components
└── screens/
    ├── home_screen.dart       # Dashboard with last reading
    ├── measurement_screen.dart # Camera PPG capture
    ├── results_screen.dart    # Full results with charts
    └── history_screen.dart    # Trend history & charts
```

---

## 🚀 Setup & Run

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Android Studio / Xcode
- Physical device (camera PPG doesn't work on simulator)

### Install & Run
```bash
cd mesure_app
flutter pub get
flutter run --release   # Release mode for better camera performance
```

### Android Minimum SDK
Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### iOS Minimum Version
In `ios/Podfile`:
```ruby
platform :ios, '14.0'
```

---

## 📦 Dependencies

| Package | Use |
|---------|-----|
| `camera` | Camera frame stream & torch control |
| `fl_chart` | RR tachogram & trend charts |
| `shared_preferences` | Local measurement history |
| `wakelock_plus` | Prevent screen sleep during 30s measurement |
| `permission_handler` | Camera & storage permission requests |
| `vibration` | Haptic feedback on measurement complete |
| `intl` | Date formatting for history |

---

## 🎨 Design System

- **Background:** `#0D1B2A` (deep navy)
- **Primary:** `#00C2CB` (medical teal)
- **Accent:** `#FF6B6B` (coral — alerts/heart)
- **Success:** `#06D6A0` (green)
- **Warning:** `#FFD166` (gold)

Designed for cognitive accessibility:
- High contrast ratios (≥ 4.5:1 WCAG AA)
- Large, clear numerals (36–56px for vital readings)
- Emoji status indicators for quick comprehension
- Simple 4-step instructions with visual icons

---

## ⚠️ Medical Disclaimer

This application is a **wellness monitoring tool** and is **NOT a medical device**. It does not meet the requirements of any medical device standard (FDA, CE, ISO 13485).

- Blood pressure estimates are derived from PPG waveform features and have **±15–20 mmHg error** without personal calibration
- SpO2 estimates are **not clinically validated** and should not be used for medical diagnosis
- HRV values are useful for trend monitoring but not equivalent to medical ECG-derived HRV

**Always consult a qualified healthcare professional for medical decisions.**

---

## 📚 References

1. Peng R et al. (2015). Extraction of HRV from Smartphone PPGs. *Computational Mathematical Methods in Medicine*.
2. Elgendi M et al. (2019). The use of photoplethysmography for assessing hypertension. *NPJ Digital Medicine*.
3. Nitzan M et al. (2014). Pulse oximetry: fundamentals and technology update. *Medical Devices*.
4. Allen J. (2007). Photoplethysmography and its application in clinical physiological measurement. *Physiological Measurement*.
