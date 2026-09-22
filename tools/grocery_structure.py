"""Author the five straight grocery zones at the map's original scale."""
import math

WHITE = (245, 249, 246)
TEAL = (35, 174, 160)
RAINBOW = [(255, 91, 118), (255, 166, 66), (255, 224, 80),
           (82, 226, 149), (78, 193, 255), (190, 117, 255)]
ZONES = [
    dict(id="Plain", length=160, width=128, height=38, accent=(255, 209, 65), wall=(249, 246, 219), floor=(241, 239, 214), light=(255, 246, 215)),
    dict(id="Salted", length=200, width=140, height=46, accent=(82, 195, 235), wall=(202, 230, 239), floor=(216, 238, 240), light=(172, 224, 255)),
    dict(id="Golden", length=240, width=152, height=56, accent=(244, 187, 51), wall=(104, 64, 87), floor=(247, 227, 169), light=(255, 204, 116)),
    dict(id="Rainbow", length=280, width=164, height=68, accent=(247, 103, 179), wall=(221, 231, 252), floor=(220, 239, 238), light=(187, 240, 255)),
    dict(id="Cosmic", length=320, width=176, height=84, accent=(106, 235, 255), wall=(44, 25, 79), floor=(64, 47, 102), light=(157, 145, 255)),
]


def build_grocery(part):
    def p(name, group, pos, size, color, **kwargs):
        light = kwargs.pop("light", None)
        if name == "CeilingLight" and light:
            kwargs["light"] = dict(light, brightness=0.12)
        return part(name, group, pos, size, color, **kwargs)

    def sign(group, name, text, pos, size, color, yaw=0):
        # Keep structural crossbeams, but omit advertising panels and labels.
        structural = {"TierGate": "TierArch", "GrocerySign": "FacadeHeader"}
        if name in structural:
            return p(structural[name], group, pos, size, color, yaw=yaw)

    def butter(group, pos, size, color, text, yaw=0):
        x, y, z = pos
        sx, sy, sz = size
        p("OversizedButter", group, pos, size, color, yaw=yaw)
        sign(group, "ButterLabel", text, (x, y, z + sz / 2 + 0.12),
             (sx * 0.85, sy * 0.65, 0.18), color)

    start = -410
    zones = []
    for index, spec in enumerate(ZONES):
        zone = dict(spec, start=start, end=start - spec["length"], index=index + 1)
        zones.append(zone)
        start = zone["end"]
        group = f'GroceryStore/Section{index + 1:02d}_{zone["id"]}'
        width, height, length = zone["width"], zone["height"], zone["length"]
        center = (zone["start"] + zone["end"]) / 2
        accent = zone["accent"]
        p("OpenFloor", group, (0, 0.25, center), (width, 0.5, length), zone["floor"])
        p("Ceiling", group, (0, height + 1, center), (width + 4, 2, length), zone["wall"])
        # Side bays and windows leave the central 64-stud lane free end to end.
        bays = length // 40
        for side in (-1, 1):
            x = side * (width / 2 + 1)
            p("WallBase", group, (x, 6, center), (2, 12, length), zone["wall"])
            p("WallCrown", group, (x, (height + 26) / 2, center), (2, height - 26, length), zone["wall"])
            p("AccentRail", group, (side * (width / 2 - 0.2), 11, center), (1, 2, length), accent)
            for bay in range(bays):
                z = zone["start"] - 20 - bay * 40
                p("Window", group, (x, 19, z), (1, 14, 36), (152, 220, 237), transparency=0.58)
                p("WindowMullion", group, (x, 19, z + 19), (3, 16, 3), accent)
                p("WindowCrossbar", group, (x, 19, z), (2, 1, 37), WHITE)
                shelf_x = side * (width / 2 - 10)
                if bay % 2 == 0:
                    for shelf_y in (2, 8, 14):
                        p("EmptyShelf", group, (shelf_x, shelf_y, z), (14, 1.5, 28),
                          RAINBOW[bay % 6] if index == 3 else accent if index >= 2 else WHITE,
                          yaw=side * 0.14 if index == 4 else 0)
                    for dz in (-13, 13):
                        p("ShelfSupport", group, (shelf_x, 8, z + dz), (2, 16, 2), accent)
                else:
                    p("DisplayPlinth", group, (shelf_x, 3, z), (17, 6, 24), accent)
            p("AisleEdge", group, (side * 32, 0.57, center), (0.8, 0.1, length), accent, collide=False)

        for bay in range(bays):
            z = zone["start"] - 20 - bay * 40
            p("CeilingRib", group, (0, height - 1, z), (width, 2, 2), accent)
            p("CeilingLight", group, (0, height - 2.5, z), (36, 1, 4), zone["light"],
              light=dict(color=zone["light"], brightness=0.55, range=min(110, height * 1.7)), collide=False)
            # Floor bands point straight ahead without becoming physical obstacles.
            for side in (-1, 1):
                p("ForwardMarker", group, (side * 3, 0.57, z), (1, 0.1, 8), accent,
                  yaw=side * math.radians(35), collide=False)

        # One open gate per tier. No doors or barriers span the combat lane.
        gate_z = zone["start"] - 3
        for side in (-1, 1):
            p("GatePillar", group, (side * 38, (height - 4) / 2, gate_z), (6, height - 4, 7), accent)
            p("GateBase", group, (side * 38, 3, gate_z), (10, 6, 11), zone["wall"])
        sign(group, "TierGate", f'{index + 1:02d}   {zone["id"].upper()} BUTTER',
             (0, height - 9, gate_z), (82, 10, 6), accent)
        if index > 0:
            previous_height = ZONES[index - 1]["height"]
            p("HeightTransition", group, (0, (height + previous_height) / 2, zone["start"]),
              (width, height - previous_height, 2), zone["wall"])
            for side in (-1, 1):
                p("WidthTransition", group, (side * (width / 2 - 3), previous_height / 2, zone["start"]),
                  (6, previous_height, 2), zone["wall"])

        # Oversized ads face the incoming player and stay outside the center lane.
        for side in (-1, 1):
            ad_x = side * (width / 2 - 15)
            ad_z = center + 12
            sign(group, "FoodAdvertisement", zone["id"].upper() + "\nBUTTER", (ad_x, height - 12, ad_z),
                 (24, 15, 1), accent)
            butter(group, (ad_x, height - 23, ad_z), (18, 6, 7), accent, "BUTTER")

        if index == 0:
            for side in (-1, 1):
                x, z = side * 53, zone["start"] - 63
                p("Refrigerator", group, (x, 10, z), (15, 20, 16), WHITE)
                p("RefrigeratorGlass", group, (x, 11, z + 8.2), (12, 16, 0.4), (146, 219, 238), transparency=0.4)
                p("FridgeHandle", group, (x + 5, 11, z + 8.8), (0.7, 7, 0.7), accent)
                sign(group, "PriceSign", "DAIRY\n$1", (x, 24, z), (16, 7, 1), accent)
                for j in range(2):
                    p("CardboardBox", group, (side * (44 + j * 8), 3, zone["end"] + 20), (7, 6, 7), (194, 151, 101))
        elif index == 1:
            for side in (-1, 1):
                x = side * 49
                p("SaltShaker", group, (x, 13, center - 32), (12, 16, 12), WHITE)
                p("SaltShakerCap", group, (x, 22, center - 32), (14, 3, 14), accent)
                for dx in (-4, 0, 4):
                    p("SaltCapHole", group, (x + dx, 23.6, center - 32), (1.5, 0.2, 1.5), (49, 99, 127))
                sign(group, "SaltLabel", "SALT", (x, 14, center - 25.8), (10, 6, 0.2), accent)
                for j in range(3):
                    p("SaltCrystal", group, (side * (46 + j * 7), 5 + j * 2, zone["end"] + 24),
                      (5, 8 + j * 2, 5), (223, 248, 255), yaw=j * 0.4)
        elif index == 2:
            for side in (-1, 1):
                x = side * 51
                p("PremiumPlinth", group, (x, 5, center), (27, 10, 34), (245, 237, 204))
                butter(group, (x, 16, center), (24, 12, 14), accent, "GOLD")
                for dz in (-23, 23):
                    p("RopePost", group, (side * 37, 5, center + dz), (2, 10, 2), accent)
                p("VelvetRope", group, (side * 37, 8, center), (1.5, 1.5, 46), (156, 37, 74))
        elif index == 3:
            for k, color in enumerate(RAINBOW):
                for side in (-1, 1):
                    p("RainbowRibbon", group, (side * (44 + k * 4), height - 6 - k, center),
                      (3, 2, length - 20), color)
            for side in (-1, 1):
                for j in range(3):
                    butter(group, (side * 53, 22 + j * 9, center - 45 + j * 35), (19, 7, 9), RAINBOW[j * 2], "BUTTER")
        else:
            for side in (-1, 1):
                for j in range(14):
                    z = zone["start"] - 20 - j * 21
                    y = 30 + (j * 13 % 40)
                    x = side * 85
                    p("StarVertical", group, (x, y, z), (1, 6, 1.4), (231, 244, 255), collide=False)
                    p("StarHorizontal", group, (x, y, z), (1, 1.4, 6), (231, 244, 255), collide=False)
                for j in range(4):
                    butter(group, (side * 57, 22 + j * 7, zone["start"] - 65 - j * 49),
                           (19, 8, 9), (157, 111, 239), "COSMIC")
            # Faceted portal frames the final display, never a branching route.
            final_z = zone["end"] + 24
            for k in range(12):
                angle = k * math.tau / 12
                p("PortalSegment", group, (math.cos(angle) * 29, 34 + math.sin(angle) * 29, final_z),
                  (6, 16, 5), accent, roll=angle,
                  light=dict(color=accent, brightness=0.2, range=25) if k % 3 == 0 else None,
                  collide=False)
            p("FinalDisplayBase", group, (0, 4, final_z + 3), (30, 8, 23), (123, 75, 188))
            butter(group, (0, 17, final_z + 3), (27, 13, 15), (172, 119, 255), "COSMIC")
            sign(group, "FinalValue", "10^30 KG", (0, 38, final_z + 4), (30, 7, 1), (95, 61, 159))
            p("EndWall", group, (0, height / 2, zone["end"] - 1), (width + 4, height, 2), zone["wall"])

    group = "GroceryStore/Entrance"
    p("EntranceApron", group, (0, 0.25, -391), (132, 0.5, 38), (229, 239, 232))
    for side in (-1, 1):
        p("FacadePier", group, (side * 60, 20, -410), (10, 40, 8), TEAL)
        p("FrontWindow", group, (side * 47, 16, -407), (16, 28, 1), (140, 220, 238), transparency=0.6)
        # Fully open glass doors flank the entrance; the path remains walkable.
        p("OpenGlassDoor", group, (side * 35, 15, -398), (1, 28, 18), (150, 229, 241), transparency=0.6)
        for z in (-389, -407):
            p("DoorFrame", group, (side * 35, 15, z), (1.6, 29, 1.6), WHITE)
        p("DoorTop", group, (side * 35, 29, -398), (1.6, 1.6, 19), WHITE)
        p("DoorHandle", group, (side * 34, 14, -392), (1, 8, 1), TEAL)
    sign(group, "GrocerySign", "SQUISH GROCERY", (0, 45, -408), (136, 16, 8), TEAL)
    p("SignTopTrim", group, (0, 54, -408), (141, 2, 10), (255, 217, 68))
    for index in range(14):
        p("AwningStripe", group, (-60.45 + index * 9.3, 33, -399), (9.3, 3, 22),
          (255, 112, 138) if index % 2 == 0 else WHITE)
    # Parked wire-basket carts, outside the 64-stud main approach.
    for side in (-1, 1):
        for n in range(2):
            x, z = side * (45 + n * 13), -389
            p("CartBase", group, (x, 3, z), (9, 1, 13), TEAL)
            for dx in (-4, 4):
                for dz in (-5, 5):
                    p("CartWheel", group, (x + dx, 1.4, z + dz), (2, 2.5, 2.5), (65, 74, 78))
                for y in (5, 8, 11):
                    p("BasketRail", group, (x + dx, y, z), (0.6, 0.6, 13), WHITE)
                for dz in (-6, 0, 6):
                    p("BasketUpright", group, (x + dx, 8, z + dz), (0.6, 7, 0.6), WHITE)
            for dz in (-6, 6):
                for y in (5, 8, 11):
                    p("BasketEnd", group, (x, y, z + dz), (9, 0.6, 0.6), WHITE)
            p("CartHandle", group, (x, 12, z + 7), (11, 1.4, 1.4), (255, 112, 138))
    return zones
