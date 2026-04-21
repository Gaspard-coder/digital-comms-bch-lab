# 📡 digital-comms-bch-lab

MATLAB simulation of a full digital communications chain — BCH channel coding, BPSK/8-QAM/16-QAM modulations, ZF/DFE equalization over AWGN and multipath channels.

*Télécom Paris — Digital Communications Project, D1, 2025-2026*

---

## Project overview

End-to-end single-carrier transmission system implementing:
- **BCH coding** over GF(2⁵), codeword length N=31 — two codes: BCH1 (t=1, k=26) and BCH2 (t=2, k=21)
- **Modulations**: BPSK, 8-QAM, 16-QAM
- **Channels**: AWGN + 3 multipath channels with raised cosine Nyquist filter (ρ=0.5)
- **Equalizers**: threshold detector, Zero-Forcing (ZF), Decision-Feedback (DFE)
- **Metrics**: BER vs Eb/N0, theoretical throughput T vs Es/N0 for 9 MCS configurations

---

## Repository structure

```
digital-comms-bch-lab/
│
├── bch/                            # BCH encoding & decoding
│   ├── Encoder_example_t1.m
│   ├── Encoder_example_t2.m
│   ├── Decoder_t1.m / Decoder_t1_batch.m
│   ├── Decoder_t2.m / Decoder_t2_batch.m
│   ├── build_syndrome_table_t1.m / build_syndrome_table_t2.m
│   ├── compute_crc.m / compute_crc_fast.m
│   ├── shift_register_modulo.m
│   └── verify_modulo.m
│
├── modulation/                     # Bit-symbol conversion & constellations
│   ├── bits2symbols.m
│   ├── symbols2bits.m
│   └── symbols_lut.m
│
├── channel/                        # Channel models & Nyquist filter
│   ├── nyquist.m
│   ├── response_channel.m
│   └── d4_students.m
│
├── equalization/                   # Detectors & equalizers
│   └── threshold_detector.m
│
├── performance/                    # BER & throughput plots
│   ├── BPSK_performance_plotting.m
│   ├── BCH1_performance_plotting.m / BCH1_performance_plotting_fast.m
│   ├── BCH2_performance_plotting_fast.m
│   ├── BPSK_equalizer_plotting.m
│   ├── BPSK_coded_equalizer_plotting.m
│   ├── QAM8_equalizer_plotting.m
│   ├── QAM16_equalizer_plotting.m
│   └── plot_theoretical_throughput_mcs.m
│
└── main.m                          # Entry point
```

---

## Usage

```matlab
% Add all folders to path and run
addpath(genpath('.'))
main
```

---

## Key parameters

| Parameter | Value |
|---|---|
| Symbol period Ts | 0.05 µs |
| Codeword length n | 31 |
| BCH1 (t=1 error) | k=26, rate 26/31 |
| BCH2 (t=2 erros) | k=21, rate 21/31 |
| Frame size N | 100 symbols |
| Nyquist roll-off ρ | 0.5 |

---
