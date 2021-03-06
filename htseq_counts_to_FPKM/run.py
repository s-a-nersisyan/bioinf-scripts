import sys
import os
from natsort import natsorted

import pandas as pd
import numpy as np

htseq_counts_path = sys.argv[1]
ENSG_GeneSymbol_path = sys.argv[2]  # File generated by make_ensg_gene_symbol_table.bash scipt
ENSG_length_path = sys.argv[3] # File generated by make_gene_length_table.bash
out_table_path = sys.argv[4]


df_ensg_gs = pd.read_csv(ENSG_GeneSymbol_path, sep="\t", index_col=0)
df_ensg_len = pd.read_csv(ENSG_length_path, sep="\t", index_col=0)

df_annot = df_ensg_len.join(df_ensg_gs)[["Gene Symbol", "merged", "Type"]]
df_annot = df_annot.loc[df_annot["Type"] == "protein_coding"].drop(columns = ["Type"])
df_annot = df_annot.rename(columns={"merged": "length"})
df_annot.index = [i.split(".")[0] for i in df_annot.index]
df_annot = df_annot.drop_duplicates()

dfs = []
for fn in os.listdir(htseq_counts_path):
    if not fn.endswith(".counts"):
        continue
    
    df = pd.read_csv("{}/{}".format(htseq_counts_path, fn), sep="\t", header=None, index_col=0)
    df.index = [i.split(".")[0] for i in df.index]
    df.columns = [fn.split(".")[0]]
    dfs.append(df)

df = pd.concat(dfs, axis=1).drop_duplicates()

common_genes = natsorted(set.intersection(set(df.index.tolist()), set(df_annot.index.tolist())))
df = df.loc[common_genes]
df_annot = df_annot.loc[common_genes]

df = df * 10**6 / df.quantile(0.75, axis=0)
df = (df.T * 10**3 / df_annot["length"]).T

df = df.join(df_annot[["Gene Symbol"]]).set_index("Gene Symbol")
df = np.log2(df + 1)

df.to_csv(out_table_path, sep="\t")
