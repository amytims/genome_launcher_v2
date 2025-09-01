args = commandArgs(trailingOnly=TRUE)

r <- read.table(paste0(args[1],"/read_lengths.txt"))

# longest read across all files
xmax <- ceiling(max(r$V1/1000))*1000

# tallest bar including all reads
ymax <- ceiling(max(hist(r$V1, breaks=seq(from=0, to=xmax, by=1000), plot=F)$counts)/50000)*50000

# how many sample files did we have?
nfiles <- length(unique(r$V2))

cols <- colorRampPalette(c("#440154FF", "#21908CFF", "#FDE725FF"), interpolate="spline")(nfiles)

pdf(paste0(args[2], "_read_length_distributions.pdf"), height=6, width=9)
    par(oma=c(0.5,1,0.5,8), xpd=NA)

    # histogram of all files
    hist(r$V1, breaks=seq(from=0, to=xmax, by=1000), las=1, ylim=c(0, ymax),
        main=paste(args[2], "read length distribution"),
        xlab="read length", ylab="", col=cols[1])

        # data summary for the last file in the list
        points(x=0.7*xmax, y=0.85*ymax, pch = 15, cex = 2, col=cols[1])
        text(x=0.7*xmax, y=0.85*ymax, unique(r$V2)[1], pos=4, cex=0.7)
        text(x=0.72*xmax, y=0.8*ymax, paste("num reads:", length(r$V1[which(r$V2==unique(r$V2)[1])])), pos=4, cex=0.7)
        text(x=0.92*xmax, y=0.8*ymax, paste("mean length:", round(mean(r$V1[which(r$V2==unique(r$V2)[1])]),0)), pos=4, cex=0.7)
        text(x=1.12*xmax, y=0.8*ymax, paste("median length:", median(r$V1[which(r$V2==unique(r$V2)[1])])), pos=4, cex=0.7)


    if (nfiles > 1) {
        for (i in 2:nfiles) {
            hist(r$V1[which(r$V2 %in% unique(r$V2)[i:nfiles])], breaks=seq(from=0, to=xmax, by=1000), las=1, col=cols[i], add=T)

            points(x=0.7*xmax, y=(0.85-(0.15*(i-1)))*ymax, pch = 15, cex = 2, col=cols[i])
            text(x=0.7*xmax, y=(0.85-(0.15*(i-1)))*ymax, unique(r$V2)[i], pos=4, cex=0.7)
            text(x=0.72*xmax, y=(0.8-(0.15*(i-1)))*ymax, paste("num reads:", length(r$V1[which(r$V2==unique(r$V2)[i])])), pos=4, cex=0.7)
            text(x=0.92*xmax, y=(0.8-(0.15*(i-1)))*ymax, paste("mean length:", round(mean(r$V1[which(r$V2==unique(r$V2)[i])]),0)), pos=4, cex=0.7)
            text(x=1.12*xmax, y=(0.8-(0.15*(i-1)))*ymax, paste("median length:", median(r$V1[which(r$V2==unique(r$V2)[i])])), pos=4, cex=0.7)
        }
    }

    text(pos=3, x=0.5*xmax, y=1*ymax, cex=0.7, paste("total reads:", length(r$V1), "   mean length:", round(mean(r$V1),0), "   median length:", median(r$V1)))
    rect(xleft=0.67*xmax,xright=1.35*xmax,ybot=(0.76-(0.15*(nfiles-1)))*ymax, ytop=0.89*ymax)
    
dev.off()