minim.internal <- function(objfun, start, est, object, method, transform,
                           verbose = getOption("verbose", FALSE), ...)
{

    ep <- paste0("in ",sQuote("minim"),": ")
    pompLoad(object,verbose=verbose)

    transform <- as.logical(transform)
    est <- as.character(est)

    if (length(start)<1)
        stop(ep,sQuote("start")," must be supplied",call.=FALSE)

    if (transform) {
        start <- partrans(object,start,dir="toEstimationScale")
        if (is.null(names(start))||(!all(est%in%names(start))))
            stop(ep,sQuote("est")," must refer to parameters named in ",
                 sQuote("partrans(object,start,dir=\"toEstimationScale\")"),call.=FALSE)
        guess <- start[est]
    } else {
        if (is.null(names(start))||(!all(est%in%names(start))))
            stop(ep,sQuote("est")," must refer to parameters named in ",
                 sQuote("start"),call.=FALSE)
        guess <- start[est]
    }

    if (length(est)==0) {

        val <- objfun(guess)
        conv <- NA
        evals <- as.integer(c(1,0))
        msg <- "no optimization performed"

    } else {

        opts <- list(...)

        if (method == 'subplex') {
            opt <- subplex::subplex(par=guess,fn=objfun,control=opts)
        } else if (method=="sannbox") {
            opt <- sannbox(par=guess,fn=objfun,control=opts)
        } else if (method=="nloptr") {
            opt <- nloptr::nloptr(x0=guess,eval_f=objfun,opts=opts)
        } else {
            opt <- optim(par=guess,fn=objfun,method=method,control=opts)
        }

        msg <- as.character(opt$message)

        if (method == "nloptr") {

            val <- opt$objective
            start[est] <- unname(opt$solution)
            conv <- opt$status
            evals <- opt$iterations

        } else {

            val <- opt$value
            start[est] <- unname(opt$par)
            conv <- opt$convergence
            evals <- opt$counts

        }
    }

    if (transform)
        start <- partrans(object,start,dir="fromEstimationScale")

    pompUnload(object,verbose=verbose)

    list(
        params=start,
        est=est,
        transform=transform,
        value=val,
        convergence=as.integer(conv),
        evals=as.integer(evals),
        msg=msg
    )
}
