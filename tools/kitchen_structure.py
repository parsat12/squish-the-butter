"""One identical starter kitchen, authored relative to a plot's build surface."""


def kitchen_parts():
    parts = []
    white, grey, teal = (240, 245, 240), (162, 175, 179), (63, 166, 156)
    def p(name, pos, size, color, **extra):
        parts.append(dict(name=name, position=pos, size=size, color=color, **extra))
    p("KitchenFloor", (-18, 0.3, -12), (44, 0.6, 38), (207, 220, 222))
    for x in range(-36, 1, 8):
        for z in range(-27, 0, 8):
            if ((x + 36) // 8 + (z + 27) // 8) % 2 == 0:
                p("FloorTile", (x, 0.63, z), (7.8, 0.06, 7.8), (229, 236, 232))
    p("BackWall", (-18, 9.6, 6.5), (44, 18, 1), white)
    p("LeftWall", (-39.5, 9.6, -12), (1, 18, 38), white)
    p("BackTrim", (-18, 18.7, 6.5), (44, 0.6, 1.2), teal)
    p("LeftTrim", (-39.5, 18.7, -12), (1.2, 0.6, 38), teal)
    for x in (-26, -16, -6):
        p("CounterCabinet", (x, 3.6, 2), (9, 6, 7), (194, 202, 183))
        p("Countertop", (x, 7, 2), (9.5, 0.8, 7.6), white)
        p("LowerDoor", (x, 3.7, -1.6), (8.3, 5.2, 0.25), (218, 223, 209))
        p("LowerHandle", (x + 2.8, 5, -1.85), (0.5, 1.6, 0.4), grey)
        p("WallCabinet", (x, 13, 4), (8.5, 5, 4), (216, 224, 213))
        p("UpperDoor", (x, 13, 1.9), (7.8, 4.5, 0.3), white)
        p("UpperHandle", (x + 2.6, 12.4, 1.65), (0.4, 1.3, 0.4), grey)
    p("SinkRim", (-16, 7.5, 2), (6.2, 0.3, 5), grey)
    p("SinkBasin", (-16, 7.68, 2), (4.8, 0.1, 3.6), (93, 120, 132))
    p("FaucetStem", (-16, 8.8, 4.4), (0.6, 2.5, 0.6), grey)
    p("FaucetSpout", (-16, 9.8, 3.5), (0.6, 0.6, 2.3), grey)
    p("Refrigerator", (-34, 7.6, -3), (8, 14, 7), white)
    p("FreezerDoor", (-34, 12, -6.65), (7.5, 4.2, 0.35), (219, 230, 229))
    p("FridgeDoor", (-34, 5.5, -6.65), (7.5, 8.2, 0.35), (228, 237, 233))
    p("FreezerHandle", (-31.4, 11.5, -7), (0.6, 2.5, 0.5), grey)
    p("FridgeHandle", (-31.4, 7, -7), (0.6, 3.5, 0.5), grey)
    p("CrackingTable", (-33, 5.5, -22), (10, 1, 9), (210, 187, 138))
    for x in (-37, -29):
        for z in (-25.5, -18.5):
            p("TableLeg", (x, 2.8, z), (1, 5, 1), grey)
    p("CrackingBoard", (-33, 6.1, -22), (6, 0.2, 5), (244, 220, 161))
    p("RoamArea", (-15, 0.7, -17), (25, 0.05, 17), teal, invisible=True)
    p("TrainingPad", (24, 0.15, -14), (28, 0.3, 28), (105, 151, 170))
    for x in (10.5, 37.5):
        p("TrainingBorder", (x, 0.4, -14), (0.6, 0.2, 28), (247, 203, 92))
    for z in (-27.5, -0.5):
        p("TrainingBorder", (24, 0.4, z), (28, 0.2, 0.6), (247, 203, 92))
    p("BagBase", (24, 1, -14), (10, 1.4, 10), (57, 67, 77), shape="Cylinder")
    p("BagStem", (24, 6, -14), (1, 10, 1), grey)
    p("PunchingBag", (24, 12, -14), (6, 12, 6), (218, 99, 97), shape="Cylinder")
    p("BagCap", (24, 18.2, -14), (6.2, 0.5, 6.2), (57, 67, 77), shape="Cylinder")
    # Four low corner markers reserve expansion space without filling the plot.
    for x in (-39, 3):
        for z in (13, 37):
            p("ExpansionCornerX", (x, 0.2, z), (4, 0.2, 0.5), teal)
            p("ExpansionCornerZ", (x, 0.2, z), (0.5, 0.2, 4), teal)
    return parts
