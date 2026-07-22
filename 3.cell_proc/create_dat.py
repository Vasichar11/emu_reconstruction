# Scanned area in microns
X_MIN, X_MAX = 5000, 35000
Y_MIN, Y_MAX = 75000, 125000

with open("volumes.dat", "w+") as file:
    for plate in range(1, 58):
        for cell in range(0, 324):
            xpos = (cell % 18 + 1) * 10000
            ypos = (cell // 18 + 1) * 10000
            if X_MIN <= xpos <= X_MAX and Y_MIN <= ypos <= Y_MAX:
                file.write(f"{plate},{cell}\n")