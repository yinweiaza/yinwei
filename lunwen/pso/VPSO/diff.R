diff<-function(x){
 #pso<-tpsco(rep(NA,30),test_f,lower=-100,upper=100,control=list(maxit=x,trace=0,SCOND=FALSE,GUASS=FALSE,m=10,r=10,n=10))
  #tpso<-tpsco(rep(NA,30),test_f,lower=-100,upper=100,control=list(maxit=x,trace=0,SCOND=TRUE,GUASS=FALSE,m=10,r=10,n=10))
  psco<-tpsco(rep(NA,30),test_f,lower=-100,upper=100,control=list(maxit=100,trace=0,SCOND=FALSE,GUASS=TRUE,m=10,n=10))  
  end<-tpsco(rep(NA,30),test_f,lower=-100,upper=100,control=list(maxit=100,trace=0,SCOND=TRUE,GUASS=TRUE,m=10,n=10))
  cbind(psco$value,end$value)
  #
}

f_name<-"Sphere"
d<-"---------------------------------------------------------"

result<-sapply(1:30,diff)

com1<-apply(result,1,mean)
com2<-apply(result,1,sd)

#dump(c("f_name","com1","com2","d"),file="record1",append=TRUE)