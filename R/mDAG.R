#' Inferring Causal Network from Mixed Observational Data Using a Directed Acyclic Graph
#'
#' This function learns a mixed directed acyclic graph based on both continuous and categorical data.
#' 
#' @param data A n x p matrix. Each row is a sample; each column is a variable.
#' @param type A string vector of length p, indicating the type of variable for each column in \code{data}. 'g' for Gaussian, 'c' for categorical.
#' @param level A vector of length p, indicating the number of categories of each variable. For continuous variables, set it to 1.
#' @param SNP A vector of length p, indicating which variable is a SNP.
#' @param lambdaGam Hyperparameter \eqn{\gamma} in the EBIC if \code{lambdaSel = 'EBIC'}. Defaults is \code{lambdaGam = 0.25}.
#' @param ruleReg Default is \code{'OR'}. Rule used to combine two estimates from nodewise regression (one from regressing A on B and the other from B on A). ruleReg = \code{'AND'} requires both estimates to be nonzero in order to set the edge to be present. ruleReg = \code{'OR'}
#' requires at least one estiamte to be nonzero in order to set the edge to be present.
#' @param threshold Default is \code{'LW'}. A threshold below which the combined estimates from nodewise regression are put to zero. threshold = \code{'LW'} refers to the threshold in Loh and Wainwright (2012). threshold = \code{'HW'} refers to the threshold in Haslbeck and Waldorp (2016). If threshold = \code{'none'} no thresholding is applied. 
#' @param weights A vector of length n, indicating weights for observations. 
#' @param alpha Significance level for permutation test of conditional independece. Default is 0.05.
#' @param nperm The number of permutations in the permutation test of conditional independece. Default is 10000.
#'  
#' @return A list of the following components:
#' \itemize{
#'   \item \code{arcs}: A two-column matrix, indicating arcs of the DAG. 
#'   \item \code{nodes}: A list. Each element is named after a node and contains the following elements.
#'   \code{} \itemize{\item \code{nbr}: a string vector indicating the neighbourhood of the node.
#'                          \item \code{parents}: a string vector indicating the parents of the node.
#'                           \item \code{children}: a string vector indicating the children of the node.}
#'   \item \code{skeleton}: A p x p adjacency matrix. If there is an edge from node i to node j, its \code{(i,j)} th entry = 1; otherwise = 0. 
#' }
#'
#' 
#' @author Wujuan Zhong, Li Dong, Quefeng Li, Xiaojing Zheng
#'
#' @references
#'
#' Jonas M. B. Haslbeck, Lourens J. Waldorp (2016). mgm: Structure Estimation for Time-Varying Mixed Graphical Models in high-dimensional Data arXiv preprint:1510.06871v2
#' 
#' Markus Kalisch, Martin Maechler, Diego Colombo, Marloes H. Maathuis, Peter Buehlmann (2012). Causal Inference Using Graphical Models with the R Package pcalg. Journal of Statistical Software, 47(11), 1-26.
#' 
#' Loh, P. L., & Wainwright, M. J. (2012, December). Structure estimation for discrete graphical models: Generalized covariance matrices and their inverses. In NIPS (pp. 2096-2104).
#' 
#' Haslbeck, J., & Waldorp, L. J. (2016). mgm: Structure Estimation for time-varying Mixed Graphical Models in high-dimensional Data. arXiv preprint arXiv:1510.06871.
#' 
#' Marco Scutari (2010). Learning Bayesian Networks with the bnlearn R Package. Journal of Statistical Software, 35(3), 1-22.
#' 
#' Venables, W. N. & Ripley, B. D. (2002) Modern Applied Statistics with S. Fourth Edition. Springer, New York. ISBN 0-387-95457-0
#' 
#' Georg Heinze and Meinhard Ploner (2018). logistf: Firth's Bias-Reduced Logistic Regression. R package version 1.23.
#'
#' Min Jin Ha (2013). PenPC: A Two-step Approach to Estimate the Skeletons of High Dimensional Directed Acyclic Graphs. R package version 0.99.1.
#' 
#' @import mgm  pcalg  logistf nnet 
#' @importFrom Rcpp evalCpp
#' @importFrom methods as new
#' @importFrom stats cor cor.test glm lm lm.fit predict resid
#' @rawNamespace import(bnlearn, except = c(dsep, shd, skeleton, pdag2dag) )
#' 
#' @useDynLib mDAG
#' 
#' @export
#' 
#' @examples 
#' 
#' # load package
#' library(mDAG)
#' type=c("g","g","g","g","c")
#' level=c(1,1,1,1,2)
#' # To save time for running example, we set nperm as 150. 
#' # Use default nperm=10000 to generate a more reliable DAG for your own data.
#' dag=mDAG(data=example_data, type=type, level=level, nperm=150)
#' print(dag$skeleton)
#' # draw the DAG
#' # library(bnlearn)
#' # bnlearn:::graphviz.backend(nodes=names(dag$nodes),arcs=dag$arcs,shape="rectangle")
#' 
#' 
mDAG=function(data,type,level,SNP=rep(0,ncol(data)),lambdaGam=0.25,ruleReg='OR',threshold='LW',
              weights=rep(1, nrow(data)),alpha=0.05,nperm=10000){
  
  cat("Step 1. Identification of the Markov Blanket","\n")
  step1=mgm_skeleton(data,type,level,SNP,lambdaGam,lambdaSel='EBIC',ruleReg,alphaSel='EBIC',threshold,weights)
  cat("\n")
  cat("Step 1 completed!","\n")
  
  cat("Step 2. Identification of the mixed DAG's skeleton ","\n")
  step2=penpc_skeleton( as.matrix(data),type,level,edgeWeights=(step1$skeleton) ,nperm = nperm, alpha = alpha)
  cat("Step 2 completed!","\n")
  
  cat("Step 3. Orientation of the mixed DAG","\n")
  step3=greedysearch_orientation(data=as.matrix(data),type=type,level=level,SNP=SNP,result=step2$graph$skeleton)
  cat("Step 3 completed!","\n")
  
  return(step3)
}

