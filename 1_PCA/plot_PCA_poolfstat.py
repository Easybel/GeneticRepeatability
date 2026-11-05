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

# =============================================================================
# SETTINGS — edit these to change the plot
# =============================================================================

CSV_FILE   = "O_output/CnemAll_wo13Samples_coordinates_poolfstat_5Nov26.csv"
OUT_PREFIX = "O_output/PCA_CnemAll_wo13Samples"  # output base name (no extension)
OUT_FORMAT = "pdf"                                # "pdf" or "png"

# Which PCs to put on the axes
X_PC = "PC1"
Y_PC = "PC2"

# Column used for colouring and ellipses
# Options: "lab", "treatment", "week", "gen_label", "lab_treat"
GROUP_BY = "lab"

# Confidence level for the ellipses
CONF_LEVEL = 0.95

# Show the pool name next to each point?
LABEL_POINTS = False

# Point size and transparency
POINT_SIZE  = 60
POINT_ALPHA = 0.85

# Colour palette — one colour per group value
# Add or change colours freely; unknown groups fall back to grey
PALETTE = {
    # Labs
    "Gent": "#E63946",
    "UVA":  "#457B9D",
    "VU":   "#2A9D8F",
    "NIOO": "#E9C46A",
    "RUG":  "#F4A261",
    "WUR":  "#6A4C93",
    # Treatments (used when GROUP_BY = "treatment")
    "bb":     "#E63946",
    "anc":    "#457B9D",
    "iso":    "#2A9D8F",
    "A00":    "#E9C46A",
    "M00":    "#F4A261",
    "bn50":   "#6A4C93",
    "bn5":    "#264653",
    "bleach": "#A8DADC",
    # Weeks / gen_label (used when GROUP_BY = "week" or "gen_label")
    0:        "#E9C46A",
    1:        "#E63946",
    15:       "#264653",
    "week0":  "#E9C46A",
    "week1":  "#E63946",
    "week15": "#264653",
}

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
groups = sorted(df[GROUP_BY].unique(), key=str)
fig, ax = plt.subplots(figsize=(8, 7))
legend_handles = []

for group in groups:
    subset = df[df[GROUP_BY] == group]
    color  = PALETTE.get(group, "#888888")  # grey if group not in palette

    # Scatter points
    ax.scatter(
        subset[X_PC], subset[Y_PC],
        color=color, s=POINT_SIZE, alpha=POINT_ALPHA,
        zorder=3
    )

    # Optional point labels
    if LABEL_POINTS:
        for _, row in subset.iterrows():
            ax.text(row[X_PC], row[Y_PC], row["pool"],
                    fontsize=5, ha="left", va="bottom", color=color)

    # 95% confidence ellipse
    confidence_ellipse(
        subset[X_PC].values, subset[Y_PC].values, ax,
        conf=CONF_LEVEL,
        edgecolor=color, facecolor=color,
        alpha=0.15, linewidth=1.5, zorder=2
    )

    legend_handles.append(mpatches.Patch(color=color, label=str(group)))

# Axes and labels
ax.set_xlabel(X_PC, fontsize=13)
ax.set_ylabel(Y_PC, fontsize=13)
ax.set_title(f"PCA — coloured by {GROUP_BY}", fontsize=14)
ax.axhline(0, color="grey", linewidth=0.5, linestyle="--")
ax.axvline(0, color="grey", linewidth=0.5, linestyle="--")
ax.legend(
    handles=legend_handles, title=GROUP_BY,
    bbox_to_anchor=(1.02, 1), loc="upper left", frameon=False
)

plt.tight_layout()

# --- 3. Save -----------------------------------------------------------------
out_file = f"{OUT_PREFIX}_{GROUP_BY}_{X_PC}vs{Y_PC}.{OUT_FORMAT}"
plt.savefig(out_file, dpi=200, bbox_inches="tight")
print(f"Saved: {out_file}")
plt.show()
