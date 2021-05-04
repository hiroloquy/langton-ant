reset
set angle degrees
#=================== Parameters ====================
Nx = 150
Ny = 150
array state[Nx*Ny]      # state = 0, 1, ..., numLR
STEP_MAX = 40000
pointSize = 1.47        # Size of a cell
numPNG = 0
SKIP = STEP_MAX/(25*100)

# Data file
numLR = 12
array datafile[numLR] = ["0R.txt", "1L.txt", "2L.txt", "3R.txt", \
                         "4R.txt", "5R.txt", "6L.txt", "7R.txt", \
                         "8L.txt", "9R.txt", "10L.txt", "11L.txt"]
# Colors of the cells (empty:dark-grey)
array color[numLR] = ["dark-grey", "#9400d3", "#009e73", "#56b4e9", \
                      "#e69f00", "#f0e442", "#0072b2", "#e51e10", \
                      "#000000", "magenta", "brown4", "pink"]
# Rule LLRRRLRLRLLR (turn left:-1 / turn right:1)
array rule[numLR] = [-1,-1,1,1,1,-1,1,-1,1,-1,-1,1]

#=================== Functions ====================
# Treat one-dimensional array as two-dimensional
idx(x, y) = x + (y-1)*Nx
# Decide point type of the cells
pointType(i) = (i==1) ? 4 : 5 # empty square:4 / filled square:5

#=================== Settings ====================
set term pngcairo truecolor enhanced dashed size 1440, 1440 font 'Times, 26'
folderName = "png_LLRRRLRLRLLR"
system sprintf("mkdir %s", folderName)
set size ratio -1
unset grid
set nokey
set xrange [0.5:Nx+0.5]
set yrange [0.5:Ny+0.5]
unset tics
unset border

#=================== Plot ====================
do for [t=0:STEP_MAX:1]{
    if(t%SKIP==0){
        print sprintf("t=%d / png=%d", t, numPNG) # Print in terminal
        set output sprintf("%s/img_%04d.png", folderName, numPNG)
        numPNG = numPNG + 1
        set title sprintf("{Step : %d", t)

        # Make txt files
        do for [s=1:numLR:1]{
            set print datafile[s]
            print sprintf("# step:%d", t)
            unset print
        }
    }

    #---------- Initiate state of Langton's ant ----------
    if(t==0){
        cellPos_x = int(Nx*0.87)
        cellPos_y = int(Ny*0.5)
        moveDir_x = 0
        moveDir_y = 1

        do for [i=1:Nx:1] {
            do for [j=1:Ny:1] {
                state[idx(i, j)] = 0
            }
        }
    } else {
    #---------- Update the ant according to the rules ----------
        k = idx(cellPos_x, cellPos_y)  # Position of the ant

        do for [s=1:numLR:1] {
            if(state[k] == s-1){
                tmpDir = moveDir_x     # Turn left or right
                moveDir_x = rule[s] * moveDir_y
                moveDir_y = (-1*rule[s]) * tmpDir
                state[k] = s%numLR     # Change the color of the square
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
        do for [s=1:numLR:1]{
            set print datafile[s] append
            do for [i=1:Nx:1] {
                do for [j=1:Ny:1] {
                    if(state[idx(i, j)] == s-1){
                        print i, j
                    }
                }
            }
            unset print
        }

        # Draw the cells and the ant
        plotCommand = "plot "
        do for [s=1:numLR:1] { # Cells
            plotCommand = plotCommand.sprintf("datafile[%d] w p pt %d ps %.3f lc rgb \"%s\", ", s, pointType(s), pointSize, color[s])
        }
        plotCommand = plotCommand.sprintf("\"<echo '%d, %d'\" w p pt 4 ps pointSize lt 7", cellPos_x, cellPos_y) # Ant
        eval plotCommand

     	set out # Output PNG file
    }
}
