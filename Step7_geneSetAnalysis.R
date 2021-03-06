#########################################################################################################################
#prepare your data for gene set analysis
#########################################################################################################################
#you'll want to have already read-in your raw microarray data,
#normalized your data,
#carried out differential expression analysis using limma,
#and perhaps even generated some a priori lists of genes you're interested in.

#for the purposes of this script we'll want several objects generated by the steps above:
#1) your normalized data batch object (normData)
#2) your experimental design file that you created during differential expression analysis
#3) your contrast matrix
#4) your moderated T statistics produced by the eBayes analysis with Limma
#5) Gene sets that you'd like to test for enrichment in your array data
#these gene sets can be 'custom' made based on your specific interests,
#or they can be downloaded from gene signature databases such as MSigDB or GeneSignatureDB

#generally speaking, there are two approaches for gene set testing.  
#both are outlined below, with several options present for each approach


#########################################################################################################################
# GENERAL APPROACH 1: SELF-CONTAINED GENE SET TESTING
#several tools available for this, many within the Limma package
#use these tests when you want to know whether one (or a few) selected gene sets are enriched 'signatures' on your array
#########################################################################################################################
library(limma)

#take a look at the matrix of moderated T statistics produced by the eBayes function that you used during differential expression analysis with Limma
#one approach to Gene Set Testing is to use the ebayes statistics as the basis for determining whether a set of probes is overrepresented in up- or down-regulated genes
head(ebFit.treatment_late$t)

#OPTION 1: use GeneSetTest function (Limma)
#the 'probeIDs' object here is a custom 'a priori' list of probset IDs generated from the end of my Limma script
#the output from the geneSetTest function is a P value that indicates whether the probe set is enriched or not
geneSetTest(probeIDs,ebFit.treatment_late$t[,3],"greater") #use "greater" or "less" to see if the gene set is enriched in up or down regulated genes

#OPTION 2a: use ROAST function (Limma)
#the output from ROAST gives three pvals, each testing whether genes are up, down or mixed (differentially expressed without regard to direction)
roast(normData, probeIDs, design, contrast.matrix.treatment_late[,1], nrot=99) 

#######NEED TO FIX THIS SECTION DOWN TO GSVA
#OPTION 2b: use mROAST function (Limma) for testing enrichment of more than one gene set
#this is essentially the same as running ROAST multiple times and then just correcting for multiple testing at the end
#first, load a gene set database list
load("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/mouse_c5.rdata")
load("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/GeneSigDBv4.0.RData")

#convert your entire array into an index of lists, by matching symbols to your array
mouseSymbols <- fit$genes$Symbol
upperSymbols <- toupper(mouseSymbols) #tolower to convert symbols to mouse
fit$genes$Symbol <-upperSymbols

mouse.c5 <- symbols2indices(Mm.gmtl.c5, fit$genes$Symbol, remove.empty=T)
mroast.res <- mroast(normData, mouse.c5, design, contrast.matrix.treatment_late[,3], nrot=99) 
dim(mroast.res)
head(mroast.res)
tail(mroast.res)

class(broadSet.Treg)

#If you're testing one or two Gene Sets, the enrichment 'profile' can be visually plotted on the scale of moderated T stats as a 'barcodeplot' (Limma)
#change the subset to indicate which contrast in your matrix you'd like to display the bayes stats for
x11(); barcodeplot(ebFit.treatment_late$t[,3], probeIDs)


#############################################################################################################################
#competitive Gene Set testing (i.e. 'GSEA'), using CAMERA, Romer, or GSEAlm
#this allows you to take a database or collection of gene sets (such as MSigDB or GeneSigDB) and pit them against each other
#the results tells you which gene sets were the most enriched in the up/down regulated genes for each contrast (pairwise comparison)
#############################################################################################################################

#OPTION 1: use CAMERA function (Limma)
camera.res <- camera(normData, mouse.c5, design, contrast.matrix.treatment_late[,1])
dim(camera.res)
head(camera.res)
tail(camera.res)

#OPTION 2: use ROMER function (Limma)
romer.res <- romer(mouse.c5, normData, design, contrast.matrix.treatment_late[,1])
dim(romer.res)
head(romer.res)
tail(romer.res)

#OPTION 3: uses the SPIA package - this is a bit different from all the above options, but is similar in concept. 
# SPIA is designed to identify signaling pathways that are overrepresented in your set of differentially expressed genes
# takes two files as input: 1) your diff expressed genes; 2) ALL your genes as the background
# SPIA is unique in that it weights each component of a signaling pathway in terms of its importance in propagating signal (i.e. it factors in pathway 'topology')



library(iBBiG)
binMat<-makeArtificial()
#plot(binMat)
res<- iBBiG(binMat@Seeddata, nModules=10)
x11(); plot(res)
statClust(res,binMat)

###########################################################################################################################################
#carry out the equivalent of ***single sample*** Gene Set Enrichment Analysis (ssGSEA) using Broad/MsigDB, GeneSigDB, or any list of gene sets
#this is a bit different than using CAMERA or ROMER, in that ssGSEA doesn't care about your contrasts (pairwise comparisons)
#instead, ssGSEA ranks genes from highest absolute expression to lowest for EACH of your samples.
#GSEA is then carried out on each ranked list
###########################################################################################################################################
#You'll need to download the .GMT files to your computer directly from from the MSigDB website (I choose the gene symbol files).  
#These can be found at:  http://www.broadinstitute.org/gsea/msigdb/collections.jsp
#place these files in a folder on your computer
#the first part of this script points to these files, so be sure to change these lines to match the directory on your computer.
#NOTE: all MSigDB files are HUMAN genes, so you shouldn't query a mouse array against them
#if you're working with mouse array data, use MSigDB files that have been mapped to human/mouse orthologs. These can be found at:
#http://bioinf.wehi.edu.au/software/MSigDB/


#Load the necessary packages
library(GSEABase)
library(GSVA)

#read in one or multiple MsigDB .GMT files (must've already downloaded these to your computer)
#each file is a vector of lists in which each list contains all the genes associated with a particular pathway

#MsigDB set C7 contains list of genes associated with immunological signatures
broadSet.C7 <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c7.all.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
#set C6 contains sets of genes that are oncogenic signatures
broadSet.C6 <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c6.all.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
#set C5 contains sets of genes associated with different GO terms
broadSet.C5.ALL <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c5.all.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C5.BP <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c5.bp.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C5.MF <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c5.mf.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
#set C3 contains lists of targets for TFs
broadSet.C3.TFT <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c3.tft.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
#set C2 contains pathways and chemical/genetic perturbations
broadSet.C2.ALL <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c2.all.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C2.KEGG <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c2.cp.kegg.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C2.BIOCARTA <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c2.cp.biocarta.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C2.REACTOME <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c2.cp.reactome.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C2.PERTURBATIONS <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c2.cgp.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())
broadSet.C2.CANONICAL <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/c2.cp.v4.0.symbols.gmt", geneIdType=SymbolIdentifier())

#alternatively, you could download and read-in the ENTIRE MSigDB.  I prefer not to do this....too cumbersome.
broad.ALL <- getGMT("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/msigdb_v4.0.symbols.gmt")

#Treg specific pathways (generated by searching MSigDB for the term 'Treg')
#includes 8 GEO entries that were used to generate 112 different signatures (UP and DOWN signatures for many different pairwise comparisons)
#note, the file that is returned by this search needs an empty line added at the end.
broadSet.Treg <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/TregSearch.gmt", geneIdType=SymbolIdentifier())

#gene sets from experiments with exhausted T cells
broadSet.Exhausted <- getGmt("/Users/danielbeiting/Documents/R_scripts/MSigDB_files/exhaustedSearch.gmt", geneIdType=SymbolIdentifier())

#Calculate the % overlap between all the gene sets in your database and represent as a correlation matrix
library(lattice)
TregOverlap <- computeGeneSetsOverlap(broadSet.Treg, upperSymbols)
rgb.palette <- colorRampPalette(c("blue", "red", "yellow"), space = "rgb")
x11(); levelplot(TregOverlap, main="Treg geneset correlation matrix", xlab="", ylab="", col.regions=rgb.palette(1000), cuts=100, cexRow=0.5, cexCol=1, margins=c(10,10))

###############################################################################################
#now that you've read in the database files, you'll need to read-in your normalized gene expression data
#if starting with a data matrix, first convert to an expressionSet object using the Biobase package
###############################################################################################

#read in a matrix of gene expression for your entire array
#make sure to have gene symbols in all caps (coerced to human) 
#also need to collapse rows so that there are no duplicate row names.  Do this using either excel the collapseRows function in the WGCNA package
#finally remove the NA collapsed row, since R will read this as a missing value, which is not allowed (I usually replace with "NOTAGENE")
library(Biobase)
myDataMatrix <- read.delim("Treg.normalizedData_late.txt", row.names = 1, header=TRUE)
head(myDataMatrix)
myDataMatrix <- as.matrix(myDataMatrix)
myEset <- new("ExpressionSet", exprs = myDataMatrix)


###############################################################################################
#run GSVA on the expressionSet data object
#be aware that if you choose a large MsigDB file here, this step may take a while
###############################################################################################
#convert your geneSetCollections into lists using the 'geneIds' function
broadSet.Treg <- geneIds(broadSet.Treg)
broadSet.Exhausted <- geneIds(broadSet.Exhausted)
broadSet.C7 <- geneIds(broadSet.C7)
broadSet.C3.TFT <- geneIds(broadSet.C3.TFT)
broadSet.C5.BP <- geneIds(broadSet.C5.BP)

Treg.res <- gsva(myDataMatrix, broadSet.Treg, min.sz=5, max.sz=500, verbose=TRUE, method="gsva")$es.obs #options for method are "gsva", ssgsea', "zscore" or "plage"
Exhausted.res <- gsva(myDataMatrix, broadSet.Exhausted, min.sz=5, max.sz=500, verbose=TRUE, method="gsva")$es.obs #options for method are "gsva", ssgsea', "zscore" or "plage"
C7.res <- gsva(myDataMatrix, broadSet.C7, min.sz=5, max.sz=500, verbose=TRUE, method="gsva")$es.obs #options for method are "gsva", ssgsea', "zscore" or "plage"
C3.TFT.res <- gsva(myDataMatrix, broadSet.C3.TFT, min.sz=5, max.sz=500, verbose=TRUE, method="gsva")$es.obs #options for method are "gsva", ssgsea', "zscore" or "plage"
C5.BP.res <- gsva(myDataMatrix, broadSet.C5.BP, min.sz=5, max.sz=500, verbose=TRUE, method="gsva")$es.obs #options for method are "gsva", ssgsea', "zscore" or "plage"

###############################################################################################################################################
#use Limma to select gene sets that are differentially enriched (based on GSVA analysis above) between your two conditions of interest
###############################################################################################################################################
#define a pval and logFC cutoff to be used later in the enrichment analysis
adjPvalueCutoff <- 0.05
logFCcutoff <- log2(0.59)

#use limma to apply a linear model to the data
library(limma)
targets <- readTargets("Treg_studyDesign3.txt", sep="\t")
targets
factorial <- paste(targets$treatment)
factorial <- factor(factorial)
factorial
design <- model.matrix(~0+factorial)
colnames(design) <- levels(factorial)
design

fit.Treg <- lmFit(Treg.res, design)
fit.Exhausted <- lmFit(Exhausted.res, design)
fit.C7 <- lmFit(C7.res, design)
fit.C3.TFT <- lmFit(C3.TFT.res, design)
fit.C5.BP <- lmFit(C5.BP.res, design)

# set up a contrast matrix based on the pairwise comparisons of interest
contrast.matrix <- makeContrasts(IL27effect = IL27 - neutral, levels=design)

# use topTable and decideTests functions of Limma to identify the differentially enriched gene sets
res.Treg <- decideTests(fit.Treg, p.value=adjPvalueCutoff, lfc=logFCcutoff)
res.Exhausted <- decideTests(fit.Exhausted, p.value=adjPvalueCutoff, lfc=logFCcutoff)
res.C7 <- decideTests(fit.C7, p.value=adjPvalueCutoff, lfc=logFCcutoff)
res.C3.TFT <- decideTests(fit.C3.TFT, p.value=adjPvalueCutoff)
res.C5.BP <- decideTests(fit.C5.BP, p.value=adjPvalueCutoff)

#the summary of the decideTests result shows how many sets were enriched in induced and repressed genes in all sample types
summary(res.Treg)
summary(res.Exhausted)
summary(res.C7)
summary(res.C3.TFT)
summary(res.C5.BP)


# extract the expression data matrix from the GSVA result and convert to an expressionSet object 
myEset.Treg <- new("ExpressionSet", exprs = Treg.res)
myEset.C7 <- new("ExpressionSet", exprs = C7.res)

#link the eset to annotation data
annotation(myEset.Treg) <- "lumiMouseAll.db"
annotation(myEset.C7) <- "lumiMouseAll.db"

# pull out the GO gene sets that are differentially enriched between the two groups
diffSets.C7 <- myEset.C7[res.C7[,1] !=0 | res.C7[,2] !=0]
diffSets.C7 <- exprs(diffSets.C7)

diffSets.Treg <- myEset.Treg[res.Treg[,1] !=0 | res.Treg[,2] !=0]
diffSets.Treg <- exprs(diffSets.Treg)

diffSets.Exhausted <- myEset.Treg[res.Exhausted[,1] ==0 | res.Exhausted[,2] ==0]
diffSets.Exhausted <- exprs(diffSets.Exhausted)

head(diffSets.C7)
head(diffSets.Treg)

setNames.C7 <- rownames(diffSets.C7)
setNames.Treg <- rownames(diffSets.Treg)
setNames.Exhausted <- rownames(diffSets.Exhausted)


###############################################################################################
#make a heatmap of differentially enriched gene sets
###############################################################################################
hr.C7 <- hclust(as.dist(1-cor(t(diffSets.C7), method="pearson")), method="complete") #cluster rows by pearson correlation
hc.C7 <- hclust(as.dist(1-cor(diffSets.C7, method="spearman")), method="complete") #cluster columns by spearman correlation

# Cut the resulting tree and create color vector for clusters.  Vary the cut height to give more or fewer clusters, or you the 'k' argument to force n number of clusters
library(RColorBrewer)
mycl.C7 <- cutree(hr.C7, k=2)
mycolhc.C7 <- rainbow(length(unique(mycl.C7)), start=0.1, end=0.9) 
mycolhc.C7 <- mycolhc.C7[as.vector(mycl.C7)] 

#load the gplots package for plotting the heatmap
library(gplots) 
#assign your favorite heatmap color scheme. Some useful examples: colorpanel(40, "darkblue", "yellow", "white"); heat.colors(75); cm.colors(75); rainbow(75); redgreen(75); library(RColorBrewer); rev(brewer.pal(9,"Blues")[-1]). Type demo.col(20) to see more color schemes.
myheatcol <- greenred(75)
#plot the hclust results as a heatmap
x11();heatmap.2(diffSets.Exhausted, Rowv=NA, Colv=NA, col=myheatcol, scale="row", labRow=setNames.Exhausted, density.info="none", trace="none", labCol = sampleLabels.NeutralIL27, cexRow=0.9, cexCol=1, margins=c(10,25)) # Creates heatmap for entire data set where the obtained clusters are indicated in the color bar.

#parse out interesting subclusters from CANONICAL 
x11(); heatmap.2(diffSets.CANONICAL, Rowv=NA, Colv=NA, col=myheatcol, scale="row", labRow=setNames.CANONICAL, density.info="none", trace="none", RowSideColors=mycolhc.CANONICAL, labCol = sampleLabels.ALL, cexRow=0.75, cexCol=1, margins=c(10,10)) # Creates heatmap for entire data set where the obtained clusters are indicated in the color bar.
x11(height=6, width=2); names(mycolhc.REACTOME) <- names(mycl.REACTOME); barplot(rep(10, max(mycl.REACTOME)), col=unique(mycolhc.REACTOME[hr.REACTOME$labels[hr.REACTOME$order]]), horiz=T, names=unique(mycl.REACTOME[hr.REACTOME$order])) # Prints color key for cluster assignments. The numbers next to the color boxes correspond to the cluster numbers in 'mycl'.
clid.CANONICAL <- c(2,2); ysub <- diffSets.CANONICAL[names(mycl.CANONICAL[mycl.CANONICAL%in%clid.CANONICAL]),]; hrsub <- hclust(as.dist(1-cor(t(ysub), method="pearson")), method="complete") 
x11(); heatmap.2(ysub, Rowv=as.dendrogram(hrsub), Colv=NA, col=myheatcol, scale="row", density.info="none", trace="none", RowSideColors=mycolhc.CANONICAL[mycl.CANONICAL%in%clid.CANONICAL], labCol = sampleLabels.ALL, labRow=setNames.CANONICAL, cexRow=0.75, cexCol=1, margins=c(10,10)) # Create heatmap for chosen sub-cluster.


#look at cluster assignments
x11(height=6, width=2); names(mycolhc.PERTURBATIONS) <- names(mycl.PERTURBATIONS); barplot(rep(10, max(mycl.PERTURBATIONS)), col=unique(mycolhc.PERTURBATIONS[hr.PERTURBATIONS$labels[hr.PERTURBATIONS$order]]), horiz=T, names=unique(mycl.PERTURBATIONS[hr.PERTURBATIONS$order])) # Prints color key for cluster assignments. The numbers next to the color boxes correspond to the cluster numbers in 'mycl'.
x11(height=6, width=2); names(mycolhc.CANONICAL) <- names(mycl.CANONICAL); barplot(rep(10, max(mycl.CANONICAL)), col=unique(mycolhc.CANONICAL[hr.CANONICAL$labels[hr.CANONICAL$order]]), horiz=T, names=unique(mycl.CANONICAL[hr.CANONICAL$order])) # Prints color key for cluster assignments. The numbers next to the color boxes correspond to the cluster numbers in 'mycl'.

#print your enrichment results to an excel spreadsheet
write.table(diffSets, "diffSets_GO_BP_GSEA.xls", sep="\t", quote=FALSE)

###############################################################################################
#select sub-clusters of co-regulated transcripts for downstream analysis
###############################################################################################
#subclusters from CANONICAL gene set collection


clid.REACTOME <- c(7,7); ysub <- diffSets.REACTOME[names(mycl.REACTOME[mycl.REACTOME%in%clid.REACTOME]),]; hrsub <- hclust.REACTOME(as.dist(1-cor(t(ysub), method="pearson")), method="complete") 


heatmap.2(ysub, Rowv=as.dendrogram(hrsub), Colv=NA, col=myheatcol, scale="row", labRow=NA, density.info="none", trace="none", RowSideColors=mycolhc[mycl%in%clid], labCol = sampleLabels.ALL, cexRow=0.75, cexCol=1, margins=c(10,10)) # Create heatmap for chosen sub-cluster.

#print out row labels in same order as shown in the heatmap
clusterIDs <- data.frame(Labels=rev(hrsub$labels[hrsub$order]))
clusterIDs <- as.vector(t(clusterIDs))
#retrieve gene symbols and entrezIDs for selected cluster and print out to an excel spreadsheet for downstream applications (i.e. GO enrichment in DAVID)
myCluster <- cbind(getSYMBOL(clusterIDs, "lumiHumanAll.db"), getEG(clusterIDs, "lumiHumanAll.db"))
write.table(myCluster, "Cluster3.xls", sep="\t", quote=FALSE)

##############################################################################
#find all genes on the array that are associated with a specific GO term(s) 
##############################################################################
require(lumiHumanAll.db)
GOterms <- as.list(lumiHumanAllGO2PROBE)

#retrieve probeset IDs for each of the GO terms of interest
isTransElong <- GOterms$"GO:0006414"
OxBurst <- GOterms$"GO:0045730"
ROSmetabolism <- GOterms$"GO:0072539"
SODactivity <- GOterms$"GO:0004784"

#if more than one term was queried above, concatenate the results to one character vector
myGOterms <- c(OxBurst, ROSmetabolism, SODactivity)

#filter your array data using the list of probeset IDs that you just generated
eset1 <- myEset[featureNames(myEset) %in% myGOterms] #myEset refers to your normalized, batch-adjusted data matrix
myFilteredExprs <- exprs(eset1)
dim(myFilteredExprs)
probeIDs <- rownames(myFilteredExprs)
#make a excel table of the retrieved data for your GO terms of interest
mySelectedGenes <- getSYMBOL(probeIDs, "lumiHumanAll.db")
mySelectedGenes <- as.matrix(mySelectedGenes)
write.table(cbind(mySelectedGenes, myFilteredExprs),"Selected_GO.xls", sep="\t", quote=FALSE)
