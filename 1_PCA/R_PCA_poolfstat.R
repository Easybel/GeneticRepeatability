# ============================================================
# Pool-seq PCA with poolfstat
# C. elegans multi-lab evolution experiment
#
# Input:  SNP VCF from bcftools mpileup + call -m
#         (produced by P_PCApipeline_poolfstat.sh)
# Output: PCA plots coloured by lab, treatment, week
# ============================================================

# -------------------------------------------------------
# 0. Packages
# -------------------------------------------------------
if (!requireNamespace("poolfstat",  quietly = TRUE)) install.packages("poolfstat")
if (!requireNamespace("ggplot2",    quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("ggrepel",    quietly = TRUE)) install.packages("ggrepel")
if (!requireNamespace("dplyr",      quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("patchwork",  quietly = TRUE)) install.packages("patchwork")

library(poolfstat)
library(ggplot2)
library(ggrepel)
library(dplyr)
library(patchwork)

# -------------------------------------------------------
# 1. Paths
# -------------------------------------------------------
vcf_file <- "/zfs/omics/projects/cevolution/1_CnemEvol/5_PCA_CnemAll/Cnem_AllSamples_mpileup_bcfcall.vcf.gz"
out_dir  <- "/zfs/omics/projects/cevolution/1_CnemEvol/5_PCA_CnemAll/outTemp"
out_name <- "CnemAll"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# -------------------------------------------------------
# 2. Sample metadata
#
# Pool names must EXACTLY match the sample names in the
# VCF header (check with: bcftools query -l your.vcf.gz).
# The names below are derived from the BAM filenames by
# stripping the suffix "_CE_2CE_sort_woDup_filt.bam".
# -------------------------------------------------------
library(vcfR)
vcf_header     <- read.vcfR(vcf_file, verbose=FALSE)
pool_names_raw <- colnames(vcf_header@gt)[-1]  # first column is FORMAT
pool_names     <- sub("_CE_2CE_sort_woDup_filt\\.bam$", "", basename(pool_names_raw))

# -------------------------------------------------------
# IMPORTANT: pool sizes (number of DIPLOID individuals per pool)
#
# Set this to the actual number of worms pooled per sample.
# If pool sizes differ between samples, provide a named
# vector matching pool_names. Example for 100 worms/pool:
# -------------------------------------------------------
pool_sizes <- rep(500, length(pool_names))   # <-- ADJUST TO YOUR EXPERIMENT
# does it assume sexual reproduction??

# -------------------------------------------------------
# 3. Read VCF into a poolfstat pooldata object
#
# vcf2pooldata() reads FORMAT/AD (allele depth counts) and
# applies initial coverage and MAF filters.
#
# min.cov.per.pool : minimum read depth per pool per SNP
# max.cov.per.pool : maximum read depth (excludes collapsed
#                   repeats / copy-number artefacts; a safe
#                   heuristic is ~2× the mean coverage)
# min.maf          : global minor allele frequency cutoff
# -------------------------------------------------------
cat("Reading VCF into poolfstat object...\n")

pooldata <- vcf2pooldata(
  vcf.file         = vcf_file,
  poolsizes        = pool_sizes,
  poolnames        = NA,
  min.cov.per.pool = 20,     # consistent with your DP20 filter
  max.cov.per.pool = 500,    # adjust to ~2x your mean coverage
  min.maf          = 0.05,   # remove very rare variants
  remove.indels    = TRUE,
  nlines.per.readblock = 1e6 # read in chunks; increase for faster machines
)

cat("pooldata summary:\n")
print(pooldata)
# Slots available:
#   pooldata@nsnp            : number of retained SNPs
#   pooldata@npools          : number of pools
#   pooldata@refallele.readcount : ref allele counts (nsnp x npools)
#   pooldata@readcoverage        : total coverage   (nsnp x npools)
#   pooldata@snp.info            : data frame with chr, pos, ref, alt

# -------------------------------------------------------
# 4. Build metadata table from pool names
#
# Name structure: {Lab}_{treatment}_{week}_{replicate}
# -------------------------------------------------------
meta <- data.frame(
  pool = pool_names,
  stringsAsFactors = FALSE
) %>%
  tidyr::separate(pool,
                  into = c("lab", "treatment", "week", "replicate"),
                  sep  = "_",
                  remove = FALSE) %>%
  mutate(
    week = as.integer(week),
    replicate  = as.integer(replicate),
    gen_label  = paste0("week", week),
    lab_treat  = paste(lab, treatment, sep = "_")
  )

# -------------------------------------------------------
# 5. Compute allele frequency matrix
#
# Each row = one pool, each column = one SNP
# freq = reference allele frequency (0–1)
# -------------------------------------------------------
freq_mat <- t(pooldata@refallele.readcount / pooldata@readcoverage)
# freq_mat is now npools × nsnp; rows are samples (pools)

cat(sprintf("Allele frequency matrix: %d pools × %d SNPs\n",
            nrow(freq_mat), ncol(freq_mat)))

# Sanity check: any pools with >10% missing data?
missing_frac <- rowMeans(is.na(freq_mat))
if (any(missing_frac > 0.10)) {
  warning("Some pools have >10% missing SNPs:\n")
  print(data.frame(pool = pool_names, missing = missing_frac) %>%
          filter(missing > 0.10) %>% arrange(desc(missing)))
}

# -------------------------------------------------------
# 6. PCA
#
# Mean-centre by SNP (column); do NOT scale (allele
# frequencies are already on a comparable scale).
# Missing values (low-coverage positions) are imputed
# with the column mean before PCA.
# -------------------------------------------------------
freq_imp <- freq_mat
col_means <- colMeans(freq_mat, na.rm = TRUE)
for (j in seq_len(ncol(freq_imp))) {
  nas <- is.na(freq_imp[, j])
  if (any(nas)) freq_imp[nas, j] <- col_means[j]
}

pca_res <- prcomp(freq_imp, center = TRUE, scale. = FALSE)

# Variance explained
pct_var <- round(100 * pca_res$sdev^2 / sum(pca_res$sdev^2), 2)

# Build plot data frame
pca_df <- as.data.frame(pca_res$x[, 1:5]) %>%
  mutate(pool = pool_names) %>%
  left_join(meta, by = "pool")

cat("Variance explained by first 5 PCs:\n")
cat(paste0("  PC", 1:5, ": ", pct_var[1:5], "%\n"), sep = "")

# -------------------------------------------------------
# 7. Plots
# -------------------------------------------------------

# --- colour palettes ---
lab_colours <- c(
  Gent = "#E69F00", NIOO = "#56B4E9", RUG = "#009E73",
  UVA  = "#F0E442", VU   = "#0072B2", WUR = "#D55E00"
)
gen_shapes <- c(`0` = 21, `1` = 22, `15` = 24)  # circle, square, triangle

theme_pca <- theme_bw(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        legend.position  = "right")

# --- Plot A: PC1 vs PC2, coloured by lab ---
pA <- ggplot(pca_df, aes(x = PC1, y = PC2,
                         fill = lab,
                         shape = factor(week),
                         label = pool)) +
  geom_point(size = 3.5, colour = "grey30", stroke = 0.4) +
  geom_text_repel(size = 2.5, max.overlaps = 15, colour = "grey20") +
  scale_fill_manual(values = lab_colours, name = "Lab") +
  scale_shape_manual(values = gen_shapes, name = "Week") +
  guides(fill = guide_legend(override.aes = list(shape = 21, size = 4))) +
  labs(x = paste0("PC1 (", pct_var[1], "%)"),
       y = paste0("PC2 (", pct_var[2], "%)"),
       title = "PCA — coloured by lab") +
  theme_pca

# --- Plot B: PC1 vs PC2, coloured by treatment ---
treat_colours <- c(
  bb     = "#1b9e77", iso    = "#d95f02", bn50   = "#7570b3",
  bn5    = "#e7298a", bleach = "#66a61e", anc    = "#a6761d",
  A00    = "#e6ab02", M00    = "#666666"
)

pB <- ggplot(pca_df, aes(x = PC1, y = PC2,
                         fill = treatment,
                         shape = factor(week))) +
  geom_point(size = 3.5, colour = "grey30", stroke = 0.4) +
  scale_fill_manual(values = treat_colours, name = "Treatment") +
  scale_shape_manual(values = gen_shapes, name = "Week") +
  guides(fill = guide_legend(override.aes = list(shape = 21, size = 4))) +
  labs(x = paste0("PC1 (", pct_var[1], "%)"),
       y = paste0("PC2 (", pct_var[2], "%)"),
       title = "PCA — coloured by treatment") +
  theme_pca

# --- Plot C: PC1 vs PC3 ---
pC <- ggplot(pca_df, aes(x = PC1, y = PC3,
                         fill = lab,
                         shape = factor(week))) +
  geom_point(size = 3.5, colour = "grey30", stroke = 0.4) +
  scale_fill_manual(values = lab_colours, name = "Lab") +
  scale_shape_manual(values = gen_shapes, name = "Week") +
  guides(fill = guide_legend(override.aes = list(shape = 21, size = 4))) +
  labs(x = paste0("PC1 (", pct_var[1], "%)"),
       y = paste0("PC3 (", pct_var[3], "%)"),
       title = "PCA — PC1 vs PC3") +
  theme_pca

# --- Plot D: scree plot ---
scree_df <- data.frame(PC  = factor(1:10, levels = 1:10),
                       pct = pct_var[1:10])
pD <- ggplot(scree_df, aes(x = PC, y = pct)) +
  geom_col(fill = "steelblue3", colour = "white", width = 0.7) +
  geom_line(aes(group = 1), colour = "grey30") +
  geom_point(colour = "grey30") +
  labs(x = "Principal component", y = "Variance explained (%)",
       title = "Scree plot") +
  theme_pca

# --- Save combined figure ---
combined <- (pA | pB) / (pC | pD)

ggsave(
  filename = file.path(out_dir, paste0(out_name, "_poolfstat_4Nov26.pdf")),
  plot     = combined,
  width    = 16,
  height   = 13,
  device   = "pdf"
)
ggsave(
  filename = file.path(out_dir, paste0(out_name, "_poolfstat_4Nov26.png")),
  plot     = combined,
  width    = 16,
  height   = 13,
  dpi      = 200
)

cat("Plots saved to:", out_dir, "\n")

# -------------------------------------------------------
# 8. Save PCA coordinates for downstream use
# -------------------------------------------------------
write.csv(
  pca_df,
  file      = file.path(out_dir, paste0(out_name, "_coordinates_poolfstat_4Nov26.csv")),
  row.names = FALSE
)

# Save the pooldata object for reuse (e.g. pairwise FST)
saveRDS(
  pooldata,
  file = file.path(out_dir, paste0(out_name, "_pooldata_object_4Nov26.rds"))
)

# -------------------------------------------------------
# 9. Optional: pairwise FST matrix (useful for AMOVA,
#    Mantel tests, or a distance-based PCoA)
# -------------------------------------------------------
# Uncomment to compute — can take a few minutes for many SNPs
#
# fst_mat <- compute.pairwiseFST(pooldata,
#                                method = "Anova",   # or "Rousset"
#                                nsnp.per.bjack.block = 500)
# saveRDS(fst_mat, file = file.path(out_dir, "pairwiseFST.rds"))
#
# # PCoA on the FST distance matrix
# pcoa_res <- cmdscale(as.dist(fst_mat@PairwiseFSTmatrix), k = 4)
# pcoa_df  <- as.data.frame(pcoa_res)
# colnames(pcoa_df) <- paste0("PCo", 1:4)
# pcoa_df$pool <- pool_names
