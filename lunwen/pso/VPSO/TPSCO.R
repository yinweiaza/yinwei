tpsco<- function (par, fn, gr = NULL, ..., lower=-1, upper=1,
                 control = list()) {
  fn1 <- function(par) fn(par, ...)/p.fnscale
  mrunif <- function(n,m,lower,upper) {
    return(matrix(runif(n*m,0,1),nrow=n,ncol=m)*(upper-lower)+lower)
  }
  norm <- function(x) sqrt(sum(x*x))
  rsphere.unif <- function(n,r) {
    temp <- runif(n)
    return((runif(1,min=0,max=r)/norm(temp))*temp)
  }
  svect <- function(a,b,n,k) {
    temp <- rep(a,n)
    temp[k] <- b
    return(temp)
  }
  mrsphere.unif <- function(n,r) {
    m <- length(r)
    temp <- matrix(runif(n*m),n,m)
    return(temp%*%diag(runif(m,min=0,max=r)/apply(temp,2,norm)))
  }
  npar <- length(par)
  lower <- as.double(rep(lower, ,npar))
  upper <- as.double(rep(upper, ,npar))
  con <- list(trace = 1, fnscale = 1, maxit = 1000L, maxf = Inf,
              abstol = -Inf, reltol = 0, REPORT = 10,
              s = NA, k = 3, p = NA, w = 1/(2*log(2)),
              c.p = .5+log(2), c.g = .5+log(2), d = NA,
              v.max = NA, rand.order = TRUE, max.restart=Inf,
              maxit.stagnate = Inf,
              vectorize=FALSE, hybrid = FALSE, hybrid.control = NULL,
              trace.stats = FALSE, type = "SPSO2007",SCOND=TRUE,m=5,iter=10,GUASS=TRUE,n=10)
  nmsC <- names(con)
  con[(namc <- names(control))] <- control
  if (length(noNms <- namc[!namc %in% nmsC])) 
    warning("unknown names in control: ", paste(noNms, collapse = ", "))
  ## Argument error checks
  if (any(upper==Inf | lower==-Inf))
    stop("fixed bounds must be provided")
  
  p.type <- pmatch(con[["type"]],c("SPSO2007","SPSO2011"))-1
  if (is.na(p.type)) stop("type should be one of \"SPSO2007\", \"SPSO2011\"")
  
  p.n<-con[["n"]]   #均匀粒子
  
  p.iter<-con[["iter"]]  #二种群迭代iter次后和一种群进行粒子交换
  p.m<-con[["m"]]  #一种群每迭代m次，和二种群进行粒子交换
  p.scond<-con[["SCOND"]]  #是否使用二分粒子群
  p.guass=con[["GUASS"]]   #是否使用均匀扰动
  p.trace <- con[["trace"]]>0L # provide output on progress?
  p.fnscale <- con[["fnscale"]] # scale funcion by 1/fnscale
  p.maxit <- con[["maxit"]] # maximal number of iterations
  p.maxf <- con[["maxf"]] # maximal number of function evaluations
  p.abstol <- con[["abstol"]] # absolute tolerance for convergence
  p.reltol <- con[["reltol"]] # relative minimal tolerance for restarting
  p.report <- as.integer(con[["REPORT"]]) # output every REPORT iterations
  p.s <- ifelse(is.na(con[["s"]]),ifelse(p.type==0,floor(10+2*sqrt(npar)),40),
                con[["s"]]) # swarm size
  p.p <- ifelse(is.na(con[["p"]]),1-(1-1/p.s)^con[["k"]],con[["p"]]) # average % of informants
  p.w0 <- con[["w"]] # exploitation constant
  if (length(p.w0)>1) {
    p.w1 <- p.w0[2]
    p.w0 <- p.w0[1]
  } else {
    p.w1 <- p.w0
  }
  p.c.p <- con[["c.p"]] # local exploration constant
  p.c.g <- con[["c.g"]] # global exploration constant
  p.d <- ifelse(is.na(con[["d"]]),norm(upper-lower),con[["d"]]) # domain diameter
  p.vmax <- con[["v.max"]]*p.d # maximal velocity
  p.randorder <- as.logical(con[["rand.order"]]) # process particles in random order?
  p.maxrestart <- con[["max.restart"]] # maximal number of restarts
  p.maxstagnate <- con[["maxit.stagnate"]] # maximal number of iterations without improvement
  p.vectorize <- as.logical(con[["vectorize"]]) # vectorize?
  if (is.character(con[["hybrid"]])) {
    p.hybrid <- pmatch(con[["hybrid"]],c("off","on","improved"))-1
    if (is.na(p.hybrid)) stop("hybrid should be one of \"off\", \"on\", \"improved\"")
  } else {
    p.hybrid <- as.integer(as.logical(con[["hybrid"]])) # use local BFGS search
  }
  p.hcontrol <- con[["hybrid.control"]] # control parameters for hybrid optim
  if ("fnscale" %in% names(p.hcontrol))
    p.hcontrol["fnscale"] <- p.hcontrol["fnscale"]*p.fnscale
  else
    p.hcontrol["fnscale"] <- p.fnscale
  p.trace.stats <- as.logical(con[["trace.stats"]]) # collect detailed stats?
  
  
  if (p.trace) {
    message("S=",p.s,", K=",con[["k"]],", p=",signif(p.p,4),", w0=",
            signif(p.w0,4),", w1=",
            signif(p.w1,4),", c.p=",signif(p.c.p,4),
            ", c.g=",signif(p.c.g,4))
    message("v.max=",signif(con[["v.max"]],4),
            ", d=",signif(p.d,4),", vectorize=",p.vectorize,
            ", hybrid=",c("off","on","improved")[p.hybrid+1])
    if (p.trace.stats) {
      stats.trace.it <- c()
      stats.trace.error <- c()
      stats.trace.f <- NULL
      stats.trace.x <- NULL
    }
  }
  ## Initialization
  if (p.reltol!=0) p.reltol <- p.reltol*p.d
  if (p.vectorize) {
    lowerM <- matrix(lower,nrow=npar,ncol=p.s)
    upperM <- matrix(upper,nrow=npar,ncol=p.s)
  }
  X <- mrunif(npar,p.s,lower,upper)
  if (!any(is.na(par)) && all(par>=lower) && all(par<=upper)) X[,1] <- par
  if (p.type==0) {
    V <- (mrunif(npar,p.s,lower,upper)-X)/2
  } else { ## p.type==1
    V <- matrix(runif(npar*p.s,min=as.vector(lower-X),max=as.vector(upper-X)),npar,p.s)
    p.c.p2 <- p.c.p/2 # precompute constants
    p.c.p3 <- p.c.p/3
    p.c.g3 <- p.c.g/3
    p.c.pg3 <- p.c.p3+p.c.g3
  }
  if (!is.na(p.vmax)) { # scale to maximal velocity
    temp <- apply(V,2,norm)
    temp <- pmin.int(temp,p.vmax)/temp
    V <- V%*%diag(temp)
  }
  f.x <- apply(X,2,fn1) # first evaluations
  stats.feval <- p.s
  P <- X
  f.p <- f.x
  P.improved <- rep(FALSE,p.s)
  i.best <- which.min(f.p)
  error <- f.p[i.best]
  init.links <- TRUE
  if (p.trace && p.report==1) {
    message("It 1: fitness=",signif(error,4))
    if (p.trace.stats) {
      stats.trace.it <- c(stats.trace.it,1)
      stats.trace.error <- c(stats.trace.error,error)
      stats.trace.f <- c(stats.trace.f,list(f.x))
      stats.trace.x <- c(stats.trace.x,list(X))
    }
  }
  
  #Initialization  function
  init<-function(npar,s,lower,upper){
    X=mrunif(npar,s,lower,upper)
    V=(mrunif(npar,s,lower,upper)-X)/2
    
    f.x<-apply(X,2,fn1)
    return(list(X,V,f.x))
  }
  
  #二种群迭代
  inter2<-function(x,y,w,p){
  
    m<-which.min(y[[3]])
    g<-matrix(rep(y[[1]][,m],p.s),nrow=npar,ncol=p.s)
    g[,m]<-x[[1]][,m]
    x[[2]]<-w*x[[2]]+runif(npar,0,p.c.p)*(y[[1]]-x[[1]])+runif(npar,0,p.c.g)*(p-x[[1]])+runif(npar,0,p.c.g)*(g-x[[1]])
   
    x[[1]]=x[[1]]+x[[2]]
    
    #check bound
    temp <-x[[1]]<lower
    if (any(temp)) {
      x[[1]][temp] <- max(lower)
      x[[2]][temp] <- 0
    }
    temp <- x[[1]]>upper
    if (any(temp)) {
      x[[1]][temp] <-min(upper)
      x[[2]][temp] <- 0
    }
    
    x[[3]]<-apply(x[[1]],2,fn1)
    return(x)
  }
  
  #二种群初始化
  if(p.scond){
    p2<-init(npar,p.s,lower,upper)
    p.p2<-p2
    
    
    
    
  }
  
  #Guass  均匀变异
  Guass<-function(x,Lower,Upper,n){
    rn<-matrix(runif(n*npar,0,1),nrow=npar,ncol=n)

    guass<-Lower+rn*(Upper-Lower)
   
    x<-x+guass
    temp<-x<min(lower)
    x[temp]<-min(lower)
    temp<-x>max(upper)
    x[temp]<-max(upper)
    
   
    
    return(x)
    
  }

  ## Iterations
  stats.iter <- 1
  stats.restart <- 0
  stats.stagnate <- 0
  
  while (stats.iter<p.maxit && stats.feval<p.maxf && error>p.abstol &&
           stats.restart<p.maxrestart && stats.stagnate<p.maxstagnate) {
    stats.iter <- stats.iter+1
    scond.stat<-FALSE
    if (p.p!=1 && init.links) {
      links <- matrix(runif(p.s*p.s,0,1)<=p.p,p.s,p.s)
      diag(links) <- TRUE
    }
    

    
    ## The swarm moves
    if (!p.vectorize) {
      if (p.randorder) {
        index <- sample(p.s)
      } else {
        index <- 1:p.s
      }
      for (i in index) {
        if (p.p==1)
          j <- i.best
        else
          j <- which(links[,i])[which.min(f.p[links[,i]])] # best informant
        temp <- (p.w0+(p.w1-p.w0)*max(stats.iter/p.maxit,stats.feval/p.maxf))
        
        V[,i] <- temp*V[,i] # exploration tendency
        if (p.type==0) {
          
          
          V[,i] <- V[,i]+runif(npar,0,p.c.p)*(P[,i]-X[,i]) # exploitation
          if (i!=j) V[,i] <- V[,i]+runif(npar,0,p.c.g)*(P[,j]-X[,i])
        } else { # SPSO 2011
          if (i!=j)
            temp <- p.c.p3*P[,i]+p.c.g3*P[,j]-p.c.pg3*X[,i] # Gi-Xi
          else
            temp <- p.c.p2*P[,i]-p.c.p2*X[,i] # Gi-Xi for local=best
          V[,i] <- V[,i]+temp+rsphere.unif(npar,norm(temp))
        }
        if (!is.na(p.vmax)) {
          temp <- norm(V[,i])
          if (temp>p.vmax) V[,i] <- (p.vmax/temp)*V[,i]
        }
        X[,i] <- X[,i]+V[,i]
        
        d.sigma<-apply(X,1,sd)
        d.mu<-apply(X,1,mean)
        
        temp1<-d.mu-d.sigma-X[,i]>0
        temp2<-d.mu-d.sigma-X[,i]<=0&d.mu+d.sigma-X[,i]>=0
        temp3<-d.mu+d.sigma-X[,i]<0
       
        pd<-NULL
        
        if(any(temp1))
          pd[temp1]=d.mu[temp1]-d.sigma[temp1]-X[,i][temp1]
        if(any(temp2))
          pd[temp2]=abs(d.mu[temp2]-X[,i][temp2])
        if(any(temp3))
          pd[temp3]=X[,i][temp3]-(d.mu[temp3]+d.sigma[temp3])
         
        
        
        #均匀变异
        if(p.guass){
          X_G<-NULL         
          X_G<-Guass(X[,i],-pd,pd,p.n)          
          X_G<-cbind(X_G,X[,i])
          X_GF<-apply(X_G[,1:p.n],2,fn1)
          X_GF<-c(X_GF,f.x[i])
          X[,i]<-X_G[which.min(X_GF)]
        }
        ## Check bounds
        temp <- X[,i]<lower
        if (any(temp)) {
          X[temp,i] <- lower[temp]
          V[temp,i] <- 0
        }
        temp <- X[,i]>upper
        if (any(temp)) {
          X[temp,i] <- upper[temp]
          V[temp,i] <- 0
        }
        
        ## Evaluate function
        if (p.hybrid==1) {
          temp <- optim(X[,i],fn,gr,...,method="L-BFGS-B",lower=lower,
                        upper=upper,control=p.hcontrol)
          V[,i] <- V[,i]+temp$par-X[,i] # disregards any v.max imposed
          X[,i] <- temp$par
          f.x[i] <- temp$value
          stats.feval <- stats.feval+as.integer(temp$counts[1])
        } else {
          f.x[i] <- fn1(X[,i])
          stats.feval <- stats.feval+1
        }
        if (f.x[i]<f.p[i]) { # improvement
          P[,i] <- X[,i]
          f.p[i] <- f.x[i]
          if (f.p[i]<f.p[i.best]) {
            i.best <- i
            if (p.hybrid==2) {
              temp <- optim(X[,i],fn,gr,...,method="L-BFGS-B",lower=lower,
                            upper=upper,control=p.hcontrol)
              V[,i] <- V[,i]+temp$par-X[,i] # disregards any v.max imposed
              X[,i] <- temp$par
              P[,i] <- temp$par
              f.x[i] <- temp$value
              f.p[i] <- temp$value
              stats.feval <- stats.feval+as.integer(temp$counts[1])
            }
          }
        }
        if (stats.feval>=p.maxf) break
     
      
      
      }
     


    } else {
      if (p.p==1)
        j <- rep(i.best,p.s)
      else # best informant
        j <- sapply(1:p.s,function(i)
          which(links[,i])[which.min(f.p[links[,i]])]) 
      temp <- (p.w0+(p.w1-p.w0)*max(stats.iter/p.maxit,stats.feval/p.maxf))
      V <- temp*V # exploration tendency
      if (p.type==0) {
        V <- V+mrunif(npar,p.s,0,p.c.p)*(P-X) # exploitation
        temp <- j!=(1:p.s)
        V[,temp] <- V[,temp]+mrunif(npar,sum(temp),0,p.c.p)*(P[,j[temp]]-X[,temp])
      } else { # SPSO 2011
        temp <- j==(1:p.s)
        temp <- P%*%diag(svect(p.c.p3,p.c.p2,p.s,temp))+
          P[,j]%*%diag(svect(p.c.g3,0,p.s,temp))-
          X%*%diag(svect(p.c.pg3,p.c.p2,p.s,temp)) # G-X
        V <- V+temp+mrsphere.unif(npar,apply(temp,2,norm))
      }
      if (!is.na(p.vmax)) {
        temp <- apply(V,2,norm)
        temp <- pmin.int(temp,p.vmax)/temp
        V <- V%*%diag(temp)
      }
      X <- X+V
      ## Check bounds
      temp <- X<lowerM
      if (any(temp)) {
        X[temp] <- lowerM[temp] 
        V[temp] <- 0
      }
      temp <- X>upperM
      if (any(temp)) {
        X[temp] <- upperM[temp]
        V[temp] <- 0
      }
      
      ## Evaluate function
      if (p.hybrid==1) { # not really vectorizing
        for (i in 1:p.s) {
          temp <- optim(X[,i],fn,gr,...,method="L-BFGS-B",lower=lower,
                        upper=upper,control=p.hcontrol)
          V[,i] <- V[,i]+temp$par-X[,i] # disregards any v.max imposed
          X[,i] <- temp$par
          f.x[i] <- temp$value
          stats.feval <- stats.feval+as.integer(temp$counts[1])
        }
      } else {
        f.x <- apply(X,2,fn1)
        stats.feval <- stats.feval+p.s
      }
      temp <- f.x<f.p
      if (any(temp)) { # improvement
        P[,temp] <- X[,temp]
        f.p[temp] <- f.x[temp]
        i.best <- which.min(f.p)
        if (temp[i.best] && p.hybrid==2) { # overall improvement
          temp <- optim(X[,i.best],fn,gr,...,method="L-BFGS-B",lower=lower,
                        upper=upper,control=p.hcontrol)
          V[,i.best] <- V[,i.best]+temp$par-X[,i.best] # disregards any v.max imposed
          X[,i.best] <- temp$par
          P[,i.best] <- temp$par
          f.x[i.best] <- temp$value
          f.p[i.best] <- temp$value
          stats.feval <- stats.feval+as.integer(temp$counts[1])
        }
      }
      if (stats.feval>=p.maxf) break
    }
    
  
  
   

    #二种群粒子迭代
   if(p.scond){
      scond.stat<-TRUE
      
      #进行迭代， 当粒子聚集程度很高的时候，倒转粒子
      p2<-inter2(p2,p.p2,p.w0,P[,i.best])
      
      #二种群粒子最优记录
      temp<-p2[[3]]-p.p2[[3]]<0
      p.p2[[1]][,temp]<-p2[[1]][,temp]
      p.p2[[3]][temp]<-p2[[3]][temp]
      
    }
 
    p.m<-ifelse(p.m<=2,2,as.integer(p.maxit%/%2*(p.maxit-stats.iter)/p.maxit))
   
     
    #信息交流
    if(scond.stat&&p.scond&&stats.iter%%p.m==0){
     
     temp<-c(p.p2[[3]],f.p)
     min<-which.min(temp)
    
     if(min<=p.s){
       max<-which.max(f.p)
       P[,max]<-p.p2[[1]][,min]
       f.p[max]<-p.p2[[3]][min]
       i.best=max
       
      
     }else{
       p.p2[[1]][,which.max(p.p2[[3]])]<-P[,min-p.s]
       p.p2[[3]][which.max(p.p2[[3]])]<-f.p[min-p.s]
            
     }
    }
   
   
    if (p.reltol!=0) {
      d <- X-P[,i.best]
      d <- sqrt(max(colSums(d*d)))
      if (d<p.reltol) {
        X <- mrunif(npar,p.s,lower,upper)
        V <- (mrunif(npar,p.s,lower,upper)-X)/2
        if (!is.na(p.vmax)) {
          temp <- apply(V,2,norm)
          temp <- pmin.int(temp,p.vmax)/temp
          V <- V%*%diag(temp)
        }
        stats.restart <- stats.restart+1
        if (p.trace) message("It ",stats.iter,": restarting")
      }
    }
    init.links <- f.p[i.best]==error # if no overall improvement
    stats.stagnate <- ifelse(init.links,stats.stagnate+1,0)
    error <- f.p[i.best]
    if (p.trace && stats.iter%%p.report==0) {
      if (p.reltol!=0) 
        message("It ",stats.iter,": fitness=",signif(error,4),
                ", swarm diam.=",signif(d,4))
      else
        message("It ",stats.iter,": fitness=",signif(error,4))
      if (p.trace.stats) {
        stats.trace.it <- c(stats.trace.it,stats.iter)
        stats.trace.error <- c(stats.trace.error,error)
        stats.trace.f <- c(stats.trace.f,list(f.x))
        stats.trace.x <- c(stats.trace.x,list(X))
      }
    }
  }
  
  if (error<=p.abstol) {
    msg <- "Converged"
    msgcode <- 0
  } else if (stats.feval>=p.maxf) {
    msg <- "Maximal number of function evaluations reached"
    msgcode <- 1
  } else if (stats.iter>=p.maxit) {
    msg <- "Maximal number of iterations reached"
    msgcode <- 2
  } else if (stats.restart>=p.maxrestart) {
    msg <- "Maximal number of restarts reached"
    msgcode <- 3
  } else {
    msg <- "Maximal number of iterations without improvement reached"
    msgcode <- 4
  }
 
  if (p.trace) message(msg)
  
  o <- list(par=P[,i.best],value=f.p[i.best],
            counts=c("function"=stats.feval,"iteration"=stats.iter,
                     "restarts"=stats.restart),
            convergence=msgcode,message=msg)
  if (p.trace && p.trace.stats) o <- c(o,list(stats=list(it=stats.trace.it,
                                                         error=stats.trace.error,
                                                         f=stats.trace.f,
                                                         x=stats.trace.x)))
  return(o)
}
test_f<-function(x){
  a<-sum(x^2-10*cos(2*pi*x)+10)
  return(a)
  
}




pm<-proc.time()
pso<-tpsco(rep(NA,30),test_f,lower=-10,upper=10,control=list(maxit=100,trace=0,REPORT=TRUE,SCOND=T,GUASS=T,m=10,n=10,s=40))
wait<-proc.time()-pm
