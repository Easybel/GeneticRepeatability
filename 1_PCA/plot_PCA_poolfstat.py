#!/usr/bin/env python3
"""
PCA plot with 95% confidence ellipses for poolSeq C. elegans data.

Input:  CSV with columns PC1–PC5, pool, lab, treatment, week,
        replicate, gen_label, lab_treat
Output: one PDF/PNG per plot
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import Ellipse
from scipy.stats import chi2

import sys
sys.path.append("/home/isabel/Documents/postDoc_Amsterdam/B_BioInfo/1_MyScripts/GitHub/GeneticRepeatability/")
from plot_config import colors_labNames, colors_treats, markers_weeks

# =============================================================================
# SETTINGS — edit these to change the plot
# =============================================================================

basePath = "/home/isabel/Documents/postDoc_Amsterdam/1_EvolWormJourney/1_Genomics/2_EvolGenomics/1_Dev_PipelineCelegans/2_PCA_AllSamples/"
CSV_FILE   = basePath + "O_output_rawR/CnemAll_wo23Samples_coordinates_poolfstat_5Nov26.csv"
OUT_PREFIX = basePath + "O_plots/PCA_CnemAll_wo23Samples"  # output base name (no extension)
OUT_FORMAT = "svg"                                # "pdf" or "png"

# Which PCs to put on the axes
X_PC = "PC1"
Y_PC = "PC2"

X_PC_perc = "7"
Y_PC_perc = "6"

# Column used for colouring and ellipses
# Options: "lab", "treatment", "week", "gen_label", "lab_treat"
GROUP_BY = "treatment"

# Confidence level for the ellipses
CONF_LEVEL = 0.95

# Show the pool name next to each point?
LABEL_POINTS = True

# Point size and transparency
POINT_SIZE  = 90
POINT_ALPHA = 0.5

# Pick palette to match GROUP_BY
COLOR_PALETTE = colors_labNames if GROUP_BY == "lab" else colors_treats


# =============================================================================
# FUNCTIONS
# =============================================================================

def confidence_ellipse(x, y, ax, conf=0.95, **kwargs):
    """
    Draw a 2D confidence ellipse for points (x, y) on matplotlib axis ax.

    Uses eigendecomposition of the 2×2 covariance matrix, scaled by the
    chi-squared quantile for the requested confidence level.
    Requires at least 3 points; skips silently otherwise.
    """
    if len(x) < 3:
        print(f"  [skipping ellipse — fewer than 3 points]")
        return

    cov = np.cov(x, y)
    eigenvalues, eigenvectors = np.linalg.eigh(cov)

    # chi2 scale factor (2 degrees of freedom = 2D ellipse)
    scale  = np.sqrt(chi2.ppf(conf, df=2))
    width  = 2 * scale * np.sqrt(eigenvalues[1])  # major axis
    height = 2 * scale * np.sqrt(eigenvalues[0])  # minor axis
    angle  = np.degrees(np.arctan2(eigenvectors[1, 1], eigenvectors[0, 1]))

    ellipse = Ellipse(
        xy=(np.mean(x), np.mean(y)),
        width=width, height=height, angle=angle,
        **kwargs
    )
    ax.add_patch(ellipse)


# =============================================================================
# MAIN
# =============================================================================

# --- 1. Load data ------------------------------------------------------------
df = pd.read_csv(CSV_FILE)
print(f"Loaded {len(df)} samples, columns: {list(df.columns)}")

# Quick check
assert X_PC in df.columns, f"Column '{X_PC}' not found in CSV"
assert Y_PC in df.columns, f"Column '{Y_PC}' not found in CSV"
assert GROUP_BY in df.columns, f"Column '{GROUP_BY}' not found in CSV"

# --- 2. Plot -----------------------------------------------------------------
#groups = sorted(df[GROUP_BY].unique(), key=str)
fig, ax = plt.subplots(figsize=(8, 7))
legend_handles = []

for (c, week), subset in df.groupby([GROUP_BY, "week"]):
    color  = COLOR_PALETTE.get(c,   "#888888")
    marker = markers_weeks.get(week,  "o")        # fallback to circle

    ax.scatter(
        subset[X_PC], subset[Y_PC],
        color=color, marker=marker,
        s=POINT_SIZE, alpha=POINT_ALPHA,
         edgecolors="black", linewidths=0.5,
        zorder=3
    )

    # Optional point labels
    if (c == "bn5"):## | (c == "bn50"):
        if LABEL_POINTS:
            for _, row in subset.iterrows():
                ax.text(row[X_PC] + row[X_PC]*0.04, row[Y_PC] + row[Y_PC]*0.01, row["replicate"],
                        fontsize=14, ha="left", va="bottom", color=color)

# 95% confidence ellipse
for c, subset in df.groupby(GROUP_BY):
    if c != "bn5":
        color = COLOR_PALETTE.get(c, "#888888")   # ← add this
        confidence_ellipse(
            subset[X_PC].values, subset[Y_PC].values, ax,
            conf=CONF_LEVEL,
            edgecolor=color, facecolor="none",
            alpha=0.9, linewidth=2, zorder=4
        )

# Axes and labels
ax.set_xlabel(X_PC + ' (' + X_PC_perc + '%)', fontsize=13)
ax.set_ylabel(Y_PC + ' (' + Y_PC_perc + '%)', fontsize=13)
ax.axhline(0, color="grey", linewidth=0.5, linestyle="--")
ax.axvline(0, color="grey", linewidth=0.5, linestyle="--")
# Two separate legends: one for lab colours, one for treatment markers
lab_handles = [mpatches.Patch(color=COLOR_PALETTE.get(c, "#888888"), label=c)
               for c in df[GROUP_BY].unique()]
treat_handles = [plt.Line2D([0], [0], marker=markers_weeks.get(t, "o"),
                             color="grey", linestyle="None",
                             markersize=7, label=t)
                 for t in sorted(df["week"].unique())]   # ← sorted()

leg1 = ax.legend(handles=lab_handles,   title=GROUP_BY,
                 bbox_to_anchor=(1.02, 1),    loc="upper left", frameon=False)
leg2 = ax.legend(handles=treat_handles, title="week",
                 bbox_to_anchor=(1.02, 0.4),  loc="upper left", frameon=False)
ax.add_artist(leg1)  # needed because the second legend() call replaces the first

plt.tight_layout()

# --- 3. Save -----------------------------------------------------------------
out_file = f"{OUT_PREFIX}_{GROUP_BY}_{X_PC}vs{Y_PC}.{OUT_FORMAT}"
plt.savefig(out_file, dpi=200, bbox_inches="tight")
print(f"Saved: {out_file}")
plt.show()