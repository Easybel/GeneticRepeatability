#!/usr/bin/env python3
"""
Shared colour and marker definitions for all plots — Genetic Repeatability paper.
Usage in other scripts:  from plot_config import colors_labNames, colors_treats, markers_weeks
"""

# ── Labs ──────────────────────────────────────────────────────────────────────
# gray, dark blue, bright blue, green, purple, reddish
lab_names   = ["UVA",     "Gent",    "VU",      "WUR",     "RUG",     "NIOO"   ]
lab_colors  = ["#BBBBBB", "#4477AA", "#66CCEE", "#228833", "#AA3377", "#EE6677"]
colors_labNames = dict(zip(lab_names, lab_colors))

# ── Treatments ────────────────────────────────────────────────────────────────
treat_names   = ["anc",     "bb",      "bn50",    "bn5",     "iso",     "bleach",  "A00",     "M00"    ]
treat_colors  = ["#000000", "#364B9A", "#F67E4B", "#A50026", "#C2E4EF", "#FEDA8B", "#6EA6CD", "#EAECCC"]
colors_treats = dict(zip(treat_names, treat_colors))

# ── Weeks / timepoints ────────────────────────────────────────────────────────
weeks         = [0,   1,   15 ]
week_markers  = ["o", "^", "s"]   # circle, triangle-up, square
markers_weeks = dict(zip(weeks, week_markers))