reset
set angle degrees
#=================== Parameters ====================
Nx = 150
Ny = 150
array state[Nx*Ny]          # state = 0, 1, ..., numLR
STEP_MAX = 130000
lineWidth = 3
pointSize = 1.47            # Size of a cell
numPNG = 0
SKIP = STEP_MAX#/(25*100)   # Skip by SKIP frame

# Data file
numLR = 9
array datafile[numLR] = ["0R.txt", "1L.txt", "2R.txt" ,"3R.txt", \
                         "4R.txt", "5R.txt" ,"6R.txt", "7L.txt", "8L.txt"]
# Default color of the empty square (dark-grey)
array color[numLR] = ["dark-grey", "#9400d3", "#009e73", "#56b4e9", \
                      "#e69f00", "#f0e442", "#0072b2", "#e51e10", "#000000"]
# Rule LRRRRRLLR (turn left:-1 / turn right:1)
array rule[numLR] = [-1, 1, 1, 1, 1, 1, -1, -1, 1] # -1:LEFT / 1:RIGHT

WHITEN_VAL = int(180./numLR)  # Add this to color, turn whiter

#=================== Functions ====================
# Treat one-dimensional array as two-dimensional
idx(x, y) = x + (y-1)*Nx

# Decide point type of the cells
pointType(i) = (i==1) ? 4 : 5 # empty square:4 / filled square:5

# Color gradation
color(i) = 0x000000 + (WHITEN_VAL*(numLR-i) << 16)+(WHITEN_VAL*(numLR-i) << 8)+(WHITEN_VAL*(numLR-i) << 0) # Base color: Black

#=================== Settings ====================
set term pngcairo truecolor enhanced dashed size 1440, 1440 font 'Times, 26'
folderName = sprintf("png_LRRRRRLLR_%dx%d", Nx, Ny)
system sprintf("mkdir %s", folderName)
set size ratio -1
unset grid
set nokey
set samples 5e3
set xrange [0.5:Nx+0.5]
set yrange [0.5:Ny+0.5]
unset tics
unset border

#=================== Plot ====================
do for [t=0:STEP_MAX:1] {
    if(t%SKIP==0){
        print sprintf("t=%d / png=%d", t, numPNG) # Print in terminal
        set output sprintf("%s/img_%04d.png", folderName, numPNG)
        numPNG = numPNG + 1
        set title sprintf("{Step : %d", t)

        do for [d=1:numLR:1]{
            set print datafile[d]
            print sprintf("# step:%d", t)
            unset print
        }
    }

    #---------- Initiate state of Langton's ant ----------
    if(t==0){
        cellPos_x = int(Nx/2)
        cellPos_y = int(Ny/2)
        moveDir_x = 0
        moveDir_y = 1

        do for [i=1:Nx:1] {
            do for [j=1:Ny:1] {
                state[idx(i, j)] = 0
            }
        }
    } else {
        #---------- Update the ant according to the rules ----------
        # Position of the ant
        k = idx(cellPos_x, cellPos_y)

        # Flip the color of the square
        do for [d=1:numLR:1] {
            if(state[k] == d-1){
                tmpDir = moveDir_x     # Turn left or right
                moveDir_x = rule[d] * moveDir_y
                moveDir_y = (-1*rule[d]) * tmpDir
                state[k] = d%numLR     # Change the color of the square
                break
            }
        }

        # Move forward one unit
        cellPos_x = cellPos_x + moveDir_x
        cellPos_y = cellPos_y + moveDir_y

        # Periodic boundary conditions
        cellPos_x = (cellPos_x > Nx) ? 1 : (cellPos_x < 1 ? Nx :cellPos_x)
        cellPos_y = (cellPos_y > Ny) ? 1 : (cellPos_y < 1 ? Ny :cellPos_y)
    }

    if(t%SKIP == 0){
        # Make up the list of position of the square
        do for [d=1:numLR:1]{
            set print datafile[d] append
            do for [i=1:Nx:1] {
                do for [j=1:Ny:1] {
                    if(state[idx(i, j)] == d-1){
                        print i, j
                    }
                }
            }
            unset print
        }

        # Draw the cells and the ant
        plotCommand = "plot "
        do for [d=1:numLR:1] {
            # plotCommand = plotCommand.sprintf("datafile[%d] w p pt %d ps %.3f lt %d, ", d, pointType[d], pointSize, d-1)
            plotCommand = plotCommand.sprintf("datafile[%d] w p pt %d ps %.3f lc rgb %d, ", d, pointType(d), pointSize, color(d))
        }
        plotCommand = plotCommand.sprintf("\"<echo '%d, %d'\" w p pt 4 ps pointSize lt 7", cellPos_x, cellPos_y)
        eval plotCommand

     	set out # Output PNG file
    }
}
