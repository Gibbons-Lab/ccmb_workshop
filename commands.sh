#!/usr/bin/env bash
#file: docs/talk.md
#extracted 2018-12-07 13:03:45.450991

source activate qiime2-2018.11

# use `\` to break up long lines
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path ubc_manifest.csv \
  --output-path ubc_data.qza \
  --input-format SingleEndFastqManifestPhred33

qiime demux summarize --i-data ubc_data.qza --o-visualization qualities.qzv

qiime dada2 denoise-single \
    --i-demultiplexed-seqs ubc_data.qza \
    --p-trunc-len 220 --p-trim-left 10 \
    --output-dir dada2 --verbose

qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences dada2/representative_sequences.qza \
    --output-dir tree

qiime diversity core-metrics-phylogenetic \
    --i-table dada2/table.qza \
    --i-phylogeny tree/rooted_tree.qza \
    --p-sampling-depth 8000 \
    --m-metadata-file samples.tsv \
    --output-dir diversity

qiime diversity alpha-group-significance \
    --i-alpha-diversity diversity/shannon_vector.qza \
    --m-metadata-file samples.tsv \
    --o-visualization diversity/alpha_groups.qzv

qiime feature-classifier classify-sklearn \
    --i-reads dada2/representative_sequences.qza \
    --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
    --o-classification taxa.qza

qiime taxa barplot \
    --i-table dada2/table.qza \
    --i-taxonomy taxa.qza \
    --m-metadata-file samples.tsv \
    --o-visualization taxa_barplot.qzv

qiime taxa collapse \
    --i-table dada2/table.qza \
    --i-taxonomy taxa.qza \
    --p-level 6 \
    --o-collapsed-table genus.qza

qiime composition add-pseudocount --i-table genus.qza --o-composition-table added_pseudo.qza

qiime composition ancom \
    --i-table added_pseudo.qza \
    --m-metadata-file samples.tsv \
    --m-metadata-column status \
    --o-visualization ancom.qzv

qiime diversity core-metrics \
    --i-table crc_dataset.qza \
    --p-sampling-depth 100000 \
    --m-metadata-file crc_metadata.tsv \
    --output-dir crc_diversity

qiime feature-table relative-frequency \
	--i-table crc_dataset.qza \
	--o-relative-frequency-table crc_relative.qza

qiime perc-norm percentile-normalize \
	--i-table crc_relative.qza \
	--m-metadata-file crc_metadata.tsv \
	--m-metadata-column disease_state \
	--m-batch-file crc_metadata.tsv \
	--m-batch-column study \
	--p-otu-thresh 0.0 \
	--o-perc-norm-table percentile_normalized.qza

python -e 'exec("""from qiime2 import Artifact
import pandas as pd

df = Artifact.load("percentile_normalized.qza").view(pd.DataFrame)
converted = Artifact.import_data("FeatureTable[Frequency]", df)
converted.save("pnorm_freq.qza")
""")'

qiime diversity beta \
    --i-table pnorm_freq.qza \
    --p-metric braycurtis \
    --o-distance-matrix pnorm_bray.qza

qiime diversity pcoa --i-distance-matrix pnorm_bray.qza --o-pcoa pnorm_pcoa.qza

qiime emperor plot \
    --i-pcoa pnorm_pcoa.qza \
    --m-metadata-file crc_metadata.tsv \
    --o-visualization pnorm_pcoa_emperor.qzv

qiime feature-table filter-samples \
	--i-table crc_dataset.qza \
	--m-metadata-file crc_metadata.tsv \
	--p-where "study=='baxter'" \
	--o-filtered-table baxter_table.qza

qiime feature-table filter-samples \
	--i-table crc_dataset.qza \
	--m-metadata-file crc_metadata.tsv \
	--p-where "study=='zeller'" \
	--o-filtered-table zeller_table.qza

python wilcoxon_test.py -i baxter_table.qza -m crc_metadata.tsv

python wilcoxon_test.py -i zeller_table.qza -m crc_metadata.tsv

python wilcoxon_test.py -i crc_dataset.qza -m crc_metadata.tsv

python wilcoxon_test.py -i pnorm_freq.qza -m crc_metadata.tsv

python wilcoxon_test.py -i pnorm_freq.qza -m crc_metadata.tsv -a 0.01 -t 0.1

